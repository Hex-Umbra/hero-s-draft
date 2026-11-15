"""Decompose les paliers pixel 16 et pixel 64 des 7 cartes en calques, pour Aseprite.

Chaque pixel appartient au calque de la derniere operation qui l'a peint : la
superposition des calques redonne exactement l'image de la presentation (verifie).
Le calque Fond reste plein, pour qu'effacer un objet laisse voir le decor.
"""
import os
import random
import sys
from PIL import Image, ImageChops, ImageDraw

import ladder
import motifs
import styles
from aseprite_io import build as build_aseprite, check_independent, work, write_manifest
from styles import Ctx, bayer, dilate

GW16, GW64, GH16, GH64 = 21, 84, 16, 64
SKY64 = ladder.SKY64
ROLE_FR = {"light": "Clair", "dark": "Sombre", "accent": "Accent", "second": "Secondaire", "point": "Point lumineux", "sym": "Symbole", "fang": "Crocs"}
CARDS = [("strike_basic", None)] + [(m.key, m) for m in motifs.PILOT]


class Layered:
    """Une image et, pixel par pixel, le calque qui l'a peinte en dernier."""

    def __init__(self, base):
        self.im = base.copy()
        self.base = base.copy()
        self.lab = Image.new("L", base.size, 0)
        self.body = Image.new("L", base.size, 0)
        self.names = ["Fond"]
        self.shading = set()
        self.d = ImageDraw.Draw(self.im)
        self.dl = ImageDraw.Draw(self.lab)
        self.db = ImageDraw.Draw(self.body)
        self.flat = base.copy()  # les aplats seuls, sans aucune operation d'ombrage
        self.df = ImageDraw.Draw(self.flat)

    def idx(self, name):
        if name not in self.names:
            self.names.append(name)
        return self.names.index(name)

    # Une operation d'ombrage (shade=True) se pose par-dessus les aplats sans les trouer :
    # elle n'entre que dans la carte "dernier peintre" (lab), pas dans la carte des aplats (body).
    def _mark(self, layer, shade):
        k = self.idx(layer)
        if shade:
            self.shading.add(layer)
        return k

    def put(self, color, mask, layer, shade=False):
        bad = set(mask.get_flattened_data()) - {0, 255}
        assert not bad, ("masque non binaire", layer, bad)
        k = self._mark(layer, shade)
        self.im.paste(color, (0, 0), mask)
        self.lab.paste(k, (0, 0), mask)
        if not shade:
            self.body.paste(k, (0, 0), mask)
            self.flat.paste(color, (0, 0), mask)

    def line(self, pts, color, layer, shade=False):
        k = self._mark(layer, shade)
        self.d.line(pts, fill=color)
        self.dl.line(pts, fill=k)
        if not shade:
            self.db.line(pts, fill=k)
            self.df.line(pts, fill=color)

    def point(self, xy, color, layer, shade=False):
        k = self._mark(layer, shade)
        self.d.point(xy, fill=color)
        self.dl.point(xy, fill=k)
        if not shade:
            self.db.point(xy, fill=k)
            self.df.point(xy, fill=color)

    def layers(self, order):
        """Les calques RGBA, du bas vers le haut, dans l'ordre demande."""
        out = [("Fond", self.base.convert("RGBA"))]
        for name in order:
            if name not in self.names or name == "Fond":
                continue
            k = self.names.index(name)
            shade = name in self.shading
            src, owner = (self.im, self.lab) if shade else (self.flat, self.body)
            m = owner.point(lambda v, k=k: 255 if v == k else 0)
            rgba = Image.new("RGBA", self.im.size, (0, 0, 0, 0))
            rgba.paste(src.convert("RGBA"), (0, 0), m)
            out.append((name, rgba))
        missing = set(self.names) - {"Fond"} - set(order)
        assert not missing, ("calques sans place", missing)
        return out


