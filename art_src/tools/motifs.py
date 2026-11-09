"""Les motifs de la serie pilote : une carte = une liste ordonnee de formes, chacune avec un role.

Le role 'fx' est l'effet (halo, trainee, flammes) : peint en lueur, hors du contour de l'objet.
Les autres roles portent une couleur ; 'hatch' liste ceux que le griffonnage hachure.
Coordonnees dans un carre unite (y vers le bas), centre dans la fenetre, x peut deborder.
"""
import math


def ellipse(cx, cy, rx, ry, a0=0, a1=360, n=64):
    return [
        (cx + rx * math.cos(math.radians(a0 + (a1 - a0) * k / n)), cy + ry * math.sin(math.radians(a0 + (a1 - a0) * k / n)))
        for k in range(n + 1)
    ]


def circle(cx, cy, r, n=64):
    return ellipse(cx, cy, r, r, 0, 360, n)[:-1]


def rot(pts, ang, cx, cy):
    a = math.radians(ang)
    ca, sa = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca) for x, y in pts]


def rrect(cx, cy, w, h, r, ang=0):
    pts = []
    for (qx, qy, a0) in ((cx + w / 2 - r, cy - h / 2 + r, -90), (cx + w / 2 - r, cy + h / 2 - r, 0), (cx - w / 2 + r, cy + h / 2 - r, 90), (cx - w / 2 + r, cy - h / 2 + r, 180)):
        pts += ellipse(qx, qy, r, r, a0, a0 + 90, 8)
    return rot(pts, ang, cx, cy)


def mirror(pts, axis=0.5):
    return [(2 * axis - x, y) for x, y in pts]


def bez(p0, p1, p2, n=16):
    return [
        ((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0], (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1])
        for t in (k / n for k in range(n + 1))
    ]


def band(p0, p1, p2, w0, w1, n=24):
    """Une trainee qui s'effile le long d'une courbe."""
    c = bez(p0, p1, p2, n)
    left, right = [], []
    for i, (x, y) in enumerate(c):
        a, b = c[max(0, i - 1)], c[min(n, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dy) or 1
        nx, ny = -dy / ln, dx / ln
        w = (w0 + (w1 - w0) * i / n) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1]


def flame(cx, cy, R, ang, tail, lobes=7.0, phase=0.0, n=160):
    """Un feu qui avance vers ang (degres) : la tete est ronde, la queue fait des langues."""
    tdir = math.radians(ang) + math.pi
    pts = []
    for k in range(n):
        th = 2 * math.pi * k / n
        d = (th - tdir + math.pi) % (2 * math.pi) - math.pi
        c = max(0.0, math.cos(d))
        spike = (0.5 + 0.5 * math.cos(lobes * d + phase)) ** 5
        e = tail * c ** 2.6 * (0.22 + 0.78 * spike) + 0.25 * tail * c ** 8
        r = R * (1 + e)
        pts.append((cx + r * math.cos(th), cy + r * math.sin(th)))
    return pts


def plus(cx, cy, s):
    a, b = s / 2, s / 6
    return [(cx - b, cy - a), (cx + b, cy - a), (cx + b, cy - b), (cx + a, cy - b), (cx + a, cy + b), (cx + b, cy + b), (cx + b, cy + a), (cx - b, cy + a), (cx - b, cy + b), (cx - a, cy + b), (cx - a, cy - b), (cx - b, cy - b)]


def heart(cx, cy, s, n=60):
    pts = []
    for k in range(n):
        t = 2 * math.pi * k / n
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x / 17 * s, cy - y / 17 * s))
    return pts


