"""Fond de combat : la place de l'horloge, une ville steampunk au crepuscule. 320 x 180, palette Apollo.

Chaque objet est rendu dans son propre calque, complet, comme s'il etait seul : la
superposition du plus lointain au plus proche donne l'image, et masquer un calque laisse
voir le decor qui est derriere. Le sol, les facades et l'engrenage sont projetes en vraie
perspective ; les plans lointains (ville, viaduc, tour) sont poses a leur profondeur.

Le combat couvre le centre (ennemis a 21 % de la hauteur, heros a 51 %, main en bas) :
le detail vit en haut (horloge, dirigeables, fumees), sur les cotes (maisons, reverberes)
et dans la bande entre les ennemis et la place (ville, viaduc, train).
"""
import math
import os
import sys
from PIL import Image, ImageFilter

from aseprite_io import build, check_independent, work, write_manifest
from bg_hall import APOLLO, C, bayer, h01, vnoise

GW, GH = 320, 180
VPX, VPY, FOC = 160, 46, 160.0
CAMH = 3.0  # hauteur de la camera au-dessus des paves : on voit la place d'un peu haut
EDGE = 20.0  # bord de la place, au-dessus du ravin
SIDE = 7.5  # demi-largeur de la place ; les maisons s'alignent dessus
GEAR = (0.0, 10.4)  # centre de l'engrenage (X, Z), sous le heros
LAMPS = [(sx * 5.6, z) for z in (6.0, 9.5, 13.0) for sx in (-1, 1)]
LANTERN_Y = CAMH - 2.35

R = {
    "sky": ["10141f", "1e1d39", "402751", "7a367b", "a23e8c", "c65197", "cf573c", "da863e", "de9e41", "e8c170"],
    "cloud": ["241527", "402751", "7a367b", "a23e8c", "c65197"],
    "haze": ["241527", "402751", "7a367b"],
    "city": ["090a14", "10141f", "151d28", "241527", "341c27"],
    "stone": ["10141f", "151d28", "202e37", "394a50", "577277", "819796"],
    "stone_warm": ["241527", "341c27", "4d2b32", "7a4841", "ad7757", "c09473"],
    "brick": ["241527", "341c27", "4d2b32", "602c2c", "7a4841", "ad7757", "c09473"],
    "slate": ["090a14", "10141f", "151d28", "202e37", "394a50"],
    "iron": ["090a14", "10141f", "151d28", "202e37", "394a50", "577277"],
    "bronze": ["241527", "341c27", "602c2c", "884b2b", "be772b", "de9e41", "e8c170"],
    "dial": ["819796", "a8b5b2", "c7cfcc", "e7d5b3", "ebede9"],
    "glow": ["be772b", "de9e41", "e8c170", "e7d5b3"],
    "canvas": ["341c27", "4d2b32", "7a4841", "ad7757", "c09473", "d7b594"],
    "awning_r": ["411d31", "752438", "a53030", "cf573c"],
    "awning_w": ["7a4841", "ad7757", "d7b594", "e7d5b3"],
    "smoke": ["394a50", "577277", "819796", "a8b5b2"],
    "wood": ["241527", "341c27", "4d2b32", "7a4841"],
}
R = {k: [C(h) for h in v] for k, v in R.items()}


def tone(ramp, v, x, y, dither=True):
    rr = R[ramp]
    t = max(0.0, min(0.999, v)) * (len(rr) - 1)
    i = int(t) + (1 if t - int(t) > (bayer(x, y) if dither else 0.5) else 0)
    return rr[min(len(rr) - 1, i)]


def proj(X, Y, Z):
    return VPX + FOC * X / Z, VPY + FOC * Y / Z


def ray(x, y):
    return x + 0.5 - VPX, y + 0.5 - VPY


def lamp_light(X, Y, Z):
    return sum(1.5 * math.exp(-((X - lx) ** 2 + (Y - LANTERN_Y) ** 2 + (Z - lz) ** 2) / 3.2) for lx, lz in LAMPS)


