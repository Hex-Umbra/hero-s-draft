"""Etape 2 : fait peindre le detail par ComfyUI, en local, guide par la structure de l'etape 1.

Envoie a ComfyUI l'image guide et ses deux cartes de guidage (profondeur et contours, lues
par ControlNet Union), lance un img2img SDXL avec le LoRA pixel art, puis recupere l'image.
Bibliotheque standard seulement : ComfyUI doit tourner (http://127.0.0.1:8188).

    python comfy_gen.py ../backgrounds/steampunk/clockwork_plaza "<prompt>" [--seed N] [--denoise D]

Le premier argument est le prefixe des fichiers de l'etape 1 : <prefixe>_guide_x4.png (ou
le nom donne par --guide), <prefixe>_depth.png et <prefixe>_edges.png. --size fixe la taille de
generation : 1360x768 pour un fond, 832x1248 pour un sprite de 64 x 96. L'image generee est
ecrite dans .work/comfy/.

Deux autres modes : --libre compose sans guide, pour explorer des idees ; --retouche repeint
seulement la bande d'un assemblage de creature_compose.py, et rend le reste a l'identique.

L'image porte le nom du prefixe, sa graine et son debruitage. Plusieurs prompts sur une meme
graine s'ecraseraient : --nom donne a chacun son propre nom d'image.
"""
import argparse
import json
import os
import time
import urllib.parse
import urllib.request
import uuid

from aseprite_io import work

HOST = os.environ.get("COMFY_HOST", "http://127.0.0.1:8188")
CHECKPOINT = "sd_xl_base_1.0.safetensors"
CONTROLNET = "controlnet-union-sdxl-1.0-promax.safetensors"
LORA = "pixel-art-xl.safetensors"
NEGATIVE = ("blurry, smooth gradients, 3d render, photo, realistic, text, letters, watermark, signature, logo, "
            "deformed, lowres, jpeg artifacts, frame, border")
NO_FIGURES = ", people, person, character, creature"  # un fond guide reste vide de personnages
ONE_FIGURE = ", duplicate, multiple figures, cropped, cut off"  # un personnage reste seul, et entier


def _post(path, data, headers):
    req = urllib.request.Request(HOST + path, data=data, headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())


def upload(path):
    """Envoie une image dans le dossier input de ComfyUI ; renvoie le nom a donner a LoadImage."""
    boundary = uuid.uuid4().hex
    name = "heros_draft_" + os.path.basename(path)
    with open(path, "rb") as f:
        payload = f.read()
    body = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue\r\n"
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{name}\"\r\n"
            f"Content-Type: image/png\r\n\r\n").encode() + payload + f"\r\n--{boundary}--\r\n".encode()
    return _post("/upload/image", body, {"Content-Type": f"multipart/form-data; boundary={boundary}"})["name"]


# les guides que lit ControlNet Union : (suffixe du fichier, type Union, fin d'effet dans le debruitage)
CONTROLS = {
    "pose": ("pose", "openpose", 0.8),
    "depth": ("depth", "depth", 0.85),
    "edges": ("edges", "canny/lineart/anime_lineart/mlsd", 0.6),
}


def workflow(guide, controls, prompt, negative, seed, denoise, lora_strength, size):
    """Le graphe ComfyUI, au format API : chaque noeud par son numero.

    controls : [(image envoyee, type Union, force, fin d'effet)], appliques l'un apres l'autre."""
    def scaled(node):
        return {"class_type": "ImageScale", "inputs": {"image": [node, 0], "upscale_method": "bicubic", "width": size[0], "height": size[1], "crop": "disabled"}}

    g = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CHECKPOINT}},
        "2": {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1], "lora_name": LORA, "strength_model": lora_strength, "strength_clip": lora_strength}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": prompt}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": negative}},
        "5": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CONTROLNET}},
        "6": {"class_type": "LoadImage", "inputs": {"image": guide}},
        "7": scaled("6"),
    }
    cond = (["3", 0], ["4", 0])
    for i, (image, kind, strength, end) in enumerate(controls):
        n = 10 + 4 * i
        g[str(n)] = {"class_type": "SetUnionControlNetType", "inputs": {"control_net": ["5", 0], "type": kind}}
        g[str(n + 1)] = {"class_type": "LoadImage", "inputs": {"image": image}}
        g[str(n + 2)] = scaled(str(n + 1))
        g[str(n + 3)] = {"class_type": "ControlNetApplyAdvanced", "inputs": {"positive": cond[0], "negative": cond[1], "control_net": [str(n), 0], "image": [str(n + 2), 0], "strength": strength, "start_percent": 0.0, "end_percent": end, "vae": ["1", 2]}}
        cond = ([str(n + 3), 0], [str(n + 3), 1])
    g["8"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["7", 0], "vae": ["1", 2]}}
    g["9"] = {"class_type": "KSampler", "inputs": {"model": ["2", 0], "positive": cond[0], "negative": cond[1], "latent_image": ["8", 0], "seed": seed, "steps": 30, "cfg": 6.5, "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": denoise}}
    g["98"] = {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}}
    g["99"] = {"class_type": "SaveImage", "inputs": {"images": ["98", 0], "filename_prefix": "heros_draft/generation"}}
    return g


