// Système de glissières modulaire pour barre LED HUB75 P5 (panneaux 320 × 160 mm)
//
// Deux rails continus (haut et bas) vissés dans les inserts M3 des panneaux ; des
// chariots (Pi, alimentation, fixation murale) s'y clipsent sans outil, n'importe où,
// au-dessus des connecteurs des panneaux.
//
// Repère « en service » :
//   X le long de la barre, Y vertical (Y+ = haut une fois au mur), Z = 0 sur la face
//   des inserts au dos des panneaux, Z+ vers le mur. Inserts M3 à Y = ±70.
//
// Pièces (paramètre `piece`) :
//   rail_jonction     200 mm, à cheval sur une jonction, 2 vis (inserts à ±8 de la jonction)
//   rail_milieu       120 mm, au milieu d'un panneau, 1 vis (insert du milieu)
//   rail_bout         100 mm, extrémité de barre, 1 vis (insert de coin) — même pièce aux 4 coins
//   cle               clavette d'alignement entre deux tronçons
//   chariot_pi        Raspberry Pi Zero 2 W clipsé (pions + crochets)
//   chariot_alim      Mean Well LRS-200 vissée par ses 4 taraudages M4 du dessous
//   chariot_mural     pied à trou de serrure (haut) + colonne d'appui (bas)
//   chariot_appui     deux colonnes d'appui contre le mur
//   assemblage        aperçu d'une barre de 2 panneaux (ne pas imprimer)
//
// Les rails haut et bas sont la MÊME pièce tournée de 180°, bouts compris.
//
// Rendu (orienté pour l'impression, sans support) :
//   openscad -D 'piece="rail_jonction"' -o rail_jonction.stl glissiere.scad

piece = "assemblage";
impression = true;            // true : pièce posée dans le bon sens pour l'impression

/* ---------- Panneaux ---------- */
insert_y   = 70;              // inserts M3 à Y = ±70 (entraxe vertical 140 mm)
bord_y     = 80;              // bord du panneau (hauteur 160)
connecteur = 8;               // hauteur des connecteurs au-dessus de la face des inserts

/* ---------- Rail (profil, rail du haut) ---------- */
z_glisse   = 14;              // dessus du rail porteur = dessous des chariots (connecteurs + 6 mm)
rail_y0    = 64.5;            // face intérieure du rail (2,2 mm autour du lamage)
gorge_dos  = 77;              // fond de la gorge
levre_y    = 74;              // nez du rebord supérieur (laisse la tête de vis accessible)
gorge_h    = 3.4;             // hauteur de la gorge (plateau de 3 mm + jeu)
rebord_ep  = 2.5;             // épaisseur du rebord
chanfrein  = 1.5;             // chanfrein d'entrée sur le nez du rebord
cran_pas   = 10;              // crans de blocage le long du rail
cran_prof  = 0.8;
vis_d      = 3.4;             // passage M3
tete_d     = 6.6;             // lamage de la tête (vis M3 × 8 : 3 mm de matière + 5 dans l'insert)
fond_vis   = 3;
cle_cote   = 4;               // clavette carrée
cle_prof   = 10;
cle_jeu    = 0.3;

/* ---------- Chariots ---------- */
plateau_ep = 3;
jeu_fond   = 0.15;            // jeu entre le crochet et le fond de gorge (v2 : 0,4 → 0,15)
// 4 clips en porte-à-faux par chariot (2 par rail), enracinés côté centre, crochet aux coins
clip_bras_ep = 3.0;           // épaisseur du bras souple (v2 : 2,5 → 3, ~1,7× plus raide)
clip_bras_l  = 26;            // longueur du bras (crochet compris)
clip_crochet = 6;             // longueur du crochet qui entre dans la gorge
clip_coin    = 3;             // retrait du crochet par rapport au bout du plateau
fente      = 4.5;             // débattement derrière le bras (crochet + bossage)
chanfrein_bande = 2;          // chanfrein d'entrée sous l'arête extérieure du crochet
jeu_nez    = 0.15;            // jeu entre les butées rigides et le nez du rebord (v2 : 0,5 → 0,15)
                              // si le chariot ne rentre pas entre les rails : 0,25 ou 0,3
