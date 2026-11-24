"""Le plan du decor de combat de la cave : des aplats poses d'apres la place de l'interface.

Le plan n'est pas le decor : c'est l'image de depart de sa passe d'ensemble, qui tient sa
composition (workflow des decors, etape 2). Il reprend l'esquisse libre retenue par le
proprietaire, une cave voutee aux cadres de bois, et ce qu'il a demande ensuite : que le fond soit
centre et ouvert. Le point de fuite tombe donc derriere le heros, le mur du fond s'ouvre par une
arche, et le couloir continue derriere la scene de combat. Sur la grille de 640 x 360, la rangee des
ennemis tient de y = 14 a 126, le heros est centre en (320, 184), la main part de y = 238 entre
x = 95 et 545 : l'arche est plus large que le heros, et les torches l'encadrent dans la bande restee
visible. Les aplats sont sombres : c'est le plan, pas le prompt, qui donne le noir du decor.

    python decor_dungeon_combat.py ../decors/dungeon/combat/dungeon_combat_plan.png [<zones.png>]

L'image fait 1280 x 720, deux fois la grille. <zones.png> recoit le plan sous la carte des zones
de decor_controle.py : ce que l'interface recouvre.
"""
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

from decor_controle import with_zones

W, H, K = 1280, 720, 2  # K : pixels du plan par pixel de la grille du decor
VP = (640, 340)  # le point de fuite : (320, 170) sur la grille, derriere le heros
HALF, UP, DOWN = 260, 170, 130  # le mur du fond, autour du point de fuite : demi-largeur, haut, bas
CEILING, WALL, WALL_LIT, MORTAR = (10, 11, 17), (26, 29, 38), (40, 44, 54), (11, 12, 18)
FLOOR, LANE, DEEP = (26, 26, 32), (42, 41, 46), (5, 6, 10)
WOOD, WOOD_LIT, IRON, FLAME, WARM = (40, 27, 22), (66, 42, 30), (54, 51, 52), (250, 176, 84), (150, 84, 42)


def at(m, dx, dy):
    """Un point du couloir, a l'echelle m (1 au mur du fond) : dx et dy en parts du mur du fond."""
    return (VP[0] + HALF * dx * m, VP[1] + (DOWN if dy > 0 else UP) * dy * m)


def glow(img, cx, cy, radius, strength):
    """Le halo chaud d'une torche : l'image tiree vers l'orange, de moins en moins loin du feu."""
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=round(255 * strength))
    warm = Image.blend(img, Image.new("RGB", img.size, WARM), 0.6)
    return Image.composite(warm, img, mask.filter(ImageFilter.GaussianBlur(radius / 2.2)))


def frame(d, m):
    """Un cadre de bois : deux poteaux, un linteau, deux contrefiches en arc."""
    t = 15 * m
    for side in (-1, 1):
        x, top, foot = at(m, side, -1)[0], at(m, side, -1)[1], at(m, side, 1)[1]
        d.rectangle([x - t, top, x + t, foot], fill=WOOD)
        d.rectangle([x - t if side > 0 else x + t - 5 * m, top, x - t + 5 * m if side > 0 else x + t, foot], fill=WOOD_LIT)
        d.line([(x, top + 150 * m), (x - side * 110 * m, top + 8 * m)], fill=WOOD, width=round(22 * m))
    d.rectangle([at(m, -1, -1)[0] - t, at(m, -1, -1)[1] - t, at(m, 1, -1)[0] + t, at(m, 1, -1)[1] + t], fill=WOOD)
    d.line([(at(m, -1, -1)[0], at(m, -1, -1)[1] + t), (at(m, 1, -1)[0], at(m, 1, -1)[1] + t)], fill=WOOD_LIT, width=max(2, round(3 * m)))


