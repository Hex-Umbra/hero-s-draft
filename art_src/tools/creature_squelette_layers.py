"""La recette de calques des squelettes : une tenue, des os, une arme a manche et, au besoin, un ecu.

Elle sert au Squelette (tier 2 : baton et ecu rond) et a la Faucheuse (tier 3 : faux). Les calques,
du bas vers le haut : Ombre (peinte avec la creature, sous la ligne de sol, ou posee par le code
sous la tenue et les os), Robe, Os, Bouclier (--bouclier), Arme. La robe est completee sous les os et sous l'arme qui la traverse, les os sous
le manche : masquer l'arme laisse voir la robe, masquer les os l'interieur de la robe.

    python creature_squelette_layers.py <prefixe> <sprite.aseprite> [--sol 183] [--apercu <fond.aseprite> <apercu.aseprite>]
                                        [--manche 2] [--bouclier]

--manche sert a un manche epais : sa demi-largeur, en cases (2 pour le baton du Squelette), et une
lecture de ses reflets dans la source, que la grille arrondit au clair des os. La main qui le serre
reste alors aux Os. Sans ces deux options, la recette range comme pour la Faucheuse.

Deux principes, appris sur ces creatures : une couleur ne suffit pas (sur la grille Apollo, des
matieres differentes tombent sur les memes gris), on la combine donc avec la forme ; et en cas de
doute, on lit la source, qui garde des nuances que la grille a fondues. Le deroule commun et les
outils de tri sont dans creature_layers.py.
"""
import math
import random

from creature_layers import N8, SHADOW, components, grow, run, touches


def shaft_line(figure, tries=4000, width=1.0):
    """La droite du manche : celle qui passe par le plus de cases brunes (RANSAC)."""
    lab = figure.lab
    brown = [c for c in figure.cells if lab[c][1] > 12 and lab[c][2] > -4 and lab[c][0] < 45]
    rng = random.Random(1)
    best = (0, None)
    for _ in range(tries if len(brown) >= 2 else 0):
        (x1, y1), (x2, y2) = rng.sample(brown, 2)
        length = math.hypot(x2 - x1, y2 - y1)
        if length < 30:
            continue
        nx, ny = (y2 - y1) / length, -(x2 - x1) / length
        score = sum(abs((x - x1) * nx + (y - y1) * ny) <= width for x, y in brown)
        if score > best[0]:
            best = (score, (x1, y1, nx, ny))
    if best[1] is None:
        raise SystemExit("pas de manche brun d'au moins 30 cases : cette recette attend une arme a manche. "
                         "Une creature d'une autre forme demande sa propre recette (creature_<forme>_layers.py).")
    x1, y1, nx, ny = best[1]
    on = [c for c in brown if abs((c[0] - x1) * nx + (c[1] - y1) * ny) <= width]
    return (x1, y1, nx, ny), on


def steel_cells(figure):
    """Les cases de la lame, reperees dans l'image source : un gris neutre ou lavande, ni sarcelle
    comme la doublure de la capuche, ni ivoire comme les os. Sur la grille Apollo, ces gris se
    confondent ; dans la source, non."""
    return figure.core(lambda L, a, b: L >= 28 and a >= -4 and -16 <= b <= 2 and math.hypot(a, b) < 14)


def shield_cells(figure, cells):
    """L'ecu : le plus grand amas brun (cuir ou bois), son contour sombre et ce qu'il enferme.

    Le brun se lit dans l'image source, sur la moyenne de chaque case. Une ouverture de deux cases
    detache ensuite l'ecu des fines formes brunes qui le touchent, comme une ceinture. Ce qu'il
    enferme, les clous et les reflets, ce sont les cases qui ont l'ecu de part et d'autre, sur leur
    ligne comme sur leur colonne."""
    tone = figure.tone
    brown = {c for c in cells if 28 <= tone[c][0] < 58 and tone[c][1] >= 9 and tone[c][2] >= 15}
    core = {c for c in brown if all((c[0] + dx, c[1] + dy) in brown for dx in range(-2, 3) for dy in range(-2, 3))}
    opened = grow(core, 2) & brown
    if not opened:
        raise SystemExit("--bouclier : pas d'amas brun assez large pour un ecu dans la creature")
    blob = components(opened)[0]
    # le bord de l'ecu, plus sombre, et son contour : l'ecu gagne de proche en proche, sur six cases
    # au plus, les cases brunes ou rouille et les contours sombres de ton chaud ; pas la tenue, froide
    rim = {c for c in cells if (tone[c][1] >= 9 and tone[c][2] >= 6) or (tone[c][0] < 20 and tone[c][1] >= 3 and tone[c][2] >= 0)}
    for _ in range(6):
        edge = {c for c in rim - blob if any((c[0] + dx, c[1] + dy) in blob for dx, dy in N8)}
        if not edge:
            break
        blob |= edge
    rows, cols = {}, {}
    for x, y in blob:
        rows.setdefault(y, []).append(x)
        cols.setdefault(x, []).append(y)
    inside = {c for c in cells if c[1] in rows and c[0] in cols
              and min(rows[c[1]]) < c[0] < max(rows[c[1]]) and min(cols[c[0]]) < c[1] < max(cols[c[0]])}
    return blob | inside