bosse      = 0.75;            // cran en V du crochet (même forme que les encoches du rail, 0,8)

/* ---------- Raspberry Pi Zero 2 W ---------- */
pi_x = 65; pi_y = 30; pi_ex = 58; pi_ey = 23;
plot_d = 6; plot_h = 5; pcb_ep = 1.4; pion_d = 2.4;
clip_ep = 1.2; clip_l = 4; clip_debord = 0.6; clip_jeu = 0.2; clip_pos_y = 11.5;

/* ---------- Alimentation LRS-200-5 ---------- */
alim_l = 215; alim_w = 115; alim_h = 30;
alim_ex = 150; alim_ey = 50;  // taraudages M4 du dessous (vis ≤ 3 mm dans le boîtier)
m4_d = 4.5;

/* ---------- Mur ---------- */
marge_mur = 4;
ecart_mur = z_glisse + plateau_ep + alim_h + marge_mur;   // 51 mm
pied_x = 15; pied_y0 = 24; pied_y1 = 52; pied_paroi = 2; pied_toit = 2;
serrure_tete_d = 10; serrure_fente = 4.5; serrure_y = 33; serrure_course = 10;
colonne_d = 12;

$fn = 40;
e = 0.01;

// ======================================================================= utilitaires
module goutte(d) {            // trou horizontal à l'impression : pointe à 45°
    circle(d = d);
    rotate(45) square(d / 2);
}

module rect_arrondi(x0, y0, x1, y1, r) {
    translate([x0 + r, y0 + r]) offset(r = r) square([x1 - x0 - 2 * r, y1 - y0 - 2 * r]);
}

// ======================================================================= rail
// Profil du rail du haut dans le plan (Y, Z) ; la gorge s'ouvre vers Y−.
module profil_rail() {
    z1 = z_glisse; z2 = z1 + gorge_h; z3 = z2 + rebord_ep;
    polygon([
        [rail_y0, 0], [bord_y, 0], [bord_y, z3],
        [levre_y + chanfrein, z3], [levre_y, z3 - chanfrein], [levre_y, z2],
        [gorge_dos, z2], [gorge_dos, z1], [rail_y0, z1]
    ]);
}

module rail(longueur, vis, cles = [true, true]) {
    difference() {
        rotate([90, 0, 90]) linear_extrude(longueur) profil_rail();
        // vis M3 + lamage (forme en goutte : axe horizontal à l'impression)
        for (x = vis) translate([x, insert_y, -e]) {
            linear_extrude(fond_vis + 2 * e) rotate(180) goutte(vis_d);
            translate([0, 0, fond_vis]) linear_extrude(z_glisse) rotate(180) goutte(tete_d);
        }
        // crans de blocage dans le fond de gorge (en V)
        for (x = [cran_pas / 2 : cran_pas : longueur])
            translate([x, gorge_dos - e, z_glisse - e])
                linear_extrude(gorge_h + 2 * e)
                    polygon([[-cran_prof, 0], [cran_prof, 0], [0, cran_prof]]);
        // allègement : poches ouvertes vers l'intérieur, entre les zones pleines
        allegement_rail(longueur, vis);
        // logements de clavette aux extrémités demandées
        for (i = [0, 1]) if (cles[i])
            translate([i == 0 ? -e : longueur - cle_prof, 0, 0])
                logement_cle();
    }
}

module logement_cle() {
    c = cle_cote + cle_jeu;
    translate([0, 68.5, z_glisse / 2]) rotate([45, 0, 0])
        translate([0, -c / 2, -c / 2]) cube([cle_prof + e, c, c]);
}

