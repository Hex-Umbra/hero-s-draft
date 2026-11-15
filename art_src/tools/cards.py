"""Le cadre de la carte de combat (140 x 196, coordonnees de CardTextRenderer) : bordure par palier, coins arrondis, couleurs de rarete."""
from PIL import Image, ImageDraw
from styles import Ctx, fill, wobble

U = 4  # 1 unite logique = 4 px dans l'image
CW, CH = 140, 196
MARGIN = 8


RARITY = [(176, 190, 197), (102, 187, 106), (66, 165, 245), (171, 71, 188), (255, 179, 0)]  # AppColors

SKINS = {
    "doodle": dict(ink=(26, 40, 110), veil=(247, 241, 222), title=("segoepr.ttf", 9.5), border="pen"),
    "pix16": dict(ink=(255, 255, 255), veil=(46, 58, 116), title=("consolab.ttf", 11), border="pix"),
    "pix64": dict(ink=(255, 255, 255), veil=(10, 38, 58), title=("consolab.ttf", 11), border="pix_gold"),
    "cel": dict(ink=(255, 255, 255), veil=(90, 24, 50), title=("impact.ttf", 11.5), border="thick_black_white"),
    "splash": dict(ink=(255, 244, 214), veil=(24, 10, 34), title=("georgiab.ttf", 10.5), border="gold"),
}


def skin(style):
    return SKINS.get(style, dict(ink=(255, 255, 255), veil=(30, 26, 36), title=("arialbd.ttf", 10.5), border="game"))


def _rounded(w, h, r):
    m = Image.new("L", (w * 2, h * 2), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * 2 - 1, h * 2 - 1], r * 2, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def _border(im, kind, rarity_col, W, H):
    d = ImageDraw.Draw(im)
    if kind == "game":
        ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(ov).rounded_rectangle([0, 0, W - 1, H - 1], 12 * U, outline=rarity_col + (128,), width=int(1.5 * U))
        im.paste(ov, (0, 0), ov)
    elif kind == "pen":
        c = Ctx(W, H, 3)
        m = 3 * U
        for _ in range(2):
            pts = [(m, m), (W - m, m), (W - m, H - m), (m, H - m), (m, m)]
            d.line(wobble(c, pts, 0.8 * U, 20), fill=(28, 52, 150), width=int(0.7 * U), joint="curve")
    elif kind == "thin_dark":
        d.rectangle([2 * U, 2 * U, W - 2 * U, H - 2 * U], outline=(40, 40, 46), width=int(0.6 * U))
    elif kind == "thick_dark":
        d.rectangle([2 * U, 2 * U, W - 2 * U, H - 2 * U], outline=(16, 14, 18), width=int(1.8 * U))
    elif kind in ("pix", "pix_gold"):
        p = int(3 * U)
        cols = [(20, 16, 40), (240, 180, 50) if kind == "pix_gold" else (120, 136, 200)]
        for i, col in enumerate(cols):
            o = i * p
            d.rectangle([o + p, o, W - p - o, o + p - 1], fill=col)
            d.rectangle([o + p, H - o - p, W - p - o, H - o], fill=col)
            d.rectangle([o, o + p, o + p - 1, H - p - o], fill=col)
            d.rectangle([W - o - p, o + p, W - o, H - p - o], fill=col)
    elif kind == "thick_black_white":
        d.rectangle([0, 0, W, H], outline=(255, 255, 255), width=int(2.4 * U))
        d.rectangle([int(2.4 * U), int(2.4 * U), W - int(2.4 * U), H - int(2.4 * U)], outline=(14, 12, 16), width=int(1.6 * U))
    elif kind == "gold":
        ov = Image.new("L", (W, H), 0)
        ImageDraw.Draw(ov).rounded_rectangle([0, 0, W - 1, H - 1], 12 * U, outline=255, width=int(3 * U))
        grad = Image.linear_gradient("L").resize((W, H))
        col = Image.composite(fill(W, H, (255, 228, 130)), fill(W, H, (150, 90, 24)), grad)
        im.paste(col, (0, 0), ov)
        ov2 = Image.new("L", (W, H), 0)
        ImageDraw.Draw(ov2).rounded_rectangle([int(3 * U), int(3 * U), W - int(3 * U), H - int(3 * U)], 10 * U, outline=255, width=int(0.5 * U))
        im.paste((60, 30, 10), (0, 0), ov2)


