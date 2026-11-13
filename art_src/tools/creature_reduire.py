"""Reduit une creature deja validee, pour qu'elle paraisse plus petite devant son fond.

Regenerer avec un guide plus petit ne marche pas : le generateur deborde de son guide, et il
remplit la place liberee avec ce qu'il veut. On reduit donc la figure retenue et ses guides, puis
on la fait repeindre legerement par ComfyUI, ce qui rend au pixel art sa grille de 8 pixels.

1. La reduction, autour d'une ancre qui ne bouge pas, le milieu des pieds (en pixels de la figure) :

    python creature_reduire.py reduire <figure.png> <prefixe des guides> <prefixe de sortie> <facteur> --ancre X,Y

   Ecrit <sortie>_base.png (la figure reduite, sur son fond uni), <sortie>_pose.png et <sortie>_edges.png.

2. La repeinte, sur la meme graine et avec le meme prompt :

    python comfy_gen.py <sortie> "<prompt>" --creature --guide base --denoise 0.35 --seed <graine> --exclure "<exclusions>"

3. Le controle de la grille, qui doit etre retombee sur 8 pixels :

    python creature_reduire.py grille <image repeinte.png>

   Il affiche la nettete de la grille, en largeur et en hauteur, a cote du minimum que demande la
   mise sur la grille. Pour le Squelette, a 70 % et 0.35, elle est retombee de justesse (7,4 et 3,8,
   pour un minimum de 3 ; la Faucheuse, generee directement, atteint 30) ; a 80 % et 0.35, non.
"""
import argparse

from PIL import Image

from bg_import import MIN_SHARPNESS, grid_sharpness, lora_grid
from creature_detour import detour
from fond_uni import CELL, TOP_ROWS, median

GW, GH = 128, 192  # la grille du sprite


def shrink(im, scale, anchor, fill):
    """L'image reduite autour de l'ancre, sur une toile de meme taille."""
    ax, ay = anchor
    small = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    out = Image.new(im.mode, im.size, fill)
    out.paste(small, (round(ax - ax * scale), round(ay - ay * scale)))
    return out


def reduce(figure, guides, out, scale, anchor):
    im = Image.open(figure).convert("RGB")
    gw = im.width // CELL
    cells = im.resize((gw, im.height // CELL), Image.BOX).load()
    ground = median([cells[x, y] for x in range(gw) for y in range(TOP_ROWS)])  # le fond uni, mesure en haut
    shrink(im, scale, anchor, ground).save(out + "_base.png")
    shrink(Image.open(guides + "_pose.png").convert("RGB"), scale, anchor, (0, 0, 0)).save(out + "_pose.png")
    shrink(Image.open(guides + "_edges.png").convert("L"), scale, anchor, 0).save(out + "_edges.png")
    print(f"reduite a {scale:.0%} autour de {anchor}, sur le fond {ground}")


def check_grid(path):
    im = Image.open(path).convert("RGB")
    ok = lora_grid(im, GW, GH) is not None
    mask = detour(im)
    rows = [y for y in range(mask.height) for x in range(mask.width) if mask.getpixel((x, y))]
    height = (max(rows) - min(rows) + 1) / GH if rows else 0
    sharp = grid_sharpness(im, GW, GH)
    print(f"grille de 8 pixels : {'retombee' if ok else 'NON retombee'}, nettete {sharp[0]:.1f} en largeur et {sharp[1]:.1f} en hauteur "
          f"(minimum {MIN_SHARPNESS}) ; silhouette, ombre comprise : {height:.0%} de la hauteur")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="mode", required=True)
    r = sub.add_parser("reduire")
    r.add_argument("figure")
    r.add_argument("guides")
    r.add_argument("sortie")
    r.add_argument("facteur", type=float)
    r.add_argument("--ancre", required=True, help="X,Y : le milieu des pieds, en pixels de la figure")
    g = sub.add_parser("grille")
    g.add_argument("image")
    a = ap.parse_args()
    if a.mode == "reduire":
        reduce(a.figure, a.guides, a.sortie, a.facteur, tuple(float(v) for v in a.ancre.split(",")))
    else:
        check_grid(a.image)


if __name__ == "__main__":
    main()
