"""Les cinq paliers de l'echelle A, appliques a n'importe quel motif de motifs.py."""
import math
import random
from PIL import Image, ImageChops, ImageDraw, ImageFilter
from styles import bayer, dilate, fill, lined_paper, painterly, paste, vgrad, wobble

STAGES = ["doodle", "pix16", "pix64", "cel", "splash"]
OUTLINE = (18, 14, 34)


def mix(a, b, t):
    return tuple(int(round(x + (y - x) * t)) for x, y in zip(a, b))


def lighten(c, t):
    return mix(c, (255, 255, 255), t)


def darken(c, t):
    return mix(c, (0, 0, 0), t)


class G:
    """Le contexte de rendu : un motif pose dans un canvas W x H, carre unite centre."""

    def __init__(self, w, h, motif, seed=7):
        self.W, self.H = w, h
        self.M = min(w, h)
        self.ox = (w - self.M) / 2
        self.oy = (h - self.M) / 2
        self.r = random.Random(seed)
        self.m = motif

    def p(self, x, y):
        return (self.ox + x * self.M, self.oy + y * self.M)

    def P(self, pts):
        return [self.p(*q) for q in pts]

    def part_mask(self, i):
        im = Image.new("L", (self.W, self.H), 0)
        ImageDraw.Draw(im).polygon(self.P(self.m.parts[i][1]), fill=255)
        return im

    def mask(self, role):
        im = Image.new("L", (self.W, self.H), 0)
        d = ImageDraw.Draw(im)
        for r, pts in self.m.parts:
            if (role == "all" and r != "fx") or r == role or (isinstance(role, tuple) and r in role):
                d.polygon(self.P(pts), fill=255)
        return im

    def solid(self):
        return [(i, r) for i, (r, _) in enumerate(self.m.parts) if r != "fx"]

    def lines(self, fx=True):
        out = []
        for r, pts in self.m.parts:
            if r in self.m.no_line or (r == "fx" and not fx):
                continue
            out.append(self.P(pts + pts[:1]))
        return out + [self.P(e) for e in self.m.extra]


def col(g, role):
    return g.m.colors[role]


# 1. Griffonnage ---------------------------------------------------------------


