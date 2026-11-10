"""Etape 3 : ramene une image generee sur la grille d'une scene, en palette Apollo exacte,
et la decoupe en calques d'apres le rendu de la scene (etape 1).

1. Alignement : on cherche la transformation (echelle, decalage) qui superpose le mieux
   les contours de l'image generee a ceux du rendu de la scene.
2. Grille : chaque case prend la couleur moyenne du groupe dominant de son bloc, puis la
   couleur Apollo la plus proche a l'oeil (en Lab), tramee avec sa voisine si besoin.
3. Calques : chaque pixel genere va au calque de l'objet visible a cet endroit dans le
   rendu de la scene. Les autres calques gardent le rendu de la scene : masquer un objet
   laisse voir ce qui est derriere lui, jamais un trou.

    python bg_import.py <scene> <image generee> <sortie.aseprite> [<copie PNG de la source>]

<scene> est le nom du manifeste ecrit par le script de la scene (hall, plaza...).
"""
import cmath
import json
import math
import os
import sys
from PIL import Image, ImageChops, ImageFilter, ImageStat

from aseprite_io import build, check_independent, work, write_manifest
from bg_hall import APOLLO, bayer


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


def _period(src, axis, expected):
    """La periode et le decalage de la grille de pixels peinte le long d'un axe, et sa nettete.

    Les changements de couleur d'un pixel au suivant se repetent a chaque bord de case : on
    cherche la periode, pres de celle qu'on attend, ou cette repetition est la plus forte."""
    d = ImageChops.difference(src, ImageChops.offset(src, *((1, 0) if axis == 0 else (0, 1)))).convert("L")
    w, h = d.size
    px = d.load()
    if axis == 0:
        prof = [sum(px[i, j] for j in range(h)) for i in range(1, w)]
    else:
        prof = [sum(px[i, j] for i in range(w)) for j in range(1, h)]
    mean = sum(prof) / len(prof)
    prof = [v - mean for v in prof]

    def spectrum(p):  # l'amplitude et la phase de la repetition de periode p
        s = sum(v * cmath.exp(2j * math.pi * (k + 1) / p) for k, v in enumerate(prof))
        return abs(s), (cmath.phase(s) % (2 * math.pi)) / (2 * math.pi) * p

    peak, p = max((spectrum(expected * (1 + i / 400))[0], expected * (1 + i / 400)) for i in range(-12, 13))
    off = spectrum(p)[1]
    floor = sorted(spectrum(expected * k / 10)[0] for k in (6, 7, 13, 14, 15))[2]  # le bruit, hors de la periode
    return p, (off + p / 2) % p - p / 2, peak / max(floor, 1)


def lora_grid(src, gw, gh):
    """La grille peinte par le LoRA pixel art, si elle tombe sur la grille de la scene.

    Le LoRA peint des cases d'environ 8 pixels : une image de 768 de large porte une grille de
    96. Quand la grille peinte a la taille de celle de la scene, on la prend telle quelle :
    c'est plus juste que l'alignement sur les contours, qui peut tomber entre deux cases."""
    t = []
    for axis, n in ((0, gw), (1, gh)):
        p, off, sharp = _period(src, axis, src.size[axis] / n)
        if sharp < 3 or abs(p * n - src.size[axis]) > 0.01 * src.size[axis]:
            return None
        t += [p, off]
    return tuple(t)


def tidy(img, palette=APOLLO):
    """Retire le bruit : un pixel seul de sa couleur, entoure d'une couleur proche, prend celle-ci.

    Un pixel tres different de son entourage (un oeil rouge, un reflet) est un detail : il reste."""
    lab = {c: _lab(c) for c in palette}
    src = img.copy()
    sp, op = src.load(), img.load()
    w, h = img.size
    changed = 0
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            c = sp[x, y]
            around = [sp[x + dx, y + dy] for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
            if c in around:
                continue
            top = max(set(around), key=around.count)
            if around.count(top) >= 5 and math.dist(lab[c], lab[top]) < 20:
                op[x, y] = top
                changed += 1
    return changed


def _lab(c):
    """La couleur dans l'espace Lab, ou les distances suivent ce que voit l'oeil."""
    def lin(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(v) for v in c)
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
    f = lambda t: t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116
    fx, fy, fz = f(x), f(y), f(z)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))


