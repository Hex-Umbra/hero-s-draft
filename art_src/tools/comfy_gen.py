"""Etape 2 : fait peindre le detail par ComfyUI, en local, guide par la structure de l'etape 1.

Envoie a ComfyUI l'image guide et ses cartes de guidage (profondeur, contours, pose, lues par
ControlNet Union), lance un img2img SDXL avec le LoRA pixel art, puis recupere l'image. ComfyUI
doit tourner (http://127.0.0.1:8188) ; on lui parle avec la bibliotheque standard seulement.

    python comfy_gen.py ../backgrounds/steampunk/clockwork_plaza "<prompt>" [--seed N] [--denoise D]

Le premier argument est le prefixe des fichiers de l'etape 1 : <prefixe>_guide_x4.png (ou
le nom donne par --guide), <prefixe>_depth.png et <prefixe>_edges.png. --size fixe la taille de
generation : 1360x768 pour un fond, 1024x1536 pour une creature ou un fond de fenetre. L'image
generee est ecrite dans .work/comfy/.

Deux autres modes : --libre compose sans guide, pour explorer des idees ; --retouche repeint
seulement la zone blanche de <prefixe>_bande.png dans <prefixe>_assemblage.png, et rend le reste
a l'identique. --zone X0,Y0,X1,Y1 donne cette zone en rectangle, a la place du fichier de bande.
--repaint F ajoute a la retouche le guide de repeinte de ControlNet Union : ComfyUI voit l'image,
noire dans la zone, et repeint la zone entiere en accord avec ce qui l'entoure, a debruitage complet.

--creature pose d'un coup les reglages d'une creature guidee par sa pose (voir CREATURE, plus bas) ;
une option donnee a la main garde le dessus. Un tour de plusieurs images se lance en une commande :
--graines N tire N graines neuves, --seed en accepte plusieurs, separees par des virgules. Les
images du tour sont alors reunies sur une planche, chacune sous sa graine.

L'image porte le nom du prefixe, sa graine et son debruitage. Plusieurs prompts sur une meme
graine s'ecraseraient : --nom donne a chacun son propre nom d'image. Chaque image generee embarque
son graphe complet (prompt, exclusions, graine, forces, guides) : comfy_meta.py le relit.
"""
import argparse
import hashlib
import json
import os
import random
import time
import urllib.parse
import urllib.request
import uuid

from PIL import Image, ImageDraw, ImageFont

from aseprite_io import work

HOST = os.environ.get("COMFY_HOST", "http://127.0.0.1:8188")
CHECKPOINT = "sd_xl_base_1.0.safetensors"
CONTROLNET = "controlnet-union-sdxl-1.0-promax.safetensors"
LORA = "pixel-art-xl.safetensors"
NEGATIVE = ("blurry, smooth gradients, 3d render, photo, realistic, text, letters, watermark, signature, logo, "
            "deformed, lowres, jpeg artifacts, frame, border")
NO_FIGURES = ", people, person, character, creature"  # un fond guide reste vide de personnages
ONE_FIGURE = ", duplicate, multiple figures, cropped, cut off"  # un personnage reste seul, et entier
STEPS, CFG, SAMPLER, SCHEDULER = 30, 6.5, "dpmpp_2m", "karras"  # l'echantillonnage, le meme pour toute la chaine

# les reglages par defaut, ceux d'un fond d'ecran, puis ceux que --creature met a leur place
DEFAULTS = dict(denoise=0.7, depth=0.7, edges=0.45, pose=0.0, lora=0.9, size="1360x768", guide="guide_x4")
CREATURE = dict(denoise=1.0, depth=0.0, edges=0.55, pose=0.85, lora=0.8, size="1024x1536", guide="guide")


def _post(path, data, headers):
    req = urllib.request.Request(HOST + path, data=data, headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())


def upload(path):
    """Envoie une image dans le dossier input de ComfyUI ; renvoie le nom a donner a LoadImage.

    Le nom porte l'empreinte du contenu : un guide retouche ne remplace pas l'ancien, et le graphe
    embarque dans une image generee designe toujours les guides qui l'ont produite."""
    boundary = uuid.uuid4().hex
    with open(path, "rb") as f:
        payload = f.read()
    name = f"heros_draft_{hashlib.sha1(payload).hexdigest()[:8]}_{os.path.basename(path)}"
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
    g["9"] = {"class_type": "KSampler", "inputs": {"model": ["2", 0], "positive": cond[0], "negative": cond[1], "latent_image": ["8", 0], "seed": seed, "steps": STEPS, "cfg": CFG, "sampler_name": SAMPLER, "scheduler": SCHEDULER, "denoise": denoise}}
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
        "6": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["5", 0], "seed": seed, "steps": STEPS, "cfg": CFG, "sampler_name": SAMPLER, "scheduler": SCHEDULER, "denoise": 1.0}},
        "7": {"class_type": "VAEDecode", "inputs": {"samples": ["6", 0], "vae": ["1", 2]}},
        "8": {"class_type": "SaveImage", "inputs": {"images": ["7", 0], "filename_prefix": "heros_draft/libre"}},
    }


