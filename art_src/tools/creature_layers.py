"""Etape 3 d'une creature assemblee : la grille Apollo, puis les calques.

L'assemblage de creature_compose.py (retouche ou non) et le decor seul sont ramenes sur la
grille, a la taille des cases du LoRA. Les calques, du bas vers le haut :

- le decor, complet : il vient du decor genere seul, rien ne manque derriere la creature ;
- l'ombre et le raccord : ce que l'assemblage a change autour de la creature ;
- l'ombre au sol peinte avec la creature, sous la ligne de sol (--sol) ;
- la robe, les os, l'arme : la creature, separee par la couleur et par la forme.

Chaque calque de la creature est complete sous ceux qui le couvrent, en prolongeant ses
propres couleurs : masquer l'arme laisse voir la robe, masquer les os l'interieur de la robe.

    python creature_layers.py <prefixe> <assemblage.png> <decor.png> <sortie.aseprite> [--sol N] [--sprite <sprite.aseprite>]

<prefixe> est celui de creature_compose.py, dont on relit <prefixe>_silhouette.png. --sprite
ecrit aussi la creature seule, sur fond transparent : c'est elle que le jeu greffe sur un decor.
"""
import argparse
import math
import random

from PIL import Image

from aseprite_io import build, check_independent, work, write_manifest
from bg_hall import APOLLO
from bg_import import _lab, lora_grid, tidy, to_grid

N8 = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
N4 = [(1, 0), (-1, 0), (0, 1), (0, -1)]


def snap(im, t, gw, gh):
    """L'image sur la grille Apollo. Le decor et l'assemblage sont lus sur la meme grille :
    un decalage d'une fraction de pixel changerait quelques cases partout."""
    out = to_grid(im, t, gw, gh, APOLLO, 0.25)
    tidy(out)
    return out


