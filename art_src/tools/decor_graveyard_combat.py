"""Le plan du decor de combat du cimetiere : des aplats poses d'apres la place de l'interface.

Le plan n'est pas le decor : c'est l'image de depart de sa passe d'ensemble, qui tient sa
composition (workflow des decors, etape 2). Il reprend l'esquisse libre retenue par le
proprietaire : un grand arbre mort a gauche, une grande lune pale a droite, des croix, un sentier
clair. Mais il les replace : sur la grille de 640 x 360, la rangee des ennemis tient de y = 14 a
126, le heros est centre en (320, 184), la main part de y = 238 entre x = 95 et 545. L'horizon et
ses tombes remontent donc dans la bande restee visible, de y = 126 a 238 ; la lune descend dans
cette bande, a droite du heros ; le tronc se range a gauche de la premiere carte.

    python decor_graveyard_combat.py ../decors/graveyard/combat/graveyard_combat_plan.png [<zones.png>]

L'image fait 1280 x 720, deux fois la grille. <zones.png> recoit le plan sous la carte des zones
de decor_controle.py : ce que l'interface recouvre.
"""
import math
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

from decor_controle import with_zones

W, H, K = 1280, 720, 2  # K : pixels du plan par pixel de la grille du decor
HORIZON = 432  # y = 216 sur la grille : les tombes se decoupent dans la bande visible
SKY_TOP, SKY_LOW, HAZE = (30, 56, 66), (46, 84, 98), (66, 106, 126)
MOON, TREE, TREE_LIT = (236, 226, 206), (36, 34, 46), (68, 64, 80)
STONE, STONE_LIT, GROUND, PATCH, PATH, DARK = (50, 52, 66), (118, 122, 136), (40, 54, 70), (78, 98, 118), (152, 132, 120), (20, 22, 34)


