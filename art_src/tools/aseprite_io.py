"""Le pont vers Aseprite : dossier de travail, assemblage des .aseprite et controles.

Un manifeste decrit des fichiers a produire : chemin de sortie, taille, palette et calques
(un PNG RGBA par calque, du bas vers le haut). Aseprite les assemble en ligne de commande,
puis les rouvre et les aplatit pour prouver que le fichier redonne l'image prevue.
"""
import json
import os
import subprocess
from PIL import Image, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.environ.get("ART_WORK") or os.path.join(HERE, ".work")
ASEPRITE_CANDIDATES = [
    r"C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe",
    r"C:\Program Files\Aseprite\Aseprite.exe",
]


def work(*parts):
    """Un chemin dans le dossier de travail, dont le dossier parent existe."""
    p = os.path.join(WORK, *parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def aseprite_exe():
    path = os.environ.get("ASEPRITE_PATH") or next((p for p in ASEPRITE_CANDIDATES if os.path.isfile(p)), None)
    if not path or not os.path.isfile(path):
        raise SystemExit("Aseprite introuvable : definir ASEPRITE_PATH vers Aseprite.exe")
    return path


def check_independent(layers, surfaces):
    """Chaque calque qui n'est pas une surface doit pouvoir etre masque sans laisser de trou.

    layers : [(nom, image RGBA)] du bas vers le haut ; surfaces : noms autorises a laisser
    un vide quand on les masque (rien n'est dessine derriere un mur ou un sol).
    """
    for hidden, _ in layers:
        if hidden in surfaces:
            continue
        flat = Image.new("RGBA", layers[0][1].size, (0, 0, 0, 0))
        for name, im in layers:
            if name != hidden:
                flat = Image.alpha_composite(flat, im)
        assert flat.getchannel("A").getextrema()[0] == 255, f"masquer « {hidden} » laisse un trou"


def _visible(im):
    """L'image telle qu'on la voit : la couleur des pixels transparents ne compte pas."""
    im = im.convert("RGBA")
    clear = Image.new("RGBA", im.size, (0, 0, 0, 0))
    return Image.composite(im, clear, im.getchannel("A").point(lambda a: 255 if a else 0))


def build(manifest_path):
    """Assemble les fichiers du manifeste, les rouvre, et compare chacun a son image de reference."""
    exe = aseprite_exe()
    for script in ("aseprite_build.lua", "aseprite_verify.lua"):
        subprocess.run([exe, "-b", "--script-param", f"manifest={manifest_path}", "--script", os.path.join(HERE, script)], check=True)
    with open(manifest_path, encoding="utf-8") as f:
        entries = json.load(f)
    for e in entries:
        ref = _visible(Image.open(e["ref"]))
        back = _visible(Image.open(e["ref"].replace("_ref.png", "_back.png")))
        assert ref.size == back.size and ImageChops.difference(ref, back).getbbox() is None, f"{e['out']} differe de son rendu"
    print(f"{len(entries)} fichier(s) .aseprite identiques a leur rendu apres aller-retour dans Aseprite")


def write_manifest(name, entries):
    path = work(f"{name}_manifest.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=1)
    return path
