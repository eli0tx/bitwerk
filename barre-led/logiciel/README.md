# Barre LED — logiciel

Programme unique (`barre.py`) qui pilote les panneaux et sert une télécommande web
(`page.html`) pour l'iPhone, en deux onglets :

- **Texte** : défilant / fixe / horloge, texte, couleur, vitesse, choix parmi toutes
  les polices BDF de la bibliothèque (6 à 24 px) ;
- **Médias** : photos, GIF animés et vidéos téléversés depuis l'iPhone (500 Mo max,
  vidéos coupées à 5 min), convertis une fois au format de la barre (cadrage remplir /
  ajuster / étirer) puis rejoués en boucle. Les médias sont reconvertis automatiquement
  si la taille de la barre change (passage de 2 à 4 panneaux).

Luminosité et marche/arrêt communs aux deux onglets. Réglages gardés dans `etat.json`,
médias dans `medias/` : tout est retrouvé au redémarrage.

## Installation sur le Pi

```bash
# 1. Liaison Python de la bibliothèque (une fois ; 10–20 min sur un Zero 2 W)
#    Depuis février 2026 la bibliothèque s'installe avec pip (plus de make build-python).
sudo apt install -y python3-dev cython3 python3-pip cmake ninja-build python3-pil
cd ~/rpi-rgb-led-matrix
sudo pip3 install . --break-system-packages
cd ~ && sudo python3 -c "import rgbmatrix; print('OK')"

# 1 bis. ffmpeg, pour les GIF et les vidéos
sudo apt install -y ffmpeg

# 2. Copier ce dossier sur le Pi (depuis le Mac) :
#    scp -r logiciel UTILISATEUR@NOM_DU_PI.local:~/barre-led

# 3. Essai
sudo python3 ~/barre-led/barre.py
#    iPhone : http://NOM_DU_PI.local (ou l'adresse Tailscale) → Partager → Sur l'écran d'accueil

# 4. Démarrage automatique
sed -i "s/UTILISATEUR/$USER/" ~/barre-led/barre-led.service
sudo cp ~/barre-led/barre-led.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now barre-led
```

Passer à 4 panneaux : `Environment=BARRE_CHAINE=4` dans le service, puis
`sudo systemctl daemon-reload && sudo systemctl restart barre-led`.
