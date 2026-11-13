"""Le decoupage d'une creature en calques : ce que toutes les formes de creature partagent.

Une recette dit quelles cases vont a quel calque, et ne contient que cela. Ce module fait le reste :
la mise sur la grille Apollo, les outils de tri que les recettes combinent, les controles et
l'ecriture des .aseprite. Deux recettes existent :

- creature_mots_layers.py, celle par defaut, pour toute forme de creature : SAM3 isole ce que
  designent les mots que la creature declare ;
- creature_squelette_layers.py, le repli sans ComfyUI : le tri par la couleur et la forme, ecrit
  pour les squelettes.

Une recette se lance comme un script :

    python creature_<recette>_layers.py <prefixe> <sprite.aseprite> [--sol 183]
                                        [--apercu <fond.aseprite> <apercu.aseprite>] [ses options]

<prefixe> est celui de creature_detour.py, dont on relit <prefixe>_cadree.png et
<prefixe>_silhouette.png. La grille se lit sur la creature elle-meme : son sprite ne depend
d'aucun fond. Sont ecrits :

- le sprite, la creature seule sur fond transparent : le livrable ;
- <prefixe>_calques.png, chaque calque seul sur un fond vif, pour le controle a l'oeil ;
- avec --apercu, la creature posee sur un fond de fenetre, au-dessus d'un calque « Décor ».

Ecrire une recette : une fonction separate(figure, options), qui renvoie les calques du bas vers le
haut, [(nom, {case: couleur})]. Ensemble, ils doivent redonner la creature, case pour case. Chaque
calque est un objet complet : fill le complete sous ceux qui le couvrent.

Toute creature a son ombre, dans le calque SHADOW, tout en bas (regle du 13/11/2026) : celle que
le generateur a peinte sous la ligne de sol, ou, s'il n'en a pas peint, celle que pose cast_shadow
sous ce qui repose au sol. Le calque se masque d'un clic : le jeu peut charger le sprite avec ou
sans son ombre, selon le fond.
"""
import argparse
import math
import os

from PIL import Image

from aseprite_io import build, check_independent, work, write_manifest
from bg_hall import APOLLO
from bg_import import MIN_SHARPNESS, _lab, grid_sharpness, lora_grid, tidy, to_grid
from creature_controle import sheet
from creature_detour import CELL
from creature_lisere import read_layers

N8 = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
N4 = [(1, 0), (-1, 0), (0, 1), (0, -1)]
SHADOW = "Ombre"  # le calque de l'ombre au sol : peinte avec la creature, ou posee par le code
DECOR = "Décor"  # le calque que l'apercu ajoute sous la creature
SHADOW_COLOUR = min(APOLLO, key=sum)  # l'ombre posee par le code : la couleur la plus sombre d'Apollo


