"""Etape 3 pour un sprite : ramene l'image generee sur la grille du sprite, en palette Apollo
exacte, retire le fond uni et decoupe le resultat selon les parties du corps.

Le generateur peint a la taille exacte de l'image guide (un multiple entier du sprite) : pas
d'alignement a chercher. Un pixel genere est garde s'il tombe dans la silhouette du rendu
de l'etape 1, elargie d'un pixel, et s'il n'a pas la couleur du fond. Il va au calque de la
partie visible a cet endroit, ou de la plus proche pour le liseré gagne autour de la silhouette.
Les autres calques gardent le rendu de l'etape 1 : masquer l'ecu laisse voir le bras derriere.

    python sprite_import.py <scene> <image generee> <sortie.aseprite> [<copie PNG de la source>]
"""
import json
import sys

from PIL import Image, ImageChops, ImageFilter

from aseprite_io import build, work, write_manifest
from bg_hall import APOLLO
from bg_import import to_grid

KEEP_BASE = ("Ombre",)  # calques gardes tels quels : le generateur ne les repeint pas


def main(scene, src_path, out_aseprite, keep_png=None):
    entry = json.load(open(work(f"{scene}_manifest.json"), encoding="utf-8"))[0]
    w, h = entry["w"], entry["h"]
    src = Image.open(src_path).convert("RGB")
    if keep_png:
        src.save(keep_png)
    scale = src.width / w
    assert abs(src.height / h - scale) < 1e-6, "l'image generee doit garder les proportions du sprite"
    img = to_grid(src, (scale, 0.0, scale, 0.0), w, h)
    base = [(e["name"], Image.open(e["png"]).convert("RGBA")) for e in entry["layers"]]
    body = [(n, im) for n, im in base if n not in KEEP_BASE]
    silhouette = Image.new("L", (w, h), 0)
    for _, im in body:
        silhouette = ImageChops.lighter(silhouette, im.getchannel("A"))
    zone = silhouette.point(lambda a: 255 if a else 0).filter(ImageFilter.MaxFilter(3))
    bg = img.getpixel((0, 0))  # le fond uni, tel que la mise sur la grille l'a rendu
    out = [(n, im.copy()) for n, im in base]
    alpha = {n: im.getchannel("A").load() for n, im in body}
    pix = {n: im.load() for n, im in out}
    ip, zp = img.load(), zone.load()
    kept = 0
    for y in range(h):
        for x in range(w):
            if not zp[x, y] or ip[x, y] == bg:
                continue
            owner = next((n for n, _ in reversed(body) if alpha[n][x, y]), None)
            if owner is None:  # juste hors de la silhouette : la partie la plus proche
                owner = next(n for n, _ in reversed(body) for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1))
                             if 0 <= x + dx < w and 0 <= y + dy < h and alpha[n][x + dx, y + dy])
            pix[owner][x, y] = ip[x, y] + (255,)
            kept += 1
    # un pixel de la silhouette d'origine que le generateur a laisse au fond devient transparent
    for y in range(h):
        for x in range(w):
            if ip[x, y] == bg:
                for n, _ in body:
                    if alpha[n][x, y]:
                        pix[n][x, y] = (0, 0, 0, 0)
    entries = []
    flat = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for i, (n, im) in enumerate(out):
        if im.getbbox() is None:
            continue
        p = work(f"{scene}_detail", "layers", f"{i:02d}.png")
        im.save(p)
        entries.append(dict(name=n, png=p))
        flat = Image.alpha_composite(flat, im)
    used = {c[:3] for c in flat.get_flattened_data() if c[3]}
    assert used <= set(APOLLO)
    manifest = [dict(out=out_aseprite, ref=work(f"{scene}_detail", "detail_ref.png"), w=w, h=h, palette=[list(c) for c in APOLLO], layers=entries)]
    flat.save(manifest[0]["ref"])
    print(f"{kept} pixels generes gardes, {len(entries)} calques, {len(used)} couleurs Apollo")
    build(write_manifest(f"{scene}_detail", manifest))


if __name__ == "__main__":
    main(*sys.argv[1:5])
