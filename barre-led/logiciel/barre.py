#!/usr/bin/env python3
"""Barre LED 4 × HUB75 — affichage + télécommande web pour iPhone.

Lancement (en root, nécessaire pour piloter le GPIO) :
    sudo python3 barre.py
Puis, sur l'iPhone, ouvrir http://<nom-du-pi>.local dans Safari
et « Partager → Sur l'écran d'accueil ».

Deux onglets dans la page :
  - Texte  : texte défilant / fixe / horloge, couleur, vitesse, police ;
  - Médias : photos, GIF et vidéos téléversés depuis l'iPhone, convertis une fois
             au format de la barre puis rejoués en boucle (vidéos : ffmpeg requis).

Réglages matériels : constantes ci-dessous, ou variables d'environnement
(BARRE_CHAINE, BARRE_PARALLELE, BARRE_PORT, BARRE_POLICES, ...).
"""
import datetime
import glob
import json
import os
import queue
import re
import secrets
import shutil
import socket
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from PIL import Image, ImageOps, UnidentifiedImageError
from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics

# ---------------------------------------------------------------- réglages
CHAINE = int(os.environ.get("BARRE_CHAINE", 2))        # panneaux par chaîne (4 plus tard)
PARALLELE = int(os.environ.get("BARRE_PARALLELE", 1))  # chaînes en parallèle (ports de la carte)
MAPPING = os.environ.get("BARRE_MAPPING", "regular")   # carte Adafruit Triple Active3
RALENTI_GPIO = int(os.environ.get("BARRE_RALENTI", 2))
PORT = int(os.environ.get("BARRE_PORT", 80))

ICI = os.path.dirname(os.path.abspath(__file__))
FICHIER_ETAT = os.path.join(ICI, "etat.json")
DOSSIER_MEDIAS = os.path.join(ICI, "medias")

TAILLE_MAX_TELEVERSEMENT = 500 * 1024 * 1024   # 500 Mo
DUREE_MAX_VIDEO = 300                          # s (au-delà, la vidéo est coupée)
IMAGES_PAR_SECONDE = 25                        # cadence des vidéos converties
EXT_IMAGES = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".tif", ".tiff"}
CADRAGES = ("remplir", "ajuster", "etirer")

MODES = ("defilant", "fixe", "horloge", "media")
JOURS = ("lun.", "mar.", "mer.", "jeu.", "ven.", "sam.", "dim.")
MOIS = ("janv.", "févr.", "mars", "avr.", "mai", "juin",
        "juil.", "août", "sept.", "oct.", "nov.", "déc.")
ANCIENNES_POLICES = {"petite": "6x13B.bdf", "moyenne": "9x18B.bdf",
                     "grande": "10x20.bdf", "geante": "texgyre-27.bdf"}

ETAT_DEFAUT = {
    "allume": True,
    "mode": "defilant",
    "texte": "Bonjour Bitwerk",
    "couleur": "#ff3c28",
    "vitesse": 40,          # pixels par seconde
    "luminosite": 50,       # %
    "police": "9x18B.bdf",
    "media": "",            # identifiant du média affiché en mode « media »
}

RE_ID = re.compile(r"[0-9a-f]{16}")


# ---------------------------------------------------------------- polices
def trouver_dossier_polices():
    candidats = [os.environ.get("BARRE_POLICES", ""),
                 os.path.join(ICI, "fonts"),
                 *glob.glob("/home/*/rpi-rgb-led-matrix/fonts"),
                 "/root/rpi-rgb-led-matrix/fonts"]
    for d in candidats:
        if d and os.path.isfile(os.path.join(d, "9x18B.bdf")):
            return d
    raise SystemExit("Polices BDF introuvables : définir BARRE_POLICES=/chemin/rpi-rgb-led-matrix/fonts")


DOSSIER_POLICES = trouver_dossier_polices()


