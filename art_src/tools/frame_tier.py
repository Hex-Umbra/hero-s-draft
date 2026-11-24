"""Les cadres de tier des ennemis, d'apres le document d'identite visuelle (18/09/2026, §4).

La fenetre est l'invariant : 64 x 96 sur tous les tiers. Le canevas et l'epaisseur de la
bordure grandissent avec le tier, si bien que la menace se lit avant l'illustration. Le cadre
porte son propre fond de fenetre, opaque. Tout est fait par le code : c'est de la geometrie.

    python frame_tier.py 2 ../cadres/tier_2.aseprite
"""
import math
import sys

from bg_hall import C, vnoise
from scene import Scene, export, shade

WINDOW = (64, 96)
TIERS = {1: ((88, 120), 12), 2: ((96, 128), 16), 3: ((96, 128), 16), 4: ((104, 136), 20), 5: ((112, 144), 24)}
FEET = 92  # la ligne de sol des creatures, en coordonnees de fenetre
ORDER = ["Fond de fenêtre", "Cadre", "Liseré de bronze", "Rivets", "Coins", "Insigne de tier"]

R = {
    "window": ["090a14", "10141f", "151d28", "202e37", "394a50"],
    "iron": ["090a14", "10141f", "151d28", "202e37", "394a50", "577277", "819796"],
    "bronze": ["241527", "341c27", "602c2c", "884b2b", "be772b", "de9e41", "e8c170"],
}
R = {k: [C(h) for h in v] for k, v in R.items()}


def tone(ramp, v, x, y, dither=True):
    return shade(R[ramp], v, x, y, dither)


