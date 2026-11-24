"""Le guide du Rat geant (tier 1), pour une generation guidee par ComfyUI.

Le Rat geant n'est pas humanoide : il n'a pas de carte OpenPose, seulement sa silhouette en contours.
Il est vu en plongee et avance presque de face vers le spectateur, comme le rat de tete de la
reference du proprietaire : la tete basse au premier plan, la gueule ouverte sur les incisives, les
pattes avant ecartees de part et d'autre, griffes en avant, le corps rond raccourci derriere la tete,
les pattes arriere qui depassent sur les cotes, et deux queues qui remontent en s'ecartant derriere le dos. Il
occupe environ 70 % de la largeur et 60 % de la hauteur, les pattes avant sur la ligne de sol.

Les formes se tracent de l'arriere vers l'avant : chacune efface, sous elle, les contours de celles
qu'elle cache. La gueule est grande : tracee a la taille du museau, elle ne sortait pas.

Les queues ont plusieurs traces, essayes tour par tour sur la graine 471738 :
- trait (tour 6) : chaque queue d'un seul trait. Une bande fine tracee par ses deux bords sortait
  en deux queues, d'ou la double queue ; d'un seul trait, elles sortent bien deux, mais fines.
- q6 (tour 7) : chaque queue en contour effile, une bande large au dos et fine a la pointe tracee par
  ses bords. Assez large, la bande se lit comme une seule queue, la plus epaisse des essais.
- a1 a a4 (tour 8) : le contour effile, sur deux queues de longueurs differentes.

    python creature_rat_geant_pose.py <prefixe>
    python creature_rat_geant_pose.py <prefixe> trait|q6|a1|a2|a3|a4

Ecrit <prefixe>_edges.png et <prefixe>_guide.png, a donner a comfy_gen.py --creature --pose 0.

Sans trace nomme, le guide est celui de la figure retenue, recopie du dossier de la creature
(rat_geant_edges.png) : la figure se rejoue toujours sous le guide qui l'a produite. Ce guide est
celui du tour 4, une seule queue en bande et une petite gueule, reduit a 80 % avec la figure ; son
trace a ete remplace des le tour 6 et n'existe plus que dans ce fichier, et a pleine taille aux
archives. Quand une autre figure est retenue, son guide prend sa place dans le dossier, et ce
script le redonne sans changer.
"""
import os
import shutil
import sys

from PIL import Image, ImageDraw

from pose import EDGE, START, H, W, at

SOL = 183 / 192  # la ligne de sol, en fraction de la hauteur
# le guide de la figure retenue, garde avec la creature
RETAINED = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sprites", "rat", "tier_1", "rat_geant_edges.png")

# en fractions de l'image
# les lignes des queues, du dos vers la pointe
LEFT = [(0.48, 0.47), (0.47, 0.41), (0.45, 0.37), (0.41, 0.345), (0.37, 0.34)]
RIGHT = [(0.52, 0.47), (0.53, 0.40), (0.555, 0.35), (0.59, 0.32), (0.625, 0.315)]
SHORT_L = [(0.48, 0.47), (0.465, 0.42), (0.44, 0.39), (0.41, 0.38)]
STUB_L = [(0.48, 0.47), (0.455, 0.44), (0.43, 0.43)]
LONG_L_CURL = [(0.48, 0.47), (0.465, 0.40), (0.44, 0.34), (0.40, 0.30), (0.35, 0.29), (0.32, 0.31)]
SHORT_R = [(0.52, 0.47), (0.54, 0.43), (0.57, 0.41), (0.60, 0.41)]
LONG_R = [(0.52, 0.47), (0.535, 0.40), (0.56, 0.34), (0.60, 0.29), (0.65, 0.27), (0.69, 0.275)]
LONG_R_S = [(0.52, 0.47), (0.54, 0.41), (0.52, 0.36), (0.49, 0.31), (0.50, 0.26), (0.54, 0.235)]
TAIL_STROKES = [LEFT, RIGHT]  # le trace « trait »
TAPERED_TAILS = {  # les traces en contour effile : (ligne, largeur au dos, largeur a la pointe), en pixels
    "q6": [(LEFT, 54, 14), (RIGHT, 54, 14)],
    "a1": [(SHORT_L, 44, 12), (LONG_R, 54, 14)],  # gauche courte, droite longue
    "a2": [(LONG_L_CURL, 54, 14), (SHORT_R, 44, 12)],  # gauche longue enroulee, droite courte
    "a3": [(STUB_L, 40, 16), (LONG_R_S, 54, 14)],  # droite longue en S, gauche en moignon
    "a4": [(SHORT_L, 28, 8), (LONG_R, 54, 14)],  # comme a1, la courte bien plus fine
}
BODY = (0.24, 0.44, 0.76, 0.81)  # le corps, un ovale plus long que large : la plongee le raccourcit a peine
HIND_LEGS = [  # les pieds arriere, qui depassent un peu sur les cotes, orteils vers l'exterieur
    [(0.27, 0.72), (0.20, 0.75), (0.155, 0.77), (0.15, 0.795), (0.18, 0.805), (0.24, 0.80), (0.28, 0.78)],
    [(0.73, 0.72), (0.80, 0.75), (0.845, 0.77), (0.85, 0.795), (0.82, 0.805), (0.76, 0.80), (0.72, 0.78)],
]
FORE_LEGS = [  # les pattes avant, sous les joues : le coude ecarte, puis la patte posee au sol
    [(0.37, 0.77), (0.29, 0.83), (0.27, SOL - 0.025), (0.35, SOL - 0.025), (0.36, 0.86), (0.41, 0.83)],
    [(0.63, 0.77), (0.71, 0.83), (0.73, SOL - 0.025), (0.65, SOL - 0.025), (0.64, 0.86), (0.59, 0.83)],
]
CLAWS = [  # les griffes : quatre par patte avant, du poignet vers la ligne de sol
    [((0.275, SOL - 0.025), (0.255, SOL)), ((0.295, SOL - 0.025), (0.285, SOL)),
     ((0.32, SOL - 0.025), (0.32, SOL)), ((0.345, SOL - 0.025), (0.36, SOL))],
    [((0.725, SOL - 0.025), (0.745, SOL)), ((0.705, SOL - 0.025), (0.715, SOL)),
     ((0.68, SOL - 0.025), (0.68, SOL)), ((0.655, SOL - 0.025), (0.64, SOL))],
]
EARS = [(0.32, 0.615, 0.43, 0.69), (0.57, 0.615, 0.68, 0.69)]  # les oreilles rondes, en ellipses
HEAD = [(0.39, 0.655), (0.50, 0.645), (0.61, 0.655), (0.65, 0.70), (0.63, 0.76), (0.565, 0.83),
        (0.53, 0.865), (0.47, 0.865), (0.435, 0.83), (0.37, 0.76), (0.35, 0.70)]  # le crane large en haut, le museau pointe vers le spectateur
