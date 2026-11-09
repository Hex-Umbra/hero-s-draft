"""Le Squelette, ennemi de tier 2, en illustration pleine fenetre : la creature et sa crypte.

Le document d'identite visuelle (18/09/2026, §4.3) laissait cette porte ouverte : quand une
entite porte son propre decor, elle n'est plus detouree, elle remplit sa fenetre. Les
proportions sont adultes (le crane fait environ 1/7 du corps), la pose est de trois quarts,
genoux flechis, et les os sont modeles plutot qu'en aplats. L'identite vient de
l'illustration actuelle : casque de fer rouille, tunique de cuir en lambeaux, epee rouillee
en travers, ecu de bois a l'embleme pale, une crypte derriere.

Tout est decrit en coordonnees relatives a la fenetre, pour rendre a n'importe quelle taille :

    python creature_squelette.py 128 ../creatures/squelette_128.aseprite
"""
import math
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from bg_hall import C, bayer, h01, vnoise
from scene import Scene, export, shade

ORDER = ["Mur de la crypte", "Arche", "Piliers", "Sol", "Os au sol", "Toiles d'araignée", "Ombre",
         "Jambes", "Bassin", "Cage thoracique", "Tunique", "Ceinture", "Bras du bouclier", "Bouclier",
         "Crâne", "Casque", "Épée", "Bras de l'épée"]
BACKGROUND = ORDER[:7]

R = {
    "wall": ["090a14", "10141f", "151d28", "202e37", "394a50", "577277"],
    "void": ["090a14", "10141f", "151d28"],
    "moss": ["10141f", "151d28", "19332d", "25562e"],
    "floor": ["090a14", "10141f", "151d28", "202e37", "394a50", "577277"],
    "bone": ["4d2b32", "7a4841", "c09473", "d7b594", "e7d5b3", "ebede9"],
    "bone_cold": ["151d28", "202e37", "394a50", "577277", "819796", "a8b5b2"],
    "leather": ["10141f", "241527", "341c27", "4d2b32", "7a4841", "ad7757"],
    "iron": ["090a14", "151d28", "202e37", "394a50", "577277", "819796"],
    "rust": ["341c27", "602c2c", "884b2b", "be772b"],
    "blade": ["202e37", "394a50", "577277", "819796", "a8b5b2"],
    "wood": ["241527", "341c27", "4d2b32", "7a4841", "ad7757"],
    "web": ["394a50", "577277", "819796"],
}
R = {k: [C(h) for h in v] for k, v in R.items()}
OUTLINE = {"bone": C("241527"), "leather": C("090a14"), "iron": C("090a14"), "blade": C("10141f"), "wood": C("090a14")}
DEPTH = {n: 20.0 - 0.6 * i for i, n in enumerate(ORDER)}


class Canvas:
    """Les coordonnees relatives de la fenetre, ramenees aux pixels d'une taille donnee."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.k = w / 64  # l'epaisseur d'un trait, mesuree en pixels d'un sprite de 64 de large

    def p(self, u, v):
        return (u * self.w, v * self.h)

    def width(self, n):
        return max(1, round(n * self.k))


def part(S, cv, layer, draw, ramp, oid, accent=None, cold=0.0):
    """Une forme modelee : eclairee d'en haut a gauche, ombree en bas a droite, plus froide
    dans les ombres (cold), cernee d'un contour sombre de sa matiere."""
    mask = Image.new("L", (cv.w, cv.h), 0)
    draw(ImageDraw.Draw(mask))
    m = mask.load()
    box = mask.getbbox()
    if not box:
        return
    ring = ImageChops.subtract(mask.filter(ImageFilter.MaxFilter(3)), mask).load()
    z = DEPTH[layer]
    x0, y0, x1, y1 = box
    for y in range(max(0, y0 - 1), min(cv.h, y1 + 1)):
        for x in range(max(0, x0 - 1), min(cv.w, x1 + 1)):
            if m[x, y]:
                inside = lambda dx, dy: 0 <= x + dx < cv.w and 0 <= y + dy < cv.h and m[x + dx, y + dy]
                v = 0.5 + 0.25 * (1 - (x - x0) / max(1, x1 - x0)) - 0.12 * (y - y0) / max(1, y1 - y0)
                v += 0.22 * (not inside(-1, 0)) + 0.12 * (not inside(0, -1)) - 0.2 * (not inside(1, 0)) - 0.15 * (not inside(0, 1))
                col = accent(x, y) if accent else None
                if col is None:
                    use_cold = cold and v < 0.45 and (0.45 - v) * 2.5 * cold > bayer(x, y)
                    col = shade(R[ramp + "_cold"] if use_cold else R[ramp], v, x, y)
                S.put(layer, x, y, col, z, oid)
            elif ring[x, y] and (x, y) not in S.z[layer]:
                S.put(layer, x, y, OUTLINE.get(ramp, C("090a14")), z, oid + "_contour")


