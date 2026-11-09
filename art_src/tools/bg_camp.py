"""Fond de l'aire de repos : un campement a la lisiere d'une foret, a l'heure bleue. 320 x 180, palette Apollo.

L'ecran de repos pose une colonne centree par-dessus le fond (icone de lune, titre, trois
options semi-transparentes), soit environ x 133-187 et y 52-128 sur cette grille. Le centre
reste donc calme : une prairie dans la brume. Le feu est juste dessous, sa lueur monte vers
le menu ; le bivouac est a gauche, les souches et le hamac a droite ; les arbres encadrent,
avec leurs lanternes ; au loin, un chateau en ruine sur sa colline, des montagnes, la lune.
"""
import math
import sys

from bg_hall import C, bayer, h01, vnoise
from scene import GH, GW, Scene, export, shade

VPX, VPY, FOC = 160, 70, 160.0
CAMH = 1.7
FIRE = (0.0, 3.1)  # (X, Z) du feu, juste sous le menu
ORDER = ["Ciel", "Lune", "Nuages", "Montagnes", "Château", "Lisière", "Prairie", "Brume", "Dalles", "Feu de camp",
         "Bivouac", "Souches et hamac", "Arbres", "Lanternes", "Premier plan"]

R = {
    "sky": ["10141f", "172038", "253a5e", "3c5e8b", "4f8fba", "819796", "c09473", "de9e41", "e8c170"],
    "cloud": ["253a5e", "3c5e8b", "577277", "819796"],
    "cloud_lit": ["c09473", "d7b594", "e8c170"],
    "moon": ["a8b5b2", "c7cfcc", "e7d5b3", "ebede9"],
    "mountain": ["172038", "253a5e", "3c5e8b", "577277", "819796"],
    "ruin": ["090a14", "10141f", "151d28", "202e37", "394a50"],
    "hill": ["10141f", "151d28", "19332d", "25562e"],
    "far_trees": ["090a14", "10141f", "151d28", "19332d"],
    "grass": ["10141f", "19332d", "25562e", "468232", "75a743"],
    "grass_warm": ["241527", "4d2b32", "7a4841", "ad7757"],
    "mist": ["394a50", "577277", "819796"],
    "stone": ["10141f", "151d28", "202e37", "394a50", "577277"],
    "stone_warm": ["241527", "341c27", "4d2b32", "7a4841", "ad7757", "c09473"],
    "wood": ["241527", "341c27", "4d2b32", "7a4841", "ad7757"],
    "bark": ["090a14", "241527", "341c27", "4d2b32", "7a4841"],
    "leather": ["241527", "341c27", "602c2c", "884b2b", "be772b"],
    "cloth": ["4d2b32", "7a4841", "ad7757", "c09473", "d7b594", "e7d5b3"],
    "canvas": ["394a50", "577277", "819796", "a8b5b2", "c7cfcc"],
    "roll": ["19332d", "25562e", "468232", "75a743"],
    "shield": ["411d31", "752438", "a53030", "cf573c"],
    "iron": ["090a14", "10141f", "202e37", "394a50", "577277"],
    "leaves": ["090a14", "10141f", "19332d", "25562e", "468232"],
    "flame": ["a53030", "cf573c", "be772b", "de9e41", "e8c170", "e7d5b3"],
    "glow": ["be772b", "de9e41", "e8c170", "e7d5b3"],
}
R = {k: [C(h) for h in v] for k, v in R.items()}
FLOWERS = [C(h) for h in ("4f8fba", "73bed3", "a23e8c", "df84a5", "e8c170", "c7cfcc")]


def tone(ramp, v, x, y, dither=True):
    return shade(R[ramp], v, x, y, dither)


def proj(X, Y, Z):
    return VPX + FOC * X / Z, VPY + FOC * Y / Z


def floor_y(Z):
    return VPY + FOC * CAMH / Z