REPAINT = ("repaint", 1.0)  # le guide de repeinte : son type Union, et sa fin d'effet dans le debruitage


def touch_up_workflow(image, mask, prompt, negative, seed, denoise, lora_strength, repaint=None):
    """Une retouche : seule la zone blanche du masque est repeinte, le reste revient a l'identique.

    repaint : (image de controle, force). L'image de controle est l'image, noire dans la zone a repeindre."""
    g = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CHECKPOINT}},
        "2": {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1], "lora_name": LORA, "strength_model": lora_strength, "strength_clip": lora_strength}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": prompt}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": negative}},
        "5": {"class_type": "LoadImage", "inputs": {"image": image}},
        "6": {"class_type": "LoadImage", "inputs": {"image": mask}},
        "7": {"class_type": "ImageToMask", "inputs": {"image": ["6", 0], "channel": "red"}},
        "8": {"class_type": "VAEEncode", "inputs": {"pixels": ["5", 0], "vae": ["1", 2]}},
        "9": {"class_type": "SetLatentNoiseMask", "inputs": {"samples": ["8", 0], "mask": ["7", 0]}},
        "10": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["9", 0], "seed": seed, "steps": STEPS, "cfg": CFG, "sampler_name": SAMPLER, "scheduler": SCHEDULER, "denoise": denoise}},
        "11": {"class_type": "VAEDecode", "inputs": {"samples": ["10", 0], "vae": ["1", 2]}},
        "12": {"class_type": "ImageCompositeMasked", "inputs": {"destination": ["5", 0], "source": ["11", 0], "x": 0, "y": 0, "resize_source": False, "mask": ["7", 0]}},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["12", 0], "filename_prefix": "heros_draft/retouche"}},
    }
    if repaint:
        control, strength = repaint
        g["20"] = {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CONTROLNET}}
        g["21"] = {"class_type": "SetUnionControlNetType", "inputs": {"control_net": ["20", 0], "type": REPAINT[0]}}
        g["22"] = {"class_type": "LoadImage", "inputs": {"image": control}}
        g["23"] = {"class_type": "ControlNetApplyAdvanced", "inputs": {"positive": ["3", 0], "negative": ["4", 0], "control_net": ["21", 0], "image": ["22", 0], "strength": strength, "start_percent": 0.0, "end_percent": REPAINT[1], "vae": ["1", 2]}}
        g["10"]["inputs"]["positive"], g["10"]["inputs"]["negative"] = ["23", 0], ["23", 1]
    return g


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