EYES = [(0.415, 0.715, 0.445, 0.735), (0.555, 0.715, 0.585, 0.735)]
NOSE = (0.48, 0.850, 0.52, 0.868)  # la truffe, au bout du museau
MOUTH = (0.44, 0.862, 0.56, 0.945)  # la gueule grande ouverte, sous la truffe
INCISORS = [  # les incisives longues, deux en haut et deux en bas
    (0.472, 0.866, 0.496, 0.910), (0.504, 0.866, 0.528, 0.910),
    (0.476, 0.915, 0.496, 0.940), (0.504, 0.915, 0.524, 0.940),
]


def box(b):
    (x0, y0), (x1, y1) = at(b[:2]), at(b[2:])
    return x0, y0, x1, y1


def tapered(line, w0, w1):
    """Le pourtour d'une bande le long de la ligne, large de w0 au dos et de w1 a la pointe, en pixels."""
    pts = [at(p) for p in line]
    left, right = [], []
    n = len(pts)
    for i, (x, y) in enumerate(pts):
        a, b = pts[max(i - 1, 0)], pts[min(i + 1, n - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        norm = (dx * dx + dy * dy) ** 0.5
        half = (w0 + (w1 - w0) * i / (n - 1)) / 2
        left.append((x - dy / norm * half, y + dx / norm * half))
        right.append((x + dy / norm * half, y - dx / norm * half))
    return left + right[::-1]


def rat_edges(tails):
    """La silhouette en contours, blanc sur noir, de l'arriere vers l'avant, avec le trace de queues nomme."""
    out = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(out)

    def polygon(pts):
        """Un contour ferme, en pixels, qui efface d'abord ce qu'il cache."""
        d.polygon(pts, fill=0)
        d.line(pts + [pts[0]], fill=255, width=EDGE, joint="curve")

    def ellipse(b):
        d.ellipse(box(b), fill=0, outline=255, width=EDGE)

    if tails == "trait":
        for tail in TAIL_STROKES:
            d.line([at(p) for p in tail], fill=255, width=EDGE, joint="curve")
    else:
        for line, w0, w1 in TAPERED_TAILS[tails]:
            band = tapered(line, w0, w1)
            d.line(band + [band[0]], fill=255, width=EDGE, joint="curve")  # le contour seul : le corps cache la base
    for leg in HIND_LEGS:
        polygon([at(p) for p in leg])
    ellipse(BODY)
    for leg in FORE_LEGS:
        polygon([at(p) for p in leg])
    for ear in EARS:
        ellipse(ear)
    polygon([at(p) for p in HEAD])
    for eye in EYES:
        ellipse(eye)
    ellipse(MOUTH)
    ellipse(NOSE)
    for tooth in INCISORS:
        d.rectangle(box(tooth), fill=0, outline=255, width=EDGE)
    for paw in CLAWS:
        for a, b in paw:
            d.line([at(a), at(b)], fill=255, width=EDGE)
    return out


if __name__ == "__main__":
    prefix = sys.argv[1]
    if len(sys.argv) > 2:
        tails = sys.argv[2]
        if tails != "trait" and tails not in TAPERED_TAILS:
            sys.exit(f"trace de queues inconnu : {tails} (trait, {', '.join(TAPERED_TAILS)})")
        rat_edges(tails).save(prefix + "_edges.png")
    else:
        shutil.copyfile(RETAINED, prefix + "_edges.png")
    Image.new("RGB", (W, H), START).save(prefix + "_guide.png")