def frame(tier):
    (W, H), b = TIERS[tier]
    S = Scene(ORDER, (W, H))
    wx0, wy0 = b, b
    wx1, wy1 = b + WINDOW[0] - 1, b + WINDOW[1] - 1
    floor = wy0 + FEET

    # le fond de fenetre : une penombre neutre, un sol leger sous les pieds, les coins assombris
    for y in range(wy0, wy1 + 1):
        for x in range(wx0, wx1 + 1):
            fx, fy = (x - wx0) / WINDOW[0], (y - wy0) / WINDOW[1]
            vign = math.hypot(fx - 0.5, (fy - 0.55) * 0.9)
            v = 0.3 + 0.22 * fy - 0.5 * max(0.0, vign - 0.3)
            if y >= floor - 6:
                v += 0.16 * (1 - abs(fx - 0.5) * 1.5)  # le sol, plus clair au centre
            if y == floor - 7:
                v -= 0.12  # la ligne ou le mur rencontre le sol
            S.put("Fond de fenêtre", x, y, tone("window", v + 0.04 * (vnoise(x / 3, y / 3, 7) - 0.5), x, y), 10.0, "fond")

    # la plaque de fer : un biseau a l'exterieur, une gorge, le bord interieur qui tombe dans la fenetre
    for y in range(H):
        for x in range(W):
            if wx0 <= x <= wx1 and wy0 <= y <= wy1:
                continue
            d_out = min(x, y, W - 1 - x, H - 1 - y)
            d_in = max(wx0 - x, x - wx1, wy0 - y, y - wy1)  # distance a la fenetre, depuis l'exterieur
            topleft = (x < W - 1 - x and d_out == x) or (y < H - 1 - y and d_out == y)
            if d_out == 0:
                v, oid = 0.0, "bord"
            elif d_out <= 2:
                v, oid = (0.78 if topleft else 0.3), "biseau"
            elif d_in <= 1:
                v, oid = 0.05, "gorge"
            elif d_in == 2:
                v, oid = (0.3 if topleft else 0.7), "levre"
            elif d_out == 3 or d_in == 3:
                v, oid = 0.22, "plaque"
            else:
                v, oid = 0.5 + 0.08 * (vnoise(x / 3.0, y / 3.0, 11) - 0.5), "plaque"
            S.put("Cadre", x, y, tone("iron", v, x, y), 1.0, oid)

    # un liseré de bronze a mi-bordure, tout autour de la fenetre
    m = b // 2
    for y in range(H):
        for x in range(W):
            on = (m <= x <= W - 1 - m and m <= y <= H - 1 - m) and not (m + 1 <= x <= W - 2 - m and m + 1 <= y <= H - 2 - m)
            if on:
                lit = x == m or y == m
                S.put("Liseré de bronze", x, y, tone("bronze", 0.72 if lit else 0.45, x, y, False), 0.9, "lisere")

    # des rivets regulierement espaces, ancres sur les bords de la fenetre
    r = (m + 3) // 2 + 1  # au milieu de la plaque, entre le biseau et le liseré
    for t in range(wx0 + 8, wx1 - 4, 16):
        for yy in (r, H - 1 - r):
            rivet(S, t, yy)
    for t in range(wy0 + 8, wy1 - 4, 16):
        for xx in (r, W - 1 - r):
            rivet(S, xx, t)

    # les coins : une equerre de bronze et sa pointe
    k = b - 2
    for cx, cy, sx, sy in ((0, 0, 1, 1), (W - 1, 0, -1, 1), (0, H - 1, 1, -1), (W - 1, H - 1, -1, -1)):
        for j in range(k + 1):
            for i in range(k + 1):
                arm = (i <= 4 or j <= 4) and i + j <= k + 3
                tip = abs(i - j) <= 1 and i <= k - 2
                if not (arm or tip):
                    continue
                x, y = cx + sx * i, cy + sy * j
                edge = i == 0 or j == 0 or (i <= 4 and j == k) or (j <= 4 and i == k) or i + j == k + 3
                lit = (sx > 0 and i == 1) or (sy > 0 and j == 1)
                v = 0.15 if edge else (0.78 if lit else 0.55 - 0.15 * (i + j) / (2 * k))
                S.put("Coins", x, y, tone("bronze", v, x, y, False), 0.8, "coin")
        rivet(S, cx + sx * 2 + (0 if sx > 0 else -1) + 1 * sx, cy + sy * 2 + (0 if sy > 0 else -1) + 1 * sy, "bronze")

    # l'insigne du tier, ancre sur le bord haut de la fenetre : une plaque et autant de pions que le tier
    pw = 6 + 6 * tier
    px0, py1 = W // 2 - pw // 2, wy0 - 2
    py0 = py1 - 9
    for y in range(py0, py1 + 1):
        for x in range(px0, px0 + pw):
            edge = x in (px0, px0 + pw - 1) or y in (py0, py1)
            S.put("Insigne de tier", x, y, tone("bronze", 0.12 if edge else (0.7 if y == py0 + 1 else 0.48), x, y, False), 0.7, "insigne")
    for n in range(tier):
        cx = px0 + 6 + n * 6 + (pw - 6 * tier - 6) // 2
        for y in range(py0 + 3, py0 + 7):
            for x in range(cx - 1, cx + 2):
                corner = (x - cx) ** 2 + (y - py0 - 4.5) ** 2 > 2.3
                if not corner:
                    S.put("Insigne de tier", x, y, tone("bronze", 0.95 if (x < cx and y < py0 + 5) else 0.7, x, y, False), 0.69, f"pion{n}")
    return S, (wx0, wy0)


def rivet(S, x, y, metal="iron"):
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            if abs(dx) + abs(dy) == 2:
                continue
            v = 0.9 if (dx, dy) in ((-1, 0), (0, -1)) else (0.15 if (dx, dy) in ((1, 0), (0, 1)) else 0.6)
            S.put("Rivets" if metal == "iron" else "Coins", x + dx, y + dy, tone(metal, v, x + dx, y + dy, False), 0.85, "rivet")


if __name__ == "__main__":
    tier = int(sys.argv[1])
    S, offset = frame(tier)
    export(S, f"frame_{tier}", sys.argv[2], surfaces=tuple(ORDER), controls=False)
    print(f"cadre de tier {tier} : canevas {S.w} x {S.h}, fenetre 64 x 96 a l'offset {offset}")