def doodle(g):
    im = lined_paper(g)
    d = ImageDraw.Draw(im)
    ink = (28, 52, 150)
    W = max(3, g.M // 200)
    for pts in g.lines():
        for _ in range(g.r.choice((2, 2, 3))):
            d.line(wobble(g, pts, g.M * 0.0075), fill=ink, width=W, joint="curve")
    # hachures rapides sur les parties sombres, qui depassent un peu
    hatch = Image.new("L", (g.W, g.H), 0)
    dh = ImageDraw.Draw(hatch)
    step = max(8, int(g.M * 0.026))
    for k in range(-g.H, g.W + g.H, step):
        dh.line(wobble(g, [(k, g.H), (k + g.H * 0.8, 0)], g.M * 0.003, 30), fill=255, width=max(2, W - 1))
    zone = dilate(g.mask(g.m.hatch), g.M * 0.012)
    d2 = Image.new("RGB", (g.W, g.H), ink)
    im.paste(d2, (0, 0), ImageChops.multiply(hatch, zone))
    for pts in g.m.marks:
        d.line(wobble(g, g.P(pts), g.M * 0.004, 8), fill=ink, width=W)
    return im


# 2. Pixel 16 ------------------------------------------------------------------


def pix16(g):
    S = g.m.sprite
    sw, sh = len(S[0]), len(S)
    gh = 16
    gw = max(sw, round(g.W / g.H * 16))
    im = fill(gw, gh, (46, 58, 116))
    ox, oy = (gw - sw) // 2, (gh - sh) // 2
    for y, row in enumerate(S):
        for x, ch in enumerate(row):
            if ch in g.m.spal:
                im.putpixel((ox + x, oy + y), g.m.spal[ch])
    return im.resize((g.W, g.H), Image.NEAREST)


# 3. Pixel 64 ------------------------------------------------------------------

SKY64 = [(10, 38, 58), (16, 66, 80), (28, 104, 106), (58, 146, 118), (126, 188, 128)]


def pix64(g, res=64):
    gh = res
    gw = round(g.W / g.H * res)
    t = G(gw, gh, g.m, 3)
    im = fill(gw, gh, SKY64[0])
    px = im.load()
    for y in range(gh):
        for x in range(gw):
            f = (y / gh) * (len(SKY64) - 1)
            i = int(f)
            px[x, y] = SKY64[min(len(SKY64) - 1, i + (1 if f - i > bayer(x, y) else 0))]
    B = lambda m: m.point(lambda v: 255 if v > 110 else 0)
    if "fx" in g.m.colors:
        fx = t.mask("fx")
        paste(im, darken(col(g, "fx"), 0.25), B(dilate(fx, 0.6)))
        paste(im, lighten(col(g, "fx"), 0.35), B(fx))
    allm = B(t.mask("all"))
    paste(im, OUTLINE, ImageChops.subtract(dilate(allm, 0.55), allm))
    for i, r in t.solid():
        mk = B(t.part_mask(i))
        c = col(g, r)
        paste(im, c, mk)
        paste(im, lighten(c, 0.5), ImageChops.subtract(mk, ImageChops.offset(mk, 1, 1)))
        paste(im, darken(c, 0.32), ImageChops.subtract(mk, ImageChops.offset(mk, -1, -1)))
    d = ImageDraw.Draw(im)
    for e in g.m.extra:
        d.line(t.P(e), fill=OUTLINE)
    rr = random.Random(4)
    halo = dilate(allm, 1.5)
    for _ in range(int(res * 0.5)):
        x, y = rr.randrange(gw), rr.randrange(gh)
        if halo.getpixel((x, y)) == 0:
            d.point((x, y), fill=(255, 236, 170))
    return im.resize((g.W, g.H), Image.NEAREST)


# 4. Dessin anime --------------------------------------------------------------


def speed(g, im, color):
    d = ImageDraw.Draw(im)
    cx, cy = g.p(*g.m.center)
    R = g.W + g.H
    r = random.Random(11)
    for k in range(52):
        a = k / 52 * 2 * math.pi + r.uniform(-0.03, 0.03)
        w = r.uniform(0.015, 0.05)
        i = g.M * r.uniform(0.4, 0.55)
        d.polygon([(cx + i * math.cos(a), cy + i * math.sin(a)), (cx + R * math.cos(a - w), cy + R * math.sin(a - w)), (cx + R * math.cos(a + w), cy + R * math.sin(a + w))], fill=color)


def cel(g):
    im = vgrad(g.W, g.H, (150, 40, 70), (250, 130, 50))
    speed(g, im, (255, 200, 110))
    if "fx" in g.m.colors:
        fx = g.mask("fx")
        paste(im, (255, 255, 240), dilate(fx, g.M * 0.008))
        paste(im, lighten(col(g, "fx"), 0.3), fx)
    k = max(2, int(g.M * 0.03))
    for i, r in g.solid():
        mk = g.part_mask(i)
        c = col(g, r)
        paste(im, c, mk)
        paste(im, darken(c, 0.3), ImageChops.subtract(mk, ImageChops.offset(mk, -k, -k)))
        paste(im, lighten(c, 0.6), ImageChops.subtract(mk, ImageChops.offset(mk, k // 2, k // 2)))
    lines = Image.new("L", (g.W, g.H), 0)
    d = ImageDraw.Draw(lines)
    for pts in g.lines(fx=False):
        d.line(pts, fill=255, width=max(8, g.M // 90), joint="curve")
    paste(im, (16, 14, 20), lines)
    return im


# 5. Peinture numerique --------------------------------------------------------


def smooth(g):
    im = vgrad(g.W, g.H, (28, 12, 44), (150, 44, 44))
    glow = fill(g.W, g.H, (0, 0, 0))
    if "fx" in g.m.colors:
        paste(glow, darken(col(g, "fx"), 0.15), g.mask("fx"))
    paste(glow, darken(col(g, "light"), 0.55), g.mask("light"))
    glow = glow.filter(ImageFilter.GaussianBlur(g.M * 0.05))
    im = ImageChops.add(im, glow)
    if "fx" in g.m.colors:
        paste(im, lighten(col(g, "fx"), 0.55), g.mask("fx").filter(ImageFilter.GaussianBlur(g.M * 0.01)))
    grad = Image.linear_gradient("L").resize((512, 512)).rotate(45, resample=Image.BILINEAR).crop((106, 106, 406, 406)).resize((g.W, g.H))
    for i, r in g.solid():
        c = col(g, r)
        shade = Image.composite(fill(g.W, g.H, lighten(c, 0.45)), fill(g.W, g.H, darken(c, 0.45)), grad)
        im.paste(shade, (0, 0), g.part_mask(i))
    return im


def splash(g):
    M = g.M
    src = smooth(g)
    base = painterly(g, src, [(1500, M * 0.06, int(M * 0.02), 10), (5000, M * 0.03, int(M * 0.009), 6), (3000, M * 0.012, max(2, int(M * 0.004)), 4)])
    m = g.mask("all").point(lambda v: 228 if v else 0).filter(ImageFilter.GaussianBlur(M * 0.002))
    base.paste(src, (0, 0), m)
    bloom = base.point(lambda v: max(0, v - 178) * 3).filter(ImageFilter.GaussianBlur(M * 0.03))
    base = ImageChops.add(base, bloom)
    d = ImageDraw.Draw(base)
    r = random.Random(9)
    for _ in range(170):
        x, y = r.uniform(0, g.W), r.uniform(0, g.H)
        s = r.uniform(1, M * 0.006)
        d.ellipse([x - s, y - s, x + s, y + s], fill=(255, r.randint(190, 245), r.randint(120, 200)))
    tip = g.p(*g.m.flare)
    s = M * 0.13
    flare = Image.new("L", (g.W, g.H), 0)
    fd = ImageDraw.Draw(flare)
    fd.polygon([(tip[0] - s, tip[1]), (tip[0], tip[1] - s * 0.06), (tip[0] + s, tip[1]), (tip[0], tip[1] + s * 0.06)], fill=255)
    fd.polygon([(tip[0], tip[1] - s), (tip[0] + s * 0.06, tip[1]), (tip[0], tip[1] + s), (tip[0] - s * 0.06, tip[1])], fill=255)
    paste(base, (255, 250, 230), flare.filter(ImageFilter.GaussianBlur(M * 0.002)))
    return base


REG = {"doodle": doodle, "pix16": pix16, "pix64": pix64, "cel": cel, "splash": splash}
PIXEL = {"pix16", "pix64"}


def render(motif, stage, w, h, seed=7):
    return REG[stage](G(w, h, motif, seed)).convert("RGB")


def art(motif, stage, w, h, seed=7):
    """L'image a la taille w x h, rendue au double puis reduite (les pixels restent nets)."""
    im = render(motif, stage, w * 2, h * 2, seed)
    return im.resize((w, h), Image.NEAREST if stage in PIXEL else Image.LANCZOS)