def floor_point(x, y):
    dy = y + 0.5 - VPY
    if dy <= 0:
        return None
    Z = FOC * CAMH / dy
    return (x + 0.5 - VPX) * Z / FOC, Z


def fire_light(X, Y, Z):
    d2 = (X - FIRE[0]) ** 2 + (Y - (CAMH - 0.4)) ** 2 + (Z - FIRE[1]) ** 2
    return 1.25 * math.exp(-d2 / 2.2)


def lit(cool, warm, v, light, x, y, amb=0.5):
    """Une surface a la lumiere du soir, rechauffee par le feu la ou il domine."""
    w = light / (amb + light)
    return shade(warm if w > 0.3 + 0.4 * bayer(x + 1, y + 2) else cool, v * (amb + light), x, y)


# --- Le lointain -------------------------------------------------------------------------------


def sky(S):
    for y in range(GH):
        t = min(1.0, y / (VPY + 4)) ** 1.25
        for x in range(GW):
            glow = max(0.0, 1 - abs(x - 90) / 200) * max(0.0, (y - 35) / 40) * 0.1
            col = tone("sky", t + glow, x, y)
            if y < 40 and h01(x, y, 61) < 0.007 * (1 - y / 40):
                col = C("ebede9") if h01(x, y, 62) < 0.5 else C("a4dddb")
            S.put("Ciel", x, y, col, 1000.0, "ciel")


def moon(S):
    cx, cy, r = 212, 20, 9.0
    for y in range(int(cy - r - 4), int(cy + r + 5)):
        for x in range(int(cx - r - 4), int(cx + r + 5)):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            bite = math.hypot(x + 0.5 - cx - 3.6, y + 0.5 - cy + 2.2)
            if d <= r and bite > r * 0.82:
                S.put("Lune", x, y, tone("moon", 0.9 - 0.4 * d / r, x, y), 900.0, "lune")
            elif r < d <= r + 3.5 and bite > r * 0.8 and (r + 3.5 - d) / 3.5 * 0.55 > bayer(x, y):
                S.put("Lune", x, y, C("577277"), 900.0, "halo")


def clouds(S):
    for y in range(8, 54):
        for x in range(GW):
            d = vnoise(x / 3.2, y * 1.5, 21) * 0.7 + vnoise(x / 1.2, y * 2.8, 22) * 0.3
            band = math.exp(-((y - 22) ** 2) / 90) * 0.6 + math.exp(-((y - 44) ** 2) / 40) * 0.45
            if d * band > 0.3:
                below = vnoise(x / 3.2, (y + 1) * 1.5, 21) * 0.7 + vnoise(x / 1.2, (y + 1) * 2.8, 22) * 0.3
                rim = below * band <= 0.3
                col = tone("cloud_lit", 0.3 + 0.5 * max(0.0, 1 - abs(x - 90) / 180), x, y) if rim else tone("cloud", 0.3 + y / 120, x, y)
                S.put("Nuages", x, y, col, 400.0, "nuage")


def mountains(S):
    peaks = [(30, 50, 34), (78, 44, 40), (128, 52, 30), (170, 47, 38), (236, 43, 44), (296, 51, 30)]
    for x in range(GW):
        top = min(py + abs(x - px) * 16 / w for px, py, w in peaks)
        for y in range(int(top), VPY + 2):
            near = min(peaks, key=lambda p: p[1] + abs(x - p[0]) * 16 / p[2])
            sunlit = x < near[0]
            snow = y - top < 3 and top < 54
            v = 0.85 if snow else (0.42 if sunlit else 0.28) - 0.12 * (y - top) / 25
            S.put("Montagnes", x, y, tone("mountain", v, x, y), 300.0, "mont")