def steel_cells(src, gw, gh):
    """Les cases de la lame, reperees dans l'image source : un gris neutre ou lavande, ni sarcelle
    comme la doublure de la capuche, ni ivoire comme les os. Sur la grille Apollo, ces gris se
    confondent ; dans la source, non."""
    sp = src.load()
    k = src.width // gw
    found = set()
    for cy in range(gh):
        for cx in range(gw):
            hits = 0
            for j in range(k // 4, k - k // 4):
                for i in range(k // 4, k - k // 4):
                    L, a, b = _lab(sp[cx * k + i, cy * k + j])
                    hits += L >= 28 and a >= -4 and -16 <= b <= 2 and math.hypot(a, b) < 14
            if hits * 2 >= (k - 2 * (k // 4)) ** 2:
                found.add((cx, cy))
    return found


def components(cells):
    """Les composantes connexes (voisinage a 4) d'un ensemble de cases, de la plus grande a la plus petite."""
    seen, comps = set(), []
    for start in cells:
        if start in seen:
            continue
        comp, stack = set(), [start]
        seen.add(start)
        while stack:
            c = stack.pop()
            comp.add(c)
            for dx, dy in N4:
                n = (c[0] + dx, c[1] + dy)
                if n in cells and n not in seen:
                    seen.add(n)
                    stack.append(n)
        comps.append(comp)
    return sorted(comps, key=len, reverse=True)


def shaft_line(cells, lab, tries=4000, width=1.0):
    """La droite du manche : celle qui passe par le plus de cases brunes (RANSAC)."""
    brown = [c for c in cells if lab[c][1] > 12 and lab[c][2] > -4 and lab[c][0] < 45]
    rng = random.Random(1)
    best = (0, None)
    for _ in range(tries):
        (x1, y1), (x2, y2) = rng.sample(brown, 2)
        length = math.hypot(x2 - x1, y2 - y1)
        if length < 30:
            continue
        nx, ny = (y2 - y1) / length, -(x2 - x1) / length
        score = sum(abs((x - x1) * nx + (y - y1) * ny) <= width for x, y in brown)
        if score > best[0]:
            best = (score, (x1, y1, nx, ny))
    x1, y1, nx, ny = best[1]
    on = [c for c in brown if abs((c[0] - x1) * nx + (c[1] - y1) * ny) <= width]
    return (x1, y1, nx, ny), on


def classify(img, silhouette, src, ground=None):
    """Les cases de la creature, rangees en ombre au sol, robe, os et arme."""
    ip, sp = img.load(), silhouette.load()
    gw, gh = img.size
    sil = {(x, y) for y in range(gh) for x in range(gw) if sp[x, y]}
    lab = {c: _lab(ip[c]) for c in sil}
    (x1, y1, nx, ny), on = shaft_line(sil, lab)
    ys = [c[1] for c in on]
    top, bottom = min(ys), max(ys)
    near = lambda c, w: abs((c[0] - x1) * nx + (c[1] - y1) * ny) <= w
    # le manche se prolonge vers le bas tant que sa droite reste dans la silhouette, meme quand
    # il passe dans l'ombre et que la grille le rend gris plutot que brun
    while any(near((x, bottom + 1), 0.75) and (x, bottom + 1) in sil for x in range(gw)):
        bottom += 1
    shaft = {c for c in sil if near(c, 1.3) and top - 1 <= c[1] <= bottom + 1 and lab[c][1] > 6 and lab[c][0] < 50}
    shaft |= {c for c in sil if near(c, 0.75) and top <= c[1] <= bottom and lab[c][0] < 55}
    # la lame : les taches d'acier, reperees dans la source, qui touchent le haut du manche,
    # et leur liseré sombre sur le bord de la silhouette
    head = min(shaft, key=lambda c: c[1])
    blade = set()
    for comp in components(steel_cells(src, gw, gh) & sil):
        if any(math.hypot(c[0] - head[0], c[1] - head[1]) <= 3 for c in comp):
            blade |= comp
    blade |= {c for c in sil if lab[c][0] < 30 and lab[c][1] > -5
              and any((c[0] + dx, c[1] + dy) in blade for dx, dy in N8)
              and any((c[0] + dx, c[1] + dy) not in sil for dx, dy in N8)}
    weapon = shaft | blade
    shadow = {c for c in sil - weapon if ground is not None and c[1] > ground}
    rest = sil - weapon - shadow
    comps = components(rest)
    body = comps[0]
    weapon |= set().union(*comps[1:]) if len(comps) > 1 else set()  # un bout de liseré detache du corps
    bones = {c for c in body if lab[c][0] >= 55}
    bones |= {c for c in body if 38 <= lab[c][0] < 55 and sum((c[0] + dx, c[1] + dy) in bones for dx, dy in N8) >= 3}
    robe = body - bones

    def enclosed(c):  # le corps de part et d'autre, a trois cases au plus, en largeur ou en hauteur
        side = lambda dx, dy: any((c[0] + dx * k, c[1] + dy * k) in body for k in (1, 2, 3))
        return (side(1, 0) and side(-1, 0)) or (side(0, 1) and side(0, -1))

    # le corps, ferme : l'arme qui le traverse est devant la robe, pas devant le decor
    closed = body | {c for c in weapon if enclosed(c)}
    return dict(shadow=shadow, robe=robe, bones=bones, weapon=weapon, body=closed)


def fill(img, own, area):
    """Le calque d'un objet complete sur `area` : chaque case manquante prend la couleur
    de ses voisines de l'objet, de proche en proche."""
    ip = img.load()
    colour = {c: ip[c] for c in own}
    todo = set(area) - set(own)
    while todo:
        grown = {}
        for c in todo:
            near = [colour[n] for n in ((c[0] + dx, c[1] + dy) for dx, dy in N8) if n in colour]
            if near:
                grown[c] = max(set(near), key=near.count)
        if not grown:
            break
        colour.update(grown)
        todo -= set(grown)
    return colour


def layer(size, colour):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    p = im.load()
    for c, v in colour.items():
        p[c] = v + (255,)
    return im


def write(name, layers, ref_img, out_aseprite, surfaces):
    """Ecrit les calques non vides et assemble le .aseprite, verifie apres aller-retour."""
    layers = [(n, im) for n, im in layers if im.getbbox()]
    check_independent(layers, surfaces)
    entries = []
    for i, (n, im) in enumerate(layers):
        p = work(name, "layers", f"{i:02d}.png")
        im.save(p)
        entries.append(dict(name=n, png=p))
    ref = work(name, "detail_ref.png")
    ref_img.save(ref)
    build(write_manifest(name, [dict(out=out_aseprite, ref=ref, w=ref_img.width, h=ref_img.height,
                                     palette=[list(c) for c in APOLLO], layers=entries)]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prefix")
    ap.add_argument("composite")
    ap.add_argument("decor")
    ap.add_argument("out")
    ap.add_argument("--sol", type=int, default=None, help="la ligne de sol : en dessous, l'ombre peinte avec la creature")
    ap.add_argument("--sprite", default=None, help="ecrit aussi la creature seule, sur fond transparent")
    a = ap.parse_args()
    silhouette = Image.open(f"{a.prefix}_silhouette.png").convert("L")
    gw, gh = silhouette.size
    src = Image.open(a.composite).convert("RGB")
    decor_src = Image.open(a.decor).convert("RGB")
    t = lora_grid(decor_src, gw, gh)
    assert t, "la grille peinte par le LoRA ne tombe pas sur la grille demandee"
    img, decor = snap(src, t, gw, gh), snap(decor_src, t, gw, gh)
    parts = classify(img, silhouette, src, a.sol)
    ip, dp, sp = img.load(), decor.load(), silhouette.load()
    size = (gw, gh)
    joint = {(x, y): ip[x, y] for y in range(gh) for x in range(gw) if not sp[x, y] and ip[x, y] != dp[x, y]}
    robe = fill(img, parts["robe"], parts["body"])
    bones = fill(img, parts["bones"], parts["bones"] | {c for c in parts["weapon"] & parts["body"]
                                                          if sum((c[0] + dx, c[1] + dy) in parts["bones"] for dx, dy in N8) >= 4})
    creature = [("Ombre", layer(size, {c: ip[c] for c in parts["shadow"]})), ("Robe", layer(size, robe)),
                ("Os", layer(size, bones)), ("Arme", layer(size, {c: ip[c] for c in parts["weapon"]}))]
    layers = [("Décor", decor.convert("RGBA")), ("Ombre et raccord", layer(size, joint))] + creature
    flat = Image.new("RGBA", size)
    for _, im in layers:
        flat = Image.alpha_composite(flat, im)
    assert flat.convert("RGB").tobytes() == img.tobytes(), "les calques ne redonnent pas l'image"
    name = a.prefix.replace("\\", "/").split("/")[-1]
    img.resize((gw * 4, gh * 4), Image.NEAREST).save(work(name + "_calques", "apercu_x4.png"))
    print(", ".join(f"{n} {len(parts[k])} cases" for n, k in (("ombre", "shadow"), ("robe", "robe"), ("os", "bones"), ("arme", "weapon"))))
    write(name + "_calques", layers, img, a.out, ("Décor",))
    if a.sprite:
        alone = Image.new("RGBA", size, (0, 0, 0, 0))
        for _, im in creature:
            alone = Image.alpha_composite(alone, im)
        write(name + "_sprite", creature, alone, a.sprite, ("Ombre", "Robe", "Os", "Arme"))


if __name__ == "__main__":
    main()