// Poches de 3 à 11 mm de haut, ouvertes sur la face intérieure du rail.
module allegement_rail(longueur, vis) {
    zones = [for (x = [14 : 4 : longueur - 14])
                if (min([for (v = vis) abs(v - x)]) > 9) x];
    for (x = zones)
        translate([x - 2.01, rail_y0 - e, 2.5]) cube([4.02, 73.5 - rail_y0, z_glisse - 5]);
}

module cle() {
    l = 2 * cle_prof - 2 * cle_jeu;
    cube([l, cle_cote, cle_cote]);
}

// ======================================================================= chariots
// Plateau commun. Le corps rigide s'arrête juste avant le nez des rebords (73,5) :
//  - 4 clips souples en porte-à-faux (2 par rail) dont le crochet passe sous le rebord,
//    avec un bossage qui tombe dans les crans du rail et une languette de déverrouillage ;
//  - 2 butées rigides au milieu, contre le nez des rebords : elles reprennent le poids
//    (barre au mur) pour que les clips ne servent qu'à retenir le chariot.
y_levre = gorge_dos - jeu_fond;                 // 76,85 : face extérieure du crochet
y_bord  = levre_y - jeu_nez;                    // 73,85 : bord du corps rigide
y_bras  = y_bord - clip_bras_ep;                // 70,85 : face intérieure du bras
y_corps = y_bras - fente;                       // 66,5 : corps rigide derrière les bras

module clip(l) {                                // clip du coin (+X, +Y)
    x1 = l - clip_coin;                         // bout du crochet
    x0 = x1 - clip_bras_l;                      // racine du bras
    // bras
    translate([x0 - e, y_bras, 0]) cube([x1 - x0 + e, clip_bras_ep, plateau_ep]);
    // crochet avec chanfrein d'entrée par-dessous et bossage de cran
    difference() {
        union() {
            translate([x1 - clip_crochet, y_bras, 0]) cube([clip_crochet, y_levre - y_bras, plateau_ep]);
            translate([x1 - clip_crochet / 2, y_levre - e, 0]) linear_extrude(plateau_ep)
                polygon([[-bosse, 0], [bosse, 0], [0, bosse + e]]);
        }
        translate([x1 - clip_crochet - e, y_levre + bosse, 0]) rotate([90, 0, 90])
            linear_extrude(clip_crochet + 2 * e)
                polygon([[e, -e], [-chanfrein_bande - bosse - e, -e], [e, chanfrein_bande + bosse + e]]);
    }
    // languette de déverrouillage : face extérieure verticale, face intérieure à 45°
    translate([x1 - 12, y_bras, plateau_ep - e]) rotate([90, 0, 90]) linear_extrude(10)
        polygon([[0, 0], [clip_bras_ep, 0], [clip_bras_ep, 7], [-7, 7]]);
}

module plateau(largeur, fenetres = []) {
    l = largeur / 2;
    x_racine = l - clip_coin - clip_bras_l;
    difference() {
        translate([-l, -y_bord, 0]) cube([largeur, 2 * y_bord, plateau_ep]);
        // logements des 4 clips (ouverts sur le bout du plateau)
        for (sx = [-1, 1], sy = [-1, 1]) mirror([sx < 0 ? 1 : 0, 0, 0]) mirror([0, sy < 0 ? 1 : 0, 0])
            translate([x_racine, y_corps, -e]) cube([l - x_racine + e, y_bord - y_corps + e, plateau_ep + 2 * e]);
        // fenêtres d'allègement / passage de câbles
        for (f = fenetres) translate([0, 0, -e]) linear_extrude(plateau_ep + 2 * e)
            rect_arrondi(f[0], f[1], f[2], f[3], 3);
    }
    for (sx = [-1, 1], sy = [-1, 1]) mirror([sx < 0 ? 1 : 0, 0, 0]) mirror([0, sy < 0 ? 1 : 0, 0])
        clip(l);
    // butées rigides contre le nez des rebords (reprennent le poids)
    for (sy = [-1, 1]) mirror([0, sy < 0 ? 1 : 0, 0])
        translate([-6, y_bord - 3, plateau_ep - e]) cube([12, 3, rebord_ep + gorge_h - plateau_ep + 0.4]);
}