def sky(gw, gh):
    im = Image.new("RGB", (gw, gh))
    px = im.load()
    for y in range(gh):
        for x in range(gw):
            f = (y / gh) * (len(SKY64) - 1)
            i = int(f)
            px[x, y] = SKY64[min(len(SKY64) - 1, i + (1 if f - i > bayer(x, y) else 0))]
    return im


B = lambda m: m.point(lambda v: 255 if v > 110 else 0)


# Pixel 64, motifs de la serie pilote (copie de ladder.pix64, calque par calque) -------


def motif64(m):
    t = ladder.G(GW64, GH64, m, 3)
    L = Layered(sky(GW64, GH64))
    if "fx" in m.colors:
        fx = t.mask("fx")
        L.put(ladder.darken(m.colors["fx"], 0.25), B(dilate(fx, 0.6)), "Halo de l'effet")
        L.put(ladder.lighten(m.colors["fx"], 0.35), B(fx), "Effet")
    allm = B(t.mask("all"))
    L.put(ladder.OUTLINE, ImageChops.subtract(dilate(allm, 0.55), allm), "Contour")
    roles = []
    for i, r in t.solid():
        mk = B(t.part_mask(i))
        c = m.colors[r]
        name = ROLE_FR.get(r, r.capitalize())
        roles.append(name)
        L.put(c, mk, name)
        L.put(ladder.lighten(c, 0.5), ImageChops.subtract(mk, ImageChops.offset(mk, 1, 1)), "Lumières", shade=True)
        L.put(ladder.darken(c, 0.32), ImageChops.subtract(mk, ImageChops.offset(mk, -1, -1)), "Ombres", shade=True)
    for e in m.extra:
        L.line(t.P(e), ladder.OUTLINE, "Traits", shade=True)
    rr = random.Random(4)
    halo = dilate(allm, 1.5)
    for _ in range(int(64 * 0.5)):
        x, y = rr.randrange(GW64), rr.randrange(GH64)
        if halo.getpixel((x, y)) == 0:
            L.point((x, y), (255, 236, 170), "Étincelles")
    order = ["Étincelles", "Halo de l'effet", "Effet", "Contour"] + list(dict.fromkeys(roles)) + ["Ombres", "Lumières", "Traits"]
    return L, order, ladder.pix64(ladder.G(GW64, GH64, m))


# Pixel 64, Frappe (copie de styles.pix_n) ----------------------------------------------


def strike64():
    t = Ctx(GW64, GH64, 3)
    L = Layered(sky(GW64, GH64))
    glow, lv = [(255, 214, 120), (255, 248, 214)], styles.LV
    L.put(glow[0], B(dilate(t.mask("slash"), 0.6)), "Halo du croissant")
    L.put(glow[1], B(t.mask("slash")), "Croissant")
    sword = B(t.mask("sword"))
    L.put((18, 14, 34), ImageChops.subtract(dilate(sword, 0.55), sword), "Contour")
    L.put(lv["light"], B(t.mask("blade_l")), "Lame, face claire")
    L.put(lv["dark"], B(t.mask("blade_d")), "Lame, face sombre")
    L.put(lv["gold"], B(t.mask("guard")), "Garde")
    L.put(lv["brown"], B(t.mask("grip")), "Poignée")
    L.put(lv["red"], B(t.mask("pommel")), "Pommeau")
    a = t.along
    for k in range(0, 12, 2):
        tt = 0.24 + k * 0.04
        L.line([t.p(*a(tt, -0.03)), t.p(*a(tt + 0.05, -0.03))], (255, 255, 255), "Reflets", shade=True)
    L.line([t.p(*a(0.19 + 0.02, 0.03)), t.p(*a(t.len - 0.14, 0.03))], lv["deep"], "Ombre de la lame", shade=True)
    L.line([t.p(*a(0.19 - 0.02, -0.11)), t.p(*a(0.19 - 0.02, 0.11))], (255, 235, 150), "Reflets", shade=True)
    r = random.Random(4)
    for _ in range(int(64 * 0.5)):
        x, y = r.randrange(GW64), r.randrange(GH64)
        if sword.getpixel((x, y)) == 0:
            L.point((x, y), (255, 236, 170), "Étincelles")
    order = ["Étincelles", "Halo du croissant", "Croissant", "Contour", "Lame, face claire", "Lame, face sombre", "Garde", "Poignée", "Pommeau", "Ombre de la lame", "Reflets"]
    return L, order, styles.pix64(Ctx(GW64, GH64))


