"""Le controle en situation d'un decor d'ecran : le decor sous un combat, a la taille du jeu.

Un decor se juge sous son interface, jamais seul. L'outil l'agrandit a la taille d'un ecran en
1080p et pose dessus un combat : une rangee d'ennemis dans les cadres de leurs tiers, sur les
fonds de fenetre du lieu, avec leurs barres et leurs languettes, le heros, et une main de cinq
cartes. Voir ../docs/workflow_decor.md, etape 6.

    python decor_controle.py <decor> <sortie.png> [--lieu forest] [--ennemis <tier>:<sprite> ...] [--zones]

<decor> est le .aseprite du decor, son PNG, ou une image generee a 8 fois sa grille — l'image
d'ensemble, une repeinte — qu'on juge ainsi avant de payer le dernier pas : elle est alors lue a
un pixel par case. Un ennemi se donne par son tier et son sprite, en .aseprite depuis art_src/ ;
« ancien:<id> » pose l'ancien sprite de assets/data/enemies/<id>/, recadre sur son illustration
(B75). Sans --ennemis, les trois creatures livrees et un ancien sprite. --zones ajoute, en voile
clair, ce que l'interface recouvre.

C'est une maquette, pas le jeu : les places viennent des maquettes du 23/11/2026 (B72, B73, B77),
les cadres sont ceux, provisoires, de frame_tier.py, et les cartes de la main sont factices. Elle
se reverifie sur le jeu une fois la vague du visuel livree.
"""
import argparse
import glob
import math
import os

from PIL import Image, ImageDraw, ImageFont

import frame_tier
from aseprite_io import HERE
from creature_lisere import read_layers

ART = os.path.join(HERE, "..")
REPO = os.path.join(ART, "..")
SCREEN = (1920, 1080)
GRID = (640, 360)  # la grille d'un decor (B74) : 3 pixels d'ecran par pixel en 1080p
U = 2              # pixels d'ecran par pixel de cadre : le palier du 1080p (B72)
ROW_Y = 227        # le centre des fenetres des ennemis
PITCH = 310        # d'une carte d'ennemi a la suivante
TIERS = {1: ((88, 120), 12), 2: ((96, 128), 16), 3: ((104, 136), 20), 4: ((112, 144), 24), 5: ((120, 152), 28)}  # B73
OLD_CROP = (308, 329, 1388, 1949)  # l'illustration d'un ancien sprite, la meme sur les quatre peintures (B75)
ZONES = {"ennemis": (40, 14, 600, 126), "heros": (285, 137, 355, 231), "main": (95, 238, 545, 360)}  # sur la grille du decor
DEFAULT_ROW = ["1:sprites/rat/tier_1/rat_geant.aseprite", "1:ancien:gobelin",
               "2:sprites/squelette/tier_2/squelette.aseprite", "3:sprites/squelette/tier_3/squelette_faucheuse.aseprite"]

RED, GREEN, CYAN = (255, 82, 82), (105, 240, 174), (0, 229, 255)
FIRE, SHOCK, FROST = ("\U0001F525", "1", RED), ("⚡", "1/3", RED), ("❄", "2/3", RED)
MIGHT, WARD = ("⚡", "+2", GREEN), ("\U0001F6E1", "3", GREEN)
# ce que chaque carte de la rangee montre, a tour de role : ses PV, son armure, ses languettes
STATES = [dict(hp="14/14", pct=1.0, right=[FIRE]), dict(hp="12/18", pct=0.67),
          dict(hp="22/30", pct=0.73, armor="6", veil=1.0, left=[WARD]), dict(hp="46/60", pct=0.77, left=[MIGHT], right=[FIRE, SHOCK, FROST])]
HAND = [("FRAPPE", (74, 28, 28)), ("DÉFENSE", (24, 40, 72)), ("ATTAQUE RAPIDE", (74, 28, 28)), ("PERCÉE", (74, 28, 28)), ("REMPART BRISÉ", (74, 28, 28))]


def font(size, name="segoeuib.ttf"):
    try:
        return ImageFont.truetype(name, size)
    except OSError:
        return ImageFont.load_default()


def flat(path, name):
    """Le rendu d'un .aseprite : ses calques, l'un sur l'autre."""
    layers = read_layers(path, name)
    out = Image.new("RGBA", layers[0][1].size, (0, 0, 0, 0))
    for _, im in layers:
        out = Image.alpha_composite(out, im)
    return out


