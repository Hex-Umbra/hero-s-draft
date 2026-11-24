"""La passe de detail d'un decor d'ecran : l'image entiere, agrandie, repeinte d'un coup.

Une generation ne compose bien qu'autour d'un megapixel, mais elle sait repeindre une image bien
plus grande : le decor se peint donc sans tuiles, et sans raccord. L'image de depart est une
sortie de ComfyUI, l'image d'ensemble ou une repeinte precedente : son prompt, ses exclusions, sa
graine et la force du LoRA sont relus dans l'image, et repris tels quels. Voir
../docs/workflow_decor.md, etape 4. ComfyUI doit tourner.

    python decor_repeindre.py <image> <LARGEURxHAUTEUR> [--denoise D] [--contours <image>] [--force F] [--seed N] [--nom <nom>]

Le decor de 640 x 360 se peint en 5120 x 2880, huit fois sa taille : le LoRA pixel art pose des
cases de 8 pixels. Une image d'ensemble nee d'un plan en aplats passe par 2560x1440 a 0.8, qui lui
redonne sa matiere en deux minutes, puis par 5120x2880 a 0.5, en un quart d'heure : a 0.6, ce
dernier pas invente des objets ; a 0.4, il garde les gros pixels du premier. Au-dela de
2560 x 1440, l'image est encodee et decodee par morceaux, pour tenir sur une carte de 8 Go.

Un interieur ne supporte pas ce premier pas a 0.8 : ses objets comptes et ses lignes droites y
sont refaits. On le peint alors deux fois en 2560x1440 : a 0.6, ce qui tient la scene mais la laisse
lisse, puis a 0.8 avec --contours <la repeinte a 0.6>. Les contours de cette image, lus sur sa
grille, guident la repeinte (ControlNet Union) : la scene de l'une, la matiere de l'autre.

L'image arrive dans .work/comfy/, sous le nom de l'image de depart, ou celui donne par --nom, suivi
de sa taille, de sa graine et de son debruitage. L'outil affiche la nettete de sa grille, et ce
qu'il reste de celle de l'image de depart.
"""
import argparse
import os

from PIL import Image, ImageFilter

from aseprite_io import work
from bg_import import MIN_SHARPNESS, grid_sharpness
from comfy_gen import CONTROLS, run, upload, workflow
from comfy_meta import graph_of

CELL = 8  # la case que peint le LoRA, en pixels
WHOLE_VAE = 2560 * 1440  # au-dela de ce nombre de pixels, le VAE passe par morceaux
CONTOUR_THRESHOLD = 14  # l'ecart de luminosite, entre deux cases voisines, qui fait un contour
CONTOUR_WIDTH = 4  # l'epaisseur des traits de la carte des contours, en pixels de l'image peinte


def settings(path):
    """Le prompt, les exclusions, la graine et la force du LoRA de l'image, lus dans son graphe."""
    g = graph_of(path)
    by_class = lambda name: [n["inputs"] for _, n in sorted(g.items(), key=lambda kv: int(kv[0])) if n["class_type"] == name]
    prompt, negative = (n["text"] for n in by_class("CLIPTextEncode")[:2])
    return prompt, negative, by_class("KSampler")[0]["seed"], by_class("LoraLoader")[0]["strength_model"]


def contours(path, size):
    """La carte des contours d'une image generee : lus sur sa grille, rendus en traits fins a la taille visee."""
    source = Image.open(path)
    cells = (source.width // CELL, source.height // CELL)
    lines = source.convert("L").resize(cells, Image.BOX).filter(ImageFilter.FIND_EDGES).point(lambda v: 255 if v > CONTOUR_THRESHOLD else 0)
    lines = lines.crop((1, 1, cells[0] - 1, cells[1] - 1)).resize(size, Image.BICUBIC).point(lambda v: 255 if v > 127 else 0)
    for _ in range(max(0, (size[0] // cells[0] - CONTOUR_WIDTH) // 2)):
        lines = lines.filter(ImageFilter.MinFilter(3))
    return lines


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("image", help="l'image de depart, sortie de ComfyUI : l'image d'ensemble, ou une repeinte")
    ap.add_argument("taille", help="la taille a peindre, LARGEURxHAUTEUR, en multiples de 8")
    ap.add_argument("--denoise", type=float, default=0.8, help="le debruitage (0.8 par defaut ; 0.5 pour le dernier pas)")
    ap.add_argument("--contours", help="une image generee qui tient la scene : ses contours guident la repeinte")
    ap.add_argument("--force", type=float, default=0.5, help="la force du guide des contours (0.5 par defaut)")
    ap.add_argument("--seed", type=int, help="la graine (celle de l'image de depart par defaut)")
    ap.add_argument("--nom", help="le nom de l'image de sortie, a la place de celui de l'image de depart")
    a = ap.parse_args()
    size = tuple(int(v) for v in a.taille.split("x"))
    if size[0] % CELL or size[1] % CELL:
        ap.error(f"la taille doit etre en multiples de {CELL} pixels : {a.taille}")
    prompt, negative, seed, lora = settings(a.image)
    seed = a.seed if a.seed is not None else seed
    source = Image.open(a.image).size
    name = a.nom or os.path.splitext(os.path.basename(a.image))[0]
    stem = f"{name}_{size[0]}x{size[1]}"
    controls = []
    if a.contours:
        guide = work("comfy", f"{stem}_contours.png")
        contours(a.contours, size).save(guide)
        controls = [(upload(guide), CONTROLS["edges"][1], a.force, CONTROLS["edges"][2])]
    graph = workflow(upload(a.image), controls, prompt, negative, seed, a.denoise, lora, size, tiled=size[0] * size[1] > WHOLE_VAE)
    out = work("comfy", f"{stem}_s{seed}_d{a.denoise}" + (f"_c{a.force}" if a.contours else "") + ".png")
    took = run(graph, out, timeout=3600)
    painted = Image.open(out).convert("RGB")
    grid = (size[0] // CELL, size[1] // CELL)
    sharp = grid_sharpness(painted, *grid)
    print(f"{out}  ({took:.0f} s)")
    print(f"grille de {grid[0]} x {grid[1]} : nettete {sharp[0]:.1f} x {sharp[1]:.1f} (minimum {MIN_SHARPNESS})")
    if source[0] < size[0]:
        before = (source[0] // CELL, source[1] // CELL)
        left = grid_sharpness(painted, *before)
        print(f"reste de la grille de depart, {before[0]} x {before[1]} : {left[0]:.1f} x {left[1]:.1f}")


if __name__ == "__main__":
    main()