def bone(d, cv, a, b, w):
    """Un os long : la diaphyse et ses deux epiphyses."""
    pa, pb = cv.p(*a), cv.p(*b)
    d.line([pa, pb], fill=255, width=cv.width(w))
    r = cv.width(w) * 0.75
    for q in (pa, pb):
        d.ellipse([q[0] - r, q[1] - r, q[0] + r, q[1] + r], fill=255)


# --- La crypte -------------------------------------------------------------------------------------

FLOOR_V = 0.74  # la ou le mur rencontre le sol


def crypt(S, cv):
    W, H = cv.w, cv.h
    fy = round(FLOOR_V * H)
    for y in range(H):
        for x in range(W):
            u, v = (x + 0.5) / W, (y + 0.5) / H
            # le mur : des blocs de pierre irreguliers, plus sombres loin de la lumiere
            row = math.floor(v * 11)
            off = 0.5 * (row % 2) + 0.2 * h01(row, 3)
            col = math.floor(u * 6 + off)
            fu, fv = (u * 6 + off) % 1, (v * 11) % 1
            joint = fu < 0.06 * cv.k ** -0.3 or fv < 0.08 * cv.k ** -0.3
            light = 0.55 - 0.45 * math.hypot(u - 0.35, v - 0.35)
            val = (0.18 if joint else light + 0.1 * (h01(col, row, 5) - 0.5) + 0.06 * (vnoise(x / (2 * cv.k), y / (2 * cv.k), 7) - 0.5))
            S.put("Mur de la crypte", x, y, shade(R["wall"], val, x, y), DEPTH["Mur de la crypte"], "joint" if joint else f"pierre{col}.{row}")
            # l'arche sombre derriere la creature : elle detache sa silhouette
            cu, top = 0.5, 0.12
            inside = abs(u - cu) < 0.27 and (v > top + 0.27 or (u - cu) ** 2 / 0.27 ** 2 + (v - (top + 0.27)) ** 2 / 0.27 ** 2 < 1) and v < FLOOR_V
            ring = abs(u - cu) < 0.33 and (v > top + 0.21 or (u - cu) ** 2 / 0.33 ** 2 + (v - (top + 0.27)) ** 2 / 0.33 ** 2 < 1) and v < FLOOR_V
            if inside:
                depth = 0.35 - 0.3 * (v - top) / (FLOOR_V - top) + 0.1 * (1 - abs(u - cu) / 0.27)
                S.put("Arche", x, y, shade(R["void"], depth, x, y), DEPTH["Arche"] + 10, "vide")
            elif ring:
                ang = math.atan2(v - (top + 0.27), (u - cu) * 1.0)
                k = math.floor((ang + math.pi) / math.pi * 9) if v < top + 0.27 else math.floor(v * 9)
                edge = abs(((ang + math.pi) / math.pi * 9) % 1 - 0.5) > 0.42 if v < top + 0.27 else abs((v * 9) % 1 - 0.5) > 0.42
                S.put("Arche", x, y, shade(R["wall"], 0.2 if edge else 0.62 - 0.3 * v + 0.08 * h01(k, 9), x, y), DEPTH["Arche"], f"voussoir{k}")
            # les piliers sur les bords, et la mousse qui les ronge
            for pu0, pu1 in ((0.0, 0.11), (0.89, 1.0)):
                if pu0 <= u <= pu1 and v < FLOOR_V + 0.02:
                    rel = (u - pu0) / (pu1 - pu0)
                    val = 0.3 + 0.35 * math.sin(math.pi * rel) * (0.8 if pu0 > 0.5 else 1.0) - 0.1 * (math.floor(v * 7) % 2) * 0.5
                    mossy = vnoise(x / (1.5 * cv.k), y / (3 * cv.k), 13) > 0.7 and v > 0.3
                    S.put("Piliers", x, y, shade(R["moss"], 0.5, x, y) if mossy else shade(R["wall"], val, x, y), DEPTH["Piliers"], "pilier")
            # le sol : des dalles en perspective, vers un point de fuite au centre
            if y >= fy:
                t = (y - fy) / (H - fy)
                rowf = math.log(1 + 6 * t) / math.log(7) * 5
                vp_u = 0.5
                spread = (u - vp_u) / (0.25 + 0.75 * t)
                fx = (spread * 4 + 0.5 * (math.floor(rowf) % 2)) % 1
                joint = (rowf % 1) < 0.1 or fx < 0.07
                val = 0.16 if joint else 0.32 + 0.25 * t * (1 - abs(u - 0.4)) + 0.08 * (h01(math.floor(spread * 4), math.floor(rowf), 21) - 0.5)
                S.put("Sol", x, y, shade(R["floor"], val, x, y), DEPTH["Sol"] - 4 * t, "joint_sol" if joint else "dalle")
    # des os epars sur le sol, et une hache brisee
    for a, b, w in (((0.06, 0.9), (0.24, 0.87), 2.2), ((0.12, 0.95), (0.2, 0.97), 1.6)):
        part(S, cv, "Os au sol", lambda d, a=a, b=b, w=w: bone(d, cv, a, b, w), "bone", "os_sol", cold=0.6)
    part(S, cv, "Os au sol", lambda d: d.ellipse([*cv.p(0.78, 0.9), *cv.p(0.86, 0.95)], fill=255), "bone", "crane_sol", cold=0.6,
         accent=lambda x, y: C("090a14") if abs(x - cv.p(0.8, 0)[0]) < cv.k and abs(y - cv.p(0, 0.92)[1]) < cv.k else None)
    part(S, cv, "Os au sol", lambda d: d.line([cv.p(0.84, 0.86), cv.p(0.97, 0.93)], fill=255, width=cv.width(1.5)), "wood", "manche_hache")
    part(S, cv, "Os au sol", lambda d: d.polygon([cv.p(0.82, 0.83), cv.p(0.88, 0.85), cv.p(0.85, 0.89)], fill=255), "iron", "fer_hache")
    # les toiles d'araignee dans les coins hauts
    web = Image.new("L", (W, H), 0)
    dw = ImageDraw.Draw(web)
    for cx, sx in ((0.0, 1), (1.0, -1)):
        for k in range(5):
            a = k / 4 * math.pi / 2
            dw.line([cv.p(cx, 0.0), cv.p(cx + sx * 0.22 * math.cos(a), 0.15 * math.sin(a))], fill=255, width=1)
        for r in (0.08, 0.14, 0.2):
            pts = [cv.p(cx + sx * r * math.cos(k / 8 * math.pi / 2), r * 0.7 * math.sin(k / 8 * math.pi / 2) + 0.01 * (k % 2)) for k in range(9)]
            dw.line(pts, fill=255, width=1)
    for y in range(H):
        for x in range(W):
            if web.getpixel((x, y)) and h01(x, y, 31) < 0.85:
                S.put("Toiles d'araignée", x, y, shade(R["web"], 0.4 + 0.4 * h01(x, y, 32), x, y), DEPTH["Toiles d'araignée"], "toile")
    # l'ombre de la creature au sol
    for y in range(H):
        for x in range(W):
            u, v = (x + 0.5) / W, (y + 0.5) / H
            dd = ((u - 0.52) / 0.3) ** 2 + ((v - 0.905) / 0.035) ** 2
            if dd < 1 and (1 - dd) > bayer(x, y) * 0.8:
                S.put("Ombre", x, y, C("090a14"), DEPTH["Ombre"], "ombre")