def _representative(src, x0, x1, y0, y1):
    """La couleur d'un bloc : la moyenne de son groupe de couleurs dominant.

    Un vote sur des couleurs deja converties laisse gagner le fond sombre et efface les
    details fins ; la moyenne du groupe dominant garde la teinte que le generateur a peinte."""
    groups = {}
    for sy in range(max(0, math.floor(y0)), min(src.height, math.ceil(y1))):
        for sx in range(max(0, math.floor(x0)), min(src.width, math.ceil(x1))):
            c = src[sx, sy]
            groups.setdefault((c[0] // 20, c[1] // 20, c[2] // 20), []).append(c)
    if not groups:
        return None
    best = max(groups.values(), key=len)
    return tuple(sum(c[i] for c in best) / len(best) for i in range(3))


def to_grid(src, t, gw, gh, palette=APOLLO, inset=0.0):
    """Ramene l'image generee sur la grille et sur la palette, en restant au plus pres de ce qu'on voit.

    Chaque case prend la couleur representative de son bloc, puis la couleur de la palette la
    plus proche a l'oeil, en Lab. Pour une couleur vive, la teinte compte plus que la clarte :
    sans cela, un ivoire dans l'ombre part vers un gris bleute. Pour un gris, c'est l'inverse :
    la pierre garde sa luminosite au lieu de chercher une teinte qu'elle n'a pas. Quand la couleur
    tombe entre deux couleurs voisines de la palette, une trame de Bayer les melange, pour rendre
    les tons que la palette n'a pas. inset retire cette part de chaque bord du bloc : sur la grille
    du LoRA, on ne lit que le coeur de chaque case."""
    pal_lab = [_lab(c) for c in palette]
    sp = src.convert("RGB").load()
    a, c, e, f = t
    out = Image.new("RGB", (gw, gh))
    op = out.load()
    for y in range(gh):
        for x in range(gw):
            rep = _representative(_Pixels(sp, src.size), a * (x + inset) + c, a * (x + 1 - inset) + c,
                                  e * (y + inset) + f, e * (y + 1 - inset) + f)
            if rep is None:  # bord hors de l'image source : on prolonge le pixel le plus proche
                rep = sp[min(src.width - 1, max(0, int(a * x + c))), min(src.height - 1, max(0, int(e * y + f)))]
            L = _lab(rep)
            wl = min(1.0, max(0.3, 1 - math.hypot(L[1], L[2]) / 30))  # le poids de la clarte, selon la vivacite
            dist = lambda u, v: (wl * (u[0] - v[0])) ** 2 + (u[1] - v[1]) ** 2 + (u[2] - v[2]) ** 2
            d = sorted((dist(L, pl), i) for i, pl in enumerate(pal_lab))
            (d1, i1), (d2, i2) = d[0], d[1]
            c1, c2 = pal_lab[i1], pal_lab[i2]
            span = dist(c1, c2)
            pick = i1
            if span < 30 ** 2:  # deux couleurs voisines : on trame entre elles
                w = (wl ** 2, 1, 1)
                tt = sum(k * (p - q) * (r - q) for k, p, q, r in zip(w, c2, c1, L)) / span
                if min(1.0, max(0.0, tt)) > bayer(x, y) + 0.25:
                    pick = i2
            op[x, y] = palette[pick]
    return out


class _Pixels:
    """L'acces aux pixels d'une image, avec sa taille, pour lire un bloc."""

    def __init__(self, access, size):
        self.access, self.width, self.height = access, size[0], size[1]

    def __getitem__(self, xy):
        return self.access[xy]


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
    t, inset = lora_grid(src, gw, gh), 0.25
    if t:
        print(f"grille du LoRA : cases de {t[0]:.2f} x {t[2]:.2f} px, decalage {t[1]:+.2f} {t[3]:+.2f} ; lecture du coeur de chaque case")
    else:
        score, t = align(src, ref)
        inset = 0.0
        naive = (src.width / gw, 0.0, src.height / gh, 0.0)
        naive_score = ImageStat.Stat(ImageChops.difference(edges(warp(src.filter(ImageFilter.GaussianBlur(1.5)), *naive, ref.size)), edges(ref))).mean[0]
        print(f"alignement : ecart des contours {naive_score:.2f} -> {score:.2f} ; echelle x {t[0]:.3f} y {t[2]:.3f}, decalage {t[1]:+.1f} {t[3]:+.1f} px source")
    entry = json.load(open(path, encoding="utf-8"))[0]
    excluded = {tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in entry.get("import_exclude", ())}
    img = to_grid(src, t, gw, gh, [c for c in APOLLO if c not in excluded], inset)
    print(f"nettoyage : {tidy(img)} pixels isoles fondus dans leur entourage")
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