class Scene:
    """Les calques, chacun avec sa profondeur et ses identifiants d'objet, pixel par pixel."""

    ORDER = ["Ciel", "Nuages", "Horizon", "Ville", "Fumées", "Dirigeables", "Viaduc", "Train", "Tour de l'horloge",
             "Balustrade", "Pavés", "Engrenage", "Maisons", "Réverbères"]

    def __init__(self):
        self.img = {n: Image.new("RGBA", (GW, GH), (0, 0, 0, 0)) for n in self.ORDER}
        self.px = {n: im.load() for n, im in self.img.items()}
        self.z = {n: {} for n in self.ORDER}
        self.oid = {n: {} for n in self.ORDER}

    def put(self, layer, x, y, col, z, oid):
        if 0 <= x < GW and 0 <= y < GH:
            self.px[layer][x, y] = col + (255,)
            self.z[layer][x, y] = z
            self.oid[layer][x, y] = oid

    def top(self, x, y):
        for n in reversed(self.ORDER):
            if (x, y) in self.z[n]:
                return n, self.z[n][x, y], self.oid[n][x, y]
        raise AssertionError((x, y))


# --- Le lointain ---------------------------------------------------------------------------


def sky(S):
    for y in range(GH):
        t = min(1.0, y / (VPY + 16)) ** 1.15
        for x in range(GW):
            glow = max(0.0, 1 - abs(x - 175) / 170) * max(0.0, (y - 30) / 40) * 0.08
            col = tone("sky", t + glow, x, y)
            if y < 34 and h01(x, y, 77) < 0.006 * (1 - y / 34):
                col = C("c7cfcc") if h01(x, y, 78) < 0.5 else C("ebede9")
            S.put("Ciel", x, y, col, 1000.0, "ciel")


