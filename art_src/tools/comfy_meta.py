"""Relit, ou rejoue, le graphe ComfyUI embarque dans une image generee par comfy_gen.py.

ComfyUI ecrit dans chaque PNG le graphe complet qui l'a produit : le prompt, les exclusions, la
graine, les forces et le nom des guides. L'image est donc sa propre fiche de generation.

    python comfy_meta.py lire <image.png> [<image.png> ...]

Affiche ces reglages, pour remplir le journal d'un brief ou retrouver comment une image a ete faite.

    python comfy_meta.py rejouer <image.png> <sortie.png>

Renvoie le meme graphe a ComfyUI et compare le resultat a l'image, pixel par pixel. C'est le temoin
a lancer apres une mise a jour de ComfyUI : si une figure commitee ne se rejoue plus a l'identique,
les graines retenues ne redonnent plus leurs images. Les guides doivent etre restes dans le dossier
input de ComfyUI, ou comfy_gen.py les envoie.
"""
import argparse
import json
import urllib.error

from PIL import Image, ImageChops, ImageStat

from comfy_gen import NEGATIVE, NO_FIGURES, ONE_FIGURE, run

MODES = {"heros_draft/generation": "guidee", "heros_draft/libre": "libre", "heros_draft/retouche": "retouche"}


def graph_of(path):
    meta = Image.open(path).info.get("prompt")
    if not meta:
        raise SystemExit(f"{path} : pas de graphe embarque, ce n'est pas une sortie directe de ComfyUI")
    return json.loads(meta)


def describe(path):
    """Les reglages d'une image, lus dans son graphe."""
    g = graph_of(path)
    by_class = lambda name: [n["inputs"] for _, n in sorted(g.items(), key=lambda kv: int(kv[0])) if n["class_type"] == name]
    sampler, lora = by_class("KSampler")[0], by_class("LoraLoader")[0]
    positive, negative = (n["text"] for n in by_class("CLIPTextEncode")[:2])
    for auto in (NEGATIVE + ONE_FIGURE, NEGATIVE + NO_FIGURES):  # ce que comfy_gen.py ajoute de lui-meme
        if negative.startswith(auto):
            negative = negative[len(auto):].lstrip(", ")
    lines = [f"{path} : {'x'.join(str(v) for v in Image.open(path).size)}, generation {MODES.get(by_class('SaveImage')[0]['filename_prefix'], 'inconnue')}",
             f"  prompt     : {positive}",
             f"  exclusions : {negative or '(aucune en plus de celles de comfy_gen.py)'}",
             f"  graine {sampler['seed']}, debruitage {sampler['denoise']}, LoRA {lora['strength_model']} ; "
             f"{sampler['steps']} pas, CFG {sampler['cfg']}, {sampler['sampler_name']} {sampler['scheduler']}"]
    guides = set()
    for control in by_class("ControlNetApplyAdvanced"):
        kind = g[control["control_net"][0]]["inputs"]["type"]
        image = g[g[control["image"][0]]["inputs"]["image"][0]]["inputs"]["image"]  # sous son changement de taille
        guides.add(image)
        lines.append(f"  guide {kind} : force {control['strength']}, jusqu'a {control['end_percent']:.0%} du debruitage, {image}")
    for image in (n["image"] for n in by_class("LoadImage") if n["image"] not in guides):
        lines.append(f"  image de depart, ou masque de retouche : {image}")
    return "\n".join(lines)


def replay(path, out):
    """Rejoue le graphe de l'image, et dit de combien le resultat s'ecarte de l'original."""
    try:
        took = run(graph_of(path), out)
    except urllib.error.HTTPError as e:
        raise SystemExit(f"ComfyUI refuse le graphe (un guide manque dans son dossier input ?) : {e.read().decode()[:600]}")
    a, b = Image.open(path).convert("RGB"), Image.open(out).convert("RGB")
    if a.size != b.size:
        raise SystemExit(f"rejouee en {took:.0f} s : la taille a change, {a.size} puis {b.size}")
    diff = ImageChops.difference(a, b)
    if diff.getbbox() is None:
        print(f"rejouee en {took:.0f} s : identique au pixel pres")
        return
    changed = sum(1 for v in diff.convert("L").get_flattened_data() if v) / (a.width * a.height)
    print(f"rejouee en {took:.0f} s : DIFFERENTE. Ecart moyen {sum(ImageStat.Stat(diff).mean) / 3:.2f} sur 255, "
          f"{changed:.1%} des pixels changes, dans la zone {diff.getbbox()}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="mode", required=True)
    r = sub.add_parser("lire")
    r.add_argument("images", nargs="+")
    p = sub.add_parser("rejouer")
    p.add_argument("image")
    p.add_argument("sortie")
    a = ap.parse_args()
    if a.mode == "lire":
        print("\n".join(describe(path) for path in a.images))
    else:
        replay(a.image, a.sortie)


if __name__ == "__main__":
    main()
