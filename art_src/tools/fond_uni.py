"""Aplatit le fond d'une creature generee, quand le generateur ne l'a pas rendu uni.

Le generateur peine a tenir un fond uni : il lui ajoute volontiers un sol d'un autre ton. Insister
dans le prompt deforme le reste (l'ecu du Squelette s'est allonge). Le code le fait a sa place.

Le fond est pris pour deux tons : celui du haut de l'image, et celui des coins bas, ou tombe le sol.
Les cases de 8 pixels proches de l'un ou de l'autre sont du fond si elles touchent le bord, ou si
elles forment une poche d'au moins --poche cases. Dans ces cases, les pixels proches des deux tons
prennent le ton du haut ; ceux de la creature, loin des deux tons, restent tels quels, meme dans une
case de bord. Un fond d'un seul ton passe aussi. Un fond raye ou en halo n'a pas ete essaye.

    python fond_uni.py <image.png> <sortie.png> [--ecart 30] [--poche 6]
"""
import argparse
import math

from PIL import Image

CELL = 8  # la case du LoRA, en pixels
TOP_ROWS = 6  # le ton du haut : les 6 premieres rangees de cases
CORNER_COLS, CORNER_ROWS = 6, 42  # le ton du sol : 6 colonnes de chaque bord, sur les 42 dernieres rangees
PIXEL_SLACK = 15  # un pixel du fond peut s'ecarter un peu plus de son ton que la moyenne de sa case


def median(colours):
    return tuple(sorted(c[i] for c in colours)[len(colours) // 2] for i in range(3))


def background_cells(cells, gw, gh, near, pocket):
    """Les cases du fond : les groupes de cases proches des deux tons, relies au bord ou assez grands."""
    candidates = {(x, y) for y in range(gh) for x in range(gw) if near(cells[x, y])}
    background, seen = set(), set()
    for start in candidates:
        if start in seen:
            continue
        group, stack, edge = [start], [start], False
        seen.add(start)
        while stack:
            x, y = stack.pop()
            edge |= x in (0, gw - 1) or y in (0, gh - 1)
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in candidates and n not in seen:
                    seen.add(n)
                    group.append(n)
                    stack.append(n)
        if edge or len(group) >= pocket:
            background.update(group)
    return background


def flatten(im, gap, pocket):
    """L'image au fond aplati sur le ton du haut, avec les deux tons et le nombre de cases de fond."""
    gw, gh = im.width // CELL, im.height // CELL
    cells = im.resize((gw, gh), Image.BOX).load()
    top = median([cells[x, y] for x in range(gw) for y in range(TOP_ROWS)])
    corners = list(range(CORNER_COLS)) + list(range(gw - CORNER_COLS, gw))
    ground = median([cells[x, y] for x in corners for y in range(gh - CORNER_ROWS, gh)])
    background = background_cells(cells, gw, gh, lambda c: math.dist(c, top) < gap or math.dist(c, ground) < gap,
                                  pocket)
    out = im.copy()
    p = out.load()
    for cx, cy in background:
        for j in range(CELL):
            for i in range(CELL):
                x, y = cx * CELL + i, cy * CELL + j
                if math.dist(p[x, y], top) < gap + PIXEL_SLACK or math.dist(p[x, y], ground) < gap + PIXEL_SLACK:
                    p[x, y] = top
    return out, top, ground, len(background)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("image")
    ap.add_argument("sortie")
    ap.add_argument("--ecart", type=float, default=30, help="distance de couleur au-dela de laquelle une case n'est plus du fond")
    ap.add_argument("--poche", type=int, default=6, help="taille minimale, en cases, d'une poche de fond enfermee")
    a = ap.parse_args()
    out, top, ground, n = flatten(Image.open(a.image).convert("RGB"), a.ecart, a.poche)
    out.save(a.sortie)
    print(f"tons {top} et {ground}, {n} cases de fond, aplaties sur {top}")


if __name__ == "__main__":
    main()
