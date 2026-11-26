# Reprise du projet « barre LED » — où on en est

À coller (ou à faire lire) au début d'une nouvelle session Claude.
Dépôt `eli0tx/bitwerk`, branche **`claude/relaxed-gauss-77mu3v`**, dossier **`barre-led/`**.
Tout est en français, unités en mm.

## Le projet

Barre lumineuse de 4 panneaux LED HUB75 P5 64 × 32 px (320 × 160 mm, ~15 mm d'épaisseur),
alignés en paysage : 1280 × 160 mm, 256 × 32 px. Jonctions à X = −320, 0, +320 (origine au centre).
Accrochée au mur, pilotée par un Raspberry Pi Zero 2 W + carte HUB75, contrôlée depuis l'iPhone.

## Matériel (confirmé)

- **Panneaux** : réf. `YS-P5-320X160-16S` (balayage 1/16), 0,3 kg, 18 W max chacun.
  Entrée **JIN** / sortie **JOUT** (attention : le Pi va sur JIN), alim 5 V sur connecteur POWER.
  **Inserts M3 mesurés** : aux 4 coins, à 8 mm du bord côté jonction, entraxe vertical 140 mm
  (→ X = ±8, Y = ±70 dans le repère de l'éclisse). Aussi un insert au milieu haut/bas (non utilisé).
- **Alimentation** : Mean Well **LRS-200-5** (5 V 40 A, boîtier n° 207 : 215 × 115 × 30 mm).
  Taraudages **M4** : 2 par grand côté à 32,5 mm de chaque bout et 12,5 mm du dessous (vis ≤ 5 mm
  dans le boîtier) ; 4 en dessous (entraxe 150 × 50, vis ≤ 3 mm). Sélecteur d'entrée sur 230 V,
  sortie réglée 5,0–5,1 V.
- **Pi** : Raspberry Pi Zero 2 WH, Raspberry Pi OS Lite 64 bits (Debian 13, Python 3.13).
  Hôte `pizero`, utilisateur `eli0tx`, accès SSH, Tailscale installé (nom `pizero` sur le tailnet).
  Wi-Fi 2,4 GHz uniquement.
- **Carte HUB75** : Adafruit **Triple Output HUB75/75E RGB Matrix Active3 Bonnet** → `--led-gpio-mapping=regular`.
  Pas de bornier 5 V : le Pi est alimenté à part (micro-USB). Interrupteur « Addr E » sans effet (panneaux 32 lignes).
- **Imprimante** : Anycubic Kobra X, buse 0,4, PETG, plateau PEI texturé, Anycubic Slicer Next sur Mac.

## Pièces imprimées — `barre-led/eclisse.scad` (OpenSCAD, paramétrique)

3 variantes (`-D 'variante="…"'`), 1 exemplaire de chaque, STL/3MF dans le dossier, archive `barre-led.zip` :

| Variante | Jonction | Contenu |
|---|---|---|
| `simple` | X = −320 | pied à trou de serrure (haut) + colonne d'appui Ø 12 (bas) |
| `simple_alim` | X = +320 | pied à trou de serrure + berceau d'alim côté −X |
| `pi` | X = 0 | Pi clipsé (4 pions + 4 crochets, `pcb_ep` = 1,4) + berceau d'alim côté +X, pas de pied |

- Plaque 80 × 156 × 3 mm ajourée en échelle, coins R4, nervures 76 × 5 × 8 à Y = ±25,
  lumières M3 centrées X = ±8 (±3 mm), Y = ±70, encoches repères à X = 0.
- Berceau d'alim : cadre bas de 8 mm + 2 piliers (trou oblong M4 en goutte à X = 85, Z = 27,5)
  qui montent jusqu'au mur, gousset à 45°. Alim centrée à X = +160, 15 mm au-dessus du dos des
  panneaux (`alim_z0`), tenue par 4 × M4 × 8 + rondelle.
- Écart dos des panneaux → mur : `ecart_mur` = 15 + 30 + 4 = 49 mm. Trous de serrure Ø 10 / fente 4,5
  vers le haut (Y+ = haut), vis murales Ø 4 espacées de 640 mm.
- Contraintes d'impression respectées : à plat face lisse sur le plateau, **aucun support, aucun pont**
  (toits en V à 45°, trous en goutte). Volumes : 33 / 43 / 38 cm³, hauteur 49 mm.
- Visserie : 12 × M3 × 8 + rondelles larges DIN 9021 (éclisses → panneaux), 4 × M4 × 8 + rondelles (alim).
- Réglages slicer conseillés : couche 0,28, 3 périmètres, 15 % remplissage, supports OFF,
  parois ext. 100–120 mm/s, buse 240–245 °C, plateau 75–80 °C, ventilation 30–50 %,
  rétraction 0,8–1,5 mm, temps de couche min 6–8 s.
- L'éclisse Pi a déjà été imprimée une fois (ancienne version) ; la version actuelle a les trous corrigés.

## Logiciel — `barre-led/logiciel/` (archive `barre-led/logiciel.zip`)

- `barre.py` : un seul programme Python (root) qui pilote la matrice (bibliothèque hzeller
  rpi-rgb-led-matrix, liaison Python installée par `sudo pip3 install . --break-system-packages`
  depuis `~/rpi-rgb-led-matrix` — la méthode `make build-python` n'existe plus depuis 2026)
  et sert une page web sur le port 80 (stdlib `http.server`, pas de dépendance hors Pillow).
- `page.html` : télécommande iPhone (à ajouter à l'écran d'accueil), 2 onglets :
  - **Texte** : défilant / fixe / horloge, texte, couleur, vitesse, choix parmi les 26 polices BDF ;
  - **Médias** : téléversement photo / GIF / vidéo (500 Mo max), conversion unique par Pillow ou
    ffmpeg en images RGB brutes au format de la barre (cadrage remplir / ajuster / étirer),
    lecture en boucle à 25 i/s, reconversion auto si la taille change.
  - Luminosité et marche/arrêt communs.
- API : `GET/POST /api/etat`, `GET /api/polices`, `GET/POST /api/medias`, `DELETE /api/medias/<id>`,
  `GET /medias/<id>/apercu.png`. État dans `etat.json`, médias dans `medias/`.
- `barre-led.service` : service systemd (`BARRE_CHAINE=2` pour l'instant ; 4 plus tard).
- Réglages matrice : rows 32, cols 64, chain 2, parallel 1, mapping `regular`, gpio_slowdown 2.
  Son du Pi désactivé (`snd_bcm2835` blacklisté, `dtparam=audio=off`), `isolcpus=3`.

## Où on en est (dernière étape)

1. Testé et OK : démo hzeller sur 2 panneaux chaînés (Port 1 → JIN), première version du logiciel
   (texte) pilotée depuis l'iPhone.
2. **En cours** : passer à la nouvelle version (polices + médias). Il reste à faire, dans l'ordre :
   - Ctrl + C pour arrêter l'ancien `barre.py` lancé à la main ;
   - depuis le Mac : `scp logiciel/barre.py logiciel/page.html eli0tx@pizero.local:~/barre-led/` ;
   - sur le Pi : `sudo apt install -y ffmpeg`, puis installer le service
     (`sed -i "s/UTILISATEUR/$USER/" ~/barre-led/barre-led.service`, copie dans
     `/etc/systemd/system/`, `daemon-reload`, `enable --now barre-led`) ;
   - vérifier `sudo systemctl status barre-led` → doit afficher `http://pizero.local`.
3. Accès distant : Tailscale fonctionne par l'adresse 100.x (`tailscale ip -4`) ou le nom complet
   `http://pizero.<tailnet>.ts.net` (MagicDNS à vérifier sur l'iPhone).

## À faire ensuite / idées

- Brancher les 2 derniers panneaux (nappes HUB75 trop courtes) : soit une chaîne de 4
  (`BARRE_CHAINE=4`, nappe ~50 cm), soit 2 chaînes de 2 sur Port 1 et Port 2 (`--led-parallel=2`
  + pixel mapper pour mettre les moitiés côte à côte, éventuellement panneaux de gauche retournés).
- Alimenter le Pi depuis la Mean Well (câble micro-USB relié au bornier), masse commune.
- Idées évoquées : code PIN sur la page, Wi-Fi de secours en point d'accès, alléger encore la plaque
  autour des vis (bandes haut/bas pleines depuis le déplacement des trous).
