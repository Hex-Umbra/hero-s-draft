"""Les guides de pose de la Faucheuse (tier 3), pour une generation guidee par ComfyUI.

La Faucheuse attaque, de trois quarts : l'appui large, le buste penche, la faux armee en arriere
a deux mains. La faux, que OpenPose ne connait pas, est tracee a part, en contours. Le dessin du
bonhomme et l'ecriture des guides sont dans pose.py.

    python creature_faucheuse_pose.py <prefixe>

Ecrit <prefixe>_pose.png, <prefixe>_edges.png et <prefixe>_guide.png. La Faucheuse a ete generee
avec comfy_gen.py --creature --edges 0.4 (pose 0.85, contours 0.4, pas de profondeur).
"""
import sys

from PIL import Image, ImageDraw

from pose import EDGE, H, W, at, write_guides

# en fractions de l'image ; l'oreille gauche, cachee de trois quarts, n'est pas placee
KEYPOINTS = {
    0: (0.40, 0.35), 1: (0.445, 0.405), 2: (0.515, 0.42), 3: (0.60, 0.455), 4: (0.665, 0.475),
    5: (0.39, 0.415), 6: (0.47, 0.50), 7: (0.585, 0.51), 8: (0.525, 0.625), 9: (0.585, 0.775), 10: (0.645, 0.945),
    11: (0.445, 0.62), 12: (0.37, 0.76), 13: (0.31, 0.94), 14: (0.41, 0.338), 15: (0.39, 0.342), 16: (0.435, 0.343),
}


def scythe_edges(points):
    """La faux en contours : le manche passe par les deux mains et part en arriere, la lame pend derriere."""
    h1, h2 = points[7], points[4]
    dx, dy = h2[0] - h1[0], h2[1] - h1[1]
    butt, head = (h1[0] - 1.6 * dx, h1[1] - 1.6 * dy), (h2[0] + 2.6 * dx, h2[1] + 2.6 * dy)
    blade = [head, (head[0] + 0.06, head[1] + 0.05), (head[0] + 0.065, head[1] + 0.14), (head[0] + 0.02, head[1] + 0.24),
             (head[0] + 0.035, head[1] + 0.13), (head[0] + 0.015, head[1] + 0.06), head]
    out = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(out)
    d.line([at(butt), at(head)], fill=255, width=EDGE)
    d.line([at(q) for q in blade], fill=255, width=EDGE, joint="curve")
    return out


if __name__ == "__main__":
    write_guides(sys.argv[1], KEYPOINTS, scythe_edges(KEYPOINTS))