def plan():
    rnd = random.Random(3)
    img = Image.new("RGB", (W, H), CEILING)
    d = ImageDraw.Draw(img)
    far = 3.2  # l'echelle du plan le plus proche, hors de l'image

    # le sol, et son allee plus claire qui file vers l'arche
    d.polygon([at(1, -1, 1), at(1, 1, 1), at(far, 1, 1), at(far, -1, 1)], fill=FLOOR)
    d.polygon([at(1, -0.62, 1), at(1, 0.62, 1), at(far, 0.5, 1), at(far, -0.5, 1)], fill=LANE)
    for i in range(1, 9):
        m = 1 + (far - 1) * (i / 9) ** 1.7
        d.line([at(m, -1, 1), at(m, 1, 1)], fill=MORTAR, width=3)
    for dx in (-0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75):
        d.line([at(1, dx, 1), at(far, dx, 1)], fill=MORTAR, width=3)

    # les deux murs de cote, leurs assises de pierre qui fuient
    for side in (-1, 1):
        d.polygon([at(1, side, -1), at(far, side, -1), at(far, side, 1), at(1, side, 1)], fill=WALL)
        for row in range(1, 7):
            dy = -1 + row * 2 / 7
            d.line([at(1, side, dy), at(far, side, dy)], fill=MORTAR, width=3)
        for _ in range(26):
            m, row = rnd.uniform(1.05, 2.6), rnd.randint(0, 6)
            m2, dy0, dy1 = m + rnd.uniform(0.08, 0.2), -1 + row * 2 / 7 + 0.03, -1 + (row + 1) * 2 / 7 - 0.03
            d.polygon([at(m, side, dy0), at(m2, side, dy0), at(m2, side, dy1), at(m, side, dy1)], fill=WALL_LIT)

    # le mur du fond, ouvert par une arche plus large que le heros ; derriere, le couloir continue
    x0, y0, x1, y1 = at(1, -1, -1) + at(1, 1, 1)
    d.rectangle([x0, y0, x1, y1], fill=WALL)
    for row in range(1, 7):
        d.line([(x0, y0 + row * (y1 - y0) / 7), (x1, y0 + row * (y1 - y0) / 7)], fill=MORTAR, width=3)
    ax0, ax1, atop = 466, 814, 208
    d.pieslice([ax0, atop, ax1, atop + 180], 180, 360, fill=DEEP)
    d.rectangle([ax0, atop + 90, ax1, y1], fill=DEEP)
    inner = 0.52  # le fond du couloir qui continue, a la moitie de l'echelle
    d.polygon([(ax0, y1), (ax1, y1), at(inner, 0.62, 1), at(inner, -0.62, 1)], fill=FLOOR)
    d.polygon([(ax0 + 70, y1), (ax1 - 70, y1), at(inner, 0.3, 1), at(inner, -0.3, 1)], fill=LANE)
    for side in (-1, 1):
        edge = ax0 if side < 0 else ax1
        d.polygon([(edge, atop + 90), at(inner, side * 0.62, -0.7), at(inner, side * 0.62, 1), (edge, y1)], fill=WALL)
    # le couloir qui continue : un seul arc au fond, et le sol qui file ; les torches du fond le montrent
    far_hw, far_floor, far_top = HALF * 0.62 * inner, at(inner, 0, 1)[1], at(inner, 0, -0.7)[1]
    d.pieslice([VP[0] - far_hw, far_top, VP[0] + far_hw, far_top + far_hw * 2], 180, 360, fill=DEEP)
    d.rectangle([VP[0] - far_hw, far_top + far_hw, VP[0] + far_hw, far_floor], fill=DEEP)
    d.arc([ax0 - 16, atop - 16, ax1 + 16, atop + 196], 180, 360, fill=(58, 62, 74), width=16)
    d.rectangle([ax0 - 16, atop + 90, ax0, y1], fill=WALL_LIT)
    d.rectangle([ax1, atop + 90, ax1 + 16, y1], fill=WALL_LIT)

    # les cadres de bois, du plus lointain au plus proche : le dernier cadre les bords de l'ecran
    for m in (1.28, 1.72, 2.36):
        frame(d, m)

    # les torches : deux de part et d'autre de l'arche, dans la bande visible, deux lueurs au fond du couloir
    torches = ((418, 306, 110, 0.9), (862, 306, 110, 0.9), (524, 338, 52, 0.9), (756, 338, 52, 0.9))
    for cx, cy, radius, strength in torches:
        img = glow(img, cx, cy, radius, strength)
    d = ImageDraw.Draw(img)
    for cx, cy, radius, _ in torches:
        s = radius / 110
        d.rectangle([cx - 5 * s, cy, cx + 5 * s, cy + 34 * s], fill=IRON)
        d.polygon([(cx - 11 * s, cy), (cx + 11 * s, cy), (cx, cy - 30 * s)], fill=FLAME)

    # les chaines aux bords, une caisse et un tonneau dans les coins que la main laisse voir
    for x in (96, W - 96):
        d.line([(x, 0), (x, 250)], fill=IRON, width=7)
    d.rectangle([24, 570, 150, 700], fill=WOOD)
    d.rectangle([24, 570, 150, 584], fill=WOOD_LIT)
    d.line([(24, 570), (150, 700)], fill=WOOD_LIT, width=6)
    d.rounded_rectangle([W - 152, 560, W - 34, 704], 18, fill=WOOD)
    for y in (588, 632, 678):
        d.line([(W - 152, y), (W - 34, y)], fill=IRON, width=7)
    return img


if __name__ == "__main__":
    image = plan()
    image.save(sys.argv[1])
    if len(sys.argv) > 2:
        with_zones(image, K).convert("RGB").save(sys.argv[2])