def lire_entete_bdf(chemin):
    """Famille, graisse, ascendante et descendante d'une police BDF."""
    info = {"famille": "", "gras": False, "ascent": 0, "descent": 0}
    with open(chemin, encoding="latin-1") as f:
        for ligne in f:
            if ligne.startswith("FAMILY_NAME"):
                info["famille"] = ligne.split(None, 1)[1].strip().strip('"')
            elif ligne.startswith("WEIGHT_NAME"):
                info["gras"] = "bold" in ligne.lower()
            elif ligne.startswith("FONT_ASCENT"):
                info["ascent"] = int(ligne.split()[1])
            elif ligne.startswith("FONT_DESCENT"):
                info["descent"] = int(ligne.split()[1])
            elif ligne.startswith("CHARS ") or ligne.startswith("STARTCHAR"):
                break
    return info


def lister_polices():
    polices = []
    for chemin in glob.glob(os.path.join(DOSSIER_POLICES, "*.bdf")):
        info = lire_entete_bdf(chemin)
        hauteur = info["ascent"] + info["descent"]
        if not 0 < hauteur <= 32:
            continue
        fichier = os.path.basename(chemin)
        nom = os.path.splitext(fichier)[0]
        detail = info["famille"] + (" gras" if info["gras"] else "")
        polices.append({"id": fichier, "nom": f"{nom} · {detail} · {hauteur} px",
                        "hauteur": hauteur, "ascent": info["ascent"]})
    polices.sort(key=lambda p: (p["hauteur"], p["id"]))
    return polices


POLICES = {p["id"]: p for p in lister_polices()}


# ---------------------------------------------------------------- état partagé
verrou = threading.Lock()
etat = dict(ETAT_DEFAUT)
version = 0                 # incrémentée à chaque changement (relance le défilement / le média)
taille_toile = None         # (largeur, hauteur), connue une fois la matrice initialisée
toile_prete = threading.Event()


def charger_etat():
    global etat
    try:
        with open(FICHIER_ETAT, encoding="utf-8") as f:
            lu = json.load(f)
        etat = valider({**ETAT_DEFAUT, **lu})
    except (OSError, ValueError, KeyError):
        etat = dict(ETAT_DEFAUT)


def ecrire_json(chemin, donnees):
    tmp = chemin + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=1)
    os.replace(tmp, chemin)


def borne(v, mini, maxi):
    return max(mini, min(maxi, int(v)))


def valider(e):
    """Retourne un état propre à partir d'un état complet (valeurs corrigées au besoin)."""
    police = ANCIENNES_POLICES.get(e["police"], e["police"])
    media = e["media"] if RE_ID.fullmatch(str(e["media"])) else ""
    return {
        "allume": bool(e["allume"]),
        "mode": e["mode"] if e["mode"] in MODES else "defilant",
        "texte": str(e["texte"]).replace("\n", " ")[:200],
        "couleur": e["couleur"] if re.fullmatch(r"#[0-9a-fA-F]{6}", str(e["couleur"])) else "#ffffff",
        "vitesse": borne(e["vitesse"], 5, 150),
        "luminosite": borne(e["luminosite"], 1, 100),
        "police": police if police in POLICES else "9x18B.bdf",
        "media": media,
    }


# ---------------------------------------------------------------- médias
def dossier_media(ident):
    return os.path.join(DOSSIER_MEDIAS, ident)


