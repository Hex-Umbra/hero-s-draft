"""La passe de detail d'un decor d'ecran : l'image d'ensemble, agrandie, repeinte tuile par tuile.

Une generation ne peint qu'une grille d'environ 160 x 90 cases (le LoRA pose des cases de 8 pixels,
le generateur compose autour d'un megapixel). Un decor plus grand se peint donc par morceaux :
l'image d'ensemble est agrandie a 8 fois la taille de la scene, decoupee en tuiles, et chaque tuile
est repeinte par ComfyUI, guidee par son morceau de la profondeur et des contours de la scene.
Voir ../docs/workflow_decor.md, etape 4. ComfyUI doit tourner, sauf pour --a-blanc et pour grille.

    python decor_tuiles.py peindre <scene> <prefixe> <image d'ensemble> "<prompt>" [options]
    python decor_tuiles.py assembler <nom> <sortie.png>
    python decor_tuiles.py grille <image.png> [--cases LxH]

<scene> est le nom du manifeste ecrit par le script de la scene (camp, hall...) : il donne la
taille de la scene et ses calques. <prefixe> est celui des fichiers de la structure :
<prefixe>_depth.png et <prefixe>_edges.png. Les tuiles vont dans .work/tuiles/<nom>/, avec leur
plan (plan.json) ; <nom> est celui de la scene, ou celui donne par --nom.

peindre repeint toutes les tuiles, ou celles nommees par --tuiles (colonne,rangee, a partir de 0),
et affiche la nettete de la grille de chacune. --mots donne un fichier de mots : le prompt de
chaque tuile reunit alors le style commun et les mots des calques qu'elle montre. --a-blanc
affiche le plan et les prompts sans rien generer.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageFilter

from aseprite_io import work
from bg_import import MIN_SHARPNESS, grid_sharpness
from comfy_gen import CONTROLS, NEGATIVE, NO_FIGURES, contact_sheet, run, upload, workflow

CELL = 8  # la case que peint le LoRA, en pixels
TILE_CONTROL = ("tile", 1.0)  # le guide de couleur : son type Union, et sa fin d'effet dans le debruitage
RESAMPLE = {"bicubique": Image.BICUBIC, "proche": Image.NEAREST}


def positions(full, tile, overlap):
    """Les origines des tuiles le long d'un axe, toutes sur un multiple d'une case.

    full, tile et overlap sont en pixels, multiples d'une case. Les tuiles sont reparties d'un bord
    a l'autre : leur recouvrement est au moins celui demande, et le meme partout a une case pres."""
    if tile >= full:
        return [0]
    n = -(-(full - overlap) // (tile - overlap))  # le nombre de tuiles, arrondi au-dessus
    return [round(i * (full - tile) / (n - 1) / CELL) * CELL for i in range(n)]


def plan_tiles(scene_size, tile_size, overlap_cells):
    """Le plan : la taille pleine (8 fois la scene) et le rectangle de chaque tuile, par (colonne, rangee)."""
    full = (scene_size[0] * CELL, scene_size[1] * CELL)
    for v in tile_size:
        if v % CELL:
            raise SystemExit(f"la taille d'une tuile doit etre un multiple de {CELL} pixels : {tile_size}")
    tile = (min(tile_size[0], full[0]), min(tile_size[1], full[1]))
    overlap = overlap_cells * CELL
    if overlap >= min(tile):
        raise SystemExit("le recouvrement doit rester plus petit que la tuile")
    xs, ys = positions(full[0], tile[0], overlap), positions(full[1], tile[1], overlap)
    tiles = {(c, r): (x, y, x + tile[0], y + tile[1]) for r, y in enumerate(ys) for c, x in enumerate(xs)}
    return full, tiles


def owned(tiles):
    """La part de chaque tuile dans l'image assemblee : dans un recouvrement, la coupe passe au
    milieu, sur une ligne de cases."""
    cols, rows = sorted({c for c, _ in tiles}), sorted({r for _, r in tiles})

    def cuts(index, axis):
        lo, hi = (0, 2) if axis == 0 else (1, 3)
        box = lambda i: tiles[(i, 0)] if axis == 0 else tiles[(0, i)]
        start = box(index)[lo]
        if index > 0:
            start += (box(index - 1)[hi] - box(index)[lo]) // 2 // CELL * CELL
        end = box(index)[hi]
        if index < (len(cols) if axis == 0 else len(rows)) - 1:
            nxt = box(index + 1)
            end = nxt[lo] + (box(index)[hi] - nxt[lo]) // 2 // CELL * CELL
        return start, end

    return {(c, r): (cuts(c, 0)[0], cuts(r, 1)[0], cuts(c, 0)[1], cuts(r, 1)[1]) for c in cols for r in rows}


def layer_shares(scene, box, full):
    """La part de chaque calque visible dans une tuile, du plus present au moins present."""
    entry = json.load(open(work(f"{scene}_manifest.json"), encoding="utf-8"))[0]
    k = full[0] / entry["w"]
    x0, y0, x1, y1 = (int(v / k) for v in box)
    alphas = [(e["name"], Image.open(e["png"]).convert("RGBA").getchannel("A").crop((x0, y0, x1, y1)).load()) for e in entry["layers"]]
    count = {}
    for y in range(y1 - y0):
        for x in range(x1 - x0):
            for name, alpha in reversed(alphas):
                if alpha[x, y]:
                    count[name] = count.get(name, 0) + 1
                    break
    total = max(1, sum(count.values()))
    return sorted(((n / total, name) for name, n in count.items()), reverse=True)


def tile_prompt(words, shares, threshold):
    """Le prompt d'une tuile : le style commun, puis les mots des calques qu'elle montre.

    Un calque sans mots n'ajoute rien ; si aucun calque nomme n'atteint le seuil, le plus
    present des calques nommes parle seul."""
    named = [(share, name) for share, name in shares if words["mots"].get(name)]
    kept = [name for share, name in named if share >= threshold] or [name for _, name in named[:1]]
    return ", ".join([words["mots"][name] for name in kept] + [words["style"]])


def thin(edges, width):
    """Les contours d'une scene font une case d'epaisseur, soit 8 pixels sur l'image pleine : trop
    pour le guide d'une tuile. On les ramene a `width` pixels, en rognant leurs deux bords."""
    lines = edges.point(lambda v: 255 if v > 127 else 0)
    for _ in range(max(0, (CELL - width) // 2)):
        lines = lines.filter(ImageFilter.MinFilter(3))
    return lines


def paint(a):
    entry = json.load(open(work(f"{a.scene}_manifest.json"), encoding="utf-8"))[0]
    scene_size = (entry["w"], entry["h"])
    name = a.nom or a.scene
    full, tiles = plan_tiles(scene_size, tuple(int(v) for v in a.tuile.split("x")), a.recouvrement)
    chosen = [tuple(int(v) for v in t.split(",")) for t in a.tuiles] if a.tuiles else sorted(tiles, key=lambda t: (t[1], t[0]))
    for t in chosen:
        if t not in tiles:
            raise SystemExit(f"pas de tuile {t[0]},{t[1]} : le plan va de 0,0 a {max(c for c, _ in tiles)},{max(r for _, r in tiles)}")
    words = json.load(open(a.mots, encoding="utf-8")) if a.mots else None
    negative = NEGATIVE + NO_FIGURES + (", " + a.exclure if a.exclure else "")
    cols, rows = len({c for c, _ in tiles}), len({r for _, r in tiles})
    print(f"scene {scene_size[0]} x {scene_size[1]} -> image pleine {full[0]} x {full[1]} ; {cols} x {rows} tuiles de "
          f"{tiles[(0, 0)][2]} x {tiles[(0, 0)][3]}, recouvrement demande {a.recouvrement} cases")

    prompts = {}
    for t in chosen:
        prompts[t] = tile_prompt(words, layer_shares(a.scene, tiles[t], full), a.seuil) if words else a.prompt
    plan = dict(scene=a.scene, full=list(full), tile=a.tuile, recouvrement=a.recouvrement, seed=a.seed, denoise=a.denoise,
                depth=a.depth, edges=a.edges, lora=a.lora, couleur=a.couleur, agrandir=a.agrandir, ensemble=os.path.abspath(a.ensemble),
                tiles={f"{c},{r}": dict(box=list(tiles[(c, r)]), prompt=prompts.get((c, r))) for c, r in tiles})
    plan_path = work("tuiles", name, "plan.json")
    if os.path.isfile(plan_path):  # une relance de quelques tuiles garde le prompt des autres
        old = json.load(open(plan_path, encoding="utf-8")).get("tiles", {})
        for key, tile in plan["tiles"].items():
            if tile["prompt"] is None and key in old and old[key]["box"] == tile["box"]:
                tile["prompt"] = old[key]["prompt"]
    if a.a_blanc:
        for t in chosen:
            print(f"tuile {t[0]},{t[1]} {tiles[t]} : {prompts[t]}")
        return
    json.dump(plan, open(plan_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    base = Image.open(a.ensemble).convert("RGB").resize(full, RESAMPLE[a.agrandir])
    depth = Image.open(f"{a.prefixe}_depth.png").convert("L").resize(full, Image.BICUBIC)
    edges = thin(Image.open(f"{a.prefixe}_edges.png").convert("L").resize(full, Image.NEAREST), a.trait)
    sheet = []
    for t in chosen:
        box = tiles[t]
        size = (box[2] - box[0], box[3] - box[1])
        stem = f"t_{t[0]}_{t[1]}"
        files = {}
        for kind, image in (("base", base), ("depth", depth), ("edges", edges)):
            files[kind] = work("tuiles", name, "guides", f"{stem}_{kind}.png")
            image.crop(box).save(files[kind])
        strengths = {"depth": a.depth, "edges": a.edges}
        controls = [(upload(files[k]), CONTROLS[k][1], strengths[k], CONTROLS[k][2]) for k in ("depth", "edges") if strengths[k] > 0]
        guide = upload(files["base"])
        if a.couleur > 0:
            controls.append((guide, TILE_CONTROL[0], a.couleur, TILE_CONTROL[1]))
        out = work("tuiles", name, f"{stem}.png")
        took = run(workflow(guide, controls, prompts[t], negative, a.seed, a.denoise, a.lora, size), out)
        sharp = grid_sharpness(Image.open(out).convert("RGB"), size[0] // CELL, size[1] // CELL)
        print(f"tuile {t[0]},{t[1]} : {out}  ({took:.0f} s) ; nettete de la grille {sharp[0]:.1f} x {sharp[1]:.1f} (minimum {MIN_SHARPNESS})")
        sheet.append((f"{t[0]},{t[1]}  {sharp[0]:.0f} x {sharp[1]:.0f}", out))
    if len(sheet) > 1:
        board = work("tuiles", name, "planche.png")
        contact_sheet(sheet, board, per_row=cols)
        print(f"planche : {board}")


def assemble(a):
    plan = json.load(open(work("tuiles", a.nom, "plan.json"), encoding="utf-8"))
    tiles = {tuple(int(v) for v in k.split(",")): tuple(t["box"]) for k, t in plan["tiles"].items()}
    missing = [t for t in tiles if not os.path.isfile(work("tuiles", a.nom, f"t_{t[0]}_{t[1]}.png"))]
    if missing:
        raise SystemExit("tuiles a peindre d'abord : " + " ".join(f"{c},{r}" for c, r in sorted(missing)))
    out = Image.new("RGB", tuple(plan["full"]))
    for t, own in owned(tiles).items():
        box = tiles[t]
        tile = Image.open(work("tuiles", a.nom, f"t_{t[0]}_{t[1]}.png")).convert("RGB")
        out.paste(tile.crop((own[0] - box[0], own[1] - box[1], own[2] - box[0], own[3] - box[1])), own[:2])
    out.save(a.sortie)
    sharp = grid_sharpness(out, out.width // CELL, out.height // CELL)
    print(f"{a.sortie} : {out.width} x {out.height}, {len(tiles)} tuiles ; nettete de la grille {sharp[0]:.1f} x {sharp[1]:.1f} (minimum {MIN_SHARPNESS})")


def grid(a):
    src = Image.open(a.image).convert("RGB")
    gw, gh = (int(v) for v in a.cases.split("x")) if a.cases else (src.width // CELL, src.height // CELL)
    sharp = grid_sharpness(src, gw, gh)
    verdict = "lisible" if min(sharp) >= MIN_SHARPNESS else "pas lisible"
    print(f"{a.image} : grille de {gw} x {gh} cases, nettete {sharp[0]:.1f} x {sharp[1]:.1f} (minimum {MIN_SHARPNESS}) : {verdict}")


def main():
    ap = argparse.ArgumentParser(description="La passe de detail d'un decor d'ecran, par tuiles.")
    sub = ap.add_subparsers(dest="commande", required=True)

    p = sub.add_parser("peindre", help="repeint les tuiles de l'image d'ensemble agrandie")
    p.add_argument("scene")
    p.add_argument("prefixe")
    p.add_argument("ensemble")
    p.add_argument("prompt")
    p.add_argument("--nom", help="le nom du dossier des tuiles, a la place de celui de la scene")
    p.add_argument("--tuiles", nargs="+", help="les tuiles a peindre, colonne,rangee (toutes par defaut)")
    p.add_argument("--tuile", default="1280x720", help="la taille d'une tuile, LARGEURxHAUTEUR (1280x720 par defaut)")
    p.add_argument("--recouvrement", type=int, default=0, help="le recouvrement de deux tuiles voisines, en cases de 8 pixels (0 par defaut)")
    p.add_argument("--seed", type=int, default=7, help="la graine, la meme pour toutes les tuiles (7 par defaut)")
    p.add_argument("--denoise", type=float, default=0.55, help="le debruitage (0.55 par defaut)")
    p.add_argument("--depth", type=float, default=0.7, help="force de la carte de profondeur (0.7 par defaut)")
    p.add_argument("--edges", type=float, default=0.45, help="force de la carte des contours (0.45 par defaut)")
    p.add_argument("--lora", type=float, default=0.9, help="force du LoRA pixel art (0.9 par defaut)")
    p.add_argument("--couleur", type=float, default=0.0, help="force du guide de couleur (ControlNet Union « tile », nourri de l'image d'ensemble ; 0 : sans)")
    p.add_argument("--agrandir", choices=sorted(RESAMPLE), default="bicubique", help="comment l'image d'ensemble est agrandie (bicubique par defaut)")
    p.add_argument("--trait", type=int, default=4, help="l'epaisseur des contours dans le guide d'une tuile, en pixels (4 par defaut)")
    p.add_argument("--mots", help="le fichier de mots : le style commun et les mots de chaque calque")
    p.add_argument("--seuil", type=float, default=0.08, help="la part d'une tuile qu'un calque doit occuper pour que ses mots comptent (0.08 par defaut)")
    p.add_argument("--exclure", default="", help="ce qui s'ajoute au prompt negatif")
    p.add_argument("--a-blanc", action="store_true", help="affiche le plan et les prompts, sans rien generer")
    p.set_defaults(run=paint)

    p = sub.add_parser("assembler", help="reunit les tuiles peintes en une image")
    p.add_argument("nom")
    p.add_argument("sortie")
    p.set_defaults(run=assemble)

    p = sub.add_parser("grille", help="mesure la nettete de la grille de 8 pixels d'une image")
    p.add_argument("image")
    p.add_argument("--cases", help="la grille attendue, LARGEURxHAUTEUR en cases (la taille de l'image divisee par 8 par defaut)")
    p.set_defaults(run=grid)

    a = ap.parse_args()
    a.run(a)


if __name__ == "__main__":
    sys.exit(main())