def castle(S):
    """Un chateau en ruine sur sa colline, a gauche du menu."""
    Z = 80.0
    for y in range(GH):
        for x in range(GW):
            hill = (x - 107) ** 2 / 40 ** 2 + (y - 72) ** 2 / 10 ** 2 <= 1 and y >= 62
            if hill:
                S.put("Château", x, y, tone("hill", 0.45 - 0.3 * (y - 62) / 12, x, y), Z + 5, "colline")
    towers = [(90, 95, 50, "t1"), (97, 104, 44, "donjon"), (106, 111, 52, "t2"), (112, 122, 56, "mur"), (120, 124, 51, "t3")]
    for x0, x1, top, name in towers:
        for y in range(top - 2, 64):
            for x in range(x0, x1 + 1):
                if y < top and ((x - x0) % 2 == 1 or name == "mur"):
                    continue  # les creneaux
                broken = name == "t2" and y < top + 3 and x > x0 + 3
                if broken:
                    continue
                window = name in ("donjon", "t1") and (y - top) % 6 == 3 and (x - x0) % 4 == 2
                lit_win = window and name == "donjon" and y < top + 8
                col = C("de9e41") if lit_win else (C("090a14") if window else tone("ruin", 0.55 if x == x0 else 0.35, x, y))
                S.put("Château", x, y, col, Z, name + ("f" if window else ""))


def treeline(S):
    for x in range(GW):
        top = VPY - 6 - 9 * vnoise(x / 6.0, 1.0, 31) - 4 * vnoise(x / 2.0, 2.0, 32)
        if 118 < x < 200:
            top += 4  # la lisiere s'ouvre un peu sur la prairie du centre
        for y in range(int(top), VPY + 4):
            S.put("Lisière", x, y, tone("far_trees", 0.55 - 0.35 * (y - top) / 14, x, y), 40.0, "lisiere")


def meadow(S):
    for y in range(VPY, GH):
        for x in range(GW):
            X, Z = floor_point(x, y)
            light = fire_light(X, CAMH, Z)
            blade = vnoise(X * 6, Z * 1.5, 41)
            v = 0.32 + 0.25 * blade - 0.1 * min(1.0, Z / 25)
            col = lit(R["grass"], R["grass_warm"], v, light * 0.6, x, y)
            k = h01(int(X * 7), int(Z * 4), 42)
            if 4.5 < Z < 22 and k < 0.012 * (1.2 - Z / 22):
                col = FLOWERS[int(h01(int(X * 7), int(Z * 4), 43) * len(FLOWERS))]
            S.put("Prairie", x, y, col, Z, "prairie")


def mist(S):
    for y in range(VPY - 10, VPY + 16):
        for x in range(GW):
            dens = math.exp(-((y - (VPY + 1)) ** 2) / 22) * (0.2 + 0.45 * vnoise(x / 9.0, y / 3.0, 51))
            if dens > bayer(x, y) * 0.9 + 0.12:
                S.put("Brume", x, y, tone("mist", 0.1 + 0.4 * dens, x, y), 30.0, "brume")


# --- Le campement --------------------------------------------------------------------------------


def flagstones(S):
    for y in range(VPY, GH):
        for x in range(GW):
            X, Z = floor_point(x, y)
            edge = 1 + 0.25 * (vnoise(X * 1.5, Z * 1.5, 61) - 0.5)
            if (X / 2.9) ** 2 + ((Z - 3.8) / 2.0) ** 2 > edge or Z < 2.0:
                continue
            row = math.floor(Z / 0.42)
            Xs = X + (0.27 if row % 2 else 0)
            col = math.floor(Xs / 0.55)
            fx, fz = Xs - col * 0.55, Z - row * 0.42
            joint = min(fx, 0.55 - fx) < 0.04 or min(fz, 0.42 - fz) < 0.035
            missing = h01(col, row, 63) < 0.07
            if missing:
                continue  # une dalle manque : l'herbe passe au travers
            v = 0.22 if joint else 0.5 + 0.2 * (h01(col, row, 64) - 0.5)
            S.put("Dalles", x, y, lit(R["stone"], R["stone_warm"], v, fire_light(X, CAMH, Z), x, y), Z, "joint" if joint else f"d{col}.{row}")


