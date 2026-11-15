"""Un fond de fenetre de creature : l'image generee, ramenee sur la grille Apollo, en un calque.

Le fond est genere librement (comfy_gen.py --libre) a 8 fois la taille de la fenetre : le LoRA
pixel art y peint des cases de 8 pixels, lues une par une. Le fond reste d'un seul calque :
c'est une surface, sur laquelle le jeu greffe la creature.

    python window_import.py <image generee> <sortie.aseprite> [--taille 128x192] [--source <copie PNG>]
"""
import argparse
import shutil

from PIL import Image

from aseprite_io import build, work, write_manifest
from bg_hall import APOLLO
from bg_import import lora_grid, tidy, to_grid


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("out")
    ap.add_argument("--taille", default="128x192", help="la taille du fond, LARGEURxHAUTEUR")
    ap.add_argument("--source", default=None, help="garde une copie de l'image generee a cet endroit")
    a = ap.parse_args()
    gw, gh = (int(v) for v in a.taille.split("x"))
    src = Image.open(a.image).convert("RGB")
    t = lora_grid(src, gw, gh)
    assert t, f"la grille peinte par le LoRA ne tombe pas sur {gw} x {gh} : generer a {gw * 8} x {gh * 8}"
    img = to_grid(src, t, gw, gh, APOLLO, 0.25)
    tidy(img)
    if a.source:
        shutil.copy(a.image, a.source)
    name = "fenetre_" + a.out.replace("\\", "/").split("/")[-1].rsplit(".", 1)[0]
    layer, ref = work(name, "decor.png"), work(name, "detail_ref.png")
    img.convert("RGBA").save(layer)
    img.save(ref)
    build(write_manifest(name, [dict(out=a.out, ref=ref, w=gw, h=gh, palette=[list(c) for c in APOLLO],
                                     layers=[dict(name="Décor", png=layer)])]))


if __name__ == "__main__":
    main()