def backdrop(path):
    """Le decor, a la taille de l'ecran. Une image generee est d'abord lue a un pixel par case."""
    im = flat(path, "controle_decor").convert("RGB") if path.lower().endswith(".aseprite") else Image.open(path).convert("RGB")
    if im.width > GRID[0]:
        im = im.resize((im.width // 8, im.height // 8), Image.BOX)
    if im.width * 9 != im.height * 16 or SCREEN[0] % im.width:
        raise SystemExit(f"{path} : {im.width} x {im.height} ne s'agrandit pas par pixels entiers a {SCREEN[0]} x {SCREEN[1]}")
    return im.resize(SCREEN, Image.NEAREST).convert("RGBA")


def tier_frame(tier):
    """Le cadre du tier, sans son fond de fenetre, a sa taille de B73.

    frame_tier.py porte encore les anciennes tailles : on lui donne celles de B73 le temps du trace."""
    old, frame_tier.TIERS = frame_tier.TIERS, TIERS
    try:
        S, _ = frame_tier.frame(tier)
    finally:
        frame_tier.TIERS = old
    out = Image.new("RGBA", (S.w, S.h), (0, 0, 0, 0))
    for n in S.order:
        if n != "Fond de fenêtre":
            out.alpha_composite(S.img[n])
    return out


def old_sprite(enemy):
    """Un ancien sprite, recadre sur son illustration et reduit a la fenetre (B75)."""
    im = Image.open(os.path.join(REPO, "assets", "data", "enemies", enemy, "sprite.png")).convert("RGBA").crop(OLD_CROP)
    w, h = 64 * U, 96 * U
    k = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


def card(tier, sprite, window, index):
    """La carte d'un ennemi : la creature sur son fond de fenetre, dans le cadre de son tier."""
    (W, H), b = TIERS[tier]
    if sprite.startswith("ancien:"):
        inner = old_sprite(sprite.split(":", 1)[1])
    else:
        inner = Image.alpha_composite(flat(window, f"controle_fond_{index}"), flat(os.path.join(ART, sprite), f"controle_ennemi_{index}"))
    out = Image.new("RGBA", (W * U, H * U), (0, 0, 0, 0))
    out.paste(inner, (b * U, b * U))
    out.alpha_composite(tier_frame(tier).resize(out.size, Image.NEAREST))
    return out


def gradient(size, stops):
    """Un degrade horizontal, d'une couleur RGBA a la suivante."""
    w, h = max(1, round(size[0])), max(1, round(size[1]))
    out = Image.new("RGBA", (w, h))
    px = out.load()
    for x in range(w):
        t = x / max(1, w - 1) * (len(stops) - 1)
        i = min(len(stops) - 2, int(t))
        col = tuple(round(p + (q - p) * (t - i)) for p, q in zip(stops[i], stops[i + 1]))
        for y in range(h):
            px[x, y] = col
    return out


def rounded(canvas, image, left, top, radius):
    """Pose une image aux coins arrondis."""
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, image.width - 1, image.height - 1], radius, fill=255)
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    layer.paste(image, (round(left), round(top)), mask)
    canvas.alpha_composite(layer)


def shadowed(d, xy, text, fnt, fill):
    """Un texte et son ombre, cale a gauche et centre en hauteur sur xy."""
    d.text((xy[0] + 1, xy[1] + 1), text, font=fnt, fill=(0, 0, 0, 255), anchor="lm")
    d.text(xy, text, font=fnt, fill=fill, anchor="lm")


def bar(canvas, left, top, width, hp, pct, armor=None, veil=0.0):
    """La barre de PV d'un ennemi, son voile d'armure et ses chiffres."""
    h = 13 * U
    rounded(canvas, Image.new("RGBA", (width, h), (0, 0, 0, 200)), left, top, 4 * U)
    rounded(canvas, gradient((width * pct - 3 * U, h - 4 * U), [(139, 0, 0, 255), (231, 76, 60, 255), (255, 118, 117, 255)]), left + 1.5 * U, top + 2 * U, 2 * U)
    if veil > 0:
        rounded(canvas, gradient((width * veil - U, h - U), [(68, 138, 255, 115), (64, 196, 255, 166)]), left + 0.5 * U, top + 0.5 * U, 3.5 * U)
    d = ImageDraw.Draw(canvas)
    fnt, icons = font(9 * U), font(8 * U, "seguiemj.ttf")
    parts = [(hp, (255, 255, 255, 255))] + ([(" \U0001F6E1 ", None), (armor, CYAN + (255,))] if armor else [])
    widths = [d.textlength(t, font=icons if col is None else fnt) for t, col in parts]
    x, y = left + (width - sum(widths)) / 2, top + h / 2
    for (text, col), w in zip(parts, widths):
        if col is None:
            d.text((x, y + U), text, font=icons, embedded_color=True, anchor="lm")
        else:
            shadowed(d, (x, y), text, fnt, col)
        x += w