// --- Pi
module chariot_pi() {
    l = 40;
    plateau(2 * l, [[-23.5, -8, 23.5, 8],
                    [-l + 6, 20, l - 6, y_corps - 5], [-l + 6, -y_corps + 5, l - 6, -20]]);
    z = plateau_ep;
    for (sx = [-1, 1], sy = [-1, 1]) translate([sx * pi_ex / 2, sy * pi_ey / 2, z - e]) {
        cylinder(d = plot_d, h = plot_h + e);
        cylinder(d = pion_d, h = plot_h + pcb_ep + 0.3);
        translate([0, 0, plot_h + pcb_ep + 0.3]) cylinder(d1 = pion_d, d2 = pion_d - 0.8, h = 0.6);
    }
    // crochets souples sur les petits côtés du Pi
    z_levre = z + plot_h + pcb_ep + clip_jeu;
    a = clip_debord + clip_jeu;
    x0 = pi_x / 2 + clip_jeu;
    for (sx = [-1, 1], sy = [-1, 1]) mirror([sx < 0 ? 1 : 0, 0, 0])
        translate([0, sy * clip_pos_y, 0]) {
            translate([x0, -clip_l / 2, z - e]) cube([clip_ep, clip_l, z_levre + 1.6 - z + e]);
            translate([0, clip_l / 2, 0]) rotate([90, 0, 0]) linear_extrude(clip_l)
                polygon([[x0 + e, z_levre], [x0 - a, z_levre], [x0 - a, z_levre + 0.3], [x0 + e, z_levre + 1.6]]);
        }
    // bande pleine sous les plots (relie les deux côtés de la fenêtre centrale)
}

// --- Alimentation : les 4 vis M4 × 6 montent par-dessous dans le boîtier
module chariot_alim() {
    l = alim_ex / 2 + 8;
    difference() {
        plateau(2 * l, [for (sx = [-1, 1]) each [
            [sx > 0 ? 6 : -alim_ex / 2 + 6, alim_ey / 2 + 6, sx > 0 ? alim_ex / 2 - 6 : -6, y_corps - 5],
            [sx > 0 ? 6 : -alim_ex / 2 + 6, -alim_ey / 2 + 6, sx > 0 ? alim_ex / 2 - 6 : -6, alim_ey / 2 - 6],
            [sx > 0 ? 6 : -alim_ex / 2 + 6, -y_corps + 5, sx > 0 ? alim_ex / 2 - 6 : -6, -alim_ey / 2 - 6]]]);
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * alim_ex / 2, sy * alim_ey / 2, -e]) cylinder(d = m4_d, h = plateau_ep + 2 * e);
    }
}

// --- Pied d'écartement creux, toit en V à 45° et trou de serrure (pas de pont)
module pied_serrure() {
    h = ecart_mur - z_glisse;                   // depuis le dessous du plateau
    wi = pied_x - 2 * pied_paroi;
    li = pied_y1 - pied_y0 - 2 * pied_paroi;
    z_toit = h - pied_toit - wi / 2;
    difference() {
        translate([-pied_x / 2, pied_y0, 0]) cube([pied_x, pied_y1 - pied_y0, h]);
        translate([-wi / 2, pied_y0 + pied_paroi, plateau_ep]) {
            cube([wi, li, z_toit - plateau_ep + e]);
            translate([0, 0, z_toit - plateau_ep]) hull() {
                cube([wi, li, e]);
                translate([wi / 2 - e, 0, wi / 2]) cube([2 * e, li, e]);
            }
        }
        translate([0, 0, z_toit]) linear_extrude(h) {
            translate([0, serrure_y]) circle(d = serrure_tete_d);
            hull() {
                translate([0, serrure_y]) circle(d = serrure_fente);
                translate([0, serrure_y + serrure_course]) circle(d = serrure_fente);
            }
        }
    }
}