def classify(figure, shaft_width=None, shield=False):
    """Les cases de la creature, rangees en ombre au sol, robe, os, arme et, si `shield`, bouclier.

    `shaft_width` est la demi-largeur du manche, en cases, de part et d'autre de sa droite (1.3 par
    defaut). Donnee, elle sert a un manche plus epais, dont les reflets et les bords sont lus aussi
    dans la source : la grille les arrondit au clair des os, la source les garde bruns."""
    sil, lab = figure.cells, figure.lab
    (x1, y1, nx, ny), on = shaft_line(figure)
    ys = [c[1] for c in on]
    top, bottom = min(ys), max(ys)
    near = lambda c, w: abs((c[0] - x1) * nx + (c[1] - y1) * ny) <= w
    # le manche se prolonge vers le bas tant que sa droite reste dans la silhouette, meme quand
    # il passe dans l'ombre et que la grille le rend gris plutot que brun
    while any(near((x, bottom + 1), 0.75) and (x, bottom + 1) in sil for x in range(figure.gw)):
        bottom += 1
    width = shaft_width or 1.3
    shaft = {c for c in sil if near(c, width) and top - 1 <= c[1] <= bottom + 1 and lab[c][1] > 6 and lab[c][0] < 50}
    shaft |= {c for c in sil if near(c, 0.75) and top <= c[1] <= bottom and lab[c][0] < 55}
    if shaft_width:
        tone = figure.tone
        shaft |= {c for c in sil if near(c, width) and top - 1 <= c[1] <= bottom + 1 and tone[c][0] < 50 and tone[c][1] >= 3}
    # la lame : les taches d'acier, reperees dans la source, qui touchent le haut du manche,
    # et leur liseré sombre sur le bord de la silhouette
    head = min(shaft, key=lambda c: c[1])
    blade = set()
    for comp in components(steel_cells(figure)):
        if any(math.hypot(c[0] - head[0], c[1] - head[1]) <= 3 for c in comp):
            blade |= comp
    blade |= {c for c in sil if lab[c][0] < 30 and lab[c][1] > -5
              and any((c[0] + dx, c[1] + dy) in blade for dx, dy in N8)
              and any((c[0] + dx, c[1] + dy) not in sil for dx, dy in N8)}
    weapon = shaft | blade
    shadow = figure.below_ground() - weapon
    rest = sil - weapon - shadow
    guard = shield_cells(figure, rest) if shield else set()
    rest -= guard
    comps = components(rest)
    body = comps[0]
    # un bout du corps que l'ecu separe du reste, ou qu'un manche epais coupe du bras : la main qui le
    # serre, reconnue a ses os ; un eclat brun du baton, lui, reste a l'arme
    for comp in comps[1:]:
        if touches(comp, guard) or (shaft_width and touches(comp, shaft) and any(lab[c][0] >= 55 for c in comp)):
            body |= comp
        else:
            weapon |= comp  # un bout de liseré detache du corps
    bones = {c for c in body if lab[c][0] >= 55}
    bones |= {c for c in body if 38 <= lab[c][0] < 55 and sum((c[0] + dx, c[1] + dy) in bones for dx, dy in N8) >= 3}
    robe = body - bones

    def enclosed(c):  # le corps de part et d'autre, a trois cases au plus, en largeur ou en hauteur
        side = lambda dx, dy: any((c[0] + dx * k, c[1] + dy * k) in body for k in (1, 2, 3))
        return (side(1, 0) and side(-1, 0)) or (side(0, 1) and side(0, -1))

    # le corps, ferme : l'arme qui le traverse est devant la robe, pas devant le decor ; l'ecu cache
    # le corps pres de son bord, sur l'epaisseur d'un bras
    closed = body | {c for c in weapon if enclosed(c)} | (guard & grow(body, 6))
    return dict(shadow=shadow, robe=robe, bones=bones, weapon=weapon, shield=guard, body=closed)


def separate(figure, a):
    """Les calques des squelettes, du bas vers le haut."""
    p = classify(figure, a.manche, a.bouclier)
    under_shaft = {c for c in p["weapon"] & p["body"] if sum((c[0] + dx, c[1] + dy) in p["bones"] for dx, dy in N8) >= 4}
    shadow = figure.pick(p["shadow"]) or figure.cast_shadow(p["robe"] | p["bones"])
    return [(SHADOW, shadow), ("Robe", figure.fill(p["robe"], p["body"])),
            ("Os", figure.fill(p["bones"], p["bones"] | under_shaft)), ("Bouclier", figure.pick(p["shield"])),
            ("Arme", figure.pick(p["weapon"]))]


def add_options(ap):
    ap.add_argument("--manche", type=float, default=None, help="la demi-largeur d'un manche epais, en cases, lu aussi dans la source (1.3 sinon)")
    ap.add_argument("--bouclier", action="store_true", help="separe un bouclier dans son propre calque")


if __name__ == "__main__":
    run(separate, add_options, __doc__.split("\n")[0])
