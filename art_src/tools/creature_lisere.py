"""Le liseré de lumiere d'une creature : un calque a part, pose sur un .aseprite deja fait.

Quand la tenue d'une creature se perd dans les fonds de son biome, un pixel de lumiere sur son bord
exterieur la detache (workflow des creatures, etape 8). L'effet est voulu, stylise : il vit dans son
propre calque, « Liseré », tout en haut, pour qu'on puisse le masquer d'un clic. C'est la seule
lumiere de la chaine qui ne soit pas cuite dans son objet.

Le fichier est relu dans Aseprite, calque par calque : les retouches faites a la main sont gardees.
Les calques existants sont recopies a l'identique, ce que le script verifie apres coup ; seul le
liseré est (re)calcule. Le fichier est reecrit sur place.

    python creature_lisere.py <creature.aseprite> [--calque Robe] [--couleur 819796] [--sol 183]

Le liseré borde les pixels visibles du calque de la tenue (--calque) dont le voisin du dessus ou d'un
cote est hors de la silhouette. La silhouette, c'est ce calque et tous ceux qui sont au-dessus de lui :
le decor et l'ombre, dessous, n'en font pas partie. Le bas, sur une case de 8 pixels au-dessus de la
ligne de sol (--sol), n'en recoit pas : la tenue y touche le sol.
"""
import argparse
import json
import os
import subprocess

from PIL import Image, ImageChops

from aseprite_io import HERE, aseprite_exe, build, work, write_manifest
from bg_hall import APOLLO

NAME = "Liseré"
CELL = 8  # une case du LoRA


def read_layers(path, name):
    """Les calques du fichier, du bas vers le haut : [(nom, image RGBA)]."""
    listing = work(name, "calques.json")
    out = os.path.dirname(listing)
    subprocess.run([aseprite_exe(), "-b", "--script-param", f"file={os.path.abspath(path)}",
                    "--script-param", f"out={out}", "--script", os.path.join(HERE, "aseprite_export.lua")], check=True)
    with open(listing, encoding="utf-8") as f:
        names = json.load(f)
    return [(n, Image.open(os.path.join(out, f"{i:02d}.png")).convert("RGBA")) for i, n in enumerate(names)]


def visible(im):
    """L'image telle qu'on la voit : la couleur des pixels transparents ne compte pas."""
    return Image.composite(im, Image.new("RGBA", im.size, (0, 0, 0, 0)), im.getchannel("A").point(lambda v: 255 if v else 0))


def rim(layers, cloth, colour, ground):
    """Le calque du liseré : un pixel de `colour` sur le bord exterieur visible du calque `cloth`."""
    i = next(k for k, (n, _) in enumerate(layers) if n == cloth)
    above = [im for _, im in layers[i + 1:]]
    w, h = layers[i][1].size
    alpha = lambda im: im.getchannel("A").point(lambda v: 255 if v else 0)
    sil, cover = alpha(layers[i][1]), Image.new("L", (w, h), 0)
    for im in above:
        sil = ImageChops.lighter(sil, alpha(im))
        cover = ImageChops.lighter(cover, alpha(im))
    rp, sp, cp = alpha(layers[i][1]).load(), sil.load(), cover.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    for y in range(min(h, ground - CELL + 1)):
        for x in range(w):
            if not rp[x, y] or cp[x, y]:
                continue
            if any(not (0 <= x + dx < w and 0 <= y + dy < h) or not sp[x + dx, y + dy] for dx, dy in ((0, -1), (-1, 0), (1, 0))):
                op[x, y] = colour + (255,)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("aseprite")
    ap.add_argument("--calque", default="Robe", help="le calque de la tenue, qui recoit le liseré")
    ap.add_argument("--couleur", default="819796", help="la couleur du liseré, une couleur Apollo en hexadecimal")
    ap.add_argument("--sol", type=int, default=183, help="la ligne de sol des creatures")
    a = ap.parse_args()
    colour = tuple(int(a.couleur.lstrip("#")[k:k + 2], 16) for k in (0, 2, 4))
    assert list(colour) in [list(c) for c in APOLLO], f"#{a.couleur} n'est pas une couleur Apollo"
    name = os.path.splitext(os.path.basename(a.aseprite))[0] + "_lisere"
    layers = [(n, im) for n, im in read_layers(a.aseprite, name) if n != NAME]
    assert any(n == a.calque for n, _ in layers), f"pas de calque « {a.calque} » dans {a.aseprite}"
    layers.append((NAME, rim(layers, a.calque, colour, a.sol)))
    entries = []
    for k, (n, im) in enumerate(layers):
        p = work(name, "layers", f"{k:02d}.png")
        im.save(p)
        entries.append(dict(name=n, png=p))
    flat = Image.new("RGBA", layers[0][1].size, (0, 0, 0, 0))
    for _, im in layers:
        flat = Image.alpha_composite(flat, im)
    ref = work(name, "lisere_ref.png")
    flat.save(ref)
    build(write_manifest(name, [dict(out=a.aseprite, ref=ref, w=flat.width, h=flat.height,
                                     palette=[list(c) for c in APOLLO], layers=entries)]))
    back = read_layers(a.aseprite, name + "_verif")
    assert [n for n, _ in back] == [n for n, _ in layers], "les calques relus ne sont pas ceux ecrits"
    for (n, im), (_, im2) in zip(layers, back):
        assert ImageChops.difference(visible(im), visible(im2)).getbbox() is None, f"le calque « {n} » a change"
    count = sum(1 for v in layers[-1][1].getchannel("A").get_flattened_data() if v)
    print(f"{a.aseprite} : lisere de {count} pixels, {len(layers)} calques relus a l'identique")


if __name__ == "__main__":
    main()
