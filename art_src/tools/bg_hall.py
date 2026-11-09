"""Fond de combat : la salle de la herse, 320 x 180, palette Apollo, en calques.

La salle est calculee en vraie perspective : chaque pixel lance un rayon depuis la camera
et touche le sol, un mur, la voute ou le mur du fond. Les textures (dalles, briques,
piliers) vivent dans les coordonnees du monde, donc la perspective est juste partout.
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFilter

from aseprite_io import build, check_independent, work, write_manifest

HEX = "172038 253a5e 3c5e8b 4f8fba 73bed3 a4dddb 19332d 25562e 468232 75a743 a8ca58 d0da91 4d2b32 7a4841 ad7757 c09473 d7b594 e7d5b3 341c27 602c2c 884b2b be772b de9e41 e8c170 241527 411d31 752438 a53030 cf573c da863e 1e1d39 402751 7a367b a23e8c c65197 df84a5 090a14 10141f 151d28 202e37 394a50 577277 819796 a8b5b2 c7cfcc ebede9".split()
C = lambda h: tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
APOLLO = [C(h) for h in HEX]

GW, GH = 320, 180
VPX, VPY, FOC = 160, 52, 160.0
FLOOR, HW, SPRING, VR, ZFAR = 1.125, 3.0, -1.5, 1.6, 10.0
PILLARS = [2.2, 3.9, 5.6, 7.3, 9.0]
TORCHES = [3.9, 7.3]
BANNERS = [3.05, 6.45]
RUNE = (0.0, 4.5)  # centre du cercle (X, Z), sous le heros
SURFACES = ("Fond lointain", "Voûte", "Murs", "Sol")  # rien n'est dessine derriere elles

RAMPS = {
    "cool": ["090a14", "10141f", "151d28", "202e37", "394a50", "577277", "819796", "a8b5b2"],
    "warm": ["10141f", "241527", "341c27", "4d2b32", "7a4841", "ad7757", "c09473", "d7b594"],
    "cyan": ["10141f", "172038", "253a5e", "3c5e8b", "4f8fba", "73bed3", "a4dddb"],
    "red": ["241527", "411d31", "752438", "a53030", "cf573c", "da863e"],
    "moss": ["10141f", "19332d", "25562e", "468232"],
    "gold": ["341c27", "884b2b", "be772b", "de9e41", "e8c170"],
    "void": ["090a14", "10141f", "1e1d39", "402751", "7a367b"],
}
RAMPS = {k: [C(h) for h in v] for k, v in RAMPS.items()}
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def bayer(x, y):
    return (BAYER[y % 4][x % 4] + 0.5) / 16


def h01(*k):
    """Hasard deterministe dans [0, 1) pour des coordonnees entieres."""
    v = 2166136261
    for n in k:
        v = ((v ^ (n & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
    v ^= v >> 13
    v = (v * 1274126177) & 0xFFFFFFFF
    return (v ^ (v >> 16)) / 2**32


def vnoise(x, y, s):
    """Bruit de valeur lisse, echelle s (en metres)."""
    x, y = x / s, y / s
    i, j = math.floor(x), math.floor(y)
    fx, fy = x - i, y - j
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b, c, d = h01(i, j, 5), h01(i + 1, j, 5), h01(i, j + 1, 5), h01(i + 1, j + 1, 5)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


# --- Le rayon --------------------------------------------------------------------------


def cast(u, v):
    dx, dy = u + 0.5 - VPX, v + 0.5 - VPY
    hits = [(ZFAR, "far")]
    if dy > 0:
        hits.append((FOC * FLOOR / dy, "floor"))
    side = None
    if dx != 0:
        zw = FOC * HW / abs(dx)
        if dy * zw / FOC >= SPRING:
            side = (zw, "wall")
    if side is None and dy < 0:
        a, b, c = dx / (FOC * HW), dy / (FOC * VR), -SPRING / VR
        A = a * a + b * b
        z = (-b * c + math.sqrt(b * b * c * c - A * (c * c - 1))) / A
        side = (z, "vault")
    if side:
        hits.append(side)
    z, surf = min(hits)
    return surf, (dx * z / FOC, dy * z / FOC, z)


def project(X, Y, Z):
    return VPX + FOC * X / Z, VPY + FOC * Y / Z


# --- Les materiaux : (calque, rampe, valeur de base, emissif) --------------------------


def near(z, centres, half):
    return any(abs(z - c) <= half for c in centres)


def bricks(a, b, la, lb, mort, seed):
    row = math.floor(b / lb)
    a2 = a + (la / 2 if row % 2 else 0)
    col = math.floor(a2 / la)
    fa, fb = a2 - col * la, b - row * lb
    if min(fa, la - fa) < mort or min(fb, lb - fb) < mort * 0.8:
        return None
    return h01(col, row, seed)


def floor_mat(X, Z):
    r = math.hypot(X - RUNE[0], Z - RUNE[1])
    ang = math.atan2(Z - RUNE[1], X - RUNE[0])
    tick = (ang / (2 * math.pi) * 16) % 1
    rune = 1.02 <= r <= 1.12 or 0.70 <= r <= 0.76 or (0.78 <= r <= 1.0 and tick < 0.07)
    k = bricks(X + 7, Z, 0.55, 0.5, 0.035, 11)
    base = 0.2 if k is None else 0.5 + (k - 0.5) * 0.22
    if k is not None and h01(int(X * 9), int(Z * 9), 3) < 0.012:
        base = 0.28
    return base, rune


def wall_mat(X, Y, Z, banners=True, pillars=True):
    for zc in BANNERS if banners else ():
        top, w = -1.35, 0.33
        bottom = 0.35 - 0.12 * abs(math.sin((Z - zc) * 22))
        if abs(Z - zc) <= w and top <= Y <= bottom:
            rel = (Z - zc) / w
            emblem = (Y + 0.75) ** 2 + (rel * 0.33) ** 2 < 0.03 or (abs(rel) < 0.12 and -1.05 < Y < -0.2)
            edge = abs(rel) > 0.82 or Y < top + 0.08
            return ("Bannières", "gold" if emblem else "red", 0.9 if emblem else (0.45 if edge else 0.62))
    for zp in PILLARS if pillars else ():
        if abs(Z - zp) <= 0.2:
            shade = 0.38 if Z < zp - 0.14 else (0.8 if Z > zp + 0.12 else 0.66)
            band = bricks(Z, Y, 2.0, 0.42, 0.03, 21)
            return ("Piliers", "cool", shade if band is not None else shade * 0.6)
    if Y > 0.85:  # plinthe
        return ("Murs", "cool", 0.36)
    k = bricks(Z, Y + 4, 0.6, 0.3, 0.035, 31)
    return ("Murs", "cool", 0.2 if k is None else 0.48 + (k - 0.5) * 0.2)


def vault_mat(X, Y, Z):
    if near(Z, PILLARS, 0.16):
        return 0.72
    th = math.atan2(-(Y - SPRING) / VR, X / HW)
    k = bricks(Z, th * 2.4, 0.6, 0.28, 0.03, 41)
    return 0.16 if k is None else 0.4 + (k - 0.5) * 0.16


GATE_R, GATE_C = 1.1, -0.2


def far_mat(X, Y):
    inside = abs(X) <= GATE_R and (Y >= GATE_C or X * X + (Y - GATE_C) ** 2 <= GATE_R**2)
    if inside:
        bar = (abs(((X + 1.1) % 0.24) - 0.12) < 0.03 or min(abs(Y - y) for y in (-0.95, -0.3, 0.3)) < 0.03) and Y < 0.55 - 0.08 * (((X + 1.1) % 0.24) / 0.24)
        return ("Fond lointain", "void", 0.25 + 0.45 * max(0, (Y + 1.3) / 2.4)), bar
    rr = math.hypot(X, Y - GATE_C)
    if GATE_R < rr < GATE_R + 0.32 and Y < GATE_C + 0.05:
        seg = math.floor(math.atan2(Y - GATE_C, X) / math.pi * 9)
        frac = (math.atan2(Y - GATE_C, X) / math.pi * 9) % 1
        return ("Fond lointain", "cool", 0.18 if frac < 0.1 or rr > GATE_R + 0.29 else 0.62 + 0.1 * h01(seg, 7)), False
    k = bricks(X + 9, Y + 4, 0.7, 0.35, 0.035, 51)
    return ("Fond lointain", "cool", 0.18 if k is None else 0.46 + (k - 0.5) * 0.18), False


def normal(surf, X, Y):
    if surf == "floor":
        return (0, -1, 0)
    if surf == "wall":
        return (-1 if X > 0 else 1, 0, 0)
    if surf == "far":
        return (0, 0, -1)
    nx, ny = X / HW**2, (Y - SPRING) / VR**2
    n = math.hypot(nx, ny)
    return (-nx / n, -ny / n, 0)


def lights(surf, P):
    X, Y, Z = P
    n = normal(surf, X, Y)
    warm = 0.0
    for zt in TORCHES:
        for sx in (-1, 1):
            T = (sx * (HW - 0.12), -0.35, zt)
            d = (T[0] - X, T[1] - Y, T[2] - Z)
            d2 = d[0] ** 2 + d[1] ** 2 + d[2] ** 2
            ln = math.sqrt(d2) or 1
            facing = max(0.3, (n[0] * d[0] + n[1] * d[1] + n[2] * d[2]) / ln)
            warm += 1.45 * math.exp(-d2 / 3.4) * facing
    cyan = 0.0
    if surf == "floor":
        r = math.hypot(X - RUNE[0], Z - RUNE[1])
        cyan = 0.75 * math.exp(-((r - 0.95) ** 2) / 0.12) + (0.18 if r < 0.95 else 0)
    amb = 0.56 if surf != "vault" else 0.5
    return amb, warm, cyan


FLAT = {"red", "gold", "moss"}  # les tissus et la mousse en aplats, sans trame


def shade(ramp, value, x, y):
    R = RAMPS[ramp]
    t = max(0.0, min(0.999, value)) * (len(R) - 1)
    i = int(t) + (1 if t - int(t) > (0.5 if ramp in FLAT else bayer(x, y)) else 0)
    return R[min(len(R) - 1, i)]


def pick(ramp, mat, amb, warm, cyan, x, y, lit):
    if not lit:
        return shade(ramp, mat * amb, x, y)
    tot = amb + warm + cyan
    v = mat * tot
    if ramp == "cool":
        b = bayer(x + 2, y + 1)
        if warm / tot > 0.3 + 0.35 * b:
            ramp = "warm"
        elif cyan / tot > 0.3 + 0.35 * b:
            ramp = "cyan"
    return shade(ramp, v, x, y)


# --- Les sprites poses a la main -------------------------------------------------------

FLAME = [
    "...r...",
    "..ror..",
    "..oyo..",
    ".royor.",
    ".oyYyo.",
    ".oYYYo.",
    ".oyYyo.",
    "..oyo..",
    ".kiiik.",
    "..kik..",
    "...k...",
]
FLAME_S = [
    "..r..",
    ".ror.",
    ".oyo.",
    "oyYyo",
    ".oYo.",
    ".kik.",
    "..k..",
]
SPAL = {"r": C("cf573c"), "o": C("be772b"), "y": C("de9e41"), "Y": C("e8c170"), "k": C("151d28"), "i": C("394a50")}


def stack_at(surf, P):
    """Les objets poses sur ce point, du bas vers le haut : [(calque, rampe, valeur)]."""
    X, Y, Z = P
    stack = []
    if surf == "floor":
        base, rune = floor_mat(X, Z)
        stack.append(("Sol", "cool", base))
        if abs(X) > 2.2 and vnoise(X, Z, 0.35) > 0.7 - 0.08 * (abs(X) - 2.2):
            stack.append(("Mousse", "moss", 0.5))
        if rune:
            stack.append(("Cercle runique", "cyan", 0.95))
    elif surf == "wall":
        lay, ramp, val = wall_mat(X, Y, Z)
        if lay != "Murs":  # sous une banniere ou un pilier, le mur continue
            stack.append(wall_mat(X, Y, Z, banners=False, pillars=False))
        stack.append((lay, ramp, val))
        if lay in ("Murs", "Piliers") and Y > 0.4 and vnoise(Z, Y, 0.3) > 0.66 + 0.25 * (1.1 - Y):
            stack.append(("Mousse", "moss", 0.45))
    elif surf == "vault":
        stack.append(("Voûte", "cool", vault_mat(X, Y, Z)))
    else:
        (lay, ramp, val), bar = far_mat(X, Y)
        stack.append((lay, ramp, val))
        if bar:
            stack.append(("Herse", "cool", 0.7))
    return stack


def render(out_png_dir):
    layers = {}
    # Un calque = un objet complet, eclaire dans sa propre couleur : le masquer le fait
    # disparaitre en entier et laisse voir, dessous, la surface complete.
    order = ["Fond lointain", "Herse", "Voûte", "Murs", "Piliers", "Sol", "Mousse", "Cercle runique", "Bannières",
             "Chaînes", "Torches", "Ombre des bords"]
    for n in order:
        layers[n] = Image.new("RGBA", (GW, GH), (0, 0, 0, 0))
    px = {n: im.load() for n, im in layers.items()}
    for y in range(GH):
        for x in range(GW):
            surf, P = cast(x, y)
            X, Y, Z = P
            amb, warm, cyan = lights(surf, P)
            stack = stack_at(surf, P)
            glow = None  # la lueur des runes sur les dalles appartient au calque du cercle
            if surf == "floor" and math.hypot(X - RUNE[0], Z - RUNE[1]) <= 1.6:
                glow, cyan = cyan, 0.0
            for lay, ramp, val in stack:
                # les runes et le vide sous la herse ont leur propre lumiere
                emissive = ramp in ("cyan", "void")
                col = shade(ramp, val, x, y) if emissive else pick(ramp, val, amb, warm, cyan, x, y, True)
                px[lay][x, y] = col + (255,)
            top_lay, ramp, val = stack[-1]
            if glow and top_lay == "Sol":
                bathed = pick(ramp, val, amb, warm, glow, x, y, True)
                if bathed != px["Sol"][x, y][:3]:
                    px["Cercle runique"][x, y] = bathed + (255,)
            # ombre des bords : le haut et les coins s'enfoncent dans le noir
            e = max(0.0, (9 - y) / 9) * 0.8 + max(0.0, (math.hypot((x - 160) / 175, (y - 70) / 150) - 0.92)) * 3
            if e > bayer(x + 1, y + 3):
                px["Ombre des bords"][x, y] = C("090a14") + (255,)
    d = ImageDraw.Draw(layers["Chaînes"])
    for sx in (-1, 1):
        X, z = sx * 0.9, 5.6
        Ytop = SPRING - VR * math.sqrt(1 - (X / HW) ** 2)
        x0, y0 = project(X, Ytop, z)
        x1, y1 = project(X, -0.8, z)
        n = int(abs(y1 - y0))
        for k in range(n + 1):
            yy = int(round(y0 + k))
            if 0 <= yy < GH:
                d.point((round(x0), yy), fill=C("577277") if (yy // 2) % 2 else C("202e37"))
        d.point((round(x0) - 1, int(y1) + 1), fill=C("394a50"))
        d.point((round(x0) + 1, int(y1) + 1), fill=C("394a50"))
        d.point((round(x0), int(y1) + 2), fill=C("394a50"))
    t = layers["Torches"]
    for zt, spr in ((TORCHES[0], FLAME), (TORCHES[1], FLAME_S)):
        for sx in (-1, 1):
            cx, cy = project(sx * (HW - 0.12), -0.35, zt)
            w, h = len(spr[0]), len(spr)
            ox, oy = round(cx) - w // 2, round(cy) - h + 3
            for j, row in enumerate(spr):
                for i, ch in enumerate(row):
                    if ch in SPAL and 0 <= ox + i < GW and 0 <= oy + j < GH:
                        t.putpixel((ox + i, oy + j), SPAL[ch] + (255,))
    os.makedirs(out_png_dir, exist_ok=True)
    flat = Image.new("RGBA", (GW, GH), (0, 0, 0, 0))
    out = []
    for i, n in enumerate(order):
        im = layers[n]
        if im.getbbox() is None:
            continue
        p = os.path.join(out_png_dir, f"{i:02d}.png")
        im.save(p)
        out.append(dict(name=n, png=p))
        flat = Image.alpha_composite(flat, im)
    used = {c[:3] for c in flat.get_flattened_data()}
    assert used <= set(APOLLO), used - set(APOLLO)
    assert min(a for *_, a in flat.get_flattened_data()) == 255, "trou dans le fond"
    return flat.convert("RGB"), out, len(used)


def control_maps(scale=4):
    """Les cartes de guidage de ComfyUI (ControlNet), a la taille de l'image guide.

    Profondeur : blanc devant, noir au fond (convention des modeles de profondeur).
    Contours : les aretes de la geometrie et des objets, et les joints des pierres.
    """
    depth = Image.new("L", (GW, GH))
    label = {}
    zmin = min(cast(x, GH - 1)[1][2] for x in range(GW))
    for y in range(GH):
        for x in range(GW):
            surf, P = cast(x, y)
            depth.putpixel((x, y), round(255 * (math.log(ZFAR) - math.log(P[2])) / (math.log(ZFAR) - math.log(zmin))))
            lay, ramp, val = stack_at(surf, P)[-1]
            label[x, y] = (surf, lay, ramp == "cool" and val <= 0.2)
    edges = Image.new("L", (GW, GH))
    for y in range(GH):
        for x in range(GW):
            here = label[x, y]
            if here[2] or any(label.get(q, here)[:2] != here[:2] for q in ((x + 1, y), (x, y + 1))):
                edges.putpixel((x, y), 255)
    size = (GW * scale, GH * scale)
    return depth.resize(size, Image.BICUBIC).filter(ImageFilter.GaussianBlur(scale / 2)), edges.resize(size, Image.NEAREST)


def main(out_aseprite):
    """Rend la salle, l'assemble en .aseprite, et pose a cote l'image guide et les cartes de guidage."""
    flat, layers, n = render(work("hall", "layers"))
    check_independent([(e["name"], Image.open(e["png"]).convert("RGBA")) for e in layers], SURFACES)
    flat.save(work("hall", "flat.png"))
    stem = os.path.splitext(out_aseprite)[0]
    flat.resize((GW * 4, GH * 4), Image.NEAREST).save(f"{stem}_guide_x4.png")
    depth, edges = control_maps()
    depth.save(f"{stem}_depth.png")
    edges.save(f"{stem}_edges.png")
    manifest = [dict(out=out_aseprite, ref=work("hall", "hall_ref.png"), w=GW, h=GH, palette=[list(c) for c in APOLLO], layers=layers,
                     surfaces=list(SURFACES), import_skip=["Ombre des bords"])]
    flat.save(manifest[0]["ref"])
    print(f"{len(layers)} calques, {n} couleurs Apollo utilisees sur 46")
    build(write_manifest("hall", manifest))


if __name__ == "__main__":
    main(sys.argv[1])
