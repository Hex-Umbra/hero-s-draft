"""Frappe aux cinq paliers de l'echelle A, et les outils de dessin partages par les autres motifs (PIL seul)."""
import math
import random
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

F = "C:/Windows/Fonts/"


def font(name, size):
    return ImageFont.truetype(F + name, size)


class Ctx:
    """Le motif vit dans un carre unite, centre dans le canvas W x H."""

    def __init__(self, w, h, seed=7):
        self.W, self.H = w, h
        self.M = min(w, h)
        self.ox = (w - self.M) / 2
        self.oy = (h - self.M) / 2
        self.r = random.Random(seed)
        T, H_ = (0.78, 0.11), (0.15, 0.72)
        dx, dy = T[0] - H_[0], T[1] - H_[1]
        ln = math.hypot(dx, dy)
        self.d = (dx / ln, dy / ln)
        self.n = (-self.d[1], self.d[0])
        self.Tip, self.Hilt, self.len = T, H_, ln

    def p(self, x, y):
        return (self.ox + x * self.M, self.oy + y * self.M)

    def along(self, t, s=0.0):
        """t le long de la lame depuis le pommeau, s en travers."""
        return (
            self.Hilt[0] + self.d[0] * t + self.n[0] * s,
            self.Hilt[1] + self.d[1] * t + self.n[1] * s,
        )

    def polys(self):
        a = self.along
        L = self.len
        g, w = 0.19, 0.052
        c = {
            "blade_l": [a(g, -w), a(L - 0.11, -w), a(L, 0), a(g, 0)],
            "blade_d": [a(g, 0), a(L, 0), a(L - 0.11, w), a(g, w)],
            "guard": [a(g - 0.03, -0.14), a(g + 0.03, -0.14), a(g + 0.03, 0.14), a(g - 0.03, 0.14)],
            "grip": [a(0.03, -0.027), a(g - 0.03, -0.027), a(g - 0.03, 0.027), a(0.03, 0.027)],
            "slash": self.crescent(),
        }
        return c

    def crescent(self):
        cx, cy = self.Hilt
        o, i = [], []
        for k in range(41):
            t = k / 40
            th = math.radians(-41 + 56 * t)
            ro = 0.74
            thick = 0.15 * ((1 - t) ** 1.3) * min(1, t * 9)
            o.append((cx + ro * math.cos(th), cy + ro * math.sin(th)))
            i.append((cx + (ro - thick) * math.cos(th), cy + (ro - thick) * math.sin(th)))
        return o + i[::-1]

    def mask(self, name):
        im = Image.new("L", (self.W, self.H), 0)
        d = ImageDraw.Draw(im)
        if name == "pommel":
            cx, cy = self.p(*self.Hilt)
            r = 0.042 * self.M
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
        elif name == "sword":
            for k in ("blade_l", "blade_d", "guard", "grip"):
                d.polygon([self.p(*q) for q in self.polys()[k]], fill=255)
            cx, cy = self.p(*self.Hilt)
            r = 0.042 * self.M
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
        else:
            d.polygon([self.p(*q) for q in self.polys()[name]], fill=255)
        return im

    def lines(self):
        """Les contours du motif, en polylignes ouvertes, du trait a la main."""
        out = []
        for k, q in self.polys().items():
            if k == "blade_d":
                continue
            if k == "blade_l":
                a = self.along
                L, g, w = self.len, 0.19, 0.052
                q = [a(g, -w), a(L - 0.11, -w), a(L, 0), a(L - 0.11, w), a(g, w)]
                out.append([self.p(*x) for x in q])
                out.append([self.p(*a(g + 0.02, 0)), self.p(*a(L - 0.06, 0))])
                continue
            if k == "slash":
                n = len(q) // 2
                out.append([self.p(*x) for x in q[:n]])
                out.append([self.p(*x) for x in q[n:]])
                continue
            out.append([self.p(*x) for x in q + q[:1]])
        cx, cy = self.Hilt
        out.append(
            [
                self.p(cx + 0.042 * math.cos(t / 12 * 2 * math.pi), cy + 0.042 * math.sin(t / 12 * 2 * math.pi))
                for t in range(13)
            ]
        )
        return out


def sub(pts, step):
    res = []
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(b[0] - a[0], b[1] - a[1]) / step))
        for i in range(n):
            res.append((a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n))
    res.append(pts[-1])
    return res