def cross(d, x, base, h, w, fill, lit=None):
    """Une croix de pierre sur son socle : (x, base) est le milieu de son pied."""
    t = max(4, w // 5)
    d.rectangle([x - t, base - h, x + t, base], fill=fill)
    d.rectangle([x - w // 2, base - h * 0.72 - t, x + w // 2, base - h * 0.72 + t], fill=fill)
    d.rectangle([x - w // 2, base - h * 0.14, x + w // 2, base], fill=fill)
    if lit:
        d.rectangle([x - t, base - h, x - t + 3, base], fill=lit)
        d.rectangle([x - w // 2, base - h * 0.72 - t, x + w // 2, base - h * 0.72 - t + 3], fill=lit)


def slab(d, x, base, h, w, fill, lit=None):
    """Une stele, au sommet arrondi."""
    d.rectangle([x - w // 2, base - h + w // 2, x + w // 2, base], fill=fill)
    d.pieslice([x - w // 2, base - h, x + w // 2, base - h + w], 180, 360, fill=fill)
    if lit:
        d.arc([x - w // 2, base - h, x + w // 2, base - h + w], 180, 300, fill=lit, width=3)


def limb(d, points, width, fill):
    """Une branche : une ligne brisee qui s'affine vers son bout."""
    for i in range(len(points) - 1):
        w = max(3, round(width * (1 - i / (len(points) - 1) * 0.75)))
        d.line([points[i], points[i + 1]], fill=fill, width=w)
        d.ellipse([points[i][0] - w / 2, points[i][1] - w / 2, points[i][0] + w / 2, points[i][1] + w / 2], fill=fill)


def plan():
    rnd = random.Random(11)
    img = Image.new("RGB", (W, H), SKY_TOP)
    d = ImageDraw.Draw(img)

    # le ciel de nuit : sombre en haut, plus clair vers l'horizon, puis une bande de collines lointaines
    for y in range(HORIZON):
        t = (y / HORIZON) ** 1.4
        d.line([(0, y), (W, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(SKY_TOP, SKY_LOW)))
    d.polygon([(0, HORIZON - 44), (220, HORIZON - 58), (520, HORIZON - 40), (800, HORIZON - 62), (1060, HORIZON - 46), (W, HORIZON - 56),
               (W, HORIZON), (0, HORIZON)], fill=HAZE)

    # la lune : basse, a droite du heros, dans la bande que l'interface laisse voir
    mx, my, mr = 960, 336, 74
    d.ellipse([mx - mr, my - mr, mx + mr, my + mr], fill=MOON)
    img = img.filter(ImageFilter.GaussianBlur(2))
    d = ImageDraw.Draw(img)

    # le sol : une terre froide, des plaques plus claires, un sentier pale qui s'elargit vers le bas
    d.rectangle([0, HORIZON, W, H], fill=GROUND)
    for _ in range(46):
        x, y = rnd.randint(0, W), rnd.randint(HORIZON + 14, H)
        s = (y - HORIZON) / (H - HORIZON)
        d.ellipse([x - 40 - 70 * s, y - 6 - 12 * s, x + 40 + 70 * s, y + 6 + 12 * s], fill=PATCH)
    d.polygon([(W / 2 - 22, HORIZON), (W / 2 + 26, HORIZON), (W / 2 + 170, H), (W / 2 - 150, H)], fill=PATH)

    # les tombes lointaines : une rangee basse, sur toute la largeur de l'horizon
    for x in range(40, W - 20, 46):
        x += rnd.randint(-14, 14)
        if abs(x - W / 2) < 50:
            continue
        h = rnd.randint(22, 44)
        (cross if rnd.random() < 0.4 else slab)(d, x, HORIZON + rnd.randint(2, 10), h, rnd.randint(16, 24), STONE)

    # les croix du second plan : dans la bande visible, de part et d'autre du heros
    for x, h, w in ((300, 150, 64), (470, 96, 44), (800, 110, 48), (1090, 138, 60)):
        cross(d, x, HORIZON + 34, h, w, STONE, STONE_LIT)
        d.rectangle([x - w * 0.8, HORIZON + 24, x + w * 0.8, HORIZON + 46], fill=STONE)
    for x, h, w in ((392, 62, 40), (560, 50, 36), (720, 56, 38), (1000, 60, 42)):
        slab(d, x, HORIZON + 40, h, w, STONE, STONE_LIT)

    # le grand arbre mort : le tronc a gauche de la premiere carte, les branches vers le haut
    d.polygon([(70, HORIZON + 70), (104, 250), (112, 0), (196, 0), (192, 250), (236, HORIZON + 70)], fill=TREE)
    d.polygon([(150, HORIZON + 40), (160, 250), (166, 0), (196, 0), (192, 250), (214, HORIZON + 40)], fill=TREE_LIT)
    for dx, reach in ((-120, 96), (-50, 124), (60, 124), (140, 100), (210, 84)):
        d.polygon([(124, HORIZON + 30), (184, HORIZON + 30), (153 + dx + 22, HORIZON + reach), (153 + dx - 22, HORIZON + reach)], fill=TREE)
    limb(d, [(170, 250), (250, 190), (340, 150), (430, 96), (500, 40)], 36, TREE)
    limb(d, [(250, 190), (330, 210), (410, 196), (470, 214)], 22, TREE)
    limb(d, [(340, 150), (360, 90), (400, 30)], 18, TREE)
    limb(d, [(130, 200), (70, 130), (30, 60), (0, 30)], 30, TREE)
    limb(d, [(150, 120), (230, 70), (290, 10)], 22, TREE)
    limb(d, [(70, 130), (20, 150), (0, 190)], 16, TREE)

    # les masses du premier plan : dans les coins que la main laisse voir, et au bord droit
    limb(d, [(W - 30, H), (W - 46, 520), (W - 30, 400), (W - 70, 330), (W - 100, 300)], 60, DARK)
    limb(d, [(W - 36, 420), (W, 370)], 30, DARK)
    cross(d, 1180, H - 6, 170, 76, DARK)
    slab(d, 1100, H + 10, 110, 70, DARK)
    cross(d, 70, H - 4, 150, 70, DARK)
    slab(d, 150, H + 16, 100, 64, DARK)
    for a in range(0, 360, 40):  # des pierres sombres au pied du tronc
        d.ellipse([153 + 110 * math.cos(math.radians(a)) - 26, HORIZON + 96 + 14 * math.sin(math.radians(a)) - 12,
                   153 + 110 * math.cos(math.radians(a)) + 26, HORIZON + 96 + 14 * math.sin(math.radians(a)) + 12], fill=TREE)
    return img


if __name__ == "__main__":
    image = plan()
    image.save(sys.argv[1])
    if len(sys.argv) > 2:
        with_zones(image, K).convert("RGB").save(sys.argv[2])