def free_workflow(prompt, negative, seed, lora_strength, size):
    """Une generation libre, sans guide : le generateur compose seul, pour explorer des idees."""
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CHECKPOINT}},
        "2": {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1], "lora_name": LORA, "strength_model": lora_strength, "strength_clip": lora_strength}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": prompt}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": negative}},
        "5": {"class_type": "EmptyLatentImage", "inputs": {"width": size[0], "height": size[1], "batch_size": 1}},
        "6": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["5", 0], "seed": seed, "steps": 30, "cfg": 6.5, "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0}},
        "7": {"class_type": "VAEDecode", "inputs": {"samples": ["6", 0], "vae": ["1", 2]}},
        "8": {"class_type": "SaveImage", "inputs": {"images": ["7", 0], "filename_prefix": "heros_draft/libre"}},
    }


def touch_up_workflow(image, mask, prompt, negative, seed, denoise, lora_strength):
    """Une retouche : seule la zone blanche du masque est repeinte, le reste revient a l'identique."""
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CHECKPOINT}},
        "2": {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1], "lora_name": LORA, "strength_model": lora_strength, "strength_clip": lora_strength}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": prompt}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": negative}},
        "5": {"class_type": "LoadImage", "inputs": {"image": image}},
        "6": {"class_type": "LoadImage", "inputs": {"image": mask}},
        "7": {"class_type": "ImageToMask", "inputs": {"image": ["6", 0], "channel": "red"}},
        "8": {"class_type": "VAEEncode", "inputs": {"pixels": ["5", 0], "vae": ["1", 2]}},
        "9": {"class_type": "SetLatentNoiseMask", "inputs": {"samples": ["8", 0], "mask": ["7", 0]}},
        "10": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["9", 0], "seed": seed, "steps": 30, "cfg": 6.5, "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": denoise}},
        "11": {"class_type": "VAEDecode", "inputs": {"samples": ["10", 0], "vae": ["1", 2]}},
        "12": {"class_type": "ImageCompositeMasked", "inputs": {"destination": ["5", 0], "source": ["11", 0], "x": 0, "y": 0, "resize_source": False, "mask": ["7", 0]}},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["12", 0], "filename_prefix": "heros_draft/retouche"}},
    }


def run(graph, out_path, timeout=900):
    pid = _post("/prompt", json.dumps({"prompt": graph, "client_id": uuid.uuid4().hex}).encode(), {"Content-Type": "application/json"})["prompt_id"]
    start = time.time()
    while time.time() - start < timeout:
        with urllib.request.urlopen(f"{HOST}/history/{pid}", timeout=30) as r:
            hist = json.loads(r.read()).get(pid)
        if hist and hist.get("status", {}).get("completed"):
            img = next(i for o in hist["outputs"].values() for i in o.get("images", []))
            q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
            with urllib.request.urlopen(f"{HOST}/view?{q}", timeout=60) as r, open(out_path, "wb") as f:
                f.write(r.read())
            return time.time() - start
        if hist and hist.get("status", {}).get("status_str") == "error":
            raise SystemExit(f"ComfyUI a echoue : {json.dumps(hist['status'])[:800]}")
        time.sleep(2)
    raise SystemExit("ComfyUI n'a pas repondu a temps")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prefix")
    ap.add_argument("prompt")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--denoise", type=float, default=0.7)
    ap.add_argument("--depth", type=float, default=0.7, help="force de la carte de profondeur")
    ap.add_argument("--edges", type=float, default=0.45, help="force de la carte des contours")
    ap.add_argument("--pose", type=float, default=0.0, help="force de la carte de pose OpenPose (<prefixe>_pose.png)")
    ap.add_argument("--lora", type=float, default=0.9, help="force du LoRA pixel art")
    ap.add_argument("--size", default="1360x768", help="taille de generation, LARGEURxHAUTEUR (multiples de 8)")
    ap.add_argument("--guide", default="guide_x4", help="suffixe de l'image guide")
    ap.add_argument("--libre", action="store_true", help="sans guide : le premier argument n'est plus qu'un nom")
    ap.add_argument("--sujet", action="store_true", help="guide vers un personnage : le negatif ne refuse plus les figures")
    ap.add_argument("--retouche", action="store_true", help="repeint la bande de <prefixe>_bande.png dans <prefixe>_assemblage.png")
    ap.add_argument("--exclure", default="", help="ce qui s'ajoute au prompt negatif")
    ap.add_argument("--nom", help="le nom de l'image de sortie, a la place de celui du prefixe")
    a = ap.parse_args()
    name = a.nom or os.path.basename(a.prefix)
    size = tuple(int(v) for v in a.size.split("x"))
    negative = NEGATIVE + (ONE_FIGURE if a.libre or a.sujet or a.retouche else NO_FIGURES) + (", " + a.exclure if a.exclure else "")
    if a.retouche:
        names = [upload(f"{a.prefix}_{k}.png") for k in ("assemblage", "bande")]
        out = work("comfy", f"{name}_retouche_s{a.seed}_d{a.denoise}.png")
        took = run(touch_up_workflow(*names, a.prompt, negative, a.seed, a.denoise, a.lora), out)
    elif a.libre:
        out = work("comfy", f"{name}_libre_s{a.seed}.png")
        took = run(free_workflow(a.prompt, negative, a.seed, a.lora, size), out)
    else:
        strengths = {"pose": a.pose, "depth": a.depth, "edges": a.edges}
        controls = [(upload(f"{a.prefix}_{suffix}.png"), kind, strengths[k], end)
                    for k, (suffix, kind, end) in CONTROLS.items() if strengths[k] > 0]
        out = work("comfy", f"{name}_s{a.seed}_d{a.denoise}.png")
        took = run(workflow(upload(f"{a.prefix}_{a.guide}.png"), controls, a.prompt, negative, a.seed, a.denoise, a.lora, size), out)
    print(f"{out}  ({took:.0f} s)")


if __name__ == "__main__":
    main()
