"""Etape 3 : ramene une image generee sur la grille 320 x 180, en palette Apollo exacte,
et la decoupe en calques d'apres la geometrie de bg_hall.py.

1. Alignement : on cherche la transformation (echelle, decalage) qui superpose le mieux
   les contours de l'image generee a ceux du rendu de reference.
2. Grille : chaque pixel source est d'abord ramene a la couleur Apollo la plus proche,
   puis chaque case de la grille prend la couleur majoritaire de son bloc.
3. Calques : les surfaces viennent du lancer de rayons ; les objets (bannieres, torches,
   runes, herse) prennent les pixels de leur couleur autour de leur position prevue.
"""
import json
import math
import os
import sys
from collections import Counter
from PIL import Image, ImageChops, ImageFilter, ImageStat

import bg_hall as H
from aseprite_io import build, check_independent, work, write_manifest

GW, GH = H.GW, H.GH


def edges(im):
    return im.convert("L").filter(ImageFilter.FIND_EDGES).filter(ImageFilter.GaussianBlur(1.2))


def warp(src, a, c, e, f, size=(GW, GH), resample=Image.BILINEAR):
    return src.transform(size, Image.AFFINE, (a, 0, c, 0, e, f), resample=resample)


def align(src, ref):
    """Recherche par paliers de la transformation qui minimise l'ecart des contours."""
    er = edges(ref)
    soft = src.filter(ImageFilter.GaussianBlur(1.5))
    best = None
    a0, e0 = src.width / GW, src.height / GH
    grid = [(a0, 0.0, e0, 0.0)]
    for step_s, step_t, span in ((0.03, 4.0, 3), (0.01, 1.5, 3), (0.004, 0.5, 3)):
        cands = []
        for a, c, e, f in grid:
            for da in range(-span, span + 1):
                for de in range(-span, span + 1):
                    for dc in range(-span, span + 1):
                        for df in range(-span, span + 1):
                            cands.append((a + da * step_s, c + dc * step_t, e + de * step_s, f + df * step_t))
        scored = []
        for t in cands:
            diff = ImageChops.difference(edges(warp(soft, *t)), er)
            scored.append((ImageStat.Stat(diff).mean[0], t))
        scored.sort()
        best = scored[0]
        grid = [t for _, t in scored[:3]]
    return best


def to_grid(src, t):
    """Chaque case prend la couleur Apollo majoritaire de son bloc source."""
    pal_img = Image.new("P", (1, 1))
    flat = [v for c in H.APOLLO for v in c]
    pal_img.putpalette(flat + flat[:3] * (256 - len(H.APOLLO)))
    q = src.convert("RGB").quantize(palette=pal_img, dither=Image.Dither.NONE)
    qp = q.load()
    a, c, e, f = t
    out = Image.new("RGB", (GW, GH))
    op = out.load()
    for y in range(GH):
        for x in range(GW):
            x0, x1 = a * x + c, a * (x + 1) + c
            y0, y1 = e * y + f, e * (y + 1) + f
            votes = Counter()
            for sy in range(max(0, math.floor(y0)), min(src.height, math.ceil(y1))):
                for sx in range(max(0, math.floor(x0)), min(src.width, math.ceil(x1))):
                    k = qp[sx, sy]
                    if k < len(H.APOLLO):
                        votes[k] += 1
            if not votes:  # bord hors de l'image source : on prolonge le pixel le plus proche
                sx = min(src.width - 1, max(0, int((x0 + x1) / 2)))
                sy = min(src.height - 1, max(0, int((y0 + y1) / 2)))
                votes[qp[sx, sy]] = 1
            op[x, y] = H.APOLLO[votes.most_common(1)[0][0]]
    return out


RED = {H.C(h) for h in ("411d31", "752438", "a53030", "cf573c", "da863e", "602c2c")}
GOLD = {H.C(h) for h in ("884b2b", "be772b", "de9e41", "e8c170", "ad7757", "c09473", "d7b594")}
FIRE = {H.C(h) for h in ("cf573c", "be772b", "de9e41", "e8c170", "da863e", "d7b594", "e7d5b3")}
CYAN = {H.C(h) for h in ("3c5e8b", "4f8fba", "73bed3", "a4dddb", "253a5e", "c7cfcc", "ebede9", "a8b5b2")}


def region(test, grow):
    """Masque L des pixels de la grille ou test(x, y) est vrai, elargi de grow pixels."""
    m = Image.new("L", (GW, GH), 0)
    p = m.load()
    for y in range(GH):
        for x in range(GW):
            if test(x, y):
                p[x, y] = 255
    return m.filter(ImageFilter.MaxFilter(2 * grow + 1)) if grow else m


