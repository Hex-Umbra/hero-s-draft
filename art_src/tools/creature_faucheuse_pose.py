"""Les guides de pose de la Faucheuse, pour une generation guidee par ComfyUI.

La pose est donnee en OpenPose (le bonhomme en batons de la convention COCO a 18 points, avec
ses couleurs par membre, celles qu'attend ControlNet) : c'est ce qui impose un geste au
generateur, la ou une silhouette pleine ne donne qu'une forme. L'arme, que OpenPose ne connait
pas, est tracee a part, en contours. L'image de depart est un aplat ocre : avec un debruitage
complet, elle ne sert qu'a fixer la taille.

    python creature_faucheuse_pose.py <prefixe>

Ecrit <prefixe>_pose.png, <prefixe>_edges.png et <prefixe>_guide.png, a donner a
comfy_gen.py --sujet --guide guide --pose 0.85 --edges 0.4 --depth 0.
"""
import math
import sys

from PIL import Image, ImageDraw

W, H = 1024, 1536

# 0 nez, 1 cou, 2 epaule D, 3 coude D, 4 poignet D, 5 epaule G, 6 coude G, 7 poignet G, 8 hanche D, 9 genou D,
# 10 cheville D, 11 hanche G, 12 genou G, 13 cheville G, 14 oeil D, 15 oeil G, 16 oreille D, 17 oreille G
# (en fractions de l'image ; l'oreille gauche, cachee de trois quarts, n'est pas placee)
KEYPOINTS = {
    0: (0.40, 0.35), 1: (0.445, 0.405), 2: (0.515, 0.42), 3: (0.60, 0.455), 4: (0.665, 0.475),
    5: (0.39, 0.415), 6: (0.47, 0.50), 7: (0.585, 0.51), 8: (0.525, 0.625), 9: (0.585, 0.775), 10: (0.645, 0.945),
    11: (0.445, 0.62), 12: (0.37, 0.76), 13: (0.31, 0.94), 14: (0.41, 0.338), 15: (0.39, 0.342), 16: (0.435, 0.343),
}
LIMBS = [(1, 2), (1, 5), (2, 3), (3, 4), (5, 6), (6, 7), (1, 8), (8, 9), (9, 10), (1, 11), (11, 12), (12, 13),
         (1, 0), (0, 14), (14, 16), (0, 15), (15, 17)]
COLOURS = [(255, 0, 0), (255, 85, 0), (255, 170, 0), (255, 255, 0), (170, 255, 0), (85, 255, 0), (0, 255, 0),
           (0, 255, 85), (0, 255, 170), (0, 255, 255), (0, 170, 255), (0, 85, 255), (0, 0, 255), (85, 0, 255),
           (170, 0, 255), (255, 0, 255), (255, 0, 85), (255, 0, 85)]
STICK, JOINT = 10, 9  # demi-largeur d'un membre et rayon d'une articulation, en pixels


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


def scythe_edges(points):
    """La faux en contours : le manche passe par les deux mains et part en arriere, la lame pend derriere."""
    h1, h2 = points[7], points[4]
    dx, dy = h2[0] - h1[0], h2[1] - h1[1]
    butt, head = (h1[0] - 1.6 * dx, h1[1] - 1.6 * dy), (h2[0] + 2.6 * dx, h2[1] + 2.6 * dy)
    blade = [head, (head[0] + 0.06, head[1] + 0.05), (head[0] + 0.065, head[1] + 0.14), (head[0] + 0.02, head[1] + 0.24),
             (head[0] + 0.035, head[1] + 0.13), (head[0] + 0.015, head[1] + 0.06), head]
    out = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(out)
    d.line([at(butt), at(head)], fill=255, width=5)
    d.line([at(q) for q in blade], fill=255, width=5, joint="curve")
    return out


if __name__ == "__main__":
    prefix = sys.argv[1]
    pose_map(KEYPOINTS).save(prefix + "_pose.png")
    scythe_edges(KEYPOINTS).save(prefix + "_edges.png")
    Image.new("RGB", (W, H), "#d7b594").save(prefix + "_guide.png")