class Figure:
    """Ce qu'une recette lit : la creature sur la grille Apollo, son image source et sa silhouette.

    cells : les cases de la creature ; colour et lab : leur couleur sur la grille ; ground : la ligne
    de sol. La grille fond ensemble des matieres que la source distingue encore : tone et core
    lisent la source."""

    def __init__(self, img, src, silhouette, ground):
        self.img, self.src, self.ground = img, src, ground
        self.gw, self.gh = img.size
        ip, sp = img.load(), silhouette.load()
        self.cells = {(x, y) for y in range(self.gh) for x in range(self.gw) if sp[x, y]}
        self.colour = {c: ip[c] for c in self.cells}
        self.lab = {c: _lab(v) for c, v in self.colour.items()}
        self._tone = None

    @property
    def tone(self):
        """La couleur de chaque case dans la source, en Lab, sur la moyenne de la case : un cuir
        marbre y reste d'un seul ton, quand la grille le disperse entre plusieurs bruns."""
        if self._tone is None:
            means = self.src.resize((self.gw, self.gh), Image.BOX).load()
            self._tone = {c: _lab(means[c]) for c in self.cells}
        return self._tone

    def core(self, test):
        """Les cases dont la moitie du coeur, dans la source, passe test(L, a, b) : la lecture
        pixel par pixel, pour une matiere que la moyenne d'une case brouillerait."""
        sp = self.src.load()
        k = self.src.width // self.gw
        span = range(k // 4, k - k // 4)
        found = set()
        for cx, cy in self.cells:
            hits = sum(bool(test(*_lab(sp[cx * k + i, cy * k + j]))) for j in span for i in span)
            if hits * 2 >= len(span) ** 2:
                found.add((cx, cy))
        return found

    def below_ground(self):
        """Les cases sous la ligne de sol : l'ombre peinte avec la creature."""
        return {c for c in self.cells if c[1] > self.ground}

    def cast_shadow(self, standing):
        """L'ombre posee par le code, pour une creature dont le generateur n'a pas peint la sienne :
        une bande pleine, d'une seule couleur, en ellipse aplatie sous `standing`, les cases qui
        reposent au sol. On n'y compte pas l'arme, qui peut descendre plus bas que les pieds."""
        feet_row = max(y for _, y in standing)
        feet = [x for x, y in standing if feet_row - 2 <= y <= feet_row]
        cx, cy = (min(feet) + max(feet)) / 2 + 0.5, feet_row + 0.5
        rx, ry = 0.674 * ((max(feet) - min(feet)) / 2 + 6), 0.674 * 3.2  # un peu plus large que l'appui, haute de quatre cases
        return {(gx, gy): SHADOW_COLOUR
                for gy in range(max(0, int(cy - ry) - 1), min(self.gh, int(cy + ry) + 2))
                for gx in range(max(0, int(cx - rx) - 1), min(self.gw, int(cx + rx) + 2))
                if math.hypot((gx + 0.5 - cx) / rx, (gy + 0.5 - cy) / ry) < 1}

    def pick(self, cells):
        """Les cases d'un calque, avec leur couleur sur la grille."""
        return {c: self.colour[c] for c in cells}

    def fill(self, own, area):
        """Le calque d'un objet complete sur `area` : chaque case manquante prend la couleur de ses
        voisines de l'objet, de proche en proche."""
        colour = self.pick(own)
        todo = set(area) - set(own)
        while todo:
            grown = {}
            for c in todo:
                near = [colour[n] for n in ((c[0] + dx, c[1] + dy) for dx, dy in N8) if n in colour]
                if near:
                    grown[c] = max(set(near), key=near.count)
            if not grown:
                break
            colour.update(grown)
            todo -= set(grown)
        return colour


def components(cells):
    """Les composantes connexes (voisinage a 4) d'un ensemble de cases, de la plus grande a la plus petite."""
    seen, comps = set(), []
    for start in cells:
        if start in seen:
            continue
        comp, stack = set(), [start]
        seen.add(start)
        while stack:
            c = stack.pop()
            comp.add(c)
            for dx, dy in N4:
                n = (c[0] + dx, c[1] + dy)
                if n in cells and n not in seen:
                    seen.add(n)
                    stack.append(n)
        comps.append(comp)
    return sorted(comps, key=len, reverse=True)


def grow(cells, k):
    """Les cases a `k` cases au plus d'un ensemble, en voisinage a 8."""
    out = set(cells)
    for _ in range(k):
        out |= {(c[0] + dx, c[1] + dy) for c in out for dx, dy in N8}
    return out


def touches(a, b):
    """Vrai si une case de `a` a une voisine (a 8) dans `b`."""
    return any((c[0] + dx, c[1] + dy) in b for c in a for dx, dy in N8)


def snap(im, t, gw, gh):
    """L'image sur la grille Apollo, en ne lisant que le coeur de chaque case du LoRA."""
    out = to_grid(im, t, gw, gh, APOLLO, 0.25)
    tidy(out)
    return out


def layer(size, colour):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    p = im.load()
    for c, v in colour.items():
        p[c] = v + (255,)
    return im


def write(name, layers, out_aseprite, surfaces):
    """Assemble le .aseprite, verifie apres aller-retour dans Aseprite."""
    check_independent(layers, surfaces)
    flat = Image.new("RGBA", layers[0][1].size, (0, 0, 0, 0))
    entries = []
    for i, (n, im) in enumerate(layers):
        p = work(name, "layers", f"{i:02d}.png")
        im.save(p)
        entries.append(dict(name=n, png=p))
        flat = Image.alpha_composite(flat, im)
    ref = work(name, "detail_ref.png")
    flat.save(ref)
    build(write_manifest(name, [dict(out=out_aseprite, ref=ref, w=flat.width, h=flat.height,
                                     palette=[list(c) for c in APOLLO], layers=entries)]))


def check_whole(figure, parts):
    """Les calques, l'un sur l'autre, doivent redonner la creature : toutes ses cases, et elles
    seules. Seule l'ombre, tout en bas, peut deborder de la silhouette : celle que pose le code."""
    assert parts and parts[0][0] == SHADOW, f"toute creature a son ombre : le premier calque doit etre « {SHADOW} »"
    seen = {}
    for _, cells in parts:
        seen.update(cells)
    assert set(seen) - set(parts[0][1]) <= figure.cells, "un calque deborde de la silhouette"
    assert figure.cells <= set(seen), "les calques ne couvrent pas toute la silhouette"
    assert all(seen[c] == figure.colour[c] for c in figure.cells), "les calques ne redonnent pas l'image"


def run(separate, add_options=None, description=None):
    """Le deroule commun a toutes les recettes : lire, mettre sur la grille, trier, controler, ecrire."""
    ap = argparse.ArgumentParser(description=description)
    ap.add_argument("prefix", help="le prefixe de creature_detour.py")
    ap.add_argument("sprite", help="le sprite a ecrire, en .aseprite")
    ap.add_argument("--sol", type=int, default=183, help="la ligne de sol : en dessous, l'ombre peinte avec la creature")
    ap.add_argument("--apercu", nargs=2, metavar=("FOND", "SORTIE"),
                    help="ecrit aussi la creature posee sur un fond de fenetre : le fond et l'apercu, en .aseprite")
    if add_options:
        add_options(ap)
    a = ap.parse_args()
    silhouette = Image.open(f"{a.prefix}_silhouette.png").convert("L")
    size = gw, gh = silhouette.size
    src = Image.open(f"{a.prefix}_cadree.png").convert("RGB")
    assert src.size == (gw * CELL, gh * CELL), "la figure cadree et sa silhouette ne vont pas ensemble"
    sharp = grid_sharpness(src, gw, gh)
    t = lora_grid(src, gw, gh)
    if not t:
        raise SystemExit(f"la creature n'a pas de grille de {CELL} pixels lisible : nettete {sharp[0]:.1f} en largeur, "
                         f"{sharp[1]:.1f} en hauteur, pour un minimum de {MIN_SHARPNESS}")
    print(f"grille de la creature : cases de {t[0]:.2f} x {t[2]:.2f} px, decalage {t[1]:+.2f} {t[3]:+.2f}, "
          f"nettete {sharp[0]:.1f} et {sharp[1]:.1f} (minimum {MIN_SHARPNESS})")
    figure = Figure(snap(src, t, gw, gh), src, silhouette, a.sol)
    parts = [(n, cells) for n, cells in separate(figure, a) if cells]
    check_whole(figure, parts)
    print(", ".join(f"{n} {len(cells)} cases" for n, cells in parts))
    creature = [(n, layer(size, cells)) for n, cells in parts]
    name = os.path.basename(a.prefix)
    vivid = Image.new("RGBA", size, (255, 0, 255, 255))
    whole = vivid
    for _, im in creature:
        whole = Image.alpha_composite(whole, im)
    sheet([("Tous les calques", whole)] + [(n, Image.alpha_composite(vivid, im)) for n, im in creature]).save(f"{a.prefix}_calques.png")
    write(name + "_sprite", creature, a.sprite, tuple(n for n, _ in creature))
    if a.apercu:
        decor = Image.new("RGBA", size, (0, 0, 0, 0))
        for _, im in read_layers(a.apercu[0], name + "_fond"):
            decor = Image.alpha_composite(decor, im)
        assert decor.size == size and decor.getchannel("A").getextrema()[0] == 255, "le fond doit couvrir tout le cadre du sprite"
        write(name + "_apercu", [(DECOR, decor)] + creature, a.apercu[1], (DECOR,))
