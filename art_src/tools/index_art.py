"""L'index des images de art_src : ce qui existe, par categorie, avec une vignette de chacune.

Parcourt les dossiers des images — sprites/, fonds/, decors/, cadres/ — et ecrit ../INDEX.md, avec
ses vignettes dans ../apercus/. Rien n'est ecrit a la main : apres avoir ajoute, renomme ou retire
une image, on relance l'outil et l'index suit.

    python index_art.py

Une image se reconnait a son dossier et a son nom :
- un sprite : sprites/<famille>/tier_<n>/<nom>.aseprite, avec son apercu <nom>_<lieu>.aseprite ;
- un fond de fenetre : fonds/<lieu>/<nom>.aseprite ;
- un decor d'ecran : decors/<lieu>/<ecran>/<nom>_detail.aseprite ;
- un decor de la premiere methode : decors/anciens_320x180/<theme>/<nom>_detail.aseprite ;
- un cadre : cadres/<nom>.aseprite.
L'etat d'une image est la ligne « Etat » de son brief, <nom>_brief.md, quand elle en a un.
"""
import glob
import os
import re

from PIL import Image

from aseprite_io import HERE
from creature_lisere import read_layers

ART = os.path.normpath(os.path.join(HERE, ".."))
OUT, PREVIEWS = os.path.join(ART, "INDEX.md"), os.path.join(ART, "apercus")
OLD = "anciens_320x180"
BACK = (58, 62, 72)  # le fond des vignettes, derriere un sprite ou un cadre detoure
WIDTH = {"sprite": 128, "fond": 128, "decor": 320, "ancien": 320, "cadre": 96}  # la largeur d'affichage dans l'index


def rel(path):
    return os.path.relpath(path, ART).replace(os.sep, "/")


def render(path, key):
    """Le rendu d'un .aseprite, ses calques l'un sur l'autre, et le nombre de ses calques."""
    layers = read_layers(path, f"index_{key}")
    out = Image.new("RGBA", layers[0][1].size, BACK + (255,))
    for _, im in layers:
        out = Image.alpha_composite(out, im)
    return out.convert("RGB"), len(layers)


def preview(path, name, scale):
    """Ecrit la vignette d'une image, agrandie par pixels entiers ; rend son chemin, sa taille et ses calques."""
    im, count = render(path, name)
    out = os.path.join(PREVIEWS, f"{name}.png")
    im.resize((im.width * scale, im.height * scale), Image.NEAREST).save(out)
    return out, im.size, count


def state(folder, stem):
    """La ligne « Etat » du brief, et le lien vers lui ; un tiret sans brief."""
    brief = os.path.join(folder, f"{stem}_brief.md")
    if not os.path.exists(brief):
        return "—"
    text = open(brief, encoding="utf-8").read()
    found = re.search(r"^\*\*État\s*:\*\*\s*(.+)$", text, re.M)
    label = found.group(1).strip().rstrip(".") if found else "brief"
    return f"{label} — [brief]({rel(brief)})"


def cell(path, kind):
    return f'<img src="{rel(path)}" width="{WIDTH[kind]}" alt="">'


def sprites():
    rows = []
    for folder in sorted(glob.glob(os.path.join(ART, "sprites", "*", "tier_*"))):
        family, tier = folder.replace(os.sep, "/").split("/")[-2:]
        stems = sorted(os.path.basename(p)[:-9] for p in glob.glob(os.path.join(folder, "*.aseprite")))
        for stem in [s for s in stems if not any(s != o and s.startswith(o + "_") for o in stems)]:
            path = os.path.join(folder, f"{stem}.aseprite")
            alone, size, count = preview(path, f"sprite_{stem}", 2)
            cells = cell(alone, "sprite")
            for other in sorted(glob.glob(os.path.join(folder, f"{stem}_*.aseprite"))):
                place = os.path.basename(other)[len(stem) + 1:-9]
                cells += " " + cell(preview(other, f"sprite_{stem}_{place}", 2)[0], "sprite")
            rows.append(f"| {cells} | **{stem}** | {family} · {tier.replace('_', ' ')} | {size[0]} × {size[1]} · {count} calques | `{rel(path)}` | {state(folder, stem)} |")
    return rows


def windows():
    rows = []
    for path in sorted(glob.glob(os.path.join(ART, "fonds", "*", "*.aseprite"))):
        stem, place = os.path.basename(path)[:-9], os.path.basename(os.path.dirname(path))
        out, size, count = preview(path, f"fond_{stem}", 2)
        rows.append(f"| {cell(out, 'fond')} | **{stem}** | {place} | {size[0]} × {size[1]} · {count} calque{'s' if count > 1 else ''} | `{rel(path)}` | {state(os.path.dirname(path), stem)} |")
    return rows


def backdrops():
    rows = []
    for path in sorted(glob.glob(os.path.join(ART, "decors", "*", "*", "*_detail.aseprite"))):
        folder = os.path.dirname(path)
        place, screen = folder.replace(os.sep, "/").split("/")[-2:]
        if place == OLD:
            continue
        stem = os.path.basename(path)[:-16]
        out, size, count = preview(path, f"decor_{stem}", 1)
        rows.append(f"| {cell(out, 'decor')} | **{stem}** | {place} · {screen} | {size[0]} × {size[1]} · {count} calque{'s' if count > 1 else ''} | `{rel(path)}` | {state(folder, stem)} |")
    return rows