def arrow_arc(cx, cy, R, t, a0, a1, head=0.075):
    """Un arc de cercle termine par une pointe de fleche, dans le sens des angles croissants."""
    n = 28
    outer = [(cx + (R + t / 2) * math.cos(math.radians(a0 + (a1 - a0) * k / n)), cy + (R + t / 2) * math.sin(math.radians(a0 + (a1 - a0) * k / n))) for k in range(n + 1)]
    inner = [(cx + (R - t / 2) * math.cos(math.radians(a0 + (a1 - a0) * k / n)), cy + (R - t / 2) * math.sin(math.radians(a0 + (a1 - a0) * k / n))) for k in range(n + 1)]
    e = math.radians(a1)
    tip = math.radians(a1 + 14)
    pts = outer + [
        (cx + (R + head) * math.cos(e), cy + (R + head) * math.sin(e)),
        (cx + R * math.cos(tip), cy + R * math.sin(tip)),
        (cx + (R - head) * math.cos(e), cy + (R - head) * math.sin(e)),
    ] + inner[::-1]
    return pts


class Motif:
    def __init__(self, key, parts, colors, sprite, spal, flare, hatch=("dark",), extra=(), marks=(), no_line=(), center=(0.5, 0.5)):
        self.key = key
        self.parts = parts
        self.colors = colors
        self.sprite = sprite
        self.spal = spal
        self.flare = flare
        self.hatch = hatch
        self.extra = list(extra)
        self.marks = list(marks)
        self.no_line = no_line
        self.center = center
        widths = {len(r) for r in sprite}
        assert len(widths) == 1, (key, widths)
        for r in sprite:
            for ch in r:
                assert ch == "." or ch in spal, (key, ch)


K = (20, 16, 40)

# 1. Defense ---------------------------------------------------------------------


def _shield_half(s=1.0, cx=0.5, cy=0.47):
    top = [(0.5 + 0.27 * t, 0.15 - 0.035 * math.sin(math.pi * (0.5 + t))) for t in (k / 10 for k in range(11))]
    side = [(0.77, 0.17 + 0.29 * t) for t in (k / 6 for k in range(1, 7))]
    tipc = bez((0.77, 0.46), (0.765, 0.76), (0.5, 0.93), 18)[1:]
    pts = top + side + tipc
    return [(cx + (x - cx) * s, cy + (y - cy) * s) for x, y in pts]


def _half_to_full(h):
    return h + mirror(h)[::-1][1:-1]


rim = _half_to_full(_shield_half())
face_r = _shield_half(0.84)
face_l = mirror(face_r)
DEFENSE = Motif(
    "defend_basic",
    [
        ("fx", ellipse(0.5, 0.6, 0.53, 0.53, 200, 340, 40) + ellipse(0.5, 0.64, 0.47, 0.47, 340, 200, 40)),
        ("accent", rim),
        ("light", face_l),
        ("dark", face_r),
        ("second", [(0.455, 0.22), (0.545, 0.22), (0.545, 0.79), (0.5, 0.83), (0.455, 0.79)]),
        ("second", [(0.30, 0.355), (0.70, 0.355), (0.70, 0.435), (0.30, 0.435)]),
        ("point", circle(0.5, 0.395, 0.065, 32)),
    ],
    {"fx": (130, 225, 250), "accent": (244, 186, 60), "light": (95, 150, 235), "dark": (40, 78, 165), "second": (236, 240, 248), "point": (214, 56, 56)},
    [
        "................",
        "...kkkkkkkkkk...",
        "..kyyyyyyyyyyk..",
        "..kybbbwwdddyk..",
        "..kybbbwwdddyk..",
        "..kywwwrrwwwyk..",
        "..kywwwrrwwwyk..",
        "..kybbbwwdddyk..",
        "..kybbbwwdddyk..",
        "..kybbbwwdddyk..",
        "...kybbwwddyk...",
        "...kyybwwdyyk...",
        "....kyywwyyk....",
        ".....kyyyyk.....",
        "......kkkk......",
        "................",
    ],
    {"k": K, "y": (240, 180, 50), "b": (90, 150, 235), "d": (40, 80, 170), "w": (240, 244, 250), "r": (214, 60, 60)},
    flare=(0.27, 0.15),
)

