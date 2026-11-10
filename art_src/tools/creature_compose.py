"""Assemble une creature generee seule sur un fond uni avec un decor genere a part.

1. Detourage : le fond uni de la creature est retire, case par case (les cases de 8 pixels
   que peint le LoRA), pour garder une silhouette nette.
2. Assemblage : la creature est posee sur le decor, a l'echelle 1, pour que les cases des
   deux images restent alignees. Son ombre au sol est posee par le code, sous les pieds.
3. Masque de retouche : une bande autour de la silhouette, que ComfyUI peut repeindre pour
   fondre les bords dans la lumiere du decor (comfy_gen.py --retouche).

    python creature_compose.py <creature.png> <decor.png> <prefixe de sortie> [--dx N] [--dy N] [--ombre-peinte]

Ecrit <prefixe>_assemblage.png, <prefixe>_silhouette.png (une case blanche par case de la
creature) et <prefixe>_bande.png (le masque de retouche).
"""
import argparse
import math

from PIL import Image, ImageChops, ImageFilter

CELL = 8  # la taille des cases peintes par le LoRA pixel art


def background_colour(im):
    """La couleur du fond uni : la mediane des pixels du bord."""
    w, h = im.size
    px = im.load()
    border = [px[x, y] for x in range(0, w, 4) for y in (0, h - 1)] + [px[x, y] for y in range(0, h, 4) for x in (0, w - 1)]
    return tuple(sorted(c[i] for c in border)[len(border) // 2] for i in range(3))


def _far_cells(im, field, threshold):
    """Les cases dont la moitie des pixels s'ecarte nettement du fond attendu a cet endroit."""
    px = im.load()
    gw, gh = im.width // CELL, im.height // CELL
    cells = set()
    for cy in range(gh):
        for cx in range(gw):
            bg = field(cx, cy)
            far = sum(math.dist(px[cx * CELL + i, cy * CELL + j], bg) > threshold for i in range(CELL) for j in range(CELL))
            if far * 2 >= CELL * CELL:
                cells.add((cx, cy))
    return cells


def _local_background(im, figure, radius=8):
    """La couleur du fond autour de chaque case : la moyenne des cases de fond voisines.
    Un fond « uni » genere n'est jamais tout a fait uni : il s'eclaircit ou s'assombrit par zones."""
    gw, gh = im.width // CELL, im.height // CELL
    means = im.resize((gw, gh), Image.BOX).load()
    fallback = background_colour(im)
    field = {}
    for cy in range(gh):
        for cx in range(gw):
            near = [means[x, y] for y in range(max(0, cy - radius), min(gh, cy + radius + 1))
                    for x in range(max(0, cx - radius), min(gw, cx + radius + 1)) if (x, y) not in figure]
            field[cx, cy] = tuple(sum(c[i] for c in near) / len(near) for i in range(3)) if near else fallback
    return field


def detour(im, threshold=28, max_hole=16):
    """La silhouette, une valeur par case : une case appartient a la creature si la moitie
    de ses pixels s'ecarte nettement du fond. Un premier passage compare au fond moyen ; le
    second, au fond local, mesure autour de chaque case. Les petits ilots isoles sont du bruit."""
    gw, gh = im.width // CELL, im.height // CELL
    bg = background_colour(im)
    rough = _far_cells(im, lambda cx, cy: bg, threshold)
    field = _local_background(im, rough)
    cells = _far_cells(im, lambda cx, cy: field[cx, cy], threshold)
    kept, seen = set(), set()
    for start in cells:
        if start in seen:
            continue
        comp, stack = [], [start]
        seen.add(start)
        while stack:
            c = stack.pop()
            comp.append(c)
            for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (c[0] + d[0], c[1] + d[1])
                if n in cells and n not in seen:
                    seen.add(n)
                    stack.append(n)
        if len(comp) >= 20:
            kept.update(comp)
    # un petit trou ferme est une case de la creature trop proche du fond (un gris d'os) : on le
    # bouche. Un grand trou ferme est du vrai fond, entoure par la creature (sous la lame d'une faux).
    holes, seen = [], set(kept)
    for start in ((x, y) for y in range(gh) for x in range(gw)):
        if start in seen:
            continue
        comp, stack, edge = [start], [start], False
        seen.add(start)
        while stack:
            x, y = stack.pop()
            edge |= x in (0, gw - 1) or y in (0, gh - 1)
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= n[0] < gw and 0 <= n[1] < gh and n not in seen:
                    seen.add(n)
                    comp.append(n)
                    stack.append(n)
        if not edge and len(comp) <= max_hole:
            holes.extend(comp)
    kept.update(holes)
    mask = Image.new("L", (gw, gh), 0)
    mp = mask.load()
    for c in kept:
        mp[c] = 255
    return mask


def ground_shadow(decor, mask, dx, dy):
    """L'ombre au sol, posee par le code sous les pieds : chaque case du decor dans une
    ellipse aplatie est assombrie, plus fort au centre. Renvoie le decor ombre."""
    mp = mask.load()
    gw, gh = mask.size
    feet_row = max(y for y in range(gh) for x in range(gw) if mp[x, y])
    feet = [x for y in range(feet_row - 2, feet_row + 1) for x in range(gw) if mp[x, y]]
    cx, cy = (min(feet) + max(feet)) / 2 + dx / CELL, feet_row + 0.5 + dy / CELL
    rx, ry = (max(feet) - min(feet)) / 2 + 6, 3.2
    out = decor.copy()
    dp, op = decor.load(), out.load()
    for gy in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for gx in range(int(cx - rx) - 1, int(cx + rx) + 2):
            r = math.hypot((gx + 0.5 - cx) / rx, (gy + 0.5 - cy) / ry)
            if r >= 1:
                continue
            k = 1 - 0.55 * (1 - r ** 2)  # le facteur d'assombrissement, 0.45 au centre
            for j in range(CELL):
                for i in range(CELL):
                    x, y = gx * CELL + i, gy * CELL + j
                    if 0 <= x < out.width and 0 <= y < out.height:
                        op[x, y] = tuple(int(v * k) for v in dp[x, y])
    return out


def compose(creature, decor, dx=0, dy=0, shadow=True):
    """La creature posee sur le decor, avec son ombre au sol si `shadow` (sinon, la creature
    porte deja la sienne, peinte par le generateur). Le decalage est arrondi a une case pres."""
    assert creature.size == decor.size, "la creature et le decor doivent avoir la meme taille"
    dx, dy = round(dx / CELL) * CELL, round(dy / CELL) * CELL
    mask = detour(creature)
    full = mask.resize(creature.size, Image.NEAREST)
    shadowed = ground_shadow(decor, mask, dx, dy) if shadow else decor
    moved = ImageChops.offset(creature, dx, dy)
    moved_mask = ImageChops.offset(full, dx, dy)
    out = Image.composite(moved, shadowed, moved_mask)
    cell_mask = ImageChops.offset(mask, dx // CELL, dy // CELL)
    return out, cell_mask


def band(cell_mask, outside=2):
    """Le masque de retouche : les cases a moins de `outside` cases hors de la silhouette.
    La creature elle-meme n'est jamais repeinte : la lame d'une faux, fine, y passerait toute."""
    grow = cell_mask.filter(ImageFilter.MaxFilter(2 * outside + 1))
    return ImageChops.subtract(grow, cell_mask)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("creature")
    ap.add_argument("decor")
    ap.add_argument("prefix")
    ap.add_argument("--dx", type=int, default=0)
    ap.add_argument("--dy", type=int, default=0)
    ap.add_argument("--ombre-peinte", action="store_true", help="la creature porte deja son ombre : le code n'en ajoute pas")
    a = ap.parse_args()
    creature = Image.open(a.creature).convert("RGB")
    decor = Image.open(a.decor).convert("RGB")
    out, cell_mask = compose(creature, decor, a.dx, a.dy, not a.ombre_peinte)
    out.save(f"{a.prefix}_assemblage.png")
    cell_mask.save(f"{a.prefix}_silhouette.png")
    band(cell_mask).resize(out.size, Image.NEAREST).save(f"{a.prefix}_bande.png")
    print(f"silhouette : {sum(1 for v in cell_mask.get_flattened_data() if v)} cases sur {cell_mask.width} x {cell_mask.height}")


if __name__ == "__main__":
    main()
