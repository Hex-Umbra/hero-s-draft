"""Etape 3 : ramene une image generee sur la grille d'une scene, en palette Apollo exacte,
et la decoupe en calques d'apres le rendu de la scene (etape 1).

1. Alignement : on cherche la transformation (echelle, decalage) qui superpose le mieux
   les contours de l'image generee a ceux du rendu de la scene.
2. Grille : chaque pixel source est d'abord ramene a la couleur Apollo la plus proche,
   puis chaque case de la grille prend la couleur majoritaire de son bloc.
3. Calques : chaque pixel genere va au calque de l'objet visible a cet endroit dans le
   rendu de la scene. Les autres calques gardent le rendu de la scene : masquer un objet
   laisse voir ce qui est derriere lui, jamais un trou.

    python bg_import.py <scene> <image generee> <sortie.aseprite> [<copie PNG de la source>]

<scene> est le nom du manifeste ecrit par le script de la scene (hall, plaza...).
"""
import json
import math
import os
import sys
from collections import Counter
from PIL import Image, ImageChops, ImageFilter, ImageStat

from aseprite_io import build, check_independent, work, write_manifest
from bg_hall import APOLLO


def edges(im):
    return im.convert("L").filter(ImageFilter.FIND_EDGES).filter(ImageFilter.GaussianBlur(1.2))


def warp(src, a, c, e, f, size, resample=Image.BILINEAR):
    return src.transform(size, Image.AFFINE, (a, 0, c, 0, e, f), resample=resample)


def align(src, ref):
    gw, gh = ref.size
    """Recherche par paliers de la transformation qui minimise l'ecart des contours."""
    er = edges(ref)
    soft = src.filter(ImageFilter.GaussianBlur(1.5))
    best = None
    a0, e0 = src.width / gw, src.height / gh
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
            diff = ImageChops.difference(edges(warp(soft, *t, ref.size)), er)
            scored.append((ImageStat.Stat(diff).mean[0], t))
        scored.sort()
        best = scored[0]
        grid = [t for _, t in scored[:3]]
    return best


def to_grid(src, t, gw, gh):
    """Chaque case prend la couleur Apollo majoritaire de son bloc source."""
    pal_img = Image.new("P", (1, 1))
    flat = [v for c in APOLLO for v in c]
    pal_img.putpalette(flat + flat[:3] * (256 - len(APOLLO)))
    q = src.convert("RGB").quantize(palette=pal_img, dither=Image.Dither.NONE)
    qp = q.load()
    a, c, e, f = t
    out = Image.new("RGB", (gw, gh))
    op = out.load()
    for y in range(gh):
        for x in range(gw):
            x0, x1 = a * x + c, a * (x + 1) + c
            y0, y1 = e * y + f, e * (y + 1) + f
            votes = Counter()
            for sy in range(max(0, math.floor(y0)), min(src.height, math.ceil(y1))):
                for sx in range(max(0, math.floor(x0)), min(src.width, math.ceil(x1))):
                    k = qp[sx, sy]
                    if k < len(APOLLO):
                        votes[k] += 1
            if not votes:  # bord hors de l'image source : on prolonge le pixel le plus proche
                sx = min(src.width - 1, max(0, int((x0 + x1) / 2)))
                sy = min(src.height - 1, max(0, int((y0 + y1) / 2)))
                votes[qp[sx, sy]] = 1
            op[x, y] = APOLLO[votes.most_common(1)[0][0]]
    return out


def cut(img, scene):
    """Les calques de la scene, ou chaque pixel visible est remplace par le pixel genere."""
    entry = json.load(open(work(f"{scene}_manifest.json"), encoding="utf-8"))[0]
    skip = set(entry.get("import_skip", ()))
    base = [(e["name"], Image.open(e["png"]).convert("RGBA")) for e in entry["layers"] if e["name"] not in skip]
    out = [(n, im.copy()) for n, im in base]
    alpha = [im.getchannel("A").load() for _, im in base]
    pix = [im.load() for _, im in out]
    ip = img.load()
    for y in range(img.height):
        for x in range(img.width):
            owner = next(i for i in range(len(base) - 1, -1, -1) if alpha[i][x, y])
            pix[owner][x, y] = ip[x, y] + (255,)
    return out, entry


def main(scene, src_path, out_aseprite, keep_png=None):
    path = work(f"{scene}_manifest.json")
    if not os.path.isfile(path):
        raise SystemExit(f"lancer d'abord le script de la scene « {scene} » : le decoupage s'appuie sur son rendu")
    src = Image.open(src_path).convert("RGB")
    if keep_png:
        src.save(keep_png)  # la source, conservee sans perte (en PNG) a cote du .aseprite
    ref = Image.open(work(scene, "flat.png")).convert("RGB")
    gw, gh = ref.size
    score, t = align(src, ref)
    naive = (src.width / gw, 0.0, src.height / gh, 0.0)
    naive_score = ImageStat.Stat(ImageChops.difference(edges(warp(src.filter(ImageFilter.GaussianBlur(1.5)), *naive, ref.size)), edges(ref))).mean[0]
    print(f"alignement : ecart des contours {naive_score:.2f} -> {score:.2f} ; echelle x {t[0]:.3f} y {t[2]:.3f}, decalage {t[1]:+.1f} {t[3]:+.1f} px source")
    img = to_grid(src, t, gw, gh)
    img.resize((gw * 4, gh * 4), Image.NEAREST).save(work(f"{scene}_detail", "apercu_x4.png"))
    layers, entry = cut(img, scene)
    check_independent(layers, entry.get("surfaces", ()))
    flat = Image.new("RGBA", (gw, gh))
    entries = []
    for i, (n, im) in enumerate(layers):
        p = work(f"{scene}_detail", "layers", f"{i:02d}.png")
        im.save(p)
        entries.append(dict(name=n, png=p))
        flat = Image.alpha_composite(flat, im)
    assert ImageChops.difference(flat.convert("RGB"), img).getbbox() is None
    used = len({c for c in img.get_flattened_data()})
    manifest = [dict(out=out_aseprite, ref=work(f"{scene}_detail", "detail_ref.png"), w=gw, h=gh, palette=[list(c) for c in APOLLO], layers=entries)]
    img.save(manifest[0]["ref"])
    print(f"{len(layers)} calques : {', '.join(n for n, _ in layers)} ; {used} couleurs Apollo")
    build(write_manifest(f"{scene}_detail", manifest))


if __name__ == "__main__":
    main(*sys.argv[1:5])