# Pixel 16 : un decor et un sprite pose a la main ---------------------------------------


def sprite16(rows, pal, bg, ox, oy):
    L = Layered(Image.new("RGB", (GW16, GH16), bg))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in pal:
                L.point((ox + x, oy + y), pal[ch], "Sprite")
    return L, ["Sprite"]


def motif16(m):
    sw, sh = len(m.sprite[0]), len(m.sprite)
    L, order = sprite16(m.sprite, m.spal, (46, 58, 116), (GW16 - sw) // 2, (GH16 - sh) // 2)
    return L, order, ladder.pix16(ladder.G(GW16, GH16, m))


STRIKE16 = [
    "............kkk.",
    "...........kwwk.",
    "..........kwwgk.",
    ".........kwwgk..",
    "........kwwgk...",
    ".......kwwgk..c.",
    "..k...kwwgk....c",
    ".kyk.kwwgk.....c",
    ".kyykwwgk......c",
    "..kyywgk.......c",
    "...kyyk.......c.",
    "..kbkyyk.....c..",
    ".kbk.kyyk..cc...",
    "kbk...kk........",
    "kk..............",
    "................",
]


def strike16():
    pal = {"k": (20, 16, 40), "w": (240, 244, 250), "g": (130, 150, 180), "y": (240, 180, 50), "b": (130, 76, 40), "c": (120, 225, 245)}
    L, order = sprite16(STRIKE16, pal, (46, 58, 116), (GW16 - 16) // 2, 0)
    return L, order, styles.pix16(Ctx(GW16, GH16))


def build(out_dir):
    manifest = []
    for key, m in CARDS:
        for stage, fn in (("pix16", strike16 if m is None else lambda m=m: motif16(m)), ("pix64", strike64 if m is None else lambda m=m: motif64(m))):
            L, order, ref = fn()
            ref = ref.convert("RGB")
            assert ref.size == L.im.size, (key, stage, ref.size, L.im.size)
            diff = ImageChops.difference(ref, L.im).getbbox()
            assert diff is None, (key, stage, "decomposition differente de l'original", diff)
            layers = L.layers(order)
            check_independent(layers, surfaces=("Fond",))
            flat = Image.new("RGBA", L.im.size)
            for _, im in layers:
                flat = Image.alpha_composite(flat, im)
            assert ImageChops.difference(flat.convert("RGB"), ref).getbbox() is None, (key, stage, "superposition")
            colors = sorted({c for _, im in layers for c, a in [(p[:3], p[3]) for p in im.get_flattened_data()] if a})
            entry = dict(out=os.path.join(out_dir, f"{key}_{stage}.aseprite"), ref=work("cards", f"{key}_{stage}_ref.png"), w=L.im.width, h=L.im.height, palette=[list(c) for c in colors], layers=[])
            ref.save(entry["ref"])
            for n, (name, im) in enumerate(layers):
                p = work("cards", f"{key}_{stage}_{n:02d}.png")
                im.save(p)
                entry["layers"].append(dict(name=name, png=p))
            manifest.append(entry)
            print(f"{key:14s} {stage}  {L.im.width}x{L.im.height}  {len(layers):2d} calques  {len(colors):2d} couleurs")
    build_aseprite(write_manifest("cards", manifest))


if __name__ == "__main__":
    build(sys.argv[1])
