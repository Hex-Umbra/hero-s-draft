"""Exporte un .aseprite vers le PNG que le jeu charge : les calques visibles, aplatis.

python export_jeu.py <source.aseprite> <cible.png> [--taille LxH]

L'outil affiche les calques exportes et ceux qu'il laisse, masques, puis refuse une image dont la
taille n'est pas --taille : dans ce cas rien n'est ecrit sous la cible. Il ne convertit aucune
couleur (les cadres et les fonds restent en Apollo exact, le decor en couleurs peintes).
"""
import argparse
import os
import struct
import subprocess
import sys

import aseprite_io


def _layers(exe, source, all_layers):
    """Les noms de calques que --list-layers donne, tous ou seulement les visibles."""
    cmd = [exe, "-b"] + (["--all-layers"] if all_layers else []) + ["--list-layers", source]
    out = subprocess.run(cmd, check=True, capture_output=True).stdout.decode("utf-8")
    return [line.strip() for line in out.splitlines() if line.strip()]


def _png_size(path):
    """La taille d'un PNG, lue dans son en-tete IHDR sans decoder l'image."""
    with open(path, "rb") as f:
        head = f.read(24)
    return struct.unpack(">II", head[16:24])


def _parse_size(text):
    width, _, height = text.partition("x")
    return int(width), int(height)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("source")
    parser.add_argument("cible")
    parser.add_argument("--taille", type=_parse_size, help="la taille attendue, LxH")
    args = parser.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    exe = aseprite_io.aseprite_exe()
    exported = _layers(exe, args.source, False)
    left = [name for name in _layers(exe, args.source, True) if name not in exported]
    print("exportés :")
    for name in exported:
        print(f"  {name}")
    print("laissés, masqués :")
    for name in left or ["aucun"]:
        print(f"  {name}")

    staged = aseprite_io.work("export_jeu", os.path.basename(args.cible))
    subprocess.run([exe, "-b", args.source, "--save-as", staged], check=True)
    size = _png_size(staged)
    if args.taille and size != args.taille:
        print(f"taille refusée : {size[0]}x{size[1]} au lieu de {args.taille[0]}x{args.taille[1]}")
        return 1
    os.makedirs(os.path.dirname(os.path.abspath(args.cible)), exist_ok=True)
    os.replace(staged, args.cible)
    print(f"{args.cible} : {size[0]}x{size[1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
