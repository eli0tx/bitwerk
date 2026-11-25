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
plot_marge    = 2.5;          // matière autour de la base d'un plot
pi_x = 65; pi_y = 30;         // dimensions du circuit imprimé
pi_fixation   = "clips";      // "clips" (sans vis) ou "vis" (autotaraudeuses M2,5)

// -- fixation par vis
plot_trou_d   = 2.2;          // vis autotaraudeuse M2,5
plot_fond     = 1.2;          // trou borgne : la vis ne traverse pas la face Z = 0 (-1 = traversant)

// -- fixation par clips : 4 pions de centrage dans les trous du Pi
//    + 4 crochets souples qui viennent sur les petits côtés du circuit
pcb_ep        = 1.4;          // ÉPAISSEUR DU CIRCUIT À MESURER (règle la hauteur des lèvres)
pion_d        = 2.4;          // trous du Pi : Ø 2,75
clip_ep       = 1.2;          // épaisseur du bras (souplesse)
clip_l        = 4;            // largeur du crochet
clip_debord   = 0.6;          // recouvrement de la lèvre sur le circuit
clip_jeu      = 0.2;          // jeu entre le circuit et le crochet
clip_pos_y    = 11.5;         // crochets près des coins, à côté du lecteur SD et du connecteur caméra
montrer_pi = false;           // true pour visualiser le Pi (ne pas exporter)

/* ---------- Fixation murale ---------- */
// Y+ = haut de la barre une fois accrochée.
// Éclisses simples : 2 pieds d'écartement, celui du haut avec un trou de serrure.
// Éclisse Pi : 2 pieds d'écartement sans trou de serrure (empêchent la barre de fléchir au milieu).
fixation_murale = true;
ecart_mur   = 35;             // dos des panneaux → mur (le Pi + carte HUB75 + nappe ≈ 30 mm)
pied_x      = 18;             // largeur du pied
pied_y0     = 26;             // départ du pied (soudé à la nervure)
pied_y1     = 56;             // fin du pied (avant les lumières M3)
pied_paroi  = 2.5;
pied_toit   = 3;              // épaisseur de la face côté mur
serrure_tete_d = 10;          // passage de la tête de vis murale (tête Ø ≤ 9)
serrure_fente  = 4.5;         // largeur de la fente (vis Ø 4)
serrure_y      = 36;          // centre du grand trou
serrure_course = 10;          // longueur de la fente, vers le haut

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

z_pcb = plaque_z + plot_h;     // dessous du circuit du Pi

module plots_pi() {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * pi_entraxe_x / 2, sy * pi_entraxe_y / 2, plaque_z - e]) {
            cylinder(d = plot_d, h = plot_h + e);
            if (pi_fixation == "clips") {          // pion de centrage chanfreiné
                cylinder(d = pion_d, h = plot_h + pcb_ep + 0.3);
                translate([0, 0, plot_h + pcb_ep + 0.3])
                    cylinder(d1 = pion_d, d2 = pion_d - 0.8, h = 0.6);
            }
        }
}

// Crochet : bras vertical + lèvre à chanfrein d'entrée, côté +X (miroir pour -X)
module crochet() {
    x0 = pi_x / 2 + clip_jeu;                    // face intérieure du bras
    z_levre = z_pcb + pcb_ep + clip_jeu;         // dessous de la lèvre
    levre_h = 1.6;
    a = clip_debord + clip_jeu;                  // avancée de la lèvre
    translate([x0, -clip_l / 2, plaque_z - e])
        cube([clip_ep, clip_l, z_levre + levre_h - plaque_z + e]);
    // profil de lèvre dans le plan XZ, extrudé sur la largeur du crochet
    translate([0, clip_l / 2, 0]) rotate([90, 0, 0])
        linear_extrude(clip_l)
            polygon([[x0 + e, z_levre], [x0 - a, z_levre],
                     [x0 - a, z_levre + 0.3], [x0 + e, z_levre + levre_h]]);
}

module clips_pi() {
    for (sx = [-1, 1], sy = [-1, 1])
        mirror([sx < 0 ? 1 : 0, 0, 0]) translate([0, sy * clip_pos_y, 0]) crochet();
}

// Pied d'écartement creux ; le toit (côté mur) porte éventuellement un trou de serrure
module pied(serrure) {
    difference() {
        translate([-pied_x / 2, pied_y0, 0]) cube([pied_x, pied_y1 - pied_y0, ecart_mur]);
        // creux, ouvert côté panneau (il tombe dans la fenêtre d'allègement)
        translate([-pied_x / 2 + pied_paroi, pied_y0 + pied_paroi, -e])
            cube([pied_x - 2 * pied_paroi, pied_y1 - pied_y0 - 2 * pied_paroi,
                  serrure ? ecart_mur - pied_toit + e : ecart_mur + 2 * e]);
        if (serrure)
            translate([0, 0, ecart_mur - pied_toit - e]) linear_extrude(pied_toit + 2 * e) {
                translate([0, serrure_y]) circle(d = serrure_tete_d);
                hull() {
                    translate([0, serrure_y]) circle(d = serrure_fente);
                    translate([0, serrure_y + serrure_course]) circle(d = serrure_fente);
                }
            }
    }
}

module eclisse() {
    difference() {
        union() {
            linear_extrude(plaque_z) profil();
            for (s = [-1, 1])
                translate([-nervure_x / 2, s * nervure_pos_y - nervure_y / 2, plaque_z - e])
                    cube([nervure_x, nervure_y, nervure_z + e]);
            if (variante == "pi") {
                plots_pi();
                if (pi_fixation == "clips") clips_pi();
            }
            if (fixation_murale) {
                pied(variante != "pi");                 // haut : trou de serrure
                mirror([0, 1, 0]) pied(false);          // bas : simple appui
            }
        }
        if (variante == "pi" && pi_fixation == "vis")
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx * pi_entraxe_x / 2, sy * pi_entraxe_y / 2, plot_fond])
                    cylinder(d = plot_trou_d, h = plaque_z + plot_h);
    }
    if (variante == "pi" && montrer_pi)
        %translate([-pi_x / 2, -pi_y / 2, z_pcb]) cube([pi_x, pi_y, pcb_ep]);
}

eclisse();
