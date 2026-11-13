"""Les guides de pose du Squelette (tier 2), pour une generation guidee par ComfyUI.

Le Squelette se tient de face, l'appui un peu ecarte, la tete droite vers le spectateur. Sa main
droite serre a hauteur de taille un baton plante au sol ; son avant-bras gauche, ecarte du corps,
porte un ecu rond. De face, la droite du personnage est a gauche de l'image. Le baton et l'ecu, que
OpenPose ne connait pas, sont traces a part, en contours. Le dessin du bonhomme et l'ecriture des
guides sont dans pose.py.

    python creature_squelette_pose.py <prefixe>

Ecrit <prefixe>_pose.png, <prefixe>_edges.png et <prefixe>_guide.png. Le Squelette a ete genere
avec comfy_gen.py --creature (pose 0.85, contours 0.55, pas de profondeur).
"""
import sys

from PIL import Image, ImageDraw

from pose import EDGE, H, W, at, write_guides

# en fractions de l'image
KEYPOINTS = {
    0: (0.515, 0.175), 1: (0.515, 0.245), 2: (0.42, 0.265), 3: (0.355, 0.36), 4: (0.275, 0.42),
    5: (0.615, 0.265), 6: (0.705, 0.355), 7: (0.755, 0.435), 8: (0.47, 0.50), 9: (0.45, 0.69), 10: (0.43, 0.855),
    11: (0.565, 0.50), 12: (0.585, 0.69), 13: (0.61, 0.855), 14: (0.49, 0.155), 15: (0.545, 0.155),
    16: (0.455, 0.16), 17: (0.585, 0.16),
}
STAFF = ((0.275, 0.11), (0.275, 0.88))  # le baton, vertical, passe par la main droite et touche le sol
SHIELD = ((0.755, 0.43), 0.115)  # l'ecu : son centre sur l'avant-bras gauche, et son rayon en fraction de la largeur


def equipment_edges():
    """Le baton et l'ecu en contours : une droite, un cercle et son umbo."""
    out = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(out)
    d.line([at(STAFF[0]), at(STAFF[1])], fill=255, width=EDGE)
    (cx, cy), r = at(SHIELD[0]), SHIELD[1] * W
    for radius in (r, r * 0.18):
        d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=255, width=EDGE)
    return out


if __name__ == "__main__":
    write_guides(sys.argv[1], KEYPOINTS, equipment_edges())