def lire_meta(ident):
    try:
        with open(os.path.join(dossier_media(ident), "meta.json"), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def lister_medias():
    medias = []
    for d in glob.glob(os.path.join(DOSSIER_MEDIAS, "*")):
        meta = lire_meta(os.path.basename(d))
        if meta:
            medias.append(meta)
    medias.sort(key=lambda m: m.get("cree", 0), reverse=True)
    return medias


file_conversion = queue.Queue()


def cadrer_image(img, w, h, cadrage):
    if cadrage == "ajuster":
        fond = Image.new("RGB", (w, h))
        petite = ImageOps.contain(img, (w, h), Image.LANCZOS)
        fond.paste(petite, ((w - petite.width) // 2, (h - petite.height) // 2))
        return fond
    if cadrage == "etirer":
        return img.resize((w, h), Image.LANCZOS)
    return ImageOps.fit(img, (w, h), Image.LANCZOS)


def filtre_ffmpeg(w, h, cadrage):
    if cadrage == "ajuster":
        return (f"scale={w}:{h}:force_original_aspect_ratio=decrease:flags=area,"
                f"pad={w}:{h}:(ow-iw)/2:(oh-ih)/2")
    if cadrage == "etirer":
        return f"scale={w}:{h}:flags=area"
    return f"scale={w}:{h}:force_original_aspect_ratio=increase:flags=area,crop={w}:{h}"


def convertir(ident):
    """Convertit l'original d'un média en images brutes RGB au format de la barre."""
    toile_prete.wait()
    w, h = taille_toile
    d = dossier_media(ident)
    meta = lire_meta(ident)
    if not meta:
        return
    meta.update(statut="conversion", erreur="")
    ecrire_json(os.path.join(d, "meta.json"), meta)
    source = os.path.join(d, meta["original"])
    brut = os.path.join(d, "images.rgb")
    try:
        image_fixe = None
        if os.path.splitext(source)[1].lower() in EXT_IMAGES:
            try:
                img = Image.open(source)
            except UnidentifiedImageError:
                raise RuntimeError("format d'image non reconnu") from None
            if not getattr(img, "is_animated", False):
                image_fixe = img
        if image_fixe is not None:
            img = ImageOps.exif_transpose(image_fixe).convert("RGB")
            with open(brut, "wb") as f:
                f.write(cadrer_image(img, w, h, meta["cadrage"]).tobytes())
            fps = 1
        else:
            if not shutil.which("ffmpeg"):
                raise RuntimeError("ffmpeg absent : sudo apt install -y ffmpeg")
            commande = ["nice", "-n", "10", "ffmpeg", "-v", "error", "-y", "-i", source,
                        "-t", str(DUREE_MAX_VIDEO), "-an",
                        "-vf", f"fps={IMAGES_PAR_SECONDE}," + filtre_ffmpeg(w, h, meta["cadrage"]),
                        "-f", "rawvideo", "-pix_fmt", "rgb24", brut]
            r = subprocess.run(commande, capture_output=True, text=True)
            if r.returncode != 0:
                raise RuntimeError((r.stderr.strip().splitlines() or ["échec de ffmpeg"])[-1][:200])
            fps = IMAGES_PAR_SECONDE
        n = os.path.getsize(brut) // (w * h * 3)
        if n == 0:
            raise RuntimeError("aucune image lisible dans ce fichier")
        with open(brut, "rb") as f:
            premiere = Image.frombytes("RGB", (w, h), f.read(w * h * 3))
        premiere.resize((w * 4, h * 4), Image.NEAREST).save(os.path.join(d, "apercu.png"))
        meta.update(statut="pret", w=w, h=h, n=n, fps=fps)
    except Exception as ex:                                   # noqa: BLE001 — remonté à la page
        meta.update(statut="erreur", erreur=str(ex).replace(source, meta["nom"])[:200] or ex.__class__.__name__)
    ecrire_json(os.path.join(d, "meta.json"), meta)


def boucle_conversion():
    while True:
        ident = file_conversion.get()
        try:
            convertir(ident)
        finally:
            file_conversion.task_done()


# ---------------------------------------------------------------- affichage
def largeur(police, texte):
    return sum(police.CharacterWidth(ord(c)) for c in texte)


def texte_horloge(police, largeur_dispo):
    m = datetime.datetime.now()
    heure = m.strftime("%H:%M")
    complet = f"{heure}  {JOURS[m.weekday()]} {m.day} {MOIS[m.month - 1]}"
    return complet if largeur(police, complet) <= largeur_dispo else heure


class Lecteur:
    """Rejoue un média converti (images RGB brutes) en boucle."""

    def __init__(self):
        self.ident = None
        self.meta = None
        self.fichier = None
        self.debut = 0.0
        self.verifie = 0.0
        self.reconversion_demandee = set()

    def fermer(self):
        if self.fichier:
            self.fichier.close()
        self.fichier, self.meta = None, None

    def image(self, ident, w, h, maintenant):
        """Retourne (image PIL ou None, délai avant la prochaine image)."""
        if ident != self.ident or maintenant - self.verifie > 1.0:
            meta = lire_meta(ident) if ident else None
            if ident != self.ident or meta != self.meta:
                self.fermer()
                self.ident, self.meta, self.debut = ident, meta, maintenant
                if meta and meta.get("statut") == "pret":
                    if (meta["w"], meta["h"]) != (w, h):     # taille de la barre changée
                        if ident not in self.reconversion_demandee:
                            self.reconversion_demandee.add(ident)
                            file_conversion.put(ident)
                    else:
                        self.fichier = open(os.path.join(dossier_media(ident), "images.rgb"), "rb")
            self.verifie = maintenant
        if not self.fichier:
            return None, 0.2
        m = self.meta
        taille = w * h * 3
        i = int((maintenant - self.debut) * m["fps"]) % m["n"]
        self.fichier.seek(i * taille)
        img = Image.frombytes("RGB", (w, h), self.fichier.read(taille))
        return img, (1.0 / m["fps"] if m["n"] > 1 else 0.2)


def boucle_affichage():
    global taille_toile
    o = RGBMatrixOptions()
    o.rows, o.cols = 32, 64
    o.chain_length, o.parallel = CHAINE, PARALLELE
    o.hardware_mapping = MAPPING
    o.gpio_slowdown = RALENTI_GPIO
    o.drop_privileges = False           # garde les droits pour écrire etat.json et les médias
    matrice = RGBMatrix(options=o)
    toile = matrice.CreateFrameCanvas()
    w, h = toile.width, toile.height
    taille_toile = (w, h)
    toile_prete.set()

    polices = {}

    def police(fichier):
        if fichier not in polices:
            p = graphics.Font()
            p.LoadFont(os.path.join(DOSSIER_POLICES, fichier))
            polices[fichier] = p
        return polices[fichier]

    lecteur = Lecteur()
    x = float(w)
    vu = -1
    t_prec = time.monotonic()
    while True:
        with verrou:
            e = dict(etat)
            v = version
        maintenant = time.monotonic()
        if v != vu:                     # réglage changé : on repart du bord droit / du début
            x, vu = float(w), v
            lecteur.ident = None
        dt, t_prec = maintenant - t_prec, maintenant

        matrice.brightness = e["luminosite"]
        toile.brightness = e["luminosite"]
        toile.Clear()
        pause = 0.1
        if e["allume"] and e["mode"] == "media":
            img, pause = lecteur.image(e["media"], w, h, maintenant)
            if img is not None:
                toile.SetImage(img)
        elif e["allume"]:
            p = police(e["police"])
            info = POLICES[e["police"]]
            r, g, b = (int(e["couleur"][i:i + 2], 16) for i in (1, 3, 5))
            couleur = graphics.Color(r, g, b)
            y = (h - info["hauteur"]) // 2 + info["ascent"]
            if e["mode"] == "defilant":
                lg = graphics.DrawText(toile, p, int(x), y, couleur, e["texte"])
                x -= e["vitesse"] * dt
                if x + lg < 0:
                    x = float(w)
                pause = 0
            else:
                t = e["texte"] if e["mode"] == "fixe" else texte_horloge(p, w)
                graphics.DrawText(toile, p, (w - largeur(p, t)) // 2, y, couleur, t)
        toile = matrice.SwapOnVSync(toile)
        reste = pause - (time.monotonic() - maintenant)
        if reste > 0:
            time.sleep(reste)


# ---------------------------------------------------------------- serveur web
PAGE = open(os.path.join(ICI, "page.html"), encoding="utf-8").read()


class Requete(BaseHTTPRequestHandler):
    def _repondre(self, code, corps, type_="application/json"):
        donnees = corps if isinstance(corps, bytes) else corps.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", type_)
        self.send_header("Content-Length", str(len(donnees)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(donnees)

    def _json(self, code, objet):
        self._repondre(code, json.dumps(objet, ensure_ascii=False))

    def _erreur(self, code, message):
        self._json(code, {"erreur": message})

    # -------- GET
    def do_GET(self):
        chemin = urlparse(self.path).path
        if chemin in ("/", "/index.html"):
            return self._repondre(200, PAGE, "text/html; charset=utf-8")
        if chemin == "/api/etat":
            with verrou:
                return self._json(200, etat)
        if chemin == "/api/polices":
            return self._json(200, [{"id": p["id"], "nom": p["nom"]} for p in POLICES.values()])
        if chemin == "/api/medias":
            return self._json(200, lister_medias())
        m = re.fullmatch(r"/medias/([0-9a-f]{16})/apercu\.png", chemin)
        if m:
            try:
                with open(os.path.join(dossier_media(m.group(1)), "apercu.png"), "rb") as f:
                    return self._repondre(200, f.read(), "image/png")
            except OSError:
                pass
        self._erreur(404, "introuvable")

    # -------- POST
    def do_POST(self):
        url = urlparse(self.path)
        if url.path == "/api/etat":
            return self._changer_etat()
        if url.path == "/api/medias":
            return self._televerser(parse_qs(url.query))
        self._erreur(404, "introuvable")

    def _changer_etat(self):
        global etat, version
        try:
            n = int(self.headers.get("Content-Length", 0))
            recu = json.loads(self.rfile.read(min(n, 10000)) or b"{}")
            if not isinstance(recu, dict):
                raise ValueError
            with verrou:
                nouveau = valider({**etat, **{k: v for k, v in recu.items() if k in ETAT_DEFAUT}})
                if any(nouveau[k] != etat[k] for k in ("texte", "mode", "police", "allume", "media")):
                    version += 1
                etat = nouveau
                ecrire_json(FICHIER_ETAT, etat)
                return self._json(200, etat)
        except (ValueError, TypeError, KeyError):
            self._erreur(400, "requête invalide")

    def _televerser(self, params):
        try:
            taille = int(self.headers.get("Content-Length", 0))
        except ValueError:
            taille = 0
        if taille <= 0:
            return self._erreur(400, "fichier vide")
        if taille > TAILLE_MAX_TELEVERSEMENT:
            return self._erreur(413, "fichier trop gros (500 Mo maximum)")
        nom = (params.get("nom") or ["media"])[0][:120]
        cadrage = (params.get("cadrage") or ["remplir"])[0]
        if cadrage not in CADRAGES:
            cadrage = "remplir"
        ext = os.path.splitext(nom)[1].lower()
        if not re.fullmatch(r"\.[a-z0-9]{1,5}", ext):
            ext = ".bin"
        ident = secrets.token_hex(8)
        d = dossier_media(ident)
        os.makedirs(d)
        original = "original" + ext
        try:
            with open(os.path.join(d, original), "wb") as f:
                reste = taille
                while reste > 0:
                    bloc = self.rfile.read(min(reste, 1 << 20))
                    if not bloc:
                        raise ConnectionError
                    f.write(bloc)
                    reste -= len(bloc)
        except (ConnectionError, OSError):
            shutil.rmtree(d, ignore_errors=True)
            return self._erreur(400, "téléversement interrompu")
        meta = {"id": ident, "nom": nom, "original": original, "cadrage": cadrage,
                "statut": "attente", "erreur": "", "cree": time.time()}
        ecrire_json(os.path.join(d, "meta.json"), meta)
        file_conversion.put(ident)
        self._json(200, meta)

    # -------- DELETE
    def do_DELETE(self):
        global etat, version
        m = re.fullmatch(r"/api/medias/([0-9a-f]{16})", urlparse(self.path).path)
        if not m or not os.path.isdir(dossier_media(m.group(1))):
            return self._erreur(404, "introuvable")
        ident = m.group(1)
        with verrou:
            if etat["media"] == ident:
                etat = valider({**etat, "media": "",
                                "mode": "defilant" if etat["mode"] == "media" else etat["mode"]})
                version += 1
                ecrire_json(FICHIER_ETAT, etat)
        shutil.rmtree(dossier_media(ident), ignore_errors=True)
        self._json(200, {"ok": True})

    def log_message(self, *args):       # pas de journal à chaque requête
        pass


def main():
    os.makedirs(DOSSIER_MEDIAS, exist_ok=True)
    charger_etat()
    threading.Thread(target=boucle_affichage, daemon=True).start()
    threading.Thread(target=boucle_conversion, daemon=True).start()
    for meta in lister_medias():        # conversions interrompues par un arrêt
        if meta.get("statut") in ("attente", "conversion"):
            file_conversion.put(meta["id"])
    nom = socket.gethostname().lower()
    suffixe = "" if PORT == 80 else f":{PORT}"
    print(f"Télécommande : http://{nom}.local{suffixe}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Requete).serve_forever()


if __name__ == "__main__":
    main()
