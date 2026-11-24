"""Le plan du decor de combat de la foret : des aplats poses d'apres la place de l'interface.

Le plan n'est pas le decor : c'est l'image de depart de sa passe d'ensemble, qui tient sa
composition (workflow des decors, essai 6). Sur la grille de 640 x 360, la rangee des ennemis
tient de y = 14 a 126, sur presque toute la largeur ; le heros est centre en (320, 184) ; la main
part de y = 238, entre x = 95 et 545. Le plan garde donc le haut calme, un fond lointain et pale,
pose les deux gros troncs aux bords de l'ecran, et le sol, son sentier et ses rochers dans le bas.

    python decor_forest_combat.py ../backgrounds/forest/combat/forest_combat_plan.png [<zones.png>]

L'image fait 1280 x 720, deux fois la grille. <zones.png> recoit le plan sous la carte des zones :
ce que l'interface recouvre.
"""
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

W, H, K = 1280, 720, 2
HORIZON = 400  # le pied du fond lointain : y = 200 sur la grille, sous la rangee des ennemis
ZONES = {"ennemis": (40, 14, 600, 126), "heros": (285, 137, 355, 231), "main": (95, 238, 545, 360)}  # sur la grille


def plan():
    rnd = random.Random(7)
    img = Image.new("RGB", (W, H), (38, 52, 60))
    d = ImageDraw.Draw(img)

    # le fond lointain : une lueur pale au centre, plus sombre vers les bords
    base, light = (40, 56, 64), (122, 146, 148)
    for x in range(W):
        t = 1 - min(1.0, abs(x - W / 2) / (W * 0.46))
        d.line([(x, 0), (x, HORIZON)], fill=tuple(round(b + (l - b) * t ** 1.6) for b, l in zip(base, light)))
    # des troncs lointains, fins et peu contrastes
    for _ in range(46):
        x = rnd.randint(150, W - 150)
        w = rnd.randint(6, 20)
        t = 1 - min(1.0, abs(x - W / 2) / (W * 0.46))
        shade = round(52 + 44 * t) - rnd.randint(0, 18)
        d.rectangle([x, 0, x + w, HORIZON + rnd.randint(-10, 20)], fill=(shade - 8, shade + 6, shade + 12))
    img = img.filter(ImageFilter.GaussianBlur(3))
    d = ImageDraw.Draw(img)

    # le sol : sombre, avec un sentier rouille qui s'elargit vers le bas, des rochers et de la mousse
    d.rectangle([0, HORIZON, W, H], fill=(34, 44, 48))
    d.polygon([(W / 2 - 40, HORIZON), (W / 2 + 50, HORIZON), (W / 2 + 330, H), (W / 2 - 300, H)], fill=(112, 70, 54))
    for _ in range(60):
        x, y = rnd.randint(120, W - 120), rnd.randint(HORIZON + 10, H - 10)
        s = (y - HORIZON) / (H - HORIZON)
        rw, rh = round(18 + 60 * s), round(10 + 30 * s)
        g = rnd.randint(70, 104)
        d.ellipse([x - rw, y - rh, x + rw, y + rh], fill=(g - 8, g + 2, g + 6))
    for _ in range(30):
        x, y = rnd.randint(140, W - 140), rnd.randint(HORIZON + 10, H - 10)
        d.ellipse([x - 44, y - 12, x + 44, y + 12], fill=(60, 78, 50))

    # les deux gros troncs, aux bords : ils cadrent l'ecran sans passer derriere les cartes
    for x0, x1, flip in ((-40, 150, 1), (W - 150, W + 40, -1)):
        d.rectangle([x0, 0, x1, HORIZON + 90], fill=(104, 54, 38))
        d.rectangle([x0 + (20 if flip > 0 else 110), 0, x0 + (70 if flip > 0 else 160), HORIZON + 90], fill=(140, 78, 48))
        cx = (x0 + x1) / 2
        for dx, reach in ((-150, 120), (-60, 170), (60, 170), (150, 120), (240 * flip, 80)):
            d.polygon([(cx - 40, HORIZON + 20), (cx + 40, HORIZON + 20), (cx + dx + 26, HORIZON + reach), (cx + dx - 26, HORIZON + reach)], fill=(104, 54, 38))
    return img


def with_zones(img):
    """Le plan sous la carte des zones : ce que l'interface recouvre, en voile clair."""
    veil = Image.new("RGBA", img.size, (0, 0, 0, 0))
    v = ImageDraw.Draw(veil)
    for x0, y0, x1, y1 in ZONES.values():
        v.rectangle([x0 * K, y0 * K, x1 * K, y1 * K], fill=(255, 255, 255, 70), outline=(255, 255, 255, 220), width=3)
    return Image.alpha_composite(img.convert("RGBA"), veil).convert("RGB")


if __name__ == "__main__":
    image = plan()
    image.save(sys.argv[1])
    if len(sys.argv) > 2:
        with_zones(image).save(sys.argv[2])
