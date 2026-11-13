"""Le masque d'une creature, par le modele de detourage de ComfyUI (BiRefNet).

Le detourage par le code (creature_detour.py) compare chaque case au fond uni : il se perd quand le
generateur a tache le fond ou y a peint un sol d'un autre ton. Le modele, lui, reconnait la figure.
Il sert dans ces cas-la, en renfort :

    python comfy_masque.py <figure.png> <masque.png>
    python creature_detour.py <figure.png> <prefixe> --masque <masque.png>

Ce qu'il ne fait pas : un fond en halo (un grand disque clair derriere la creature) reste dans le
masque, le modele le prend pour un objet. Et il retire le plus souvent l'ombre peinte au sol.

ComfyUI doit tourner, avec birefnet.safetensors dans son dossier models/background_removal.
"""
import sys

from comfy_gen import run, upload

MODEL = "birefnet.safetensors"


def mask_workflow(image):
    """Le graphe ComfyUI : l'image, le modele de detourage, et son masque rendu en image (blanc sur la figure)."""
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": image}},
        "2": {"class_type": "LoadBackgroundRemovalModel", "inputs": {"bg_removal_name": MODEL}},
        "3": {"class_type": "RemoveBackground", "inputs": {"bg_removal_model": ["2", 0], "image": ["1", 0]}},
        "4": {"class_type": "MaskToImage", "inputs": {"mask": ["3", 0]}},
        "5": {"class_type": "SaveImage", "inputs": {"images": ["4", 0], "filename_prefix": "heros_draft/masque"}},
    }


if __name__ == "__main__":
    took = run(mask_workflow(upload(sys.argv[1])), sys.argv[2])
    print(f"{sys.argv[2]}  ({took:.0f} s)")