def campfire(S):
    fx, fz = FIRE
    base = floor_y(fz)
    s = FOC / fz  # pixels par metre a la distance du feu
    for k in range(11):  # le cercle de pierres
        a = k / 11 * 2 * math.pi
        X, Z = fx + 0.5 * math.cos(a), fz + 0.5 * math.sin(a)
        u, v = proj(X, CAMH, Z)
        rx, ry = 0.13 * FOC / Z, 0.09 * FOC / Z
        front = math.sin(a) < 0
        S.fill("Feu de camp", lambda d, u=u, v=v, rx=rx, ry=ry: d.ellipse([u - rx, v - ry * 1.6, u + rx, v + ry * 0.4], fill=255),
               Z, f"pierre{k}", lambda x, y, front=front, v=v: tone("stone_warm", 0.75 if y < v - 1 else (0.5 if front else 0.4), x, y))
    for sign in (-1, 1):  # les buches croisees
        S.fill("Feu de camp", lambda d, sign=sign: d.line([(VPX - 0.38 * s, base - 0.02 * s + sign * 4), (VPX + 0.38 * s, base - 0.08 * s - sign * 4)], fill=255, width=max(2, int(0.1 * s))),
               fz, f"buche{sign}", lambda x, y: tone("wood", 0.45 if (x + y) % 5 else 0.25, x, y))
    height = 0.38 * s
    for layer_i, (w, hgt, v) in enumerate(((0.36, 1.0, 0.25), (0.26, 0.82, 0.55), (0.15, 0.6, 0.85))):
        def draw(d, w=w, hgt=hgt):
            pts = []
            for i in range(25):
                t = i / 24
                ang = math.pi * t
                r = w * s * math.sin(ang) ** 0.8
                lick = 1 + 0.25 * math.sin(t * 19 + layer_i)
                pts.append((VPX - r * math.cos(ang) * 1.0, base - 3 - height * hgt * math.sin(ang) ** 6 * lick - 4 * math.sin(ang)))
            pts += [(VPX + w * s, base - 3), (VPX - w * s, base - 3)]
            d.polygon(pts, fill=255)
        S.fill("Feu de camp", draw, fz - 0.01 * layer_i, f"flamme{layer_i}", lambda x, y, v=v: tone("flame", v + 0.12 * (1 - (base - y) / height), x, y, False))
    for k in range(9):  # les etincelles
        px = int(VPX + (h01(k, 71) - 0.5) * 0.7 * s)
        py = int(base - height - 2 - h01(k, 72) * 14)
        S.put("Feu de camp", px, py, C("e8c170") if k % 2 else C("de9e41"), fz, "etincelle")


def prop_box(S, layer, X0, X1, Z, h, ramp, oid, detail=None, Y0=0.0):
    """Une boite vue de face, posee sur le sol ou sur une autre (Y0 : hauteur de sa base)."""
    u0, v1 = proj(X0, CAMH - Y0, Z)
    u1, v0 = proj(X1, CAMH - Y0 - h, Z)
    light = fire_light((X0 + X1) / 2, CAMH - Y0 - h / 2, Z)

    def color(x, y):
        edge = x < u0 + 1.5 or x > u1 - 1.5 or y < v0 + 1.5 or y > v1 - 1.5
        val = 0.3 if edge else 0.5 + 0.08 * h01(int((x - u0) / 3), 3)
        if detail and detail(x - u0, y - v0, u1 - u0, v1 - v0):
            val = 0.25
        return shade(R[ramp], val * (0.5 + light), x, y)
    S.fill(layer, lambda d: d.rectangle([u0, v0, u1, v1], fill=255), Z, oid, color)
    return u0, v0, u1, v1


