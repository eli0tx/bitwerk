# Barre LED — logiciel

Programme unique (`barre.py`) qui pilote les panneaux et sert une télécommande web
(`page.html`) pour l'iPhone : allumer/éteindre, mode défilant / fixe / horloge,
texte, couleur, luminosité, vitesse, taille du texte. Les réglages sont gardés dans
`etat.json` et retrouvés au redémarrage.

## Installation sur le Pi

```bash
# 1. Liaison Python de la bibliothèque (une fois)
sudo apt install -y python3-dev cython3
cd ~/rpi-rgb-led-matrix
make build-python
sudo make install-python
sudo python3 -c "import rgbmatrix; print('OK')"

# 2. Copier ce dossier sur le Pi (depuis le Mac) :
#    scp -r logiciel UTILISATEUR@barre-led.local:~/barre-led

# 3. Essai
sudo python3 ~/barre-led/barre.py
#    iPhone : http://barre-led.local  → Partager → Sur l'écran d'accueil

# 4. Démarrage automatique
sed -i "s/UTILISATEUR/$USER/" ~/barre-led/barre-led.service
sudo cp ~/barre-led/barre-led.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now barre-led
```

Passer à 4 panneaux : `Environment=BARRE_CHAINE=4` dans le service, puis
`sudo systemctl daemon-reload && sudo systemctl restart barre-led`.
