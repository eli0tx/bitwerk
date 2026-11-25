// Éclisses de jonction pour barre LED 4 × HUB75 P5 (64 × 32 px, 320 × 160 mm)
// Barre : 1280 × 160 mm, jonctions à X = -320, 0, +320 mm.
//
// Repère de la pièce :
//   X = 0 sur la jonction entre deux panneaux
//   Y = 0 au milieu de la hauteur
//   Z = 0 sur la face posée contre le dos des panneaux (face lisse, côté plateau)
//
// Version allégée : plaque de 3 mm ajourée en échelle. La matière ne reste que là
// où elle travaille : bandes de vissage (haut/bas), semelles des nervures,
// longerons latéraux et, en variante Pi, l'assise des plots.
//
// Rendu :
//   openscad -D 'variante="simple"' -o eclisse_simple.stl eclisse.scad
//   openscad -D 'variante="pi"'     -o eclisse_pi.stl     eclisse.scad
//
// Impression : à plat, Z = 0 sur le plateau, sans support. PETG, 4 périmètres.

variante = "simple";          // "simple" (×2) ou "pi" (×1, jonction centrale)

/* ---------- Plaque ---------- */
plaque_x = 80;                // 40 mm de chaque côté de la jonction
plaque_y = 150;
plaque_z = 3;                 // 3 mm suffisent : la rigidité vient des nervures
plaque_r = 4;                 // coins arrondis (moins de décollement)

/* ---------- Allègement ---------- */
allegement = true;            // false = plaque pleine
fenetre_r  = 3;               // rayon des angles des fenêtres
bord_lat   = 6;               // largeur des longerons latéraux (X = ±34 → ±40)
marge_nerv = 3;               // matière gardée de part et d'autre d'une nervure
marge_vis  = 7;               // distance mini entre l'axe des vis et une fenêtre (tête M3 Ø5,5 + rondelle)

/* ---------- Nervures (face arrière) ---------- */
nervure_x = 76;
nervure_y = 5;
nervure_z = 8;                // hauteur au-dessus de la plaque
nervure_pos_y = 25;           // nervures à ±25

/* ---------- Trous oblongs M3 ---------- */
// À VÉRIFIER sur les panneaux : position des inserts M3 au dos.
oblong_largeur = 3.4;
oblong_x_min   = 8;           // centre de l'arrondi intérieur de la lumière
oblong_x_max   = 34;          // centre de l'arrondi extérieur de la lumière
oblong_pos_y   = 60;          // lumières à ±60

/* ---------- Encoches repères (axe de jonction) ---------- */
encoche_x = 1.2;
encoche_y = 2.5;

/* ---------- Raspberry Pi Zero 2 WH ---------- */
pi_entraxe_x  = 58;
pi_entraxe_y  = 23;
plot_d        = 6;
plot_h        = 5;            // au-dessus de la plaque
plot_trou_d   = 2.2;          // vis autotaraudeuse M2,5
plot_fond     = 1.2;          // trou borgne : la vis ne traverse pas la face Z = 0 (-1 = traversant)
plot_marge    = 2.5;          // matière autour de la base d'un plot
pi_x = 65; pi_y = 30;         // encombrement du Pi (fantôme uniquement)
montrer_pi = false;           // true pour visualiser le Pi (ne pas exporter)

$fn = 40;
e = 0.01;

module rect_arrondi(x0, y0, x1, y1, r) {
    translate([x0 + r, y0 + r]) offset(r = r) square([x1 - x0 - 2 * r, y1 - y0 - 2 * r]);
}

module oblong2d(x0, x1, l) {
    hull() { translate([x0, 0]) circle(d = l); translate([x1, 0]) circle(d = l); }
}

// Profil 2D de la plaque (vue de dos)
module profil() {
    xi = plaque_x / 2 - bord_lat;                       // bord intérieur des longerons
    y_nerv_int = nervure_pos_y - nervure_y / 2 - marge_nerv;
    y_nerv_ext = nervure_pos_y + nervure_y / 2 + marge_nerv;
    y_vis      = oblong_pos_y - marge_vis;
    // fenêtre centrale : réduite en variante Pi pour garder l'assise des plots
    xc = variante == "pi" ? pi_entraxe_x / 2 - plot_d / 2 - plot_marge : xi;

    difference() {
        rect_arrondi(-plaque_x / 2, -plaque_y / 2, plaque_x / 2, plaque_y / 2, plaque_r);
        if (allegement) {
            rect_arrondi(-xc, -y_nerv_int, xc, y_nerv_int, fenetre_r);
            for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0])
                rect_arrondi(-xi, y_nerv_ext, xi, y_vis, fenetre_r);
        }
        for (sx = [-1, 1], sy = [-1, 1])
            translate([0, sy * oblong_pos_y]) mirror([sx < 0 ? 1 : 0, 0])
                oblong2d(oblong_x_min, oblong_x_max, oblong_largeur);
        for (y = [-plaque_y / 2 - e, plaque_y / 2 - encoche_y])
            translate([-encoche_x / 2, y]) square([encoche_x, encoche_y + e]);
    }
}

module eclisse() {
    difference() {
        union() {
            linear_extrude(plaque_z) profil();
            for (s = [-1, 1])
                translate([-nervure_x / 2, s * nervure_pos_y - nervure_y / 2, plaque_z - e])
                    cube([nervure_x, nervure_y, nervure_z + e]);
            if (variante == "pi")
                for (sx = [-1, 1], sy = [-1, 1])
                    translate([sx * pi_entraxe_x / 2, sy * pi_entraxe_y / 2, plaque_z - e])
                        cylinder(d = plot_d, h = plot_h + e);
        }
        if (variante == "pi")
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx * pi_entraxe_x / 2, sy * pi_entraxe_y / 2, plot_fond])
                    cylinder(d = plot_trou_d, h = plaque_z + plot_h);
    }
    if (variante == "pi" && montrer_pi)
        %translate([-pi_x / 2, -pi_y / 2, plaque_z + plot_h]) cube([pi_x, pi_y, 1]);
}

eclisse();
