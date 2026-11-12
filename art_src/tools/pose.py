"""Le dessin des guides de pose, commun a toutes les creatures.

Chaque creature a son propre script, creature_<nom>_pose.py, ecrit neuf d'apres son brief : il ne
contient que ce qui lui est propre, ses 18 points et son equipement. Ce module fait le reste :
le bonhomme OpenPose (la convention COCO a 18 points, avec les couleurs par membre qu'attend
ControlNet) et l'ecriture des trois guides.

Les points se donnent en fractions de l'image. La droite et la gauche sont celles du personnage :
quand il fait face au spectateur, sa droite est a gauche de l'image.

    0 nez, 1 cou, 2 epaule D, 3 coude D, 4 poignet D, 5 epaule G, 6 coude G, 7 poignet G,
    8 hanche D, 9 genou D, 10 cheville D, 11 hanche G, 12 genou G, 13 cheville G,
    14 oeil D, 15 oeil G, 16 oreille D, 17 oreille G

Un point cache (une oreille, de trois quarts) ne se place pas.
"""
import math

from PIL import Image, ImageDraw

W, H = 1024, 1536
LIMBS = [(1, 2), (1, 5), (2, 3), (3, 4), (5, 6), (6, 7), (1, 8), (8, 9), (9, 10), (1, 11), (11, 12), (12, 13),
         (1, 0), (0, 14), (14, 16), (0, 15), (15, 17)]
COLOURS = [(255, 0, 0), (255, 85, 0), (255, 170, 0), (255, 255, 0), (170, 255, 0), (85, 255, 0), (0, 255, 0),
           (0, 255, 85), (0, 255, 170), (0, 255, 255), (0, 170, 255), (0, 85, 255), (0, 0, 255), (85, 0, 255),
           (170, 0, 255), (255, 0, 255), (255, 0, 85), (255, 0, 85)]
STICK, JOINT = 10, 9  # demi-largeur d'un membre et rayon d'une articulation, en pixels
EDGE = 5  # l'epaisseur d'un contour d'equipement, en pixels
START = "#d7b594"  # l'image de depart, un aplat ocre : avec un debruitage complet, elle ne fixe que la taille


def at(p):
    return p[0] * W, p[1] * H


def pose_map(points):
    """La carte OpenPose : chaque membre est un fuseau colore, fondu a 60 %, puis les articulations."""
    out = Image.new("RGB", (W, H), (0, 0, 0))
    for i, (a, b) in enumerate(LIMBS):
        if a not in points or b not in points:
            continue
        (x1, y1), (x2, y2) = at(points[a]), at(points[b])
        ang = math.atan2(y2 - y1, x2 - x1)
        half, mx, my = math.hypot(x2 - x1, y2 - y1) / 2, (x1 + x2) / 2, (y1 + y2) / 2
        pts = [(mx + half * math.cos(ang) * math.cos(t) - STICK * math.sin(ang) * math.sin(t),
                my + half * math.sin(ang) * math.cos(t) + STICK * math.cos(ang) * math.sin(t))
               for t in (k * math.pi / 18 for k in range(36))]
        limb = Image.new("RGB", (W, H), COLOURS[i])
        mask = Image.new("L", (W, H), 0)
        ImageDraw.Draw(mask).polygon(pts, fill=255)
        out = Image.composite(Image.blend(out, limb, 0.6), out, mask)
    d = ImageDraw.Draw(out)
    for i, p in points.items():
        x, y = at(p)
        d.ellipse((x - JOINT, y - JOINT, x + JOINT, y + JOINT), fill=COLOURS[i])
    return out


def write_guides(prefix, points, edges):
    """Ecrit <prefixe>_pose.png (OpenPose), <prefixe>_edges.png (l'equipement) et <prefixe>_guide.png
    (l'image de depart), a donner a comfy_gen.py --sujet --guide guide."""
    pose_map(points).save(prefix + "_pose.png")
    edges.save(prefix + "_edges.png")
    Image.new("RGB", (W, H), START).save(prefix + "_guide.png")
