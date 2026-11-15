"""La planche du controle en situation d'une creature (etape 7 du workflow des creatures).

Le sprite est pose sur chacun des fonds de son biome, puis dans le cadre de son tier, et a cote
d'autres creatures (les voisins) posees sur le premier fond. Le cadre est trace par frame_tier.py :
sa fenetre fait 64 x 96, la moitie du sprite, et il est donc agrandi deux fois pour l'accueillir.

Le controle juge le design seul : le calque Liseré est masque, sauf avec --avec-lisere.

    python creature_controle.py <sprite.aseprite> <tier> <planche.png>
        [--fonds <fond.aseprite> ...] [--voisins <sprite.aseprite> ...] [--avec-lisere]

Sans --fonds, les trois fonds de fenetre de la foret. La planche est agrandie trois fois.
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFont

from aseprite_io import HERE
from creature_lisere import NAME as RIM, read_layers
from frame_tier import frame

FOREST = [os.path.join(HERE, "..", "backgrounds", "windows", "forest", f"forest_window_{i}.aseprite") for i in (1, 2, 3)]
ZOOM, GAP, LABEL = 3, 20, 50  # l'agrandissement de la planche, l'espace entre deux vignettes, la hauteur des titres


def flat(path, name, hidden=()):
    """Le rendu d'un .aseprite : ses calques visibles, l'un sur l'autre."""
    layers = read_layers(path, name)
    out = Image.new("RGBA", layers[0][1].size, (0, 0, 0, 0))
    for n, im in layers:
        if n not in hidden:
            out = Image.alpha_composite(out, im)
    return out


def framed(scene, tier):
    """La vignette posee dans la fenetre du cadre de son tier, le cadre agrandi deux fois."""
    S, (wx, wy) = frame(tier)
    out = Image.new("RGBA", (S.w, S.h), (0, 0, 0, 0))
    for n in S.order:
        out = Image.alpha_composite(out, S.img[n])
    out = out.resize((S.w * 2, S.h * 2), Image.NEAREST)
    out.paste(scene, (wx * 2, wy * 2))
    return out


def sheet(tiles):
    try:
        font = ImageFont.truetype("arial.ttf", 22)
    except OSError:
        font = ImageFont.load_default()
    w = sum(t.width * ZOOM for _, t in tiles) + GAP * (len(tiles) + 1)
    h = max(t.height * ZOOM for _, t in tiles) + LABEL + GAP
    out = Image.new("RGB", (w, h), (24, 24, 28))
    d = ImageDraw.Draw(out)
    x = GAP
    for label, t in tiles:
        big = t.resize((t.width * ZOOM, t.height * ZOOM), Image.NEAREST)
        out.paste(big.convert("RGB"), (x, LABEL))
        d.text((x, 14), label, fill=(240, 240, 240), font=font)
        x += big.width + GAP
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("sprite")
    ap.add_argument("tier", type=int)
    ap.add_argument("planche")
    ap.add_argument("--fonds", nargs="+", default=FOREST, help="les fonds du biome, en .aseprite")
    ap.add_argument("--voisins", nargs="*", default=[], help="d'autres creatures a poser a cote, en .aseprite")
    ap.add_argument("--avec-lisere", action="store_true", help="garde le calque Liseré visible")
    a = ap.parse_args()
    hidden = () if a.avec_lisere else (RIM,)
    sprite = flat(a.sprite, "controle_sprite", hidden)
    backgrounds = [flat(p, f"controle_fond_{i}") for i, p in enumerate(a.fonds)]
    scenes = [Image.alpha_composite(b, sprite) for b in backgrounds]
    stem = lambda p: os.path.splitext(os.path.basename(p))[0]
    tiles = [(stem(p), s) for p, s in zip(a.fonds, scenes)]
    tiles.append((f"Cadre du tier {a.tier}", framed(scenes[0], a.tier)))
    for i, p in enumerate(a.voisins):
        tiles.append((stem(p), Image.alpha_composite(backgrounds[0], flat(p, f"controle_voisin_{i}", hidden))))
    sheet(tiles).save(a.planche)
    print(f"planche : {len(tiles)} vignettes, lisere {'visible' if a.avec_lisere else 'masque'}")


if __name__ == "__main__":
    main()