def contact_sheet(tiles, out_path, width=384, per_row=6):
    """La planche d'un tour : les images, reduites, chacune sous son titre. tiles : [(titre, chemin)]."""
    try:
        font = ImageFont.truetype("arial.ttf", 22)
    except OSError:
        font = ImageFont.load_default()
    thumbs = []
    for label, path in tiles:
        im = Image.open(path).convert("RGB")
        thumbs.append((label, im.resize((width, round(im.height * width / im.width)), Image.BOX)))
    gap, label_h = 16, 40
    cols, lines = min(per_row, len(thumbs)), -(-len(thumbs) // per_row)
    cell_h = max(t.height for _, t in thumbs) + label_h
    out = Image.new("RGB", (gap + cols * (width + gap), gap + lines * (cell_h + gap)), (24, 24, 28))
    d = ImageDraw.Draw(out)
    for i, (label, t) in enumerate(thumbs):
        x, y = gap + (i % per_row) * (width + gap), gap + (i // per_row) * (cell_h + gap)
        d.text((x, y + 6), label, fill=(240, 240, 240), font=font)
        out.paste(t, (x, y + label_h))
    out.save(out_path)


def main():
    ap = argparse.ArgumentParser(description="Fait peindre une image par ComfyUI : guidee, libre (--libre) ou en retouche (--retouche).")
    ap.add_argument("prefix")
    ap.add_argument("prompt")
    ap.add_argument("--seed", default=None, help="la graine, ou plusieurs separees par des virgules (7 par defaut)")
    ap.add_argument("--graines", type=int, default=None, help="tire ce nombre de graines neuves, a la place de --seed")
    ap.add_argument("--creature", action="store_true",
                    help="les reglages d'une creature guidee par sa pose : " + ", ".join(f"{k} {v}" for k, v in CREATURE.items()) + ", et --sujet")
    ap.add_argument("--denoise", type=float, help=f"le debruitage ({DEFAULTS['denoise']} par defaut)")
    ap.add_argument("--depth", type=float, help=f"force de la carte de profondeur ({DEFAULTS['depth']} par defaut)")
    ap.add_argument("--edges", type=float, help=f"force de la carte des contours ({DEFAULTS['edges']} par defaut)")
    ap.add_argument("--pose", type=float, help=f"force de la carte de pose OpenPose, <prefixe>_pose.png ({DEFAULTS['pose']} par defaut)")
    ap.add_argument("--lora", type=float, help=f"force du LoRA pixel art ({DEFAULTS['lora']} par defaut)")
    ap.add_argument("--size", help=f"taille de generation, LARGEURxHAUTEUR, en multiples de 8 ({DEFAULTS['size']} par defaut)")
    ap.add_argument("--guide", help=f"suffixe de l'image guide ({DEFAULTS['guide']} par defaut)")
    ap.add_argument("--libre", action="store_true", help="sans guide : le premier argument n'est plus qu'un nom")
    ap.add_argument("--sujet", action="store_true", help="guide vers un personnage : le negatif ne refuse plus les figures")
    ap.add_argument("--retouche", action="store_true", help="repeint la bande de <prefixe>_bande.png dans <prefixe>_assemblage.png")
    ap.add_argument("--zone", help="en retouche : la zone a repeindre, en rectangle X0,Y0,X1,Y1, a la place de <prefixe>_bande.png")
    ap.add_argument("--repaint", type=float, default=0.0, help="en retouche : force du guide de repeinte, pour repeindre une zone entiere (0 : sans)")
    ap.add_argument("--exclure", default="", help="ce qui s'ajoute au prompt negatif")
    ap.add_argument("--nom", help="le nom de l'image de sortie, a la place de celui du prefixe")
    a = ap.parse_args()
    if a.seed and a.graines:
        ap.error("--seed ou --graines, pas les deux")
    for k, v in (CREATURE if a.creature else DEFAULTS).items():  # une option donnee a la main garde le dessus
        if getattr(a, k) is None:
            setattr(a, k, v)
    seeds = ([random.SystemRandom().randrange(1, 1_000_000) for _ in range(a.graines)] if a.graines
             else [int(v) for v in (a.seed or "7").split(",")])
    name = a.nom or os.path.basename(a.prefix)
    size = tuple(int(v) for v in a.size.split("x"))
    single = a.libre or a.sujet or a.creature or a.retouche
    negative = NEGATIVE + (ONE_FIGURE if single else NO_FIGURES) + (", " + a.exclure if a.exclure else "")
    if a.retouche:
        image, band = f"{a.prefix}_assemblage.png", f"{a.prefix}_bande.png"
        if a.zone:
            band = work("comfy", f"{name}_zone.png")
            mask = Image.new("L", Image.open(image).size, 0)
            ImageDraw.Draw(mask).rectangle(tuple(int(v) for v in a.zone.split(",")), fill=255)
            mask.save(band)
        names = [upload(image), upload(band)]
        repaint = None
        if a.repaint > 0:
            source = Image.open(image).convert("RGB")
            control = work("comfy", f"{name}_repaint.png")
            Image.composite(Image.new("RGB", source.size, (0, 0, 0)), source, Image.open(band).convert("L")).save(control)
            repaint = (upload(control), a.repaint)
        graph = lambda seed: touch_up_workflow(*names, a.prompt, negative, seed, a.denoise, a.lora, repaint)
        stem = lambda seed: f"{name}_retouche_s{seed}_d{a.denoise}"
    elif a.libre:
        graph = lambda seed: free_workflow(a.prompt, negative, seed, a.lora, size)
        stem = lambda seed: f"{name}_libre_s{seed}"
    else:
        strengths = {"pose": a.pose, "depth": a.depth, "edges": a.edges}
        controls = [(upload(f"{a.prefix}_{suffix}.png"), kind, strengths[k], end)
                    for k, (suffix, kind, end) in CONTROLS.items() if strengths[k] > 0]
        guide = upload(f"{a.prefix}_{a.guide}.png")
        graph = lambda seed: workflow(guide, controls, a.prompt, negative, seed, a.denoise, a.lora, size)
        stem = lambda seed: f"{name}_s{seed}_d{a.denoise}"
    tiles = []
    for seed in seeds:
        out = work("comfy", stem(seed) + ".png")
        took = run(graph(seed), out)
        tiles.append((f"graine {seed}", out))
        print(f"{out}  ({took:.0f} s)")
    if len(tiles) > 1:
        board = work("comfy", f"{name}_planche_s{seeds[0]}.png")
        contact_sheet(tiles, board)
        print(f"planche du tour : {board}")
        print("graines : " + ", ".join(str(v) for v in seeds))


if __name__ == "__main__":
    main()
