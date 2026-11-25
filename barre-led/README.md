# Barre LED 4 × HUB75 — éclisses de jonction

4 panneaux P5 64 × 32 px (320 × 160 mm), alignés en paysage : barre de 1280 × 160 mm (256 × 32 px).
Jonctions à X = −320, 0 et +320 mm (origine au centre de la barre).

| Fichier | Quantité | Emplacement |
|---|---|---|
| `eclisse_simple.stl` | 2 | jonctions X = ±320 |
| `eclisse_pi.stl` | 1 | jonction centrale X = 0 (Raspberry Pi Zero 2 WH) |

Source paramétrique : `eclisse.scad` (OpenSCAD). Régénérer :

```sh
openscad -D 'variante="simple"' -o eclisse_simple.stl eclisse.scad
openscad -D 'variante="pi"'     -o eclisse_pi.stl     eclisse.scad
```

![Éclisse Pi](apercu_eclisse_pi.png)

## Géométrie

Repère : X = 0 sur la jonction, Y = 0 à mi-hauteur, Z = 0 sur la face contre le dos des panneaux.

- Plaque 80 × 150 × 4 mm, centrée sur la jonction.
- 2 nervures 76 × 5 × 8 mm (8 mm au-dessus de la plaque, Z 4 → 12), centrées à Y = ±25.
- 4 lumières M3 de 3,4 mm, centres d'arrondi de X = ±8 à ±34 (lumière de 6,3 à 35,7 mm), à Y = ±60.
- Encoches repères 1,2 × 2,5 mm à X = 0, en haut et en bas.
- Variante Pi : 4 plots Ø 6 × 5 mm à X = ±29, Y = ±11,5 (entraxe 58 × 23),
  trous Ø 2,2 mm borgnes (fond de 1,2 mm côté panneau) pour vis autotaraudeuses M2,5.

## À vérifier avant impression

- **Position des inserts M3 au dos des panneaux** : Y = ±60 et X = 8 → 34 sont supposés.
  Tout est en paramètres en tête de `eclisse.scad`.
- Profondeur : plaque + plots + Pi + carte HUB75 dépassent les ~15 mm d'épaisseur des panneaux.

## Impression

À plat, Z = 0 sur le plateau (face lisse), sans support. PETG, 4 périmètres.