# 2. Boule de feu ----------------------------------------------------------------

FB = (0.62, 0.6)
FIREBALL = Motif(
    "fireball",
    [
        ("fx", flame(FB[0], FB[1], 0.24, 35, 1.7, 13.0, 0.9)),
        ("dark", flame(FB[0], FB[1], 0.19, 35, 2.1, 13.0, 0.3)),
        ("light", flame(FB[0] + 0.015, FB[1] + 0.01, 0.13, 35, 1.6, 11.0, 1.4)),
        ("point", circle(FB[0] + 0.03, FB[1] + 0.02, 0.065, 32)),
        ("second", circle(0.2, 0.2, 0.02, 12)),
        ("second", circle(0.13, 0.38, 0.015, 12)),
        ("second", circle(0.33, 0.1, 0.014, 12)),
    ],
    {"fx": (255, 150, 50), "dark": (226, 74, 30), "light": (255, 190, 60), "point": (255, 250, 218), "second": (255, 160, 60)},
    [
        "r...............",
        ".r..r...........",
        "..rr.r..r.......",
        "...rrorr.r......",
        "....roorr.r.....",
        "....roooorr.....",
        ".....rooyyoorr..",
        "......royyyyor..",
        ".....rooywwyyor.",
        "......roywwwyor.",
        ".......royyyyor.",
        "........rooyoor.",
        ".........rrorr..",
        "...........rr...",
        "................",
        "................",
    ],
    {"r": (170, 30, 30), "o": (240, 110, 30), "y": (255, 210, 60), "w": (255, 250, 220)},
    flare=(FB[0] + 0.05, FB[1] + 0.04),
    marks=[[(0.08, 0.55), (0.24, 0.62)], [(0.2, 0.75), (0.36, 0.78)], [(0.42, 0.08), (0.5, 0.22)]],
)

# 3. Potion de soin --------------------------------------------------------------


def _flask():
    r, cy = 0.27, 0.62
    a_l = math.degrees(math.atan2(-math.sqrt(r * r - 0.07 ** 2), -0.07))
    a_r = math.degrees(math.atan2(-math.sqrt(r * r - 0.07 ** 2), 0.07))
    arc = ellipse(0.5, cy, r, r, a_l % 360, a_r, 60)
    return [(0.43, 0.25)] + arc + [(0.57, 0.25)]


def _liquid(level=0.53):
    r, cy = 0.245, 0.62
    a = math.degrees(math.asin((level - cy) / r))
    arc = ellipse(0.5, cy, r, r, a, 180 - a, 50)
    x0, x1 = arc[-1][0], arc[0][0]
    wave = [(x0 + (x1 - x0) * k / 20, level + 0.012 * math.sin(k / 20 * 3 * math.pi)) for k in range(1, 20)]
    return arc + wave


POTION = Motif(
    "heal_potion",
    [
        ("fx", plus(0.2, 0.36, 0.11)),
        ("fx", plus(0.82, 0.3, 0.09)),
        ("fx", plus(0.76, 0.84, 0.07)),
        ("light", _flask()),
        ("light", rrect(0.5, 0.235, 0.2, 0.05, 0.015)),
        ("second", rrect(0.5, 0.155, 0.13, 0.12, 0.02)),
        ("dark", _liquid()),
        ("accent", heart(0.5, 0.68, 0.1)),
        ("point", ellipse(0.5, 0.62, 0.21, 0.21, 200, 245, 14) + ellipse(0.5, 0.62, 0.17, 0.17, 245, 200, 14)),
        ("accent", circle(0.62, 0.6, 0.018, 12)),
        ("accent", circle(0.36, 0.66, 0.014, 12)),
    ],
    {"fx": (255, 130, 170), "light": (196, 230, 240), "second": (150, 96, 50), "dark": (215, 45, 85), "accent": (255, 205, 220), "point": (255, 255, 255)},
    [
        "......nnnn......",
        ".....knnnnk.....",
        ".....kkkkkk.....",
        "......kwgk......",
        "......kwgk......",
        ".....kkwgkk.....",
        "....kwgggggk....",
        "...kwgggggggk...",
        "..kwrrrrrrrrrk..",
        "..kwrrppprrrrk..",
        "..krrpppppprrk..",
        "..krrrpppprrrk..",
        "...krrrpprrrk...",
        "....krrrrrrk....",
        ".....kkkkkk.....",
        "................",
    ],
    {"k": K, "n": (150, 96, 50), "g": (190, 225, 235), "w": (255, 255, 255), "r": (210, 40, 80), "p": (255, 190, 210)},
    flare=(0.4, 0.5),
    no_line=("point",),
)