def tab(canvas, side, edge_x, top, entries):
    """Une languette d'alterations ou de bonus, contre un cote du gabarit."""
    if not entries:
        return
    w, h = 30 * U, (6 + 31 * len(entries)) * U
    left = edge_x + U - w if side == "left" else edge_x - U
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle([left, top, left + w - 1, top + h - 1], 4 * U, fill=(20, 20, 30, 255), outline=(118, 103, 52, 255), width=max(1, U // 2))
    icons, values = font(14 * U, "seguiemj.ttf"), font(10 * U)
    for i, (icon, value, color) in enumerate(entries):  # une entree tient 31 pixels de cadre : l'icone sur 17, la valeur dessous
        y = top + 3 * U + i * 31 * U
        d.text((left + w / 2, y + 8.5 * U), icon, font=icons, embedded_color=True, anchor="mm")
        d.text((left + w / 2, y + 22 * U), value, font=values, fill=color + (255,), anchor="mm")


def enemy(canvas, image, tier, cx, state):
    """Une carte d'ennemi, sa barre et ses languettes, ancrees au gabarit de 88 x 120 centre sur la fenetre (B77)."""
    b = TIERS[tier][1]
    wx, wy = cx - 32 * U, ROW_Y - 48 * U
    canvas.alpha_composite(image, (wx - b * U, wy - b * U))
    bar(canvas, wx - 12 * U, wy - 29 * U, 88 * U, state["hp"], state["pct"], state.get("armor"), state.get("veil", 0))
    tab(canvas, "left", wx - 12 * U, wy - U, state.get("left", []))
    tab(canvas, "right", wx + 76 * U, wy - U, state.get("right", []))


def hero(canvas):
    im = Image.open(os.path.join(REPO, "assets", "data", "classes", "paladin", "paladin.png")).convert("RGBA")
    w, h = 211, 281
    im = im.resize((w, round(w * im.height / im.width)), Image.LANCZOS).crop((0, 0, w, h))
    left, top = SCREEN[0] // 2 - 105, 551 - 140
    canvas.alpha_composite(im, (left, top))
    ImageDraw.Draw(canvas).rectangle([left, top, left + w - 1, top + h - 1], outline=(255, 255, 255, 255), width=4)


def hand(canvas):
    """Une main de cinq cartes factices, en eventail."""
    fnt = font(13)
    for i, (name, col) in enumerate(HAND):
        tile = Image.new("RGBA", (171, 232), (0, 0, 0, 0))
        d = ImageDraw.Draw(tile)
        d.rounded_rectangle([0, 0, 170, 231], 12, fill=col + (255,), outline=(255, 255, 255, 90), width=2)
        d.text(((171 - d.textlength(name, font=fnt)) / 2, 22), name, font=fnt, fill=(255, 255, 255, 255))
        a = (i - 2) * 4.8
        tile = tile.rotate(-a, resample=Image.BICUBIC, expand=True)
        cx = SCREEN[0] / 2 + 1620 * math.sin(math.radians(a))
        cy = 832 + 1620 * (1 - math.cos(math.radians(a)))
        canvas.alpha_composite(tile, (round(cx - tile.width / 2), round(cy - tile.height / 2)))


def with_zones(image, scale):
    """L'image sous la carte des zones : ce que l'interface recouvre, en voile clair."""
    veil = Image.new("RGBA", image.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(veil)
    for x0, y0, x1, y1 in ZONES.values():
        d.rectangle([x0 * scale, y0 * scale, x1 * scale, y1 * scale], fill=(255, 255, 255, 70), outline=(255, 255, 255, 220), width=3)
    return Image.alpha_composite(image.convert("RGBA"), veil)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("decor", help="le decor : un .aseprite, un PNG, ou une image generee a 8 fois sa grille")
    ap.add_argument("sortie")
    ap.add_argument("--lieu", default="forest", help="le lieu, pour ses fonds de fenetre (forest par defaut)")
    ap.add_argument("--ennemis", nargs="+", default=DEFAULT_ROW, help="la rangee : <tier>:<sprite.aseprite depuis art_src/>, ou <tier>:ancien:<id>")
    ap.add_argument("--zones", action="store_true", help="ajoute ce que l'interface recouvre, en voile clair")
    a = ap.parse_args()
    windows = sorted(glob.glob(os.path.join(ART, "fonds", a.lieu, "*.aseprite")))
    if not windows:
        raise SystemExit(f"pas de fond de fenetre pour le lieu « {a.lieu} »")
    canvas = backdrop(a.decor)
    hero(canvas)
    hand(canvas)
    x0 = SCREEN[0] / 2 - PITCH * (len(a.ennemis) - 1) / 2
    for i, spec in enumerate(a.ennemis):
        tier, sprite = spec.split(":", 1)
        image = card(int(tier), sprite, windows[i % len(windows)], i)
        enemy(canvas, image, int(tier), round(x0 + i * PITCH), STATES[i % len(STATES)])
    if a.zones:
        canvas = with_zones(canvas, SCREEN[0] // GRID[0])
    canvas.convert("RGB").save(a.sortie)
    print(f"{a.sortie} : {len(a.ennemis)} ennemis sur {os.path.basename(a.decor)}, a {SCREEN[0]} x {SCREEN[1]}")


if __name__ == "__main__":
    main()
