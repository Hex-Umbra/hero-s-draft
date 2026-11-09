"""Etape 2 : fait peindre le detail par ComfyUI, en local, guide par la structure de l'etape 1.

Envoie a ComfyUI l'image guide et ses deux cartes de guidage (profondeur et contours, lues
par ControlNet Union), lance un img2img SDXL avec le LoRA pixel art, puis recupere l'image.
Bibliotheque standard seulement : ComfyUI doit tourner (http://127.0.0.1:8188).

    python comfy_gen.py ../backgrounds/steampunk/clockwork_plaza "<prompt>" [--seed N] [--denoise D]

Le premier argument est le prefixe des fichiers de l'etape 1 : <prefixe>_guide_x4.png (ou
le nom donne par --guide), <prefixe>_depth.png et <prefixe>_edges.png. --size fixe la taille de
generation : 1360x768 pour un fond, 832x1248 pour un sprite de 64 x 96. L'image generee est
ecrite dans .work/comfy/.
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
            "people, person, character, creature, deformed, lowres, jpeg artifacts, frame, border")


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


def workflow(guide, depth, edges, prompt, seed, denoise, depth_strength, edge_strength, lora_strength, size):
    """Le graphe ComfyUI, au format API : chaque noeud par son numero."""
    def scaled(node):
        return {"class_type": "ImageScale", "inputs": {"image": [node, 0], "upscale_method": "bicubic", "width": size[0], "height": size[1], "crop": "disabled"}}

    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CHECKPOINT}},
        "2": {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1], "lora_name": LORA, "strength_model": lora_strength, "strength_clip": lora_strength}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": prompt}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": NEGATIVE}},
        "5": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CONTROLNET}},
        "6": {"class_type": "SetUnionControlNetType", "inputs": {"control_net": ["5", 0], "type": "depth"}},
        "7": {"class_type": "SetUnionControlNetType", "inputs": {"control_net": ["5", 0], "type": "canny/lineart/anime_lineart/mlsd"}},
        "8": {"class_type": "LoadImage", "inputs": {"image": guide}},
        "9": {"class_type": "LoadImage", "inputs": {"image": depth}},
        "10": {"class_type": "LoadImage", "inputs": {"image": edges}},
        "11": scaled("8"),
        "12": scaled("9"),
        "13": scaled("10"),
        "14": {"class_type": "ControlNetApplyAdvanced", "inputs": {"positive": ["3", 0], "negative": ["4", 0], "control_net": ["6", 0], "image": ["12", 0], "strength": depth_strength, "start_percent": 0.0, "end_percent": 0.85, "vae": ["1", 2]}},
        "15": {"class_type": "ControlNetApplyAdvanced", "inputs": {"positive": ["14", 0], "negative": ["14", 1], "control_net": ["7", 0], "image": ["13", 0], "strength": edge_strength, "start_percent": 0.0, "end_percent": 0.6, "vae": ["1", 2]}},
        "16": {"class_type": "VAEEncode", "inputs": {"pixels": ["11", 0], "vae": ["1", 2]}},
        "17": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "positive": ["15", 0], "negative": ["15", 1], "latent_image": ["16", 0], "seed": seed, "steps": 30, "cfg": 6.5, "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": denoise}},
        "18": {"class_type": "VAEDecode", "inputs": {"samples": ["17", 0], "vae": ["1", 2]}},
        "19": {"class_type": "SaveImage", "inputs": {"images": ["18", 0], "filename_prefix": "heros_draft/generation"}},
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
    ap.add_argument("--lora", type=float, default=0.9, help="force du LoRA pixel art")
    ap.add_argument("--size", default="1360x768", help="taille de generation, LARGEURxHAUTEUR (multiples de 8)")
    ap.add_argument("--guide", default="guide_x4", help="suffixe de l'image guide")
    a = ap.parse_args()
    size = tuple(int(v) for v in a.size.split("x"))
    names = [upload(f"{a.prefix}_{k}.png") for k in (a.guide, "depth", "edges")]
    out = work("comfy", f"{os.path.basename(a.prefix)}_s{a.seed}_d{a.denoise}.png")
    took = run(workflow(*names, a.prompt, a.seed, a.denoise, a.depth, a.edges, a.lora, size), out)
    print(f"{out}  ({took:.0f} s)")


if __name__ == "__main__":
    main()