def clouds(S):
    for y in range(4, 52):
        for x in range(GW):
            d = vnoise(x / 2.6, y * 1.6, 9) * 0.75 + vnoise(x / 1.1, y * 3.0, 3) * 0.25
            band = math.exp(-((y - 26) ** 2) / 170) * 0.55 + math.exp(-((y - 44) ** 2) / 30) * 0.35
            if d * band > 0.3:
                below = vnoise(x / 2.6, (y + 1) * 1.6, 9) * 0.75 + vnoise(x / 1.1, (y + 1) * 3.0, 3) * 0.25
                lit = below * band <= 0.3 or y > 40
                col = tone("sky", 0.66 + 0.1 * h01(x // 6, y // 3, 5), x, y) if lit else tone("cloud", 0.35 + y / 110, x, y)
                S.put("Nuages", x, y, col, 400.0, "nuage")


def skyline(S, layer, Z, seed, ramp, hmin, hmax, windows, chimneys):
    """Une rangee de batiments en silhouette, posee a la profondeur Z, qui monte du ravin."""
    X = -Z * 1.2
    k = 0
    base = 14.0
    stacks = []
    while X < Z * 1.2:
        w = 2.0 + 4.0 * h01(k, seed)
        top = -(hmin + (hmax - hmin) * h01(k, seed + 1))
        roof = h01(k, seed + 2)
        x0, y0 = proj(X, top, Z)
        x1, y1 = proj(X + w, base, Z)
        for y in range(max(0, int(y0) - 3), min(GH, int(y1) + 1)):
            for x in range(max(0, int(x0)), min(GW, int(x1) + 1)):
                rel = (x - x0) / max(1, x1 - x0)
                peak = y0 - (3 * (1 - abs(rel - 0.5) * 2) if roof > 0.6 else 0)
                if y < peak:
                    continue
                rim = y - peak < 1.0
                col = tone(ramp, 0.55 if rim else 0.25 + 0.1 * h01(k, 9), x, y)
                wid = "mur"
                if windows and not rim:
                    wx, wy = int((x - x0) / 2.2), int((y - y0) / 2.6)
                    if (x - x0) % 2.2 < 1.1 and (y - y0) % 2.6 < 1.3 and h01(k, wx, wy, seed) < windows:
                        col, wid = (C("e8c170") if h01(k, wx, wy, 3) < 0.4 else C("de9e41")), f"f{wx}.{wy}"
                S.put(layer, x, y, col, Z, f"b{k}{wid}")
        if chimneys and h01(k, seed + 4) < chimneys:
            cx = X + w * (0.2 + 0.6 * h01(k, seed + 5))
            ctop = top - 2.5 - 4 * h01(k, seed + 6)
            u0, v0 = proj(cx, ctop, Z)
            u1, v1 = proj(cx + 0.8, top, Z)
            for y in range(max(0, int(v0)), min(GH, int(v1) + 1)):
                for x in range(int(u0), int(u1) + 1):
                    S.put(layer, x, y, tone(ramp, 0.5 if y - v0 < 1 else 0.2, x, y), Z, f"c{k}")
            stacks.append((u0 + (u1 - u0) / 2, v0, Z))
        X += w + 0.3 * h01(k, seed + 3)
        k += 1
    return stacks


def smoke(S, stacks):
    for n, (u, v, Z) in enumerate(stacks):
        for y in range(max(0, int(v) - 34), int(v) + 1):
            t = (v - y) / 34
            cx = u + 18 * t ** 1.4
            rad = 2.0 + 8 * t
            for x in range(int(cx - rad) - 1, int(cx + rad) + 2):
                d = min(1.0, abs(x - cx) / rad)
                dens = (1 - d ** 2) * (1 - t ** 1.5) * (0.6 + 0.7 * vnoise(x / 2.5, y / 2.0, 11 + n))
                if dens > bayer(x, y) * 0.75 + 0.1:
                    S.put("Fumées", x, y, tone("smoke", 0.25 + 0.6 * (1 - t) * vnoise(x / 2.0, y / 2.0, 4), x, y), Z - 1, "fumee")


def airship(S, cx, cy, Z, length, seed):
    """Un dirigeable : l'enveloppe et ses cotes, la nacelle et ses hublots allumes."""
    a = FOC * length / 2 / Z
    b = a * 0.28
    for y in range(int(cy - b) - 1, int(cy + b * 2.4) + 2):
        for x in range(int(cx - a) - 2, int(cx + a) + 3):
            dx, dy = (x + 0.5 - cx) / a, (y + 0.5 - cy) / b
            if dx * dx + dy * dy <= 1:
                rib = abs(((dx + 1) * 5) % 1 - 0.5) < 0.09
                col = tone("canvas", 0.75 - 0.45 * max(0, dy) + 0.1 * (dy < -0.4) - (0.18 if rib else 0), x, y)
                S.put("Dirigeables", x, y, col, Z, f"env{seed}" + ("r" if rib else ""))
            elif abs(dx) < 0.28 and 1.35 <= dy <= 2.2:
                window = dy < 1.85 and (x % 3 == 0) and dy > 1.6
                S.put("Dirigeables", x, y, C("de9e41") if window else tone("wood", 0.45 if dy < 1.55 else 0.22, x, y), Z, f"nac{seed}")
            elif abs(dx) < 0.26 and 1.0 <= dy < 1.35 and (x % 4 == 0):
                S.put("Dirigeables", x, y, C("202e37"), Z, f"cable{seed}")
            elif 0.95 < dx < 1.12 and abs(dy) < 1.6:
                S.put("Dirigeables", x, y, tone("wood", 0.4, x, y), Z, f"queue{seed}")


# --- Le ravin : viaduc, train, tour ------------------------------------------------------------


def viaduct(S):
    Z, deck, under = 40.0, 4.0, 4.8
    span = 8.0
    for y in range(GH):
        for x in range(GW):
            dx, dy = ray(x, y)
            X, Y = dx * Z / FOC, dy * Z / FOC
            if Y < deck - 0.5 or Y > 14:
                continue
            if Y < deck:  # garde-corps du tablier
                if (X % 1.2) < 0.25 or Y > deck - 0.12:
                    S.put("Viaduc", x, y, tone("iron", 0.45, x, y), Z, "rail")
                continue
            if Y <= under:
                S.put("Viaduc", x, y, tone("brick", 0.6 if Y < deck + 0.15 else 0.42, x, y), Z, "tablier")
                continue
            m = X % span
            r = math.hypot(m - span / 2, Y - (under + span / 2 - 0.6))
            pier = m < 1.0 or m > span - 1.0
            if pier or r > span / 2 - 1.0:
                col = tone("brick", 0.34 + (0.08 if (int(Y * 3) % 2) else 0) + (0.14 if m < 0.25 or r > span / 2 - 0.75 else 0), x, y)
                S.put("Viaduc", x, y, col, Z, "pile" if pier else "arche")


def train(S):
    Z, deck = 40.0, 4.0
    cars = [(5.0, 9.0, "loco"), (9.6, 15.0, "w1"), (15.6, 21.0, "w2"), (21.6, 27.0, "w3")]
    for x0w, x1w, name in cars:
        loco = name == "loco"
        top = deck - (2.2 if loco else 1.8)
        for y in range(GH):
            for x in range(GW):
                dx, dy = ray(x, y)
                X, Y = dx * Z / FOC, dy * Z / FOC
                if x0w <= X <= x1w and top <= Y <= deck:
                    if loco and X > x1w - 1.4 and Y < deck - 1.2:
                        continue  # la cabine est plus basse que la cheminee a l'avant
                    window = (not loco) and Y < deck - 0.9 and Y > deck - 1.4 and (X - x0w) % 1.1 < 0.6
                    col = C("e8c170") if window else tone("bronze" if loco else "wood", 0.45 if Y < top + 0.3 else 0.3, x, y)
                    S.put("Train", x, y, col, Z - 0.5, name + ("f" if window else ""))
                if loco and 5.6 <= X <= 6.2 and deck - 3.2 <= Y < top:
                    S.put("Train", x, y, tone("iron", 0.35, x, y), Z - 0.5, "cheminee")
    return proj(5.9, deck - 3.2, Z) + (Z,)


def tower(S):
    Z = 30.0
    half, roof = 2.6, -8.9
    cy = -6.75
    rad = 1.65
    for y in range(GH):
        for x in range(GW):
            dx, dy = ray(x, y)
            X, Y = dx * Z / FOC, dy * Z / FOC
            if Y > 9 or Y < roof - 6:
                continue
            r = math.hypot(X, Y - cy)
            if r <= rad:
                ang = math.atan2(Y - cy, X)
                tick = r > rad * 0.78 and abs(((ang / (2 * math.pi)) * 12) % 1 - 0.5) > 0.42
                hand = (abs(X) < 0.08 and cy - rad * 0.7 < Y < cy) or (abs(Y - cy - X * 0.35) < 0.08 and 0 < X < rad * 0.55)
                if r > rad * 0.92:
                    col, oid = tone("bronze", 0.7, x, y), "cadran_bord"
                elif tick or hand:
                    col, oid = C("241527"), "aiguilles"
                else:
                    col, oid = tone("dial", 0.85 - 0.3 * r / rad, x, y), "cadran"
                S.put("Tour de l'horloge", x, y, col, Z - 0.2, oid)
            elif abs(X) <= half and Y >= roof:
                corner = abs(X) > half - 0.35
                cornice = abs(Y - (cy - rad - 0.5)) < 0.18 or abs(Y - (cy + rad + 0.5)) < 0.18
                window = abs(X) < 0.5 and (Y + 30) % 2.4 < 1.3 and Y > cy + rad + 0.8
                if window:
                    col, oid = C("de9e41"), f"fen{int((Y + 30) // 2.4)}"
                else:
                    brick = int((Y + 30) / 0.35) + 100 * int((X + 9 + (0.3 if int((Y + 30) / 0.35) % 2 else 0)) / 0.7)
                    col = tone("brick", 0.62 if (corner or cornice) else 0.32 + 0.12 * h01(brick, 2), x, y)
                    oid = "corniche" if cornice else ("angle" if corner else "tour")
                S.put("Tour de l'horloge", x, y, col, Z, oid)
            elif abs(X) <= half + 0.4 and roof - 0.5 <= Y < roof:
                S.put("Tour de l'horloge", x, y, tone("slate", 0.6, x, y), Z, "toit")
            elif abs(X) <= (half + 0.2) * (1 - (roof - Y) / 6) and Y < roof - 0.5:
                S.put("Tour de l'horloge", x, y, tone("slate", 0.35 + 0.15 * (X < 0), x, y), Z, "fleche")


# --- La place ----------------------------------------------------------------------------------


def floor_point(x, y):
    dx, dy = ray(x, y)
    if dy <= 0:
        return None
    Z = FOC * CAMH / dy
    return dx * Z / FOC, Z


def plaza(S):
    for y in range(GH):
        for x in range(GW):
            p = floor_point(x, y)
            if p is None:
                continue
            X, Z = p
            if Z > EDGE or abs(X) > SIDE + (4 if Z <= HOUSE_END[1 if X > 0 else -1] else 0):
                continue
            row = math.floor(Z / 0.3)
            Xs = X + (0.15 if row % 2 else 0)
            col = math.floor(Xs / 0.3)
            fx, fz = Xs - col * 0.3, Z - row * 0.3
            mortar = min(fx, 0.3 - fx) < 0.03 or min(fz, 0.3 - fz) < 0.03
            warm = lamp_light(X, CAMH, Z)
            amb = 0.58
            v = (0.17 if mortar else 0.5 + 0.2 * (h01(col, row, 7) - 0.5)) * (amb + warm)
            ramp = "stone_warm" if warm / (amb + warm) > 0.25 + 0.4 * bayer(x + 1, y + 2) else "stone"
            S.put("Pavés", x, y, tone(ramp, v, x, y), Z, "joint" if mortar else f"p{col}.{row}")


def gear(S):
    gx, gz = GEAR
    small = (4.0, 9.0, 1.2)
    for y in range(GH):
        for x in range(GW):
            p = floor_point(x, y)
            if p is None:
                continue
            X, Z = p
            warm = lamp_light(X, CAMH, Z)
            for cx, cz, R0, teeth, name in ((gx, gz, 3.0, 20, "grand"), (small[0], small[1], small[2], 10, "petit")):
                r = math.hypot(X - cx, Z - cz)
                ang = math.atan2(Z - cz, X - cx)
                tooth = abs(((ang / (2 * math.pi)) * teeth) % 1 - 0.5) < 0.24
                ring_in = R0 * 0.68
                if ring_in <= r <= R0 or (R0 < r <= R0 * 1.16 and tooth):
                    outline = r < ring_in + 0.08 or (r > R0 * 1.16 - 0.08) or (R0 - 0.08 < r <= R0 and not tooth)
                    v = 0.22 if outline else (0.62 + 0.12 * math.cos(ang - 2.4)) * (0.8 + warm * 0.4)
                    S.put("Engrenage", x, y, tone("bronze", v, x, y), Z, f"{name}_dents" if r > R0 else f"{name}_anneau")
                elif r < ring_in and name == "grand":
                    if r > ring_in - 0.07:
                        S.put("Engrenage", x, y, tone("bronze", 0.3, x, y), Z, "cadran_bord")
                        continue
                    tick = r > ring_in * 0.82 and abs(((ang / (2 * math.pi)) * 12) % 1 - 0.5) > 0.4
                    hand = (abs(X - cx) < 0.08 and cz < Z < cz + ring_in * 0.7) or (abs(Z - cz) < 0.08 and cx < X < cx + ring_in * 0.5)
                    col = C("241527") if (tick or hand) else tone("dial", 0.55 + 0.25 * (1 - r / ring_in), x, y)
                    S.put("Engrenage", x, y, col, Z, "aiguilles" if (tick or hand) else "cadran")
                elif r < ring_in and name == "petit" and r < 0.25:
                    S.put("Engrenage", x, y, tone("bronze", 0.4, x, y), Z, "petit_axe")


def balustrade(S):
    for y in range(GH):
        for x in range(GW):
            dx, dy = ray(x, y)
            for Z, xmin, xmax in ((EDGE, -SIDE, SIDE),):
                X, Y = dx * Z / FOC, dy * Z / FOC
                if xmin <= X <= xmax and CAMH - 1.0 <= Y <= CAMH:
                    if (X % 0.7) < 0.12 or Y < CAMH - 0.9 or abs(Y - (CAMH - 0.15)) < 0.06:
                        S.put("Balustrade", x, y, tone("iron", 0.4 if Y < CAMH - 0.9 else 0.28, x, y), Z, "balustre")
            for sx in (-1, 1):  # les cotes de la place, au-dela des maisons
                if dx * sx <= 0:
                    continue
                Z = FOC * SIDE / abs(dx)
                Y = dy * Z / FOC
                if HOUSE_END[sx] <= Z <= EDGE and CAMH - 1.0 <= Y <= CAMH and ((Z % 0.7) < 0.15 or Y < CAMH - 0.9):
                    S.put("Balustrade", x, y, tone("iron", 0.35, x, y), Z, "balustre_cote")


def above(h):
    """La coordonnee Y d'un point a h metres au-dessus des paves."""
    return CAMH - h


# (debut Z, fin Z, hauteur de la facade, numero) ; l'ardoise du toit monte d'un metre au-dessus
HOUSES = {
    -1: [(4.0, 7.6, 8.4, 0), (7.6, 11.0, 7.4, 1), (11.0, 14.0, 9.2, 2)],
    1: [(4.0, 8.0, 7.8, 3), (8.0, 12.0, 6.6, 4)],
}


HOUSE_END = {sx: max(z1 for _, z1, _, _ in hs) for sx, hs in HOUSES.items()}


def houses(S):
    for y in range(GH):
        for x in range(GW):
            dx, dy = ray(x, y)
            if dx == 0:
                continue
            sx = 1 if dx > 0 else -1
            Z = FOC * SIDE / abs(dx)
            Y = dy * Z / FOC
            for z0, z1, height, k in HOUSES[sx]:
                top = above(height)
                if not (z0 <= Z <= z1 and top - 1.0 <= Y <= CAMH):
                    continue
                rel = (Z - z0) / (z1 - z0)
                warm = lamp_light(sx * SIDE, Y, Z)
                if Y < top:  # le toit d'ardoise, vu par la tranche
                    edge = Y < top - 0.85 or abs(rel - 0.5) > 0.47
                    S.put("Maisons", x, y, tone("slate", 0.55 if edge else 0.3, x, y), Z, f"toit{k}")
                    continue
                floors = [(above(4.6), above(3.6)), (above(6.4), above(5.4)), (above(8.2), above(7.2))]
                win = None
                for fi, (wy0, wy1) in enumerate(floors):
                    if wy0 >= top + 0.3 and wy0 <= Y <= wy1:
                        for wi, wc in enumerate((0.27, 0.73)):
                            if abs(rel - wc) < 0.11:
                                win = (fi, wi, wy0, wy1, wc)
                if win:
                    fi, wi, wy0, wy1, wc = win
                    frame = Y < wy0 + 0.1 or Y > wy1 - 0.1 or abs(rel - wc) > 0.09 or abs(Y - (wy0 + wy1) / 2) < 0.04
                    lit = h01(k, fi, wi, 5) < 0.75
                    col = tone("wood", 0.4, x, y) if frame else (tone("glow", 0.55 + 0.3 * h01(k, fi, wi), x, y) if lit else tone("slate", 0.3, x, y))
                    S.put("Maisons", x, y, col, Z, f"h{k}w{fi}.{wi}" + ("c" if frame else ""))
                    continue
                if above(2.9) <= Y <= above(2.4):  # l'auvent de la boutique, raye
                    stripe = int(rel * 9) % 2
                    S.put("Maisons", x, y, tone("awning_r" if stripe else "awning_w", 0.55 if Y > above(2.5) else 0.75, x, y, False), Z, f"auvent{k}.{int(rel * 9)}")
                    continue
                if above(2.35) <= Y <= above(0.05) and 0.12 < rel < 0.88:
                    door = 0.42 < rel < 0.58
                    if door:
                        col = tone("wood", 0.28 if abs(rel - 0.5) < 0.07 else 0.45, x, y)
                    else:
                        mullion = (rel * 10) % 1 < 0.14 or abs(Y - above(1.6)) < 0.06
                        col = tone("wood", 0.3, x, y) if (mullion or Y >= above(0.6)) else tone("glow", 0.12 + 0.25 * h01(int(rel * 10), int(Y * 3), k), x, y)
                    S.put("Maisons", x, y, col, Z, f"boutique{k}" + ("p" if door else ""))
                    continue
                pipe = sx > 0 and abs(rel - 0.06) < 0.025
                if pipe:
                    S.put("Maisons", x, y, tone("bronze", 0.55, x, y), Z, f"tuyau{k}")
                    continue
                brick_r = math.floor((Y + 20) / 0.22)
                brick_c = math.floor((Z + (0.25 if brick_r % 2 else 0)) / 0.5)
                fz, fy = (Z + (0.25 if brick_r % 2 else 0)) % 0.5, (Y + 20) % 0.22
                mortar = fz < 0.05 or fy < 0.035
                pilaster = rel < 0.03 or rel > 0.97
                v = (0.2 if mortar else 0.42 + 0.14 * (h01(brick_c, brick_r, k) - 0.5)) + (0.15 if pilaster else 0)
                S.put("Maisons", x, y, tone("brick", v * (0.75 + 0.6 * warm), x, y), Z, "joint" if mortar else f"h{k}b")


def lamps(S):
    for lx, lz in LAMPS:
        for y in range(GH):
            for x in range(GW):
                dx, dy = ray(x, y)
                X, Y = dx * lz / FOC, dy * lz / FOC
                rel = X - lx
                if abs(rel) <= 0.06 and LANTERN_Y + 0.35 <= Y <= CAMH:
                    S.put("Réverbères", x, y, tone("iron", 0.3, x, y), lz, f"mat{lx}{lz}")
                elif abs(rel) <= 0.2 and LANTERN_Y - 0.2 <= Y < LANTERN_Y + 0.35:
                    frame = abs(rel) > 0.15 or Y < LANTERN_Y - 0.12 or Y > LANTERN_Y + 0.28
                    S.put("Réverbères", x, y, tone("iron", 0.4, x, y) if frame else tone("glow", 0.75, x, y), lz, f"lanterne{lx}{lz}" + ("c" if frame else ""))


def render(out_dir):
    S = Scene()
    sky(S)
    clouds(S)
    skyline(S, "Horizon", 120.0, 31, "haze", 4, 16, 0.0, 0.0)
    stacks = skyline(S, "Ville", 70.0, 11, "city", 3, 13, 0.14, 0.45)
    viaduct(S)
    stacks.append(train(S))
    smoke(S, stacks)
    airship(S, 222, 9, 60.0, 30.0, 1)
    airship(S, 96, 11, 95.0, 22.0, 2)
    tower(S)
    balustrade(S)
    plaza(S)
    gear(S)
    houses(S)
    lamps(S)
    flat = Image.new("RGBA", (GW, GH), (0, 0, 0, 0))
    entries = []
    for i, n in enumerate(S.ORDER):
        if S.img[n].getbbox() is None:
            continue
        p = os.path.join(out_dir, f"{i:02d}.png")
        os.makedirs(out_dir, exist_ok=True)
        S.img[n].save(p)
        entries.append(dict(name=n, png=p))
        flat = Image.alpha_composite(flat, S.img[n])
    used = {c[:3] for c in flat.get_flattened_data()}
    assert used <= set(APOLLO), used - set(APOLLO)
    return S, flat.convert("RGB"), entries, len(used)


def control_maps(S, scale=4):
    """Profondeur (blanc devant) et contours (les limites entre objets), a la taille du guide."""
    depth = Image.new("L", (GW, GH))
    edges = Image.new("L", (GW, GH))
    top = {(x, y): S.top(x, y) for y in range(GH) for x in range(GW)}
    lo, hi = math.log(3.0), math.log(1000.0)
    def shape(n, oid):
        """L'objet a l'echelle ou ses contours comptent : les joints, les pierres d'une meme
        surface et les fenetres de la ville lointaine sont laisses au generateur."""
        if n == "Pavés":
            return "pave"
        if n in ("Ville", "Horizon"):
            return oid.split("f")[0].replace("mur", "")
        if n == "Maisons" and (oid == "joint" or oid.endswith("b")):
            return "mur"
        return oid

    for (x, y), (n, z, oid) in top.items():
        depth.putpixel((x, y), round(255 * max(0.0, min(1.0, (hi - math.log(z)) / (hi - lo)))))
        here = (n, shape(n, oid))
        if n in ("Ciel", "Nuages", "Fumées"):
            continue
        if any((top[q][0], shape(top[q][0], top[q][2])) != here for q in ((x + 1, y), (x, y + 1)) if q in top):
            edges.putpixel((x, y), 255)
    size = (GW * scale, GH * scale)
    return depth.resize(size, Image.BICUBIC).filter(ImageFilter.GaussianBlur(scale / 2)), edges.resize(size, Image.NEAREST)


def main(out_aseprite):
    S, flat, layers, n = render(work("plaza", "layers"))
    check_independent([(e["name"], Image.open(e["png"]).convert("RGBA")) for e in layers], ("Ciel",))
    flat.save(work("plaza", "flat.png"))
    stem = os.path.splitext(out_aseprite)[0]
    flat.resize((GW * 4, GH * 4), Image.NEAREST).save(f"{stem}_guide_x4.png")
    depth, edges = control_maps(S)
    depth.save(f"{stem}_depth.png")
    edges.save(f"{stem}_edges.png")
    manifest = [dict(out=out_aseprite, ref=work("plaza", "plaza_ref.png"), w=GW, h=GH, palette=[list(c) for c in APOLLO], layers=layers,
                     surfaces=["Ciel"])]
    flat.save(manifest[0]["ref"])
    print(f"{len(layers)} calques, {n} couleurs Apollo utilisees sur 46")
    build(write_manifest("plaza", manifest))


if __name__ == "__main__":
    main(sys.argv[1])