def base_layers():
    """Les calques du rendu de base, par nom : ils fournissent le dessous des objets."""
    path = work("hall_manifest.json")
    if not os.path.isfile(path):
        raise SystemExit("lancer d'abord bg_hall.py : le decoupage s'appuie sur son rendu")
    with open(path, encoding="utf-8") as f:
        entries = json.load(f)[0]["layers"]
    return {e["name"]: Image.open(e["png"]).convert("RGBA") for e in entries}


def cut(img):
    """Un calque par objet. Sous chaque objet, la surface est completee par le rendu de base :
    masquer une banniere, un pilier ou le cercle laisse voir un mur ou un sol, jamais un trou."""
    info = [[H.cast(x, y) for x in range(GW)] for y in range(GH)]
    ref = base_layers()

    def wall_is(x, y, name):
        surf, (X, Y, Z) = info[y][x]
        return surf == "wall" and H.wall_mat(X, Y, Z)[0] == name

    def banner_hem(x, y):
        """La banniere et ses franges, que le generateur a pu allonger de quelques pixels."""
        return any(y - k >= 0 and wall_is(x, y - k, "Bannières") for k in range(0, 9))

    def gate(x, y):
        surf, (X, Y, Z) = info[y][x]
        return surf == "far" and H.far_mat(X, Y)[0][1] == "void"

    def disc(x, y):
        surf, (X, Y, Z) = info[y][x]
        return surf == "floor" and math.hypot(X - H.RUNE[0], Z - H.RUNE[1]) <= 1.3

    torch = ref["Torches"].split()[3].point(lambda v: 255 if v else 0)
    # (calque, masque, couleurs acceptees ou None pour toutes), par priorite decroissante
    zones = [
        ("Torches", torch.filter(ImageFilter.MaxFilter(5)), FIRE),
        ("Bannières", region(lambda x, y: wall_is(x, y, "Bannières"), 1), None),
        ("Bannières", region(banner_hem, 3), RED | GOLD | {H.C("241527"), H.C("341c27")}),
        ("Piliers", region(lambda x, y: wall_is(x, y, "Piliers"), 0), None),
        ("Cercle runique", region(disc, 1), None),
        ("Herse", region(gate, 1), None),
    ]
    surface = {"far": "Fond lointain", "vault": "Voûte", "wall": "Murs", "floor": "Sol"}
    order = ["Fond lointain", "Voûte", "Murs", "Piliers", "Sol", "Herse", "Cercle runique", "Bannières", "Torches"]
    layers = {n: Image.new("RGBA", (GW, GH), (0, 0, 0, 0)) for n in order}
    ip = img.load()
    for y in range(GH):
        for x in range(GW):
            c = ip[x, y]
            surf = surface[info[y][x][0]]
            name = surf
            for zn, m, colors in zones:
                if m.getpixel((x, y)) and (colors is None or c in colors):
                    name = zn
                    break
            layers[name].putpixel((x, y), c + (255,))
            if name != surf:
                fill = ref[surf].getpixel((x, y))
                assert fill[3] == 255, (surf, x, y)
                layers[surf].putpixel((x, y), fill)
    return [(n, layers[n]) for n in order if layers[n].getbbox()]


def main(src_path, out_aseprite, keep_png=None):
    src = Image.open(src_path).convert("RGB")
    if keep_png:
        src.save(keep_png)  # la source, conservee sans perte (en PNG) a cote du .aseprite
    ref = Image.open(work("hall", "flat.png")).convert("RGB")
    (score, t) = align(src, ref)
    naive = (src.width / GW, 0.0, src.height / GH, 0.0)
    naive_score = ImageStat.Stat(ImageChops.difference(edges(warp(src.filter(ImageFilter.GaussianBlur(1.5)), *naive)), edges(ref))).mean[0]
    print(f"alignement : ecart des contours {naive_score:.2f} -> {score:.2f} ; echelle x {t[0]:.3f} y {t[2]:.3f}, decalage {t[1]:+.1f} {t[3]:+.1f} px source")
    img = to_grid(src, t)
    img.resize((GW * 4, GH * 4), Image.NEAREST).save(work("detail", "apercu_x4.png"))
    layers = cut(img)
    check_independent(layers, H.SURFACES)
    flat = Image.new("RGBA", (GW, GH))
    entries = []
    for i, (n, im) in enumerate(layers):
        p = work("detail", "layers", f"{i:02d}.png")
        im.save(p)
        entries.append(dict(name=n, png=p))
        flat = Image.alpha_composite(flat, im)
    assert ImageChops.difference(flat.convert("RGB"), img).getbbox() is None
    used = len({c for c in img.get_flattened_data()})
    manifest = [dict(out=out_aseprite, ref=work("detail", "detail_ref.png"), w=GW, h=GH, palette=[list(c) for c in H.APOLLO], layers=entries)]
    img.save(manifest[0]["ref"])
    print(f"{len(layers)} calques : {', '.join(n for n, _ in layers)} ; {used} couleurs Apollo")
    build(write_manifest("detail", manifest))


if __name__ == "__main__":
    main(*sys.argv[1:4])
