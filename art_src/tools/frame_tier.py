"""Les cadres de tier des ennemis : la gravure epineuse (B81), du tier 1 au tier 5.

La fenetre est l'invariant : 64 x 96 sur tous les tiers, transparente (le fond de fenetre est un
asset a part, B67). Le canevas grandit de 4 pixels par cote a chaque tier (B73). Autour, une ronce
d'encre, ajouree : seul le dessin est opaque, le decor se voit entre les vrilles. Elle part de deux
coins opposes et envahit le cadre, tier apres tier :
  1 : un filet ; la ronce aux coins bas-gauche et haut-droit, deux feuilles, des epines courtes ;
  2 : ces deux coins s'allongent et s'entrelacent ; des pousses aux deux autres coins ; en haut et en
      bas, ronce et pousse s'arretent a egale distance du centre, pour que l'ecusson tombe juste ;
  3 : la diagonale court presque au milieu des bords et s'y enroule ; les deux autres coins se
      remplissent ; des baies au coeur des boucles ;
  4 : la ronce fait tout le tour et se tresse ; des fleurons au milieu des flancs ;
  5 : des crochets aux quatre coins, une couronne d'epines, un fleuron en bas, des baies partout.
La marque du tier tient dans les 12 pixels au-dessus de la fenetre (B77) : un ecusson et 1 a 5
gemmes, vertes, violettes, rouges, orange, blanches.

Le trait fait 2 pixels, ombre (la lumiere vient d'en haut a gauche) et cerne de sombre, avec un
eclat cuivre qui le fait lire sur un tronc (B82) ; une courbe n'a jamais de marche en L. Chaque
calque est un objet entier, avec son propre cerne : le masquer le retire tout entier. Tout est fait par le code : le cadre ne passe pas par ComfyUI.

    python frame_tier.py 2 ../cadres/tier_2.aseprite
    python frame_tier.py tous ../cadres
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageOps

from bg_hall import C
from scene import Scene, export

WINDOW = (64, 96)
TIERS = {1: ((88, 120), 12), 2: ((96, 128), 16), 3: ((104, 136), 20), 4: ((112, 144), 24), 5: ((120, 152), 28)}  # B73
ORDER = ["Filet", "Ronce", "Pousses", "Fleurons", "Baies", "Écusson", "Gemmes"]
OUTLINE = C("090a14")
INK = [C(h) for h in ("090a14", "241527", "341c27", "4d2b32", "ad7757")]  # [sombre, ombre, moyen, clair, eclat]
GEMS = {1: ("19332d", "25562e", "468232", "75a743", "a8ca58"),  # vert
        2: ("402751", "7a367b", "a23e8c", "c65197", "df84a5"),  # violet
        3: ("411d31", "752438", "a53030", "cf573c", "da863e"),  # rouge
        4: ("602c2c", "a53030", "cf573c", "da863e", "e8c170"),  # orange
        5: ("a53030", "da863e", "e8c170", "ebede9", "ebede9")}  # blanc incandescent
GEMS = {k: [C(h) for h in v] for k, v in GEMS.items()}
BERRY = GEMS[3]
MAIN, OTHER = ("bl", "tr"), ("tl", "br")  # la diagonale ou la ronce nait, et les deux autres coins


def by(tier, *values):
    return values[tier - 1]


# --------------------------------------------------------------------------- le trace
def raster(pts):
    """Une suite de points flottants en pixels contigus, sans marche en L."""
    out = []
    for x, y in pts:
        p = (math.floor(x + 0.5), math.floor(y + 0.5))
        if out:
            q = out[-1]
            if p == q:
                continue
            dx, dy = p[0] - q[0], p[1] - q[1]
            n = max(abs(dx), abs(dy))
            for k in range(1, n):
                r = (q[0] + math.floor(dx * k / n + 0.5), q[1] + math.floor(dy * k / n + 0.5))
                if r != out[-1]:
                    out.append(r)
        out.append(p)
    res = []
    for i, p in enumerate(out):
        if res and i + 1 < len(out):
            a, c = res[-1], out[i + 1]
            if abs(a[0] - c[0]) == 1 and abs(a[1] - c[1]) == 1 and (a[0] == p[0] or a[1] == p[1]) and (c[0] == p[0] or c[1] == p[1]):
                continue
        res.append(p)
    return res


def bez(p0, p1, p2, p3):
    n = int(4 * (math.dist(p0, p1) + math.dist(p1, p2) + math.dist(p2, p3))) + 2
    return [((1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t * t * p2[0] + t ** 3 * p3[0],
             (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t * t * p2[1] + t ** 3 * p3[1])
            for t in (k / n for k in range(n + 1))]


def arc(cx, cy, r, a0, a1):
    n = max(8, int(abs(a1 - a0) * r * 4))
    return [(cx + r * math.cos(a0 + (a1 - a0) * k / n), cy + r * math.sin(a0 + (a1 - a0) * k / n)) for k in range(n + 1)]


def spiral(cx, cy, r0, turns, a0, sign=1):
    n = int(60 * turns * max(1.0, r0 / 3))
    return [(cx + r0 * (1 - 0.8 * k / n) * math.cos(a0 + sign * 2 * math.pi * turns * k / n),
             cy + r0 * (1 - 0.8 * k / n) * math.sin(a0 + sign * 2 * math.pi * turns * k / n)) for k in range(n + 1)]


def stroke(d, pts, w=2):
    for x, y in raster(pts):
        d.rectangle([x, y, x + w - 1, y + w - 1], fill=255)


def thorn(d, x, y, nx, ny, length):
    h = 1.2 if length < 6 else 1.8
    d.polygon([(x - ny * h, y + nx * h), (x + ny * h, y - nx * h), (x + nx * length, y + ny * length)], fill=255)


def leaf(d, x, y, ang, length):
    ex, ey = x + length * math.cos(ang), y + length * math.sin(ang)
    px, py = -math.sin(ang) * 1.4, math.cos(ang) * 1.4
    d.polygon([(x, y), ((x + ex) / 2 + px, (y + ey) / 2 + py), (ex, ey), ((x + ex) / 2 - px, (y + ey) / 2 - py)], fill=255)


# --------------------------------------------------------------------------- le cadre et ses calques
class Frame:
    """Les calques du cadre ; un calque est une pile de materiaux, chacun un masque et sa rampe."""

    def __init__(self, tier):
        (self.W, self.H), self.b = TIERS[tier]
        self.t = tier
        self.x0 = self.y0 = self.b
        self.x1, self.y1 = self.b + WINDOW[0] - 1, self.b + WINDOW[1] - 1
        self.cx, self.cy = self.b + 31.5, self.b + 47.5
        self.layers = {n: [] for n in ORDER}

    def mat(self, layer, ramp=INK):
        m = Image.new("L", (self.W, self.H), 0)
        self.layers[layer].append((m, ramp))
        return ImageDraw.Draw(m), m

    def inwin(self, x, y):
        return self.x0 <= x <= self.x1 and self.y0 <= y <= self.y1

    def render(self, layer):
        """Un calque : chaque materiau ombre par ses bords, puis le cerne du calque entier."""
        out = Image.new("RGBA", (self.W, self.H), (0, 0, 0, 0))
        px = out.load()
        painted = set()
        for m, ramp in self.layers[layer]:
            mp = m.load()
            on = lambda x, y: 0 <= x < self.W and 0 <= y < self.H and mp[x, y] > 0
            for y in range(self.H):
                for x in range(self.W):
                    if not mp[x, y] or self.inwin(x, y):
                        continue
                    up, lf, dn, rt = on(x, y - 1), on(x - 1, y), on(x, y + 1), on(x + 1, y)
                    if not up and not lf:
                        i = 4
                    elif not up or not lf:
                        i = 3
                    elif not dn or not rt:
                        i = 1
                    else:
                        i = 2 if (x * 7 + y * 13) % 11 else 1
                    px[x, y] = ramp[i] + (255,)
                    painted.add((x, y))
        for y in range(self.H):
            for x in range(self.W):
                if (x, y) not in painted and not self.inwin(x, y) and any((x + dx, y + dy) in painted for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    px[x, y] = OUTLINE + (255,)
        return out


def mirror(m, hx=True, vy=True):
    """Reflete un masque : son quart haut-gauche sur les trois autres, ou sa moitie gauche sur la droite."""
    W, H = m.size
    if hx:
        m.paste(ImageOps.mirror(m.crop((0, 0, W // 2, H))), (W // 2, 0))
    if vy:
        m.paste(ImageOps.flip(m.crop((0, 0, W, H // 2))), (0, H // 2))


def place(m, corners):
    """Un masque dessine dans le quart haut-gauche, pose aux coins demandes."""
    W, H = m.size
    q = m.crop((0, 0, W // 2, H // 2))
    out = Image.new("L", (W, H), 0)
    for c, im, at in (("tl", q, (0, 0)), ("tr", ImageOps.mirror(q), (W // 2, 0)),
                      ("bl", ImageOps.flip(q), (0, H // 2)), ("br", ImageOps.flip(ImageOps.mirror(q)), (W // 2, H // 2))):
        if c in corners:
            out.paste(im, at)
    m.paste(out)


def corner(f, layer, corners, reach, r, every, length, interlace=False, braid=False, leaves=False, hook=False, reach_top=None):
    """Une ronce de coin : sa boucle, deux vrilles le long des bords sur reach (de 0 a 1 du demi-bord), leurs epines."""
    t, x0, y0 = f.t, f.x0, f.y0
    e, amp = by(t, 6, 7, 8, 9, 10), by(t, 1.4, 1.8, 2.0, 2.2, 2.4)  # la distance a la fenetre, l'ondulation
    lx, ly = x0 - e - 1, y0 - e - 1
    d, m = f.mat(layer)
    stroke(d, arc(lx, ly, r, 0, 2 * math.pi))
    top = [(lx + r + k / 3, y0 - e + amp * math.sin(k / 15)) for k in range(int(3 * (reach if reach_top is None else reach_top) * (f.cx - lx - r + 2)))]
    left = [(x0 - e + amp * math.sin(k / 15), ly + r + k / 3) for k in range(int(3 * reach * (f.cy - ly - r + 2)))]
    stroke(d, top)
    stroke(d, left)
    if reach < 1 or (reach_top or 1) < 1:  # le bout des vrilles s'enroule
        ex, ey = top[-1]
        stroke(d, spiral(ex + 1, ey - 2.2, 2.2, 0.85, math.pi / 2, -1), 1)
        ex, ey = left[-1]
        stroke(d, spiral(ex - 2.2, ey + 1, 2.2, 0.85, 0, 1), 1)
    if braid:  # une seconde vrille, plus fine, tressee avec la premiere
        stroke(d, [(x, y0 - e - 2 * amp * math.sin((x - lx) / 5) + 1) for x, _ in top], 1)
        stroke(d, [(x0 - e - 2 * amp * math.sin((y - ly) / 5) + 1, y) for _, y in left], 1)
    if interlace:  # deux boucles plus petites, de part et d'autre du coin
        stroke(d, arc(lx + 2 * r, ly + 1, r - 1.5, 0, 2 * math.pi), 1)
        stroke(d, arc(lx + 1, ly + 2 * r, r - 1.5, 0, 2 * math.pi), 1)
    for k in range(int(r) * 3 + 9, len(top) - 4, every * 3):
        thorn(d, top[k][0] + 0.5, top[k][1] - 0.5, 0, -1, length)
    for k in range(int(r) * 3 + 9, len(left) - 4, every * 3):
        thorn(d, left[k][0] - 0.5, left[k][1] + 0.5, -1, 0, length)
    if leaves:
        leaf(d, lx + r + 1, ly - r + 1, -0.6, 4)
        leaf(d, lx - r + 1, ly + r + 1, 2.2, 4)
    if hook:  # un crochet en diagonale, vers dehors, qui se recourbe
        h = bez((lx - r * 0.7, ly - r * 0.7), (lx - r - 5, ly - r - 3), (lx - r - 6, ly - r - 7), (lx - r - 2, ly - r - 9))
        for k, (x, y) in enumerate(h):
            w = 3 if k < len(h) * 0.4 else 2 if k < len(h) * 0.75 else 1
            d.rectangle([round(x), round(y), round(x) + w - 1, round(y) + w - 1], fill=255)
    place(m, corners)
    return lx, ly, top, left


def frame(tier):
    f = Frame(tier)
    t, x0 = tier, f.x0
    d, _ = f.mat("Filet")
    d.rectangle([f.x0 - 1, f.y0 - 1, f.x1 + 1, f.y1 + 1], outline=255)

    if t == 1:
        lx, ly, top, left = corner(f, "Ronce", MAIN, 0.45, 3.5, 9, 2, leaves=True)
    elif t == 2:
        lx, ly, top, left = corner(f, "Ronce", MAIN, 0.75, 4.5, 8, 3, interlace=True, leaves=True, reach_top=0.55)
        corner(f, "Pousses", OTHER, 0.25, 2.8, 9, 2, reach_top=0.55)
    elif t == 3:
        lx, ly, top, left = corner(f, "Ronce", MAIN, 0.9, 5.5, 7, 4, interlace=True)
        corner(f, "Pousses", OTHER, 0.55, 4.0, 8, 3, interlace=True)
    else:
        ring = dict(reach=1.0, r=by(t, 0, 0, 0, 6.0, 6.5), every=by(t, 0, 0, 0, 7, 8), length=by(t, 0, 0, 0, 5, 8),
                    interlace=True, braid=True, hook=(t == 5))
        lx, ly, top, left = corner(f, "Ronce", MAIN, **ring)
        corner(f, "Pousses", OTHER, **ring)

    if t >= 4:  # le fleuron du milieu des flancs
        d, m = f.mat("Fleurons")
        cy, dm = f.cy, by(t, 0, 0, 0, 15, 17)
        leaf(d, x0 - 2, cy, math.pi, dm)
        stroke(d, bez((x0 - 3, cy - 1), (x0 - 4, cy - 6), (x0 - dm + 1, cy - 8), (x0 - dm + 2, cy - 5)), 1)
        stroke(d, spiral(x0 - dm + 3.5, cy - 5, 1.8, 0.7, math.pi, 1), 1)
        mirror(m)
    if t == 5:  # le fleuron du bas
        d, m = f.mat("Fleurons")
        leaf(d, f.cx - 0.5, f.y1 + 2, math.pi / 2, 15)
        stroke(d, bez((f.cx - 1.5, f.y1 + 3), (f.cx - 6, f.y1 + 4), (f.cx - 8, f.y1 + 8), (f.cx - 5, f.y1 + 9)), 1)
        mirror(m, vy=False)

    if t >= 3:  # les baies : au coeur des boucles de la diagonale, puis aux quatre coins et aux fleurons, puis le long des vrilles
        pts = {(lx, f.H - 2 - ly), (f.W - 2 - lx, ly)}
        if t >= 4:
            pts |= {(lx, ly), (f.W - 2 - lx, f.H - 2 - ly), (x0 - 16, round(f.cy) - 1), (f.W - 1 - x0 + 15, round(f.cy) - 1)}
        if t == 5:
            for x, y in [top[k] for k in range(60, len(top) - 20, 45)] + [left[k] for k in range(60, len(left) - 20, 45)]:
                x, y = round(x), round(y)
                pts |= {(x, y), (f.W - 2 - x, y), (x, f.H - 2 - y), (f.W - 2 - x, f.H - 2 - y)}
        d, _ = f.mat("Baies", BERRY)
        for x, y in sorted(pts):
            d.rectangle([x, y, x + 1, y + 1], fill=255)

    # l'ecusson du haut-centre, et sa couronne d'epines a partir du tier 3
    d, m = f.mat("Écusson")
    y, w = f.b - 6, by(t, 5, 9, 11, 14, 17)
    stroke(d, [(f.cx - 0.5, y - 5), (f.cx - w, y), (f.cx - 0.5, y + 5)], 1)
    if t >= 2:
        stroke(d, spiral(f.cx - w - 2.5, y - 1, 2, 0.7, 0, -1), 1)
    if t >= 3:
        thorn(d, f.cx - 0.5, y - 5, 0, -1, by(t, 0, 0, 4, 5, 6))
    if t >= 4:
        thorn(d, f.cx - 6, y - 2, -0.5, -1, by(t, 0, 0, 0, 4, 5))
    if t == 5:
        thorn(d, f.cx - 11, y - 1, -0.8, -1, 5)
        thorn(d, f.cx - 16, y, -1, -0.6, 4)
    mirror(m, vy=False)

    # les gemmes du tier, centrees sur la fenetre
    d, _ = f.mat("Gemmes", GEMS[t])
    left_x = f.b + 30 - 3 * (t - 1)
    for k in range(t):
        d.rectangle([left_x + 6 * k, f.b - 8, left_x + 6 * k + 3, f.b - 6], fill=255)

    S = Scene(ORDER, (f.W, f.H))
    for n in ORDER:
        px = f.render(n).load()
        for y in range(f.H):
            for x in range(f.W):
                if px[x, y][3]:
                    S.put(n, x, y, px[x, y][:3], 1.0, n)
    return S, (f.x0, f.y0)


def write(tier, out):
    S, offset = frame(tier)
    export(S, f"frame_{tier}", out, surfaces=tuple(ORDER), controls=False)
    print(f"cadre de tier {tier} : canevas {S.w} x {S.h}, fenetre 64 x 96 a l'offset {offset}")


if __name__ == "__main__":
    if sys.argv[1] == "tous":
        for tier in TIERS:
            write(tier, os.path.join(sys.argv[2], f"tier_{tier}.aseprite"))
    else:
        write(int(sys.argv[1]), sys.argv[2])
