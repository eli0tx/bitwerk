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
//   openscad -D 'variante="simple"'      -o eclisse_simple.stl      eclisse.scad
//   openscad -D 'variante="simple_alim"' -o eclisse_simple_alim.stl eclisse.scad
//   openscad -D 'variante="pi"'          -o eclisse_pi.stl          eclisse.scad
//
// Alimentation Mean Well LRS-200-5 (5 V 40 A, 215 × 115 × 30 mm) posée entre
// l'éclisse Pi (X = 0) et l'éclisse X = +320 : chacune porte un berceau qui
// reçoit une extrémité du boîtier.
//
// Impression : à plat, Z = 0 sur le plateau, sans support. PETG, 4 périmètres.

variante = "simple";          // "simple"      : X = -320, sans berceau
                              // "simple_alim" : X = +320, berceau d'alimentation côté -X
                              // "pi"          : X = 0, Pi + berceau d'alimentation côté +X

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

/* ---------- Alimentation (berceaux) ---------- */
alim_l      = 215;            // LRS-200 : 215 × 115 × 30 mm (toutes tensions)
alim_w      = 115;
alim_h      = 30;
alim_z0     = 15;             // dessous de l'alim au-dessus du dos des panneaux
                              // (passe au-dessus des connecteurs HUB75 et d'alimentation des panneaux)
entraxe_eclisses = 320;       // l'alim est centrée entre deux éclisses
berceau_l   = 30;             // longueur du berceau au-delà du bord de la plaque
berceau_jeu = 0.4;            // jeu latéral autour du boîtier
berceau_paroi = 3;
berceau_levre = 1.2;          // lèvre qui clipse le dessus du boîtier
berceau_butee_h = 3;          // petite butée qui empêche l'alim de glisser (n'empêche pas le câblage)
montrer_alim = false;         // true pour visualiser l'alim (ne pas exporter)

/* ---------- Fixation murale ---------- */
// Y+ = haut de la barre une fois accrochée.
// Éclisses simples : 2 pieds d'écartement, celui du haut avec un trou de serrure.
// Éclisse Pi : 2 pieds d'écartement sans trou de serrure (empêchent la barre de fléchir au milieu).
fixation_murale = true;
marge_mur   = 4;              // air entre l'alim et le mur
// dos des panneaux → mur : dessus de l'alim + lèvres du berceau + marge
ecart_mur   = alim_z0 + alim_h + berceau_jeu + 2 * berceau_levre + marge_mur;
pied_x      = 15;             // largeur du pied
pied_y0     = 26;             // départ du pied (soudé à la nervure)
pied_y1     = 54;             // fin du pied (avant les lumières M3)
pied_paroi  = 2;
butee_d     = 12;             // pied du bas : simple colonne creuse d'appui
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

// Pied du bas : colonne creuse soudée à la nervure
module butee() {
    y = -(nervure_pos_y + nervure_y / 2 + butee_d / 2 - 1);
    translate([0, y, 0]) difference() {
        cylinder(d = butee_d, h = ecart_mur);
        translate([0, 0, -e]) cylinder(d = butee_d - 2 * pied_paroi, h = ecart_mur + 2 * e);
    }
}

// Berceau d'alimentation, côté +X (miroir pour -X).
// Tout part du plateau (aucun porte-à-faux) :
//  - deux joues latérales qui reprennent le poids (barre au mur : gravité selon -Y)
//    et clipsent le dessus du boîtier ; en bas, un rebord sur lequel le boîtier repose ;
//  - le prolongement des deux nervures, sur lequel le boîtier repose aussi ;
//  - deux entretoises transversales : l'une soudée au bord de la plaque,
//    l'autre en bout, qui dépasse un peu et sert de butée.
x_alim = entraxe_eclisses / 2 - alim_l / 2;     // extrémité du boîtier (52,5 mm)
module berceau() {
    x0 = plaque_x / 2;
    x1 = x0 + berceau_l;
    yi = alim_w / 2 + berceau_jeu;               // face intérieure des joues
    ye = yi + berceau_paroi;
    rebord = 4;                                  // appui du boîtier le long des joues
    ep = 2.4;                                    // épaisseur des entretoises
    z_dessus = alim_z0 + alim_h + berceau_jeu;   // dessous de la lèvre
    xb = x_alim - 1 - ep;                        // entretoise-butée, 1 mm avant le boîtier
    // prolongement des nervures
    for (s = [-1, 1])
        translate([x0 - 2, s * nervure_pos_y - nervure_y / 2, 0])
            cube([x1 - x0 + 2, nervure_y, alim_z0]);
    // joues + rebord d'appui
    for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0]) {
        difference() {
            translate([x0, yi, 0]) cube([berceau_l, berceau_paroi, z_dessus + 2 * berceau_levre]);
            // fenêtre d'allègement (rend aussi la joue plus souple pour clipser)
            translate([x0 + 6, yi - e, alim_z0 + 6])
                cube([berceau_l - 12, berceau_paroi + 2 * e, alim_h - 14]);
        }
        translate([x0, yi - rebord, 0]) cube([berceau_l, rebord + e, alim_z0]);
        // lèvre de clipsage, chanfrein d'entrée côté mur
        translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(berceau_l)
            polygon([[yi + e, z_dessus], [yi - berceau_levre, z_dessus],
                     [yi - berceau_levre, z_dessus + 0.4], [yi + e, z_dessus + 2 * berceau_levre]]);
    }
    // entretoise soudée au bord de la plaque
    translate([x0 - 2, -ye, 0]) cube([ep + 2, 2 * ye, alim_z0]);
    // entretoise-butée
    translate([xb, -ye, 0]) cube([ep, 2 * ye, alim_z0 + berceau_butee_h]);
    if (montrer_alim)
        %translate([x_alim, -alim_w / 2, alim_z0]) cube([alim_l, alim_w, alim_h]);
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
                pied(variante != "pi");                 // haut : trou de serrure sur les éclisses simples
                butee();                                // bas : simple appui
            }
            if (variante == "pi") berceau();
            if (variante == "simple_alim") mirror([1, 0, 0]) berceau();
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
