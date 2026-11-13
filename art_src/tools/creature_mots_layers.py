"""La recette de calques par mots : SAM3 dit ce qui appartient a chaque objet, la creature ne declare que ses mots.

C'est la recette par defaut, pour toute forme de creature. Elle n'a aucun seuil de couleur a regler :
la creature declare ses calques et les mots anglais de chacun, dans <nom>_calques.json, range avec elle.

    {
      "calques": ["Ombre", "Robe", "Bouclier", "Arme", "Os"],
      "mots": {"Arme": ["staff"], "Bouclier": ["shield"], "Robe": ["clothes"], "Os": ["skeleton"]},
      "sous_le_sol": ["Arme"]
    }

- calques : du bas vers le haut. Le premier est toujours l'ombre.
- mots : pour chaque calque, les mots qui le designent. L'ordre compte : chaque calque reclame ses cases
  a son tour, et une case deja prise ne change plus de main. On va donc du plus sur au plus large :
  « skeleton » designe aussi la tenue, il passe apres « clothes ».
- sous_le_sol : les calques qui ont le droit de descendre sous la ligne de sol, comme une arme plantee.
  Tout le reste, sous la ligne de sol, est l'ombre peinte. Ces calques ne comptent pas non plus pour
  placer l'ombre du code, quand la creature n'a pas d'ombre peinte.

Une case qu'aucun mot ne reclame suit la majorite de ses voisines. Chaque calque est ensuite complete
sous les cases des calques plus hauts qu'il encadre : masquer la main laisse voir le manche qu'elle serre.

    python creature_mots_layers.py <prefixe> <sprite.aseprite> --recette <nom>_calques.json [--sol 183]
                                   [--apercu <fond.aseprite> <apercu.aseprite>]

Les mots se cherchent avant, sur une planche : python comfy_masque.py <prefixe>_cadree.png <planche.png> --mots ...
ComfyUI doit tourner, avec SAM3. Sans lui, une recette par le code reste possible : creature_squelette_layers.py.
Le deroule commun est dans creature_layers.py.
"""
import json

from comfy_masque import word_cells
from creature_layers import N8, SHADOW, run

REACH = 8  # un calque passe sous une case d'un calque plus haut s'il l'encadre a moins de 8 cases, en ligne ou en colonne


def read_recipe(path):
    with open(path, encoding="utf-8") as f:
        recipe = json.load(f)
    order, words, below = recipe["calques"], recipe["mots"], recipe.get("sous_le_sol", [])
    assert order[0] == SHADOW, f"le premier calque doit etre « {SHADOW} »"
    assert SHADOW not in words, f"« {SHADOW} » ne se designe pas par un mot : c'est ce qui passe sous la ligne de sol"
    for name in list(words) + below:
        assert name in order, f"« {name} » n'est pas dans la liste des calques"
    return order, words, below


def owners(figure, words, below, cells_of):
    """A quel calque va chaque case : {case: calque}, et le nombre de cases qu'un mot ou la ligne de sol a reclamees."""
    owner = {}
    for name, names in words.items():
        claimed = set().union(*(cells_of[w] for w in names)) & figure.cells
        for c in claimed:
            owner.setdefault(c, name)
    for c in figure.below_ground():
        if owner.get(c) not in below:
            owner[c] = SHADOW
    direct = len(owner)
    rank = list(words) + [SHADOW]  # a egalite entre voisines, le calque qui reclame le premier l'emporte
    todo = figure.cells - set(owner)
    while todo:
        grown = {}
        for c in todo:
            near = [owner[n] for n in ((c[0] + dx, c[1] + dy) for dx, dy in N8) if n in owner]
            if near:
                grown[c] = max((name for name in rank if name in near), key=near.count)
        if not grown:
            break
        owner.update(grown)
        todo -= set(grown)
    assert not todo, f"{len(todo)} cases ne touchent aucun calque : les mots ne designent rien dans la creature"
    return owner, direct


def complete(figure, owner, order):
    """Les calques, du bas vers le haut : chacun complete sous les cases des calques plus hauts qu'il encadre."""
    parts = []
    for i, name in enumerate(order):
        own = {c for c in figure.cells if owner[c] == name}
        if name == SHADOW or not own:
            parts.append((name, figure.pick(own)))
            continue
        above = {c for c in figure.cells if owner[c] in order[i + 1:]}

        def framed(c):
            side = lambda dx, dy: any((c[0] + dx * k, c[1] + dy * k) in own for k in range(1, REACH + 1))
            return (side(1, 0) and side(-1, 0)) or (side(0, 1) and side(0, -1))

        parts.append((name, figure.fill(own, own | {c for c in above if framed(c)})))
    return parts


def separate(figure, a):
    order, words, below = read_recipe(a.recette)
    cells_of = word_cells(f"{a.prefix}_cadree.png", [w for names in words.values() for w in names])
    for w, cells in cells_of.items():
        if not cells & figure.cells:
            raise SystemExit(f"le mot « {w} » ne designe rien dans la creature : le changer, ou le retirer de la recette")
    owner, direct = owners(figure, words, below, cells_of)
    print(f"{direct} cases sur {len(figure.cells)} reclamees par un mot ou par la ligne de sol ; les autres suivent leurs voisines")
    parts = complete(figure, owner, order)
    if not parts[0][1]:  # pas d'ombre peinte : le code en pose une sous ce qui repose au sol
        standing = {c for c in figure.cells if owner[c] not in below}
        parts[0] = (SHADOW, figure.cast_shadow(standing))
    return parts


def add_options(ap):
    ap.add_argument("--recette", required=True, help="la declaration de la creature : ses calques et leurs mots, en JSON")


if __name__ == "__main__":
    run(separate, add_options, __doc__.split("\n")[0])
