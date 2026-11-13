"""Detoure une creature generee seule sur un fond uni, et la place dans le cadre du sprite.

1. Detourage : le fond uni est retire case par case (les cases de 8 pixels que peint le LoRA),
   chaque case comparee au fond mesure autour d'elle, pour garder une silhouette nette.
2. Placement : la creature est posee dans le cadre du sprite (128 x 192 cases), a l'echelle 1 et
   par cases entieres. Une figure generee sur une toile plus petite que le cadre y est centree,
   en bas. Les pieds vont sur la ligne de sol.

    python creature_detour.py <figure.png> <prefixe> [--sol 183] [--pieds R | --dy N] [--dx N] [--ombre-peinte] [--cadre 128x192]
                              [--masque <masque.png>]

Sans --pieds ni --dy, les pieds sont pris au bas de la silhouette. Quand le generateur a peint une
ombre au sol (--ombre-peinte), le bas de la silhouette est cette ombre : l'outil ne devine pas les
pieds. Il affiche les dernieres rangees, ou se lit la rangee des pieds, a redonner par --pieds.

Quand le fond n'est pas uni (des taches, un sol d'un autre ton), le detourage par le code se perd :
--masque prend a sa place le masque de comfy_masque.py, blanc sur la creature, ramene aux cases.

Ecrit <prefixe>_cadree.png (la figure placee, sur son fond uni), <prefixe>_silhouette.png (une case
blanche par case de la creature) et <prefixe>_detouree.png (la creature seule sur un fond vif, pour
controler le detourage a l'oeil).
"""
import argparse
import math

from PIL import Image

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


def cells_of(mask, figure):
    """Un masque en pixels (blanc sur la creature) ramene aux cases : une case est a la creature
    si le masque en couvre la moitie."""
    assert mask.size == figure.size, "le masque et la figure doivent avoir la meme taille"
    return mask.resize((figure.width // CELL, figure.height // CELL), Image.BOX).point(lambda v: 255 if v >= 128 else 0)


def place(figure, mask, frame, dx=0, dy=0):
    """La figure et sa silhouette posees dans le cadre : centrees, en bas, puis decalees de
    (dx, dy) pixels, arrondis a une case. Renvoie la figure cadree et sa silhouette, en cases."""
    gw, gh = frame
    ox, oy = (gw - mask.width) // 2 + round(dx / CELL), gh - mask.height + round(dy / CELL)
    canvas = Image.new("RGB", (gw * CELL, gh * CELL), background_colour(figure))
    canvas.paste(figure, (ox * CELL, oy * CELL))
    cells = Image.new("L", (gw, gh), 0)
    cells.paste(mask, (ox, oy))
    return canvas, cells


def rows(mask):
    """La largeur de la silhouette, en cases, pour chaque rangee qu'elle occupe."""
    mp = mask.load()
    width = {y: sum(1 for x in range(mask.width) if mp[x, y]) for y in range(mask.height)}
    return {y: n for y, n in width.items() if n}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("figure")
    ap.add_argument("prefix")
    ap.add_argument("--cadre", default="128x192", help="le cadre du sprite, en cases")
    ap.add_argument("--sol", type=int, default=183, help="la ligne de sol, la rangee ou tombent les pieds")
    ap.add_argument("--pieds", type=int, help="la rangee des pieds, lue dans une premiere passe : elle va sur la ligne de sol")
    ap.add_argument("--dx", type=int, default=0, help="un decalage horizontal, en pixels (multiple de 8)")
    ap.add_argument("--dy", type=int, help="un decalage vertical impose, en pixels (multiple de 8), a la place de --pieds")
    ap.add_argument("--ombre-peinte", action="store_true", help="le bas de la silhouette est une ombre peinte, pas les pieds")
    ap.add_argument("--masque", help="le masque de comfy_masque.py, a la place du detourage par le code")
    a = ap.parse_args()
    frame = tuple(int(v) for v in a.cadre.split("x"))
    figure = Image.open(a.figure).convert("RGB")
    assert figure.width % CELL == 0 and figure.height % CELL == 0, "la figure doit mesurer un multiple de 8 pixels"
    assert figure.width <= frame[0] * CELL and figure.height <= frame[1] * CELL, "la figure depasse le cadre"
    mask = cells_of(Image.open(a.masque).convert("L"), figure) if a.masque else detour(figure)
    natural = rows(place(figure, mask, frame)[1])  # les rangees dans le cadre, avant tout decalage vertical
    bottom = max(natural)
    if a.dy is not None:
        dy = a.dy
    elif a.pieds is not None or not a.ombre_peinte:
        dy = (a.sol - (bottom if a.pieds is None else a.pieds)) * CELL
    else:
        dy = 0
    canvas, cells = place(figure, mask, frame, a.dx, dy)
    canvas.save(f"{a.prefix}_cadree.png")
    cells.save(f"{a.prefix}_silhouette.png")
    vivid = Image.new("RGB", canvas.size, (255, 0, 255))
    Image.composite(canvas, vivid, cells.resize(canvas.size, Image.NEAREST)).save(f"{a.prefix}_detouree.png")
    placed = rows(cells)
    kept, total = sum(placed.values()), sum(natural.values())
    print(f"silhouette : {kept} cases sur {frame[0]} x {frame[1]}, rangees {min(placed)} a {max(placed)}, "
          f"{(max(placed) - min(placed) + 1) / frame[1]:.0%} de la hauteur")
    if kept < total:
        print(f"ATTENTION : {total - kept} cases de la creature sortent du cadre")
    print("bas de la silhouette avant decalage, rangee:largeur en cases : "
          + " ".join(f"{y}:{natural[y]}" for y in sorted(natural)[-12:]))
    if a.dy is None and a.pieds is None and a.ombre_peinte:
        print("ombre peinte : la rangee des pieds ne se devine pas. La lire ci-dessus, la ou la silhouette s'elargit "
              "en ombre, puis relancer avec --pieds R. Rien n'a ete decale.")
    else:
        print(f"decalage vertical : {dy:+d} px ; ligne de sol : rangee {a.sol}")


if __name__ == "__main__":
    main()
