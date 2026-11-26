#!/usr/bin/env python3
"""Barre LED 4 × HUB75 — affichage + télécommande web pour iPhone.

Lancement (en root, nécessaire pour piloter le GPIO) :
    sudo python3 barre.py
Puis, sur l'iPhone, ouvrir http://barre-led.local dans Safari
et « Partager → Sur l'écran d'accueil ».

Réglages matériels : constantes ci-dessous, ou variables d'environnement
(BARRE_CHAINE, BARRE_PARALLELE, BARRE_PORT, BARRE_POLICES, ...).
"""
import datetime
import glob
import json
import os
import re
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics

# ---------------------------------------------------------------- réglages
CHAINE = int(os.environ.get("BARRE_CHAINE", 2))        # panneaux par chaîne (4 plus tard)
PARALLELE = int(os.environ.get("BARRE_PARALLELE", 1))  # chaînes en parallèle (ports de la carte)
MAPPING = os.environ.get("BARRE_MAPPING", "regular")   # carte Adafruit Triple Active3
RALENTI_GPIO = int(os.environ.get("BARRE_RALENTI", 2))
PORT = int(os.environ.get("BARRE_PORT", 80))

ICI = os.path.dirname(os.path.abspath(__file__))
FICHIER_ETAT = os.path.join(ICI, "etat.json")

POLICES = {                                           # nom affiché → fichier BDF
    "petite": "6x13B.bdf",
    "moyenne": "9x18B.bdf",
    "grande": "10x20.bdf",
    "geante": "texgyre-27.bdf",
}
MODES = ("defilant", "fixe", "horloge")
JOURS = ("lun.", "mar.", "mer.", "jeu.", "ven.", "sam.", "dim.")
MOIS = ("janv.", "févr.", "mars", "avr.", "mai", "juin",
        "juil.", "août", "sept.", "oct.", "nov.", "déc.")

ETAT_DEFAUT = {
    "allume": True,
    "mode": "defilant",
    "texte": "Bonjour Bitwerk",
    "couleur": "#ff3c28",
    "vitesse": 40,          # pixels par seconde
    "luminosite": 50,       # %
    "police": "moyenne",
}


# ---------------------------------------------------------------- état partagé
verrou = threading.Lock()
etat = dict(ETAT_DEFAUT)
version = 0                 # incrémentée à chaque changement (relance le défilement)


def charger_etat():
    global etat
    try:
        with open(FICHIER_ETAT, encoding="utf-8") as f:
            lu = json.load(f)
        etat = valider({**ETAT_DEFAUT, **lu})
    except (OSError, ValueError):
        etat = dict(ETAT_DEFAUT)


def sauver_etat():
    tmp = FICHIER_ETAT + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(etat, f, ensure_ascii=False, indent=1)
    os.replace(tmp, FICHIER_ETAT)


def borne(v, mini, maxi):
    return max(mini, min(maxi, int(v)))


def valider(e):
    """Retourne un état propre ; lève ValueError si une valeur est invalide."""
    propre = {
        "allume": bool(e["allume"]),
        "mode": e["mode"] if e["mode"] in MODES else "defilant",
        "texte": str(e["texte"]).replace("\n", " ")[:200],
        "couleur": e["couleur"] if re.fullmatch(r"#[0-9a-fA-F]{6}", str(e["couleur"])) else "#ffffff",
        "vitesse": borne(e["vitesse"], 5, 150),
        "luminosite": borne(e["luminosite"], 1, 100),
        "police": e["police"] if e["police"] in POLICES else "moyenne",
    }
    return propre


# ---------------------------------------------------------------- affichage
def trouver_polices():
    candidats = [os.environ.get("BARRE_POLICES", ""),
                 os.path.join(ICI, "fonts"),
                 *glob.glob("/home/*/rpi-rgb-led-matrix/fonts"),
                 "/root/rpi-rgb-led-matrix/fonts"]
    for d in candidats:
        if d and os.path.isfile(os.path.join(d, POLICES["moyenne"])):
            return d
    raise SystemExit("Polices BDF introuvables : définir BARRE_POLICES=/chemin/rpi-rgb-led-matrix/fonts")


def largeur(police, texte):
    return sum(police.CharacterWidth(ord(c)) for c in texte)