# 4. Metallisation ---------------------------------------------------------------

_cr = [(0.5, 0.31), (0.56, 0.285), (0.6, 0.23), (0.7, 0.21), (0.765, 0.25), (0.735, 0.33), (0.69, 0.39), (0.672, 0.46), (0.685, 0.6), (0.668, 0.74), (0.61, 0.815), (0.5, 0.84)]
METAL = Motif(
    "metallicize",
    [
        ("sym", arrow_arc(0.5, 0.53, 0.44, 0.05, 150, 250)),
        ("sym", arrow_arc(0.5, 0.53, 0.44, 0.05, -30, 70)),
        ("light", mirror(_cr)[::-1] + [(0.5, 0.31)]),
        ("dark", _cr),
        ("accent", [(0.485, 0.31), (0.515, 0.31), (0.515, 0.84), (0.485, 0.84)]),
        ("accent", [(0.44, 0.27), (0.5, 0.315), (0.56, 0.27), (0.565, 0.29), (0.5, 0.34), (0.435, 0.29)]),
    ],
    {"sym": (110, 220, 245), "light": (225, 232, 244), "dark": (125, 140, 172), "accent": (240, 180, 56)},
    [
        "....................",
        ".c....kk......kk....",
        "cc...kssk....kddk...",
        ".c...ksssk..kdddk...",
        ".c...kssssyyddddk...",
        "c.....kssyyyyddk..c.",
        "c.....ksssyydddk..c.",
        "c.....ksssyydddk...c",
        "c.....kkkkyykkkk...c",
        "c.....ksssyydddk...c",
        ".c....ksssyydddk...c",
        ".c....kkkkyykkkk..c.",
        ".......kssyyddk...c.",
        "........kkkkkk...cc.",
        "..................c.",
        "....................",
    ],
    {"k": K, "s": (225, 232, 244), "d": (125, 140, 172), "y": (240, 180, 50), "c": (110, 220, 245)},
    flare=(0.38, 0.27),
    extra=[[(0.325, 0.6), (0.675, 0.6)], [(0.34, 0.71), (0.66, 0.71)]],
)

# 5. Concentration ---------------------------------------------------------------