def old_backdrops():
    rows = []
    for path in sorted(glob.glob(os.path.join(ART, "decors", OLD, "*", "*_detail.aseprite"))):
        folder, stem = os.path.dirname(path), os.path.basename(path)[:-16]
        out, size, count = preview(path, f"ancien_{stem}", 2)
        rows.append(f"| {cell(out, 'ancien')} | **{stem}** | {os.path.basename(folder)} | {size[0]} × {size[1]} · {count} calques | `{rel(path)}` | {state(folder, stem)} |")
    return rows


def frames():
    rows = []
    for path in sorted(glob.glob(os.path.join(ART, "cadres", "*.aseprite"))):
        stem = os.path.basename(path)[:-9]
        out, size, count = preview(path, f"cadre_{stem}", 2)
        rows.append(f"| {cell(out, 'cadre')} | **{stem}** | {size[0]} × {size[1]} · {count} calques | `{rel(path)}` | {state(os.path.dirname(path), stem)} |")
    return rows


def table(head, rows):
    if not rows:
        return ["Aucune image pour l'instant.", ""]
    return [f"| {' | '.join(head)} |", "|" + ":---|" * len(head)] + rows + [""]


def main():
    os.makedirs(PREVIEWS, exist_ok=True)
    for old in glob.glob(os.path.join(PREVIEWS, "*.png")):
        os.remove(old)
    s, w, b, o, f = sprites(), windows(), backdrops(), old_backdrops(), frames()
    lines = [
        "# Index des images de `art_src`",
        "",
        "Tout ce que la chaîne pixel art a produit, par catégorie, avec une vignette de chaque image. **Ce fichier est écrit par un outil** : on ne le retouche pas à la main. Après avoir ajouté, renommé ou retiré une image, on le régénère depuis `art_src/tools/` :",
        "",
        "`python index_art.py`",
        "",
        "| Catégorie | Dossier | Ce que c'est | Images |",
        "|:---|:---|:---|:---|",
        f"| [Sprites](#sprites) | `sprites/<famille>/tier_<n>/` | Une créature détourée, en 128 × 192, avec son aperçu sur un fond de fenêtre | {len(s)} |",
        f"| [Fonds de fenêtre](#fonds-de-fenêtre) | `fonds/<lieu>/` | L'image derrière une créature, dans la fenêtre de son cadre, en 128 × 192 | {len(w)} |",
        f"| [Décors d'écran](#décors-décran) | `decors/<lieu>/<écran>/` | L'image derrière tout un écran, en 640 × 360 | {len(b)} |",
        f"| [Décors de la première méthode](#décors-de-la-première-méthode) | `decors/{OLD}/<thème>/` | Trois décors en 320 × 180, gardés à part : aucun n'est repris tel quel | {len(o)} |",
        f"| [Cadres](#cadres) | `cadres/` | Le cadre d'un tier d'ennemi, autour de la fenêtre | {len(f)} |",
        "",
        "Chaque image livrable est un `.aseprite`. À côté d'elle, dans son dossier : ses images sources, ses guides, et son brief quand elle en a un. Les versions remplacées sont dans [`archives/`](archives/README.md) ; les méthodes, dans [`docs/`](docs/) ; les outils et leurs commandes, dans [`tools/`](tools/README.md).",
        "",
        "## Sprites",
        "",
        "La première vignette est le sprite seul ; les suivantes, ses aperçus sur un fond de fenêtre. Méthode : [le workflow des créatures](docs/workflow_creature.md).",
        "",
        *table(["Aperçu", "Nom", "Famille · tier", "Taille", "Fichier", "État"], s),
        "## Fonds de fenêtre",
        "",
        "Méthode : [le workflow des fonds de fenêtre](docs/workflow_fond.md).",
        "",
        *table(["Aperçu", "Nom", "Lieu", "Taille", "Fichier", "État"], w),
        "## Décors d'écran",
        "",
        "Méthode : [le workflow des décors](docs/workflow_decor.md).",
        "",
        *table(["Aperçu", "Nom", "Lieu · écran", "Taille", "Fichier", "État"], b),
        "## Décors de la première méthode",
        "",
        "En 320 × 180, par la structure en calques et une seule génération. Chaque dossier porte aussi `<nom>.aseprite`, la structure rendue par le code, et ses cartes de guidage.",
        "",
        *table(["Aperçu", "Nom", "Thème", "Taille", "Fichier", "État"], o),
        "## Cadres",
        "",
        *table(["Aperçu", "Nom", "Taille", "Fichier", "État"], f),
    ]
    with open(OUT, "w", encoding="utf-8", newline="\n") as out:
        out.write("\n".join(lines).rstrip("\n") + "\n")
    print(f"{rel(OUT)} : {len(s)} sprite(s), {len(w)} fond(s) de fenetre, {len(b)} decor(s), {len(o)} ancien(s) decor(s), {len(f)} cadre(s)")


if __name__ == "__main__":
    main()