def texte_horloge(police, largeur_dispo):
    m = datetime.datetime.now()
    heure = m.strftime("%H:%M")
    complet = f"{heure}  {JOURS[m.weekday()]} {m.day} {MOIS[m.month - 1]}"
    return complet if largeur(police, complet) <= largeur_dispo else heure


def boucle_affichage():
    o = RGBMatrixOptions()
    o.rows, o.cols = 32, 64
    o.chain_length, o.parallel = CHAINE, PARALLELE
    o.hardware_mapping = MAPPING
    o.gpio_slowdown = RALENTI_GPIO
    o.drop_privileges = False           # garde les droits pour écrire etat.json
    matrice = RGBMatrix(options=o)
    toile = matrice.CreateFrameCanvas()
    w, h = toile.width, toile.height

    dossier = trouver_polices()
    polices = {}
    for nom, fichier in POLICES.items():
        p = graphics.Font()
        p.LoadFont(os.path.join(dossier, fichier))
        polices[nom] = p

    x = float(w)
    vu = -1
    t_prec = time.monotonic()
    while True:
        with verrou:
            e = dict(etat)
            v = version
        if v != vu:                     # texte ou réglage changé : on repart du bord droit
            x, vu = float(w), v
        maintenant = time.monotonic()
        dt, t_prec = maintenant - t_prec, maintenant

        matrice.brightness = e["luminosite"]
        toile.Clear()
        if e["allume"]:
            police = polices[e["police"]]
            r, g, b = (int(e["couleur"][i:i + 2], 16) for i in (1, 3, 5))
            couleur = graphics.Color(r, g, b)
            y = (h - police.height) // 2 + police.baseline
            if e["mode"] == "defilant":
                lg = graphics.DrawText(toile, police, int(x), y, couleur, e["texte"])
                x -= e["vitesse"] * dt
                if x + lg < 0:
                    x = float(w)
            else:
                t = e["texte"] if e["mode"] == "fixe" else texte_horloge(police, w)
                graphics.DrawText(toile, police, (w - largeur(police, t)) // 2, y, couleur, t)
        toile = matrice.SwapOnVSync(toile)
        if not e["allume"] or e["mode"] != "defilant":
            time.sleep(0.1)             # rien ne bouge : inutile de redessiner 60 fois par seconde


# ---------------------------------------------------------------- serveur web
PAGE = open(os.path.join(ICI, "page.html"), encoding="utf-8").read()


class Requete(BaseHTTPRequestHandler):
    def _repondre(self, code, corps, type_):
        donnees = corps.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", type_)
        self.send_header("Content-Length", str(len(donnees)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(donnees)

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            self._repondre(200, PAGE, "text/html; charset=utf-8")
        elif self.path == "/api/etat":
            with verrou:
                self._repondre(200, json.dumps(etat, ensure_ascii=False), "application/json")
        else:
            self._repondre(404, "introuvable", "text/plain; charset=utf-8")

    def do_POST(self):
        global etat, version
        if self.path != "/api/etat":
            return self._repondre(404, "introuvable", "text/plain; charset=utf-8")
        try:
            n = int(self.headers.get("Content-Length", 0))
            recu = json.loads(self.rfile.read(min(n, 10000)) or b"{}")
            if not isinstance(recu, dict):
                raise ValueError
            with verrou:
                nouveau = valider({**etat, **{k: v for k, v in recu.items() if k in ETAT_DEFAUT}})
                relance = any(nouveau[k] != etat[k] for k in ("texte", "mode", "police", "allume"))
                etat = nouveau
                if relance:
                    version += 1
                sauver_etat()
                corps = json.dumps(etat, ensure_ascii=False)
            self._repondre(200, corps, "application/json")
        except (ValueError, TypeError, KeyError):
            self._repondre(400, "requête invalide", "text/plain; charset=utf-8")

    def log_message(self, *args):       # pas de journal à chaque requête
        pass


def main():
    charger_etat()
    threading.Thread(target=boucle_affichage, daemon=True).start()
    print(f"Télécommande : http://barre-led.local:{PORT}" if PORT != 80 else
          "Télécommande : http://barre-led.local")
    ThreadingHTTPServer(("0.0.0.0", PORT), Requete).serve_forever()


if __name__ == "__main__":
    main()
