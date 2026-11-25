// Éclisses de jonction pour barre LED 4 × HUB75 P5 (64 × 32 px, 320 × 160 mm)
// Barre : 1280 × 160 mm, jonctions à X = -320, 0, +320 mm.
//
// Repère de la pièce :
//   X = 0 sur la jonction entre deux panneaux
//   Y = 0 au milieu de la hauteur
//   Z = 0 sur la face posée contre le dos des panneaux (face lisse, côté plateau)
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
plaque_z = 4;

/* ---------- Nervures (face arrière) ---------- */
nervure_x = 76;
nervure_y = 5;
nervure_z = 8;                // hauteur au-dessus de la plaque
nervure_pos_y = [-25, 25];

/* ---------- Trous oblongs M3 ---------- */
// À VÉRIFIER sur les panneaux : position des inserts M3 au dos.
oblong_largeur = 3.4;
oblong_x_min   = 8;           // bord intérieur de la lumière
oblong_x_max   = 34;          // bord extérieur de la lumière
oblong_pos_y   = [-60, 60];

/* ---------- Encoches repères (axe de jonction) ---------- */
encoche_x = 1.2;
encoche_y = 2.5;

/* ---------- Raspberry Pi Zero 2 WH ---------- */
pi_entraxe_x  = 58;
pi_entraxe_y  = 23;
plot_d        = 6;
plot_h        = 5;            // au-dessus de la plaque
plot_trou_d   = 2.2;          // vis autotaraudeuse M2,5
plot_fond     = 1.2;          // trou borgne : la vis ne traverse pas la face Z = 0
pi_x = 65; pi_y = 30;         // encombrement du Pi (fantôme uniquement)
montrer_pi = false;           // true pour visualiser le Pi (ne pas exporter)

$fn = 48;
e = 0.01;

module oblong(x0, x1, l) {
    // lumière dont les extrémités extérieures vont de x0 à x1
    r = l / 2;
    hull() {
        translate([x0 + r, 0, 0]) cylinder(d = l, h = plaque_z + 2 * e);
        translate([x1 - r, 0, 0]) cylinder(d = l, h = plaque_z + 2 * e);
    }
}

module plaque() {
    difference() {
        union() {
            translate([-plaque_x / 2, -plaque_y / 2, 0])
                cube([plaque_x, plaque_y, plaque_z]);
            for (y = nervure_pos_y)
                translate([-nervure_x / 2, y - nervure_y / 2, plaque_z - e])
                    cube([nervure_x, nervure_y, nervure_z + e]);
        }
        // trous oblongs, de part et d'autre de la jonction
        for (s = [-1, 1], y = oblong_pos_y)
            translate([0, y, -e]) mirror([s < 0 ? 1 : 0, 0, 0])
                oblong(oblong_x_min, oblong_x_max, oblong_largeur);
        // encoches repères en haut et en bas, à X = 0
        for (y = [-plaque_y / 2 - e, plaque_y / 2 - encoche_y])
            translate([-encoche_x / 2, y, -e])
                cube([encoche_x, encoche_y + e, plaque_z + 2 * e]);
    }
}

module plots_pi() {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * pi_entraxe_x / 2, sy * pi_entraxe_y / 2, plaque_z - e])
            cylinder(d = plot_d, h = plot_h + e);
}

module eclisse_pi() {
    difference() {
        union() { plaque(); plots_pi(); }
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * pi_entraxe_x / 2, sy * pi_entraxe_y / 2, plot_fond])
                cylinder(d = plot_trou_d, h = plaque_z + plot_h);
    }
    if (montrer_pi)
        %translate([-pi_x / 2, -pi_y / 2, plaque_z + plot_h]) cube([pi_x, pi_y, 1]);
}

if (variante == "pi") eclisse_pi();
else plaque();
