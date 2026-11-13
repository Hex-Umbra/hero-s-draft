"""Les masques que ComfyUI tire d'une figure : la creature entiere (BiRefNet), ou ce qu'un mot designe (SAM3).

1. Le masque de la creature, pour le detourage. Le detourage par le code (creature_detour.py) compare
   chaque case au fond uni : il se perd quand le generateur a tache le fond ou y a peint un sol d'un
   autre ton. Le modele, lui, reconnait la figure :

    python comfy_masque.py <figure.png> <masque.png>
    python creature_detour.py <figure.png> <prefixe> --masque <masque.png>

   Ce qu'il ne fait pas : un fond en halo (un grand disque clair derriere la creature) reste dans le
   masque, le modele le prend pour un objet. Et il retire le plus souvent l'ombre peinte au sol.

2. Les masques par mots, pour les calques. SAM3 isole ce qu'un mot anglais designe : « scythe », « robe »,
   « shield ». C'est ce que lit la recette de calques par mots (creature_mots_layers.py). Pour chercher
   les mots d'une creature, une planche montre ce que chacun isole :

    python comfy_masque.py <prefixe>_cadree.png <planche.png> --mots scythe robe skeleton hand

   Un mot ne rend pas toujours ce qu'on attend : « bones » ne rend que le crane, « shadow » peut
   designer une lame. On regarde la planche avant d'ecrire la recette.

ComfyUI doit tourner, avec birefnet.safetensors dans models/background_removal pour le premier usage,
et sam3.1_multiplex_fp16.safetensors dans models/checkpoints pour le second.
"""
import argparse
import os

from PIL import Image

from aseprite_io import work
from comfy_gen import contact_sheet, run, upload
from creature_detour import CELL

MODEL = "birefnet.safetensors"
SAM3 = "sam3.1_multiplex_fp16.safetensors"


def mask_workflow(image):
    """Le graphe ComfyUI : l'image, le modele de detourage, et son masque rendu en image (blanc sur la figure)."""
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": image}},
        "2": {"class_type": "LoadBackgroundRemovalModel", "inputs": {"bg_removal_name": MODEL}},
        "3": {"class_type": "RemoveBackground", "inputs": {"bg_removal_model": ["2", 0], "image": ["1", 0]}},
        "4": {"class_type": "MaskToImage", "inputs": {"mask": ["3", 0]}},
        "5": {"class_type": "SaveImage", "inputs": {"images": ["4", 0], "filename_prefix": "heros_draft/masque"}},
    }


def word_workflow(image, word):
    """Le graphe ComfyUI : SAM3 segmente ce que designe `word`, et rend le masque en image."""
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": SAM3}},
        "2": {"class_type": "LoadImage", "inputs": {"image": image}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["1", 1], "text": word}},
        "4": {"class_type": "SAM3_Detect", "inputs": {"model": ["1", 0], "image": ["2", 0], "conditioning": ["3", 0], "threshold": 0.5, "refine_iterations": 2, "individual_masks": False}},
        "5": {"class_type": "MaskToImage", "inputs": {"mask": ["4", 0]}},
        "6": {"class_type": "SaveImage", "inputs": {"images": ["5", 0], "filename_prefix": "heros_draft/mot"}},
    }


def word_cells(figure_path, words):
    """Pour chaque mot, les cases de 8 pixels que SAM3 lui attribue dans la figure : {mot: {case}}.
    Une case est au mot si son masque en couvre la moitie."""
    figure = Image.open(figure_path)
    grid = figure.width // CELL, figure.height // CELL
    image = upload(figure_path)
    stem = os.path.splitext(os.path.basename(figure_path))[0]
    out = {}
    for word in words:
        path = work("masques", f"{stem}_{word.replace(' ', '_')}.png")
        run(word_workflow(image, word), path)
        cells = Image.open(path).convert("L").resize(figure.size, Image.BILINEAR).resize(grid, Image.BOX).load()
        out[word] = {(x, y) for y in range(grid[1]) for x in range(grid[0]) if cells[x, y] >= 128}
    return out


def word_sheet(figure_path, words, out_path):
    """La planche des mots : pour chacun, la figure eteinte hors de ce qu'il isole."""
    figure = Image.open(figure_path).convert("RGB")
    dim = Image.blend(figure, Image.new("RGB", figure.size, (0, 0, 0)), 0.82)
    stem = os.path.splitext(os.path.basename(figure_path))[0]
    tiles = []
    for word, cells in word_cells(figure_path, words).items():
        mask = Image.new("L", (figure.width // CELL, figure.height // CELL), 0)
        for c in cells:
            mask.putpixel(c, 255)
        view = work("masques", f"{stem}_{word.replace(' ', '_')}_vue.png")
        Image.composite(figure, dim, mask.resize(figure.size, Image.NEAREST)).save(view)
        tiles.append((f"{word} : {len(cells)} cases", view))
        print(f"{word} : {len(cells)} cases")
    contact_sheet(tiles, out_path, width=300)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("figure")
    ap.add_argument("sortie", help="le masque de la creature, ou, avec --mots, la planche des mots")
    ap.add_argument("--mots", nargs="+", help="les mots a essayer avec SAM3, a la place du masque de la creature")
    a = ap.parse_args()
    if a.mots:
        word_sheet(a.figure, a.mots, a.sortie)
        print(f"planche des mots : {a.sortie}")
    else:
        took = run(mask_workflow(upload(a.figure)), a.sortie)
        print(f"{a.sortie}  ({took:.0f} s)")


if __name__ == "__main__":
    main()
