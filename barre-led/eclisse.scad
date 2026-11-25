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
// Alimentation Mean Well LRS-200-5 (5 V 40 A, boîtier n° 207 : 215 × 115 × 30 mm)
// posée entre l'éclisse Pi (X = 0) et l'éclisse X = +320 : chacune porte un berceau
// dont les joues sont vissées dans les taraudages M4 latéraux du boîtier
// et servent aussi de pieds d'écartement contre le mur.
//
// Impression : à plat, Z = 0 sur le plateau, sans support. PETG, 4 périmètres.

variante = "simple";          // "simple"      : X = -320, sans berceau
                              // "simple_alim" : X = +320, berceau d'alimentation côté -X
                              // "pi"          : X = 0, Pi + berceau d'alimentation côté +X

/* ---------- Plaque ---------- */
plaque_x = 80;                // 40 mm de chaque côté de la jonction
plaque_y = 156;               // trous à ±70 + rondelle Ø 9 + 3,5 mm de bord (panneau : 160)
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
// Inserts M3 mesurés sur les panneaux (YS-P5-320X160-16S) : aux coins, à 8 mm du bord
// côté jonction, entraxe vertical 140 mm. Lumières centrées sur X = ±8, ±3 mm de réglage.
oblong_largeur = 3.4;
oblong_x_min   = 5;           // centre de l'arrondi intérieur de la lumière
oblong_x_max   = 11;          // centre de l'arrondi extérieur de la lumière
oblong_pos_y   = 70;          // lumières à ±70

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
// Taraudages latéraux (plan Mean Well) : 4 × M4, 2 par grand côté,
// à 32,5 mm de chaque bout et 12,5 mm du dessous ; pénétration de vis ≤ 5 mm.
alim_trou_x = 32.5;
alim_trou_z = 12.5;
vis_alim_d  = 4.5;            // passage M4
vis_alim_jeu_x = 1.5;         // trou oblong ±1,5 mm en X (tolérance d'entraxe)
berceau_jeu = 0.4;            // jeu latéral autour du boîtier
berceau_paroi = 3;            // épaisseur des piliers : M4 × 8 + rondelle → 4,2 mm dans le boîtier
pilier_marge  = 4;            // matière autour du trou oblong
cadre_h     = 8;              // hauteur du cadre bas sous l'alim
cadre_ep    = 2.4;            // épaisseur des traverses
gousset     = 18;             // gousset extérieur des piliers (45°)
montrer_alim = false;         // true pour visualiser l'alim (ne pas exporter)

/* ---------- Fixation murale ---------- */
// Y+ = haut de la barre une fois accrochée.
// Éclisse X = -320 : pied à trou de serrure en haut + colonne d'appui en bas.
// Éclisse X = +320 : pied à trou de serrure ; l'appui est assuré par les joues du berceau.
// Éclisse Pi : aucun pied, les joues du berceau s'appuient contre le mur.
fixation_murale = true;
marge_mur   = 4;              // air entre le dessus de l'alim et le mur
// dos des panneaux → mur : dessus de l'alim + marge
ecart_mur   = alim_z0 + alim_h + marge_mur;
pied_x      = 15;             // largeur du pied
pied_y0     = 26;             // départ du pied (soudé à la nervure)
pied_y1     = 54;             // fin du pied (avant les lumières M3)
pied_paroi  = 2;
butee_d     = 12;             // pied du bas : simple colonne creuse d'appui
pied_toit   = 2;              // épaisseur de la face côté mur (au sommet du toit en V)
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

// Pied d'écartement creux. Sans trou de serrure : tube ouvert aux deux bouts.
// Avec trou de serrure : le creux se referme en toit à 45° (pas de pont à l'impression) ;
// la tête de la vis murale vient se caler contre les deux pentes.
module pied(serrure) {
    wi = pied_x - 2 * pied_paroi;                     // largeur intérieure (X)
    li = pied_y1 - pied_y0 - 2 * pied_paroi;          // longueur intérieure (Y)
    z_toit = ecart_mur - pied_toit - wi / 2;          // départ des pentes
    difference() {
        translate([-pied_x / 2, pied_y0, 0]) cube([pied_x, pied_y1 - pied_y0, ecart_mur]);
        translate([-wi / 2, pied_y0 + pied_paroi, -e]) {
            cube([wi, li, (serrure ? z_toit : ecart_mur) + 2 * e]);
            if (serrure)                              // toit en V à 45°
                translate([0, 0, z_toit]) hull() {
                    cube([wi, li, e]);
                    translate([wi / 2 - e, 0, wi / 2]) cube([2 * e, li, e]);
                }
        }
        if (serrure)
            translate([0, 0, z_toit]) linear_extrude(ecart_mur - z_toit + e) {
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
// Réduit au strict nécessaire, tout part du plateau (aucun porte-à-faux, aucun pont) :
//  - un cadre bas (2 longerons + 2 traverses) relié au bord de la plaque ;
//  - sur chaque longeron, un pilier qui reçoit la vis M4 latérale du boîtier
//    et monte jusqu'au mur (pied d'écartement), contreventé par un gousset à 45°.
// Le boîtier ne repose sur rien : il est tenu par ses 4 vis M4.
x_alim  = entraxe_eclisses / 2 - alim_l / 2;    // extrémité du boîtier (52,5 mm)
x_vis   = x_alim + alim_trou_x;                 // axe des vis M4 (85 mm)
z_vis   = alim_z0 + alim_trou_z;                // 27,5 mm
module trou_goutte(d) {                         // trou horizontal en goutte (sommet à 45°)
    circle(d = d);
    rotate(45) square(d / 2);
}
module berceau() {
    x0 = plaque_x / 2;
    pil = vis_alim_d + 2 * vis_alim_jeu_x + 2 * pilier_marge;   // largeur du pilier (X)
    x1 = x_vis + pil / 2;
    yi = alim_w / 2 + berceau_jeu;               // face intérieure des piliers
    ye = yi + berceau_paroi;
    // traverses : au bord de la plaque et en bout
    translate([x0 - 2, -ye, 0]) cube([cadre_ep + 2, 2 * ye, cadre_h]);
    translate([x1 - cadre_ep, -ye, 0]) cube([cadre_ep, 2 * ye, cadre_h]);
    for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0]) {
        // longeron
        translate([x0, yi, 0]) cube([x1 - x0, berceau_paroi, cadre_h]);
        // pilier + trou oblong M4 en goutte
        difference() {
            translate([x_vis - pil / 2, yi, 0]) cube([pil, berceau_paroi, ecart_mur]);
            translate([0, yi + berceau_paroi + e, 0]) rotate([90, 0, 0])
                linear_extrude(berceau_paroi + 2 * e) hull()
                    for (dx = [-vis_alim_jeu_x, vis_alim_jeu_x])
                        translate([x_vis + dx, z_vis]) trou_goutte(vis_alim_d);
        }
        // gousset extérieur à 45° (pente vers le haut, imprimable)
        translate([x_vis - cadre_ep / 2, ye - e, 0]) rotate([90, 0, 90])
            linear_extrude(cadre_ep)
                polygon([[0, 0], [gousset, 0], [0, gousset]]);
    }
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
                if (variante != "pi") pied(true);       // haut : trou de serrure
                if (variante == "simple") butee();      // bas : simple appui
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