# --- Le squelette ------------------------------------------------------------------------------------


def skeleton(S, cv):
    k = cv.k
    legs = (((0.47, 0.545), (0.42, 0.70), 2.2), ((0.42, 0.71), (0.40, 0.865), 1.6), ((0.40, 0.87), (0.33, 0.895), 1.5),
            ((0.56, 0.545), (0.61, 0.705), 2.2), ((0.61, 0.715), (0.64, 0.865), 1.6), ((0.64, 0.87), (0.71, 0.895), 1.5))
    part(S, cv, "Jambes", lambda d: ([bone(d, cv, a, b, w) for a, b, w in legs],
                                     [d.ellipse([cv.p(u - 0.02, v - 0.012)[0], cv.p(u, v - 0.012)[1], cv.p(u + 0.02, v)[0], cv.p(u, v + 0.012)[1]], fill=255) for u, v in ((0.42, 0.705), (0.61, 0.71))]),
         "bone", "jambes", cold=0.7)
    part(S, cv, "Bassin", lambda d: d.polygon([cv.p(0.44, 0.52), cv.p(0.59, 0.52), cv.p(0.575, 0.565), cv.p(0.53, 0.585), cv.p(0.5, 0.585), cv.p(0.455, 0.565)], fill=255),
         "bone", "bassin", cold=0.7)

    def ribs(d):
        d.line([cv.p(0.515, 0.27), cv.p(0.515, 0.53)], fill=255, width=cv.width(1.5))
        d.line([cv.p(0.40, 0.3), cv.p(0.63, 0.3)], fill=255, width=cv.width(1.2))
        for i in range(6):
            v = 0.33 + i * 0.026
            half = 0.105 - i * 0.008
            box = [*cv.p(0.515 - half, v - 0.02), *cv.p(0.515 + half, v + 0.02)]
            d.arc(box, 195, 345, fill=255, width=cv.width(1.0))
            d.arc(box, 15, 165, fill=255, width=max(1, cv.width(0.7)))
    part(S, cv, "Cage thoracique", ribs, "bone", "cotes", cold=0.7)
    hem = [cv.p(0.42 + i * 0.022, 0.61 + 0.025 * (i % 2) + 0.015 * h01(i, 5)) for i in range(10)]
    part(S, cv, "Tunique", lambda d: (d.polygon([cv.p(0.44, 0.45), cv.p(0.5, 0.43), cv.p(0.6, 0.46), cv.p(0.625, 0.6)] + hem[::-1] + [cv.p(0.415, 0.6)], fill=255),
                                       d.line([cv.p(0.42, 0.3), cv.p(0.6, 0.47)], fill=255, width=cv.width(1.4))),
         "leather", "tunique", accent=lambda x, y: R["leather"][1] if h01(x // max(1, round(k)), y // max(1, round(2 * k)), 3) < 0.12 else None)
    part(S, cv, "Ceinture", lambda d: d.rectangle([*cv.p(0.42, 0.505), *cv.p(0.61, 0.52)], fill=255), "leather", "ceinture",
         accent=lambda x, y: R["rust"][2] if abs(x - cv.p(0.515, 0)[0]) < 1.5 * k else None)
    part(S, cv, "Bras du bouclier", lambda d: (bone(d, cv, (0.63, 0.305), (0.70, 0.40), 1.5), bone(d, cv, (0.70, 0.405), (0.66, 0.46), 1.3)), "bone", "bras_g", cold=0.7)
    pts = [cv.p(0.62, 0.36), cv.p(0.79, 0.375), cv.p(0.785, 0.5), cv.p(0.7, 0.6), cv.p(0.63, 0.49)]
    cx, cy = cv.p(0.705, 0.45)

    def shield_accent(x, y):
        u, v = x / cv.w, y / cv.h
        if (x - cx) ** 2 / (0.022 * cv.w) ** 2 + (y - cy) ** 2 / (0.016 * cv.h) ** 2 < 1:
            return shade(R["bone"], 0.75, x, y)  # l'embleme : un crane pale, peint
        for a in range(4):
            ang = a * math.pi / 2 + 0.4
            px, py = cx + math.cos(ang) * 0.06 * cv.w, cy + math.sin(ang) * 0.05 * cv.h
            if abs((x - cx) * (py - cy) - (y - cy) * (px - cx)) / max(1, math.hypot(px - cx, py - cy)) < 0.7 * k and (x - cx) * (px - cx) + (y - cy) * (py - cy) > 0 and math.hypot(x - cx, y - cy) < 0.065 * cv.w:
                return shade(R["bone"], 0.55, x, y)
        if h01(x // max(1, round(2 * k)), y, 6) < 0.1:
            return R["wood"][1]  # le fil du bois
        return None
    part(S, cv, "Bouclier", lambda d: (d.polygon(pts, fill=255)), "wood", "ecu", accent=shield_accent)
    part(S, cv, "Bouclier", lambda d: d.line(pts + pts[:1], fill=255, width=cv.width(1.2)), "iron", "ecu_cercle")

    def skull_accent(x, y):
        u, v = x / cv.w, y / cv.h
        for eu in (0.495, 0.547):
            if ((u - eu) / 0.019) ** 2 + ((v - 0.204) / 0.012) ** 2 < 1:
                glint = ((u - eu + 0.005) / 0.006) ** 2 + ((v - 0.204) / 0.004) ** 2 < 1
                return R["rust"][1] if glint else C("090a14")
        if abs(u - 0.52) < 0.008 and 0.215 < v < 0.232:
            return C("090a14")
        if 0.243 < v < 0.252 and 0.49 < u < 0.555:
            return C("241527") if (x // max(1, round(k))) % 2 else R["bone"][5]
        return None
    part(S, cv, "Crâne", lambda d: (d.ellipse([*cv.p(0.465, 0.16), *cv.p(0.578, 0.24)], fill=255), d.rectangle([*cv.p(0.482, 0.225), *cv.p(0.56, 0.262)], fill=255)),
         "bone", "crane", accent=skull_accent, cold=0.6)
    part(S, cv, "Casque", lambda d: (d.chord([*cv.p(0.458, 0.14), *cv.p(0.587, 0.225)], 180, 360, fill=255), d.rectangle([*cv.p(0.455, 0.18), *cv.p(0.59, 0.188)], fill=255),
                                     d.rectangle([*cv.p(0.517, 0.185), *cv.p(0.524, 0.214)], fill=255)),
         "iron", "casque", accent=lambda x, y: (R["rust"][int(h01(x, y, 8) * 3)] if vnoise(x / (1.5 * k), y / (1.5 * k), 17) > 0.6 else None))
    hand, tip = (0.3, 0.545), (0.56, 0.8)

    def sword(d):
        a, b = cv.p(*hand), cv.p(*tip)
        d.line([a, b], fill=255, width=cv.width(2.2))
        dx, dy = b[0] - a[0], b[1] - a[1]
        n = math.hypot(dx, dy)
        px, py = -dy / n, dx / n
        g = 0.045 * cv.w
        d.line([(a[0] + px * g, a[1] + py * g), (a[0] - px * g, a[1] - py * g)], fill=255, width=cv.width(1.6))
        d.line([a, (a[0] - dx / n * 0.06 * cv.w, a[1] - dy / n * 0.06 * cv.w)], fill=255, width=cv.width(1.6))
    part(S, cv, "Épée", sword, "blade", "epee",
         accent=lambda x, y: R["rust"][1 + int(h01(x, y, 2) * 2)] if vnoise(x / (2 * k), y / (2 * k), 19) > 0.72 else None)
    part(S, cv, "Bras de l'épée", lambda d: (bone(d, cv, (0.40, 0.305), (0.33, 0.43), 1.5), bone(d, cv, (0.33, 0.435), (0.30, 0.53), 1.3),
                                             d.ellipse([*cv.p(0.282, 0.528), *cv.p(0.318, 0.556)], fill=255)), "bone", "bras_d", cold=0.7)


def shape(n, oid):
    """Les joints du mur et du sol sont laisses au generateur ; les objets gardent leurs contours."""
    if n in ("Mur de la crypte", "Sol"):
        return n
    return oid.replace("_contour", "")


def render(size):
    w = size
    h = size * 3 // 2
    S = Scene(ORDER, (w, h))
    cv = Canvas(w, h)
    crypt(S, cv)
    skeleton(S, cv)
    return S


if __name__ == "__main__":
    size = int(sys.argv[1])
    S = render(size)
    controls = len(sys.argv) < 4 or sys.argv[3] != "--sans-guide"
    export(S, f"squelette_{size}", sys.argv[2], surfaces=("Mur de la crypte",), shape=shape, skip=("Toiles d'araignée", "Ombre"),
           depth_range=(5.0, 40.0), guide_scale=768 // size, controls=controls,
           import_exclude=("a8ca58", "d0da91"))  # sans eux, l'ivoire des os ne vire pas au vert pale