def bivouac(S):
    # les caisses, au fond du bivouac
    brace = lambda dx, dy, w, h: abs(dy / h - dx / w) < 0.09 or abs(dy / h - (1 - dx / w)) < 0.09
    prop_box(S, "Bivouac", -2.55, -1.95, 5.4, 0.58, "wood", "caisse1", brace)
    prop_box(S, "Bivouac", -1.92, -1.32, 5.4, 0.58, "wood", "caisse2", brace)
    prop_box(S, "Bivouac", -2.25, -1.65, 5.45, 0.55, "wood", "caisse3", brace, Y0=0.58)
    # le bouclier, appuye contre les caisses
    u, v = proj(-1.35, CAMH - 0.38, 5.2)
    rx, ry = 0.3 * FOC / 5.2, 0.38 * FOC / 5.2
    light = fire_light(-1.35, CAMH - 0.38, 5.2)
    S.fill("Bivouac", lambda d: d.ellipse([u - rx, v - ry, u + rx, v + ry], fill=255), 5.1, "bouclier",
           lambda x, y: tone("iron", 0.55, x, y) if math.hypot((x - u) / rx, (y - v) / ry) > 0.8
           else (tone("glow", 0.3, x, y, False) if math.hypot(x - u, y - v) < 2 else tone("shield", (0.45 + 0.1 * (x < u)) * (0.6 + light), x, y)))
    # la natte et la couverture roulee
    corners = [proj(-2.0, CAMH, 3.4), proj(-0.95, CAMH, 3.4), proj(-0.95, CAMH, 4.4), proj(-2.0, CAMH, 4.4)]
    S.fill("Bivouac", lambda d: d.polygon(corners, fill=255), 3.9, "natte",
           lambda x, y: tone("wood", (0.55 if (y // 2) % 2 else 0.45) * (0.6 + fire_light(-1.5, CAMH, 3.9)), x, y))
    u0, v0 = proj(-2.05, CAMH - 0.24, 4.45)
    u1, v1 = proj(-0.9, CAMH, 4.45)
    S.fill("Bivouac", lambda d: d.rounded_rectangle([u0, v0, u1, v1], radius=(v1 - v0) / 2, fill=255), 4.4, "couverture",
           lambda x, y: tone("cloth", 0.75 - 0.35 * (y - v0) / max(1, v1 - v0), x, y))
    # le sac a dos et son couchage roule
    u0, v0, u1, v1 = prop_box(S, "Bivouac", -2.95, -2.45, 4.1, 0.62, "leather", "sac",
                              lambda dx, dy, w, h: abs(dx - w * 0.3) < 0.8 or abs(dx - w * 0.7) < 0.8 or abs(dy - h * 0.35) < 0.8)
    S.fill("Bivouac", lambda d: d.rounded_rectangle([u0 - 1, v0 - 6, u1 + 1, v0], radius=3, fill=255), 4.05, "couchage",
           lambda x, y: tone("roll", 0.55 if y < v0 - 3 else 0.35, x, y))


def stumps_and_hammock(S):
    for X, Z, r, h, k in ((1.45, 3.35, 0.3, 0.42, 1), (2.6, 5.0, 0.26, 0.36, 2)):
        u, top = proj(X, CAMH - h, Z)
        _, bottom = proj(X, CAMH, Z)
        rx = r * FOC / Z
        ry = rx * 0.32
        light = fire_light(X, CAMH - h / 2, Z)
        S.fill("Souches et hamac", lambda d, u=u, top=top, bottom=bottom, rx=rx, ry=ry: (d.rectangle([u - rx, top, u + rx, bottom], fill=255), d.ellipse([u - rx, bottom - ry, u + rx, bottom + ry], fill=255),
               d.polygon([(u - rx - 3, bottom + 1), (u - rx, bottom - 4), (u - rx + 2, bottom + 1)], fill=255), d.polygon([(u + rx + 3, bottom + 1), (u + rx, bottom - 4), (u + rx - 2, bottom + 1)], fill=255)),
               Z, f"souche{k}", lambda x, y, u=u, rx=rx, light=light: tone("bark", (0.55 - 0.25 * abs(x - u) / max(1, rx) + (0.1 if (x // 2) % 2 else 0)) * (0.55 + light), x, y))
        S.fill("Souches et hamac", lambda d, u=u, top=top, rx=rx, ry=ry: d.ellipse([u - rx, top - ry, u + rx, top + ry], fill=255),
               Z - 0.01, f"souche{k}_dessus", lambda x, y, u=u, top=top, rx=rx, ry=ry: tone("wood", 0.7 if (int(math.hypot((x - u) / rx, (y - top) / max(1, ry)) * 4) % 2) else 0.55, x, y))
    # les deux poteaux du hamac et la toile
    posts = [(3.1, 6.6), (4.7, 5.0)]
    ends = []
    for X, Z in posts:
        u, top = proj(X, CAMH - 1.5, Z)
        _, bottom = proj(X, CAMH, Z)
        w = 0.11 * FOC / Z
        S.fill("Souches et hamac", lambda d, u=u, top=top, bottom=bottom, w=w: d.polygon([(u - w, bottom), (u - w * 0.8, top), (u, top - 3), (u + w * 0.8, top), (u + w, bottom)], fill=255),
               Z, f"poteau{X}", lambda x, y, u=u: tone("bark", 0.5 if x < u else 0.3, x, y))
        _, rope = proj(X, CAMH - 1.15, Z)
        S.fill("Souches et hamac", lambda d, u=u, rope=rope, w=w: d.rectangle([u - w, rope - 1, u + w, rope + 1], fill=255), Z - 0.02, f"corde{X}",
               lambda x, y: C("ad7757") if (x + y) % 2 else C("7a4841"))
        ends.append((u, rope))
    (ua, va), (ub, vb) = ends
    pts_top, pts_bot = [], []
    for i in range(21):
        t = i / 20
        sag = 11 * math.sin(math.pi * t)
        x = ua + (ub - ua) * t
        y = va + (vb - va) * t + sag
        pts_top.append((x, y))
        pts_bot.append((x, y + 2 + 3 * math.sin(math.pi * t)))
    S.fill("Souches et hamac", lambda d: d.polygon(pts_top + pts_bot[::-1], fill=255), 5.8, "hamac",
           lambda x, y: tone("canvas", 0.65 - 0.2 * ((x - ua) / max(1, ub - ua)) + (0.1 if x % 4 == 0 else 0), x, y))


def trees(S):
    # un sapin au bord gauche, un grand feuillu derriere lui, deux arbres a droite
    for x in range(0, 46):
        for y in range(GH):
            tier = (y - 6) % 26
            width = (y - 6) * 0.22 + tier * 0.55 if y > 6 else 0
            if abs(x - 15) <= width * 0.55 and y < 160:
                S.put("Arbres", x, y, tone("leaves", 0.45 - 0.2 * (tier / 26) + 0.1 * vnoise(x / 2, y / 2, 81), x, y), 3.0, "sapin")
            elif 12 <= x <= 18 and y >= 150:
                S.put("Arbres", x, y, tone("bark", 0.4, x, y), 3.0, "sapin_tronc")
    trunks = [(30, 42, 3.8, "chene"), (286, 302, 3.4, "arbre_droit")]
    for x0, x1, Z, name in trunks:
        light = 0.4
        for y in range(GH):
            flare = max(0.0, (y - (floor_y(Z) - 18)) / 18) * 6
            for x in range(int(x0 - flare), int(x1 + flare) + 1):
                if y > floor_y(Z) + 2:
                    continue
                rel = (x - x0) / max(1, x1 - x0)
                ridge = 0.1 if (x - x0 + int(4 * vnoise(x / 3, y / 9, 86))) % 4 == 0 else 0
                S.put("Arbres", x, y, tone("bark", (0.3 + 0.3 * math.sin(math.pi * min(1.0, max(0.0, rel))) - ridge + 0.06 * vnoise(x / 2, y / 6, 82)) * (0.6 + light * (y > 110)), x, y), Z, name)
    # la ramure : des masses de feuilles qui encadrent le haut sans couvrir la lune
    for y in range(0, 62):
        for x in range(GW):
            left = 1 - x / 150 - y / 70 + 0.35 * (vnoise(x / 7, y / 6, 83) - 0.5)
            right = (x - 238) / 90 - y / 55 + 0.35 * (vnoise(x / 7, y / 6, 84) - 0.5)
            if left > 0.12 or right > 0.12:
                v = 0.3 + 0.35 * vnoise(x / 3, y / 3, 85) - 0.15 * (y / 62)
                S.put("Arbres", x, y, tone("leaves", v, x, y), 3.5, "ramure")
    for x0, y0, x1, y1 in ((38, 34, 80, 26), (232, 26, 300, 34)):  # deux branches qui portent les lanternes
        S.fill("Arbres", lambda d, a=(x0, y0, x1, y1): d.line([(a[0], a[1]), (a[2], a[3])], fill=255, width=3), 3.5, "branche",
               lambda x, y: tone("bark", 0.4, x, y))


def lanterns(S):
    for hx, hy, ly in ((66, 30, 44), (248, 29, 44)):
        for y in range(hy, ly - 3):
            S.put("Lanternes", hx, y, C("7a4841") if y % 2 else C("4d2b32"), 3.5, "corde")
        for y in range(ly - 4, ly + 5):
            for x in range(hx - 3, hx + 4):
                frame = x in (hx - 3, hx + 3) or y in (ly - 4, ly + 4) or y == ly - 3 and abs(x - hx) > 1
                S.put("Lanternes", x, y, tone("iron", 0.45, x, y) if frame else tone("glow", 0.65 + 0.3 * (abs(x - hx) < 2), x, y, False), 3.5, "lanterne" + ("c" if frame else ""))
        for y in range(ly - 12, ly + 13):
            for x in range(hx - 12, hx + 13):
                d = math.hypot(x - hx, y - ly)
                if 5.5 < d < 12 and (1 - d / 12) * 0.5 > bayer(x, y) and not (x == hx and y < ly):
                    S.put("Lanternes", x, y, C("de9e41") if d < 8 else C("be772b"), 3.5, "halo")


def foreground(S):
    for y in range(140, GH):
        for x in range(GW):
            for cx, side in ((0, 1), (GW, -1)):
                reach = 78 - (GH - y) * 1.3 + 22 * (vnoise(x / 5, y / 4, 91 + (side > 0)) - 0.5)
                if (x - cx) * side < reach and (x - cx) * side >= 0:
                    fern = vnoise(x / 2.2, y / 3.5, 93)
                    autumn = h01(x // 4, y // 4, 94) < 0.05
                    col = tone("bark", 0.6, x, y) if autumn else tone("leaves", 0.2 + 0.45 * fern, x, y)
                    S.put("Premier plan", x, y, col, 2.0, "fougere")


def render():
    S = Scene(ORDER)
    sky(S)
    moon(S)
    clouds(S)
    mountains(S)
    castle(S)
    treeline(S)
    meadow(S)
    mist(S)
    flagstones(S)
    campfire(S)
    bivouac(S)
    stumps_and_hammock(S)
    trees(S)
    lanterns(S)
    foreground(S)
    return S


def shape(n, oid):
    """Les dalles et la prairie laissent leurs joints au generateur ; le reste garde ses objets."""
    if n == "Dalles":
        return "dalle"
    return oid.rstrip("f")


if __name__ == "__main__":
    export(render(), "camp", sys.argv[1], surfaces=("Ciel",), shape=shape, skip=("Ciel", "Nuages", "Brume", "Lune"), depth_range=(2.0, 1000.0))