CONC = Motif(
    "concentration",
    [
        ("fx", band((0.36, 0.42), (0.42, 0.22), (0.6, 0.18), 0.02, 0.09)),
        ("fx", band((0.42, 0.52), (0.62, 0.36), (0.86, 0.32), 0.02, 0.09)),
        ("dark", rrect(0.335, 0.685, 0.27, 0.38, 0.03, -8)),
        ("dark", rrect(0.315, 0.665, 0.27, 0.38, 0.03, -8)),
        ("dark", rrect(0.295, 0.645, 0.27, 0.38, 0.03, -8)),
        ("accent", rot([(0.295, 0.56), (0.35, 0.645), (0.295, 0.73), (0.24, 0.645)], -8, 0.295, 0.645)),
        ("light", rrect(0.6, 0.4, 0.25, 0.35, 0.03, 10)),
        ("accent", rot([(0.6, 0.33), (0.645, 0.4), (0.6, 0.47), (0.555, 0.4)], 10, 0.6, 0.4)),
        ("light", rrect(0.86, 0.45, 0.25, 0.35, 0.03, 24)),
        ("accent", rot([(0.86, 0.38), (0.905, 0.45), (0.86, 0.52), (0.815, 0.45)], 24, 0.86, 0.45)),
    ],
    {"fx": (130, 225, 250), "dark": (58, 88, 170), "light": (244, 236, 214), "accent": (240, 180, 56)},
    [
        "...............c.....",
        "..............kkkkk..",
        "..c......c....kwwwk..",
        ".........kkkkkkwywk..",
        ".........kwwwkkyyyk..",
        "..c......kwywkkwywk..",
        ".........kyyykkwwwk..",
        ".........kwywkkkkkk..",
        ".kkkkk...kwwwk.......",
        ".kbbbkk..kkkkk.......",
        ".kbybkbk.............",
        ".kyyykbk.............",
        ".kbybkbk.............",
        ".kbbbkbk.............",
        ".kkkkkbk.............",
        "..kkkkkk.............",
    ],
    {"k": K, "w": (244, 236, 214), "y": (240, 180, 50), "b": (58, 88, 170), "c": (130, 225, 250)},
    flare=(0.95, 0.3),
)

# 6. Forme demoniaque ------------------------------------------------------------

_face = [(0.5, 0.235), (0.6, 0.245), (0.68, 0.3), (0.715, 0.4), (0.705, 0.53), (0.655, 0.66), (0.585, 0.77), (0.5, 0.815)]
_horn = bez((0.6, 0.27), (0.74, 0.17), (0.9, 0.02), 14) + bez((0.9, 0.02), (0.86, 0.22), (0.695, 0.36), 14)[1:]
_brow = [(0.515, 0.415), (0.665, 0.345), (0.685, 0.385), (0.53, 0.455)]
_eye = [(0.55, 0.47), (0.6, 0.445), (0.655, 0.455), (0.62, 0.5)]
_fang = [(0.535, 0.64), (0.575, 0.64), (0.555, 0.705)]
DEMON = Motif(
    "demon_form",
    [
        ("fx", flame(0.5, 0.58, 0.33, 90, 0.95, 9.0, 0.3)),
        ("accent", _horn),
        ("accent", mirror(_horn)),
        ("light", mirror(_face)[::-1] + [(0.5, 0.235)]),
        ("dark", _face),
        ("second", _brow),
        ("second", mirror(_brow)),
        ("point", _eye),
        ("point", mirror(_eye)),
        ("second", [(0.4, 0.625), (0.6, 0.625), (0.565, 0.725), (0.435, 0.725)]),
        ("fang", _fang),
        ("fang", mirror(_fang)),
    ],
    {"fx": (255, 110, 40), "accent": (236, 220, 180), "light": (200, 52, 52), "dark": (128, 24, 36), "second": (52, 8, 18), "point": (255, 214, 60), "fang": (245, 240, 230)},
    [
        ".h..............h.",
        ".hh............hh.",
        "..hh..........hh..",
        "..hhh.kkkkkk.hhh..",
        "...hhkrrrrdddkhh..",
        "....krrrrrddddk...",
        "....krkkrrdkkdk...",
        "....krryyrdyydk...",
        "....krrrrrddddk...",
        "....krrrrkkdddk...",
        ".....krkkkkkdk....",
        ".....krkwkkwdk....",
        "......krrrddk.....",
        ".......kkkkk......",
        "..................",
        "..................",
    ],
    {"k": K, "h": (236, 220, 180), "r": (200, 52, 52), "d": (128, 24, 36), "y": (255, 214, 60), "w": (245, 240, 230)},
    flare=(0.38, 0.47),
    extra=[[(0.47, 0.585), (0.5, 0.605), (0.53, 0.585)]],
)

PILOT = [DEFENSE, FIREBALL, POTION, METAL, CONC, DEMON]
