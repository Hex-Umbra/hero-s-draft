"""Ce que partagent les fonds peints par calques : la scene, ses calques complets, les
cartes de guidage pour ComfyUI et l'export en .aseprite.

Une scene est une pile de calques, du plus lointain au plus proche. Chaque objet est rendu
dans son calque comme s'il etait seul ; chaque pixel retient sa profondeur et l'objet qui
l'a peint, ce qui donne la carte de profondeur et la carte des contours.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

from aseprite_io import build, check_independent, work, write_manifest
from bg_hall import APOLLO, bayer

GW, GH = 320, 180


def shade(colors, v, x, y, dither=True):
    """La couleur d'une rampe pour une valeur dans [0, 1], tramee par Bayer ou en aplats."""
    t = max(0.0, min(0.999, v)) * (len(colors) - 1)
    i = int(t) + (1 if t - int(t) > (bayer(x, y) if dither else 0.5) else 0)
    return colors[min(len(colors) - 1, i)]


class Scene:
    """Les calques, chacun avec sa profondeur et ses identifiants d'objet, pixel par pixel.

    Un fond fait 320 x 180 et couvre tout ; un sprite ou un cadre a sa propre taille et
    peut laisser du transparent.
    """

    def __init__(self, order, size=(GW, GH)):
        self.order = order
        self.w, self.h = size
        self.img = {n: Image.new("RGBA", size, (0, 0, 0, 0)) for n in order}
        self.px = {n: im.load() for n, im in self.img.items()}
        self.z = {n: {} for n in order}
        self.oid = {n: {} for n in order}

    def put(self, layer, x, y, col, z, oid):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[layer][x, y] = col + (255,)
            self.z[layer][x, y] = z
            self.oid[layer][x, y] = oid

    def fill(self, layer, draw, z, oid, color):
        """Peint une forme : draw(ImageDraw) la trace en blanc sur un masque, color(x, y) donne la couleur."""
        mask = Image.new("L", (self.w, self.h), 0)
        draw(ImageDraw.Draw(mask))
        box = mask.getbbox()
        if not box:
            return
        m = mask.load()
        for y in range(box[1], box[3]):
            for x in range(box[0], box[2]):
                if m[x, y]:
                    self.put(layer, x, y, color(x, y), z, oid)

    def top(self, x, y):
        """Le calque visible en (x, y), sa profondeur et son objet ; le vide pour un pixel transparent."""
        for n in reversed(self.order):
            if (x, y) in self.z[n]:
                return n, self.z[n][x, y], self.oid[n][x, y]
        return "", math.inf, "vide"


def control_maps(S, shape, skip, depth_range, scale=4):
    """Profondeur (blanc devant) et contours (les limites entre objets), a la taille du guide.

    shape(calque, oid) ramene un identifiant a l'objet dont les contours comptent ; les
    calques de skip (ciel, nuages, fumees...) ne tracent aucun contour.
    """
    depth = Image.new("L", (S.w, S.h))
    edges = Image.new("L", (S.w, S.h))
    top = {(x, y): S.top(x, y) for y in range(S.h) for x in range(S.w)}
    lo, hi = math.log(depth_range[0]), math.log(depth_range[1])
    for (x, y), (n, z, oid) in top.items():
        depth.putpixel((x, y), round(255 * max(0.0, min(1.0, (hi - math.log(z)) / (hi - lo)))))
        if n in skip:
            continue
        here = (n, shape(n, oid))
        if any((top[q][0], shape(top[q][0], top[q][2])) != here for q in ((x + 1, y), (x, y + 1)) if q in top):
            edges.putpixel((x, y), 255)
    size = (S.w * scale, S.h * scale)
    return depth.resize(size, Image.BICUBIC).filter(ImageFilter.GaussianBlur(scale / 2)), edges.resize(size, Image.NEAREST)


def export(S, name, out_aseprite, surfaces, shape=lambda n, oid: oid, skip=(), depth_range=(3.0, 1000.0), guide_scale=4, guide_bg=None, controls=True, import_exclude=()):
    """Ecrit les calques, controle la palette et l'independance, pose a cote du .aseprite
    l'image guide et les cartes de guidage, puis assemble le fichier dans Aseprite.

    guide_scale : l'agrandissement de l'image guide (4 pour un fond ; pour un sprite, de quoi
    atteindre la taille de generation). guide_bg : la couleur posee sous un sprite transparent,
    dans l'image guide seulement. controls : False pour un asset qui ne passe pas par le generateur,
    comme un cadre ; ni image guide ni cartes de guidage ne sont alors ecrites. import_exclude :
    les couleurs Apollo (en hexadecimal) que l'import de l'image generee ne doit pas utiliser."""
    out_dir = work(name, "layers")
    os.makedirs(out_dir, exist_ok=True)
    flat = Image.new("RGBA", (S.w, S.h), (0, 0, 0, 0))
    layers = []
    for i, n in enumerate(S.order):
        if S.img[n].getbbox() is None:
            continue
        p = os.path.join(out_dir, f"{i:02d}.png")
        S.img[n].save(p)
        layers.append(dict(name=n, png=p))
        flat = Image.alpha_composite(flat, S.img[n])
    used = {c[:3] for c in flat.get_flattened_data() if c[3]}
    assert used <= set(APOLLO), used - set(APOLLO)
    check_independent([(e["name"], Image.open(e["png"]).convert("RGBA")) for e in layers], surfaces)
    flat.save(work(name, "flat.png"))
    stem = os.path.splitext(out_aseprite)[0]
    if controls:
        _write_controls(S, flat, stem, shape, skip, depth_range, guide_scale, guide_bg)
    manifest = [dict(out=out_aseprite, ref=work(name, f"{name}_ref.png"), w=S.w, h=S.h, palette=[list(c) for c in APOLLO],
                     layers=layers, surfaces=list(surfaces), import_exclude=list(import_exclude))]
    flat.save(manifest[0]["ref"])
    print(f"{len(layers)} calques, {len(used)} couleurs Apollo utilisees sur 46")
    build(write_manifest(name, manifest))


def _write_controls(S, flat, stem, shape, skip, depth_range, guide_scale, guide_bg):
    guide = flat.convert("RGB") if guide_bg is None else Image.alpha_composite(Image.new("RGBA", flat.size, guide_bg + (255,)), flat).convert("RGB")
    guide.resize((S.w * guide_scale, S.h * guide_scale), Image.NEAREST).save(f"{stem}_guide_x{guide_scale}.png")
    depth, edges = control_maps(S, shape, skip, depth_range, guide_scale)
    depth.save(f"{stem}_depth.png")
    edges.save(f"{stem}_edges.png")