def wobble(c, pts, amp, step=14):
    q = sub(pts, step)
    f1, f2 = c.r.uniform(0.008, 0.016), c.r.uniform(0.02, 0.04)
    p1, p2, p3, p4 = [c.r.uniform(0, 6.28) for _ in range(4)]
    res, s = [], 0.0
    for x, y in q:
        s += step
        res.append(
            (
                x + amp * (math.sin(s * f1 + p1) + 0.5 * math.sin(s * f2 + p2)),
                y + amp * (math.sin(s * f1 + p3) + 0.5 * math.sin(s * f2 + p4)),
            )
        )
    return res


def noise(w, h, sigma=40, blur=0):
    n = Image.effect_noise((w, h), sigma)
    return n.filter(ImageFilter.GaussianBlur(blur)) if blur else n


def fill(w, h, color):
    return Image.new("RGB", (w, h), color)


def vgrad(w, h, a, b):
    g = Image.linear_gradient("L").resize((w, h))
    return Image.composite(fill(w, h, b), fill(w, h, a), g)


def dilate(m, r):
    return m.filter(ImageFilter.GaussianBlur(r)).point(lambda v: 255 if v > 18 else 0)


def paste(im, color, m):
    im.paste(color, (0, 0), m)


def paper_texture(im, amount=10):
    n = noise(im.width, im.height, amount).convert("RGB")
    return ImageChops.overlay(im, Image.blend(fill(im.width, im.height, (128, 128, 128)), n, 0.5))


# --- Palier 1 : griffonnage ----------------------------------------------------