module colonne(y) {
    h = ecart_mur - z_glisse;
    translate([0, y, 0]) difference() {
        cylinder(d = colonne_d, h = h);
        translate([0, 0, plateau_ep]) cylinder(d = colonne_d - 2 * pied_paroi, h = h);
    }
}

module chariot_mural(serrure = true) {
    l = 40;
    plateau(2 * l, [[-l + 6, -14, l - 6, 14]]);
    if (serrure) pied_serrure(); else colonne((pied_y0 + pied_y1) / 2);
    colonne(-(pied_y0 + pied_y1) / 2);
}

// ======================================================================= placement
L_J = 200; L_M = 120; L_B = (320 - L_M) / 2;

module piece_rail(nom) {
    if (nom == "rail_jonction") rail(L_J, [L_J / 2 - 8, L_J / 2 + 8]);
    if (nom == "rail_milieu")   rail(L_M, [L_M / 2]);
    // bout symétrique : sert aux 4 coins (le 2e lamage et la 2e clavette restent inutilisés)
    if (nom == "rail_bout")     rail(L_B, [8, L_B - 8]);
}

// Rail couché sur sa face extérieure (Y = 80) : gorge ouverte vers le haut.
module pose_rail() {
    translate([0, 0, bord_y]) rotate([-90, 0, 0]) children();
}

module assemblage(n = 2) {
    x0 = -n * 160;
    // panneaux
    for (i = [0 : n - 1]) color([0.2, 0.2, 0.22])
        translate([x0 + i * 320 + 0.5, -bord_y, -15]) cube([319, 2 * bord_y, 15]);
    // rails haut et bas
    for (haut = [true, false]) {
        tourne = haut ? [0, 0, 0] : [0, 0, 180];
        troncons = concat(
            [[x0, "rail_bout"]],
            [for (i = [0 : n - 1]) [x0 + i * 320 + L_B, "rail_milieu"]],
            [for (i = [1 : n - 1]) [x0 + i * 320 - L_J / 2, "rail_jonction"]],
            [[x0 + n * 320 - L_B, "rail_bout"]]);
        for (t = troncons) color("SteelBlue") {
            lg = t[1] == "rail_jonction" ? L_J : t[1] == "rail_milieu" ? L_M : L_B;
            if (haut) translate([t[0], 0, 0]) piece_rail(t[1]);
            else translate([t[0] + lg, 0, 0]) rotate(tourne) piece_rail(t[1]);
        }
    }
    // chariots
    translate([0, 0, z_glisse]) {
        color("Orange") translate([-160, 0, 0]) chariot_pi();
        color("Orange") translate([160, 0, 0]) chariot_alim();
        color([0.75, 0.75, 0.78]) translate([160 - alim_l / 2, -alim_w / 2, plateau_ep]) cube([alim_l, alim_w, alim_h]);
        color("ForestGreen") translate([-160 - pi_x / 2, -pi_y / 2, plateau_ep + plot_h]) cube([pi_x, pi_y, pcb_ep]);
        color("Orange") translate([-280, 0, 0]) chariot_mural();
        color("Orange") translate([280, 0, 0]) chariot_mural();
        color("Orange") translate([-60, 0, 0]) chariot_mural(false);
    }
}

// ======================================================================= sortie
if (piece == "assemblage") assemblage();
else if (piece[0] == "r") {
    if (impression) pose_rail() piece_rail(piece); else piece_rail(piece);
}
else if (piece == "cle") cle();
else if (piece == "chariot_pi") chariot_pi();
else if (piece == "chariot_alim") chariot_alim();
else if (piece == "chariot_mural") chariot_mural(true);
else if (piece == "chariot_appui") chariot_mural(false);
