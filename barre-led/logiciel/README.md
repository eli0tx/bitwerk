# Barre LED — logiciel

Programme unique (`barre.py`) qui pilote les panneaux et sert une télécommande web
(`page.html`) pour l'iPhone : allumer/éteindre, mode défilant / fixe / horloge,
texte, couleur, luminosité, vitesse, taille du texte. Les réglages sont gardés dans
`etat.json` et retrouvés au redémarrage.

## Installation sur le Pi

```bash
# 1. Liaison Python de la bibliothèque (une fois ; 10–20 min sur un Zero 2 W)
#    Depuis février 2026 la bibliothèque s'installe avec pip (plus de make build-python).
sudo apt install -y python3-dev cython3 python3-pip cmake ninja-build python3-pil
cd ~/rpi-rgb-led-matrix
sudo pip3 install . --break-system-packages
cd ~ && sudo python3 -c "import rgbmatrix; print('OK')"

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