def lined_paper(c):
    im = fill(c.W, c.H, (247, 241, 222))
    d = ImageDraw.Draw(im)
    gap = int(c.M * 0.075)
    for y in range(gap // 2, c.H, gap):
        d.line([(0, y), (c.W, y)], fill=(170, 195, 225), width=max(2, c.M // 300))
    x = int(c.M * 0.11)
    d.line([(x, 0), (x, c.H)], fill=(226, 130, 130), width=max(3, c.M // 260))
    return paper_texture(im, 8)


def doodle(c):
    im = lined_paper(c)
    d = ImageDraw.Draw(im)
    ink = (28, 52, 150)
    W = max(3, c.M // 200)
    for pts in c.lines():
        for _ in range(c.r.choice((2, 2, 3))):
            d.line(wobble(c, pts, c.M * 0.0075), fill=ink, width=W, joint="curve")
    # gribouillis de la lame : quelques hachures qui depassent
    for k in range(26):
        t = 0.24 + k * 0.024
        a, b = c.p(*c.along(t, -0.05)), c.p(*c.along(t + 0.03, 0.05))
        d.line(wobble(c, [a, b], c.M * 0.003, 8), fill=ink, width=max(2, W - 1))
    # traits de vitesse
    for k in range(4):
        a = c.p(0.60 + k * 0.05, 0.85 - k * 0.1)
        b = (a[0] + c.M * 0.09, a[1] + c.M * 0.035)
        d.line(wobble(c, [a, b], c.M * 0.004, 8), fill=ink, width=W)
    return im


# --- Paliers 2 et 3 : pixel 16 et pixel 64 -------------------------------------


def pix16(c):
    S = [
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
    pal = {"k": (20, 16, 40), "w": (240, 244, 250), "g": (130, 150, 180), "y": (240, 180, 50), "b": (130, 76, 40), "c": (120, 225, 245)}
    bg = (46, 58, 116)
    gw = 16
    gh = max(16, round(c.H / c.W * 16))
    if c.W > c.H:
        gh = 16
        gw = round(c.W / c.H * 16)
    im = fill(gw, gh, bg)
    ox, oy = (gw - 16) // 2, (gh - 16) // 2
    for y, row in enumerate(S):
        for x, ch in enumerate(row):
            if ch in pal:
                im.putpixel((ox + x, oy + y), pal[ch])
    return im.resize((c.W, c.H), Image.NEAREST)


def bayer(x, y):
    m = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    return m[y % 4][x % 4] / 16


def pix_n(c, res, sky, glow, levels, seed=3, motif=True):
    if c.W >= c.H:
        gh = res
        gw = round(c.W / c.H * res)
    else:
        gw = res
        gh = round(c.H / c.W * res)
    t = Ctx(gw, gh, seed)
    im = fill(gw, gh, sky[0])
    px = im.load()
    for y in range(gh):
        for x in range(gw):
            f = (y / gh) * (len(sky) - 1)
            i = int(f)
            px[x, y] = sky[min(len(sky) - 1, i + (1 if f - i > bayer(x, y) else 0))]
    if not motif:
        return im.resize((c.W, c.H), Image.NEAREST)
    B = lambda m: m.point(lambda v: 255 if v > 110 else 0)
    # croissant
    paste(im, glow[0], B(dilate(t.mask("slash"), 0.6)))
    paste(im, glow[1], B(t.mask("slash")))
    sword = B(t.mask("sword"))
    outline = ImageChops.subtract(dilate(sword, 0.55), sword)
    paste(im, (18, 14, 34), outline)
    bl, bd = B(t.mask("blade_l")), B(t.mask("blade_d"))
    paste(im, levels["light"], bl)
    paste(im, levels["dark"], bd)
    paste(im, levels["gold"], B(t.mask("guard")))
    paste(im, levels["brown"], B(t.mask("grip")))
    paste(im, levels["red"], B(t.mask("pommel")))
    if res >= 48:
        # reflets et ombres dans la lame, par bandes
        a, L = t.along, t.len
        d = ImageDraw.Draw(im)
        for k in range(0, 12, 2):
            tt = 0.24 + k * 0.04
            d.line([t.p(*a(tt, -0.03)), t.p(*a(tt + 0.05, -0.03))], fill=(255, 255, 255))
        d.line([t.p(*a(0.19 + 0.02, 0.03)), t.p(*a(L - 0.14, 0.03))], fill=levels["deep"])
        d.line([t.p(*a(0.19 - 0.02, -0.11)), t.p(*a(0.19 - 0.02, 0.11))], fill=(255, 235, 150))
        # etincelles
        r = random.Random(4)
        for _ in range(int(res * 0.5)):
            x, y = r.randrange(gw), r.randrange(gh)
            if sword.getpixel((x, y)) == 0:
                d.point((x, y), fill=(255, 236, 170))
    return im.resize((c.W, c.H), Image.NEAREST)


LV = {
    "light": (226, 232, 244),
    "dark": (120, 140, 176),
    "deep": (72, 82, 122),
    "gold": (240, 180, 56),
    "brown": (122, 72, 40),
    "red": (214, 60, 60),
}


def pix64(c):
    return pix_n(
        c,
        64,
        [(10, 38, 58), (16, 66, 80), (28, 104, 106), (58, 146, 118), (126, 188, 128)],
        [(255, 214, 120), (255, 248, 214)],
        LV,
    )


# --- Palier 4 : dessin anime ---------------------------------------------------


def flat_layers(c, im, pal, shade=True):
    paste(im, pal["slash"], c.mask("slash"))
    paste(im, pal["light"], c.mask("blade_l"))
    paste(im, pal["dark"] if shade else pal["light"], c.mask("blade_d"))
    paste(im, pal["gold"], c.mask("guard"))
    paste(im, pal["brown"], c.mask("grip"))
    paste(im, pal["red"], c.mask("pommel"))


def outlined(c, im, w, color=(16, 14, 20)):
    lines = Image.new("L", (c.W, c.H), 0)
    d = ImageDraw.Draw(lines)
    for pts in c.lines():
        d.line(pts, fill=255, width=w, joint="curve")
    paste(im, color, lines)


PAL = {
    "slash": (255, 244, 200),
    "light": (232, 238, 246),
    "dark": (142, 160, 190),
    "gold": (244, 186, 60),
    "brown": (132, 78, 44),
    "red": (214, 56, 56),
}


def speed_lines(c, im, col):
    d = ImageDraw.Draw(im)
    cx, cy = c.p(0.6, 0.35)
    R = (c.W + c.H)
    r = random.Random(11)
    for k in range(52):
        a = k / 52 * 2 * math.pi + r.uniform(-0.03, 0.03)
        w = r.uniform(0.015, 0.05)
        i = c.M * r.uniform(0.34, 0.5)
        d.polygon(
            [
                (cx + i * math.cos(a), cy + i * math.sin(a)),
                (cx + R * math.cos(a - w), cy + R * math.sin(a - w)),
                (cx + R * math.cos(a + w), cy + R * math.sin(a + w)),
            ],
            fill=col,
        )


def cel(c):
    im = vgrad(c.W, c.H, (150, 40, 70), (250, 130, 50))
    speed_lines(c, im, (255, 200, 110))
    paste(im, (255, 255, 240), dilate(c.mask("slash"), c.M * 0.006))
    flat_layers(c, im, PAL)
    # ombre dure sur la garde et reflet dur sur la lame
    a = c.along
    hl = Image.new("L", (c.W, c.H), 0)
    ImageDraw.Draw(hl).polygon(
        [c.p(*a(0.28, -0.04)), c.p(*a(0.48, -0.04)), c.p(*a(0.48, -0.015)), c.p(*a(0.28, -0.015))], fill=255
    )
    paste(im, (255, 255, 255), hl)
    outlined(c, im, max(8, c.M // 90))
    return im


# --- Palier 5 : peinture numerique ---------------------------------------------


def smooth(c):
    im = vgrad(c.W, c.H, (28, 12, 44), (150, 44, 44))
    glow = fill(c.W, c.H, (0, 0, 0))
    paste(glow, (255, 170, 80), c.mask("slash"))
    paste(glow, (255, 220, 170), c.mask("blade_l"))
    glow = glow.filter(ImageFilter.GaussianBlur(c.M * 0.05))
    im = ImageChops.add(im, glow)
    paste(im, (255, 240, 200), c.mask("slash").filter(ImageFilter.GaussianBlur(c.M * 0.004)))
    grad = Image.linear_gradient("L").resize((512, 512)).rotate(45, resample=Image.BILINEAR).crop((106, 106, 406, 406)).resize((c.W, c.H))
    bl = Image.composite(fill(c.W, c.H, (255, 255, 255)), fill(c.W, c.H, (150, 170, 200)), grad)
    bd = Image.composite(fill(c.W, c.H, (140, 160, 200)), fill(c.W, c.H, (46, 54, 90)), grad)
    im.paste(bl, (0, 0), c.mask("blade_l"))
    im.paste(bd, (0, 0), c.mask("blade_d"))
    gd = Image.composite(fill(c.W, c.H, (255, 225, 130)), fill(c.W, c.H, (170, 100, 30)), grad)
    im.paste(gd, (0, 0), c.mask("guard"))
    paste(im, (96, 54, 30), c.mask("grip"))
    im.paste(Image.composite(fill(c.W, c.H, (250, 110, 90)), fill(c.W, c.H, (130, 20, 30)), grad), (0, 0), c.mask("pommel"))
    return im


def painterly(c, src, passes):
    out = src.filter(ImageFilter.GaussianBlur(c.M * 0.02))
    d = ImageDraw.Draw(out)
    f = 6.0 / c.M
    for n, length, width, jit in passes:
        for _ in range(n):
            x, y = c.r.randrange(c.W), c.r.randrange(c.H)
            col = src.getpixel((x, y))
            col = tuple(max(0, min(255, v + c.r.randint(-jit, jit))) for v in col)
            a = math.sin(x * f) + math.cos(y * f * 1.4) + c.r.uniform(-0.3, 0.3)
            x2, y2 = x + length * math.cos(a), y + length * math.sin(a)
            d.line([(x, y), ((x + x2) / 2 + c.r.uniform(-3, 3), (y + y2) / 2 + c.r.uniform(-3, 3)), (x2, y2)], fill=col, width=width, joint="curve")
    return out


def keep_form(c, painted, src, a=170):
    m = c.mask("sword").point(lambda v: a if v else 0).filter(ImageFilter.GaussianBlur(c.M * 0.002))
    painted.paste(src, (0, 0), m)
    return painted


def splash(c):
    M = c.M
    src = smooth(c)
    base = painterly(c, src, [(1500, M * 0.06, int(M * 0.02), 10), (5000, M * 0.03, int(M * 0.009), 6), (3000, M * 0.012, max(2, int(M * 0.004)), 4)])
    base = keep_form(c, base, src, 205)
    # bloom, rayons, etincelles
    bloom = base.point(lambda v: max(0, v - 150) * 3).filter(ImageFilter.GaussianBlur(M * 0.03))
    base = ImageChops.add(base, bloom)
    d = ImageDraw.Draw(base)
    r = random.Random(9)
    for _ in range(170):
        x, y = c.p(r.random(), r.random())
        x += r.uniform(-c.ox, c.ox) if c.ox else 0
        y += r.uniform(-c.oy, c.oy) if c.oy else 0
        s = r.uniform(1, M * 0.006)
        d.ellipse([x - s, y - s, x + s, y + s], fill=(255, r.randint(190, 245), r.randint(120, 200)))
    tip = c.p(*c.Tip)
    s = M * 0.13
    flare = Image.new("L", (c.W, c.H), 0)
    fd = ImageDraw.Draw(flare)
    fd.polygon([(tip[0] - s, tip[1]), (tip[0], tip[1] - s * 0.06), (tip[0] + s, tip[1]), (tip[0], tip[1] + s * 0.06)], fill=255)
    fd.polygon([(tip[0], tip[1] - s), (tip[0] + s * 0.06, tip[1]), (tip[0], tip[1] + s), (tip[0] - s * 0.06, tip[1])], fill=255)
    flare = flare.filter(ImageFilter.GaussianBlur(M * 0.002))
    paste(base, (255, 250, 230), flare)
    return base


REG = {"doodle": doodle, "pix16": pix16, "pix64": pix64, "cel": cel, "splash": splash}
PIXEL = {"pix16", "pix64"}


def render(name, w=1024, h=1024, seed=7):
    return REG[name](Ctx(w, h, seed)).convert("RGB")
