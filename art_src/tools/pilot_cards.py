"""Les cartes de la serie pilote, sur la mise en page reelle du combat (140 x 196)."""
from PIL import Image, ImageDraw, ImageFont
import cards
import ladder
import motifs
from aseprite_io import work
from styles import fill, font

U = cards.U
CW, CH, MARGIN = cards.CW, cards.CH, cards.MARGIN
ICONS = "C:/Users/Gpdac/development/Flutter/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf"
TIMER = 0xF44A

TYPES = {
    "attack": ("ATTAQUE", (200, 50, 50)),
    "skill": ("COMPÉTENCE", (40, 90, 200)),
    "power": ("POUVOIR", (220, 160, 40)),
}
RED, BLUE, PINK, AMBER, ORANGE = (255, 82, 82), (68, 138, 255), (255, 64, 129), (255, 193, 7), (255, 171, 64)

# valeurs par palier : regle G1 (_rules/02-4), la pioche ne grandit pas (G2)
DATA = {
    "defend_basic": dict(title="DÉFENSE", type="skill", cost=1, exhaust=False, effects=[(0xF016B, BLUE, [5, 6, 7, 8, 10], None)]),
    "fireball": dict(title="BOULE DE FEU", type="attack", cost=2, exhaust=False, effects=[(0xF7CD, RED, [6, 7, 8, 10, 12], None), (0xF86B, ORANGE, [2, 3, 4, 5, 6], 2)]),
    "heal_potion": dict(title="POTION DE SOIN", type="skill", cost=1, exhaust=True, effects=[(0xF738, PINK, [3, 4, 5, 6, 7], None)]),
    "metallicize": dict(title="MÉTALLISATION", type="power", cost=1, exhaust=False, effects=[(0xF59E, BLUE, [2, 3, 4, 5, 6], 2)]),
    "concentration": dict(title="CONCENTRATION", type="skill", cost=0, exhaust=True, effects=[(0xF01E8, AMBER, [2, 2, 2, 2, 2], None)]),
    "demon_form": dict(title="FORME DÉMONIAQUE", type="power", cost=2, exhaust=False, effects=[(0xF5CA, ORANGE, [2, 3, 4, 5, 6], 4)]),
}


def _fit(d, text, name, size, maxw):
    f = font(name, int(size * U))
    while d.textlength(text, font=f) > maxw and size > 6:
        size -= 0.25
        f = font(name, int(size * U))
    return f


def _badges(d, effects, stage, ink, veil, cy):
    fi = ImageFont.truetype(ICONS, int(19 * U))
    fv = font("arialbd.ttf", int(13 * U))
    fs = font("arial.ttf", int(15 * U))
    ft = ImageFont.truetype(ICONS, int(8 * U))
    fd = font("arialbd.ttf", int(8 * U))
    items = []
    for cp, color, vals, dur in effects:
        g, v = chr(cp), " " + str(vals[stage])
        items.append((g, color, v, dur, d.textlength(g, font=fi) + d.textlength(v, font=fv)))
    sep = "  |  "
    sw = d.textlength(sep, font=fs)
    total = sum(it[4] for it in items) + sw * (len(items) - 1)
    x = CW * U / 2 - total / 2
    for k, (g, color, v, dur, w) in enumerate(items):
        d.text((x, cy), g, font=fi, fill=color, anchor="lm")
        gw = d.textlength(g, font=fi)
        d.text((x + gw, cy + 0.5 * U), v, font=fv, fill=ink, anchor="lm")
        if dur:
            t = chr(TIMER)
            tw = d.textlength(t, font=ft) + d.textlength(" " + str(dur), font=fd)
            tx = x + w / 2 - tw / 2
            dim = ladder.mix(veil, ink, 0.65)
            d.text((tx, cy + 13 * U), t, font=ft, fill=dim, anchor="lm")
            d.text((tx + d.textlength(t, font=ft), cy + 13 * U), " " + str(dur), font=fd, fill=dim, anchor="lm")
        x += w
        if k < len(items) - 1:
            d.text((x, cy), sep, font=fs, fill=ladder.mix(veil, ink, 0.3), anchor="lm")
            x += sw


def card(motif, stage, neutral=False):
    data = DATA[motif.key]
    style = ladder.STAGES[stage]
    sk = cards.skin(style)
    ink = sk["ink"]
    label, tcol = TYPES[data["type"]]
    veil = ladder.mix(sk["veil"], tcol, 0.3)
    W, H = CW * U, CH * U
    rar = (150, 150, 150) if neutral else cards.RARITY[stage]
    im = fill(W, H, veil)
    wy0, wy1, wx0, wx1 = 34 * U, 130 * U, 7 * U, 133 * U
    im.paste(ladder.art(motif, style, wx1 - wx0, wy1 - wy0), (wx0, wy0))
    d = ImageDraw.Draw(im)
    d.rectangle([wx0, wy0, wx1, wy1], outline=ink, width=int(0.6 * U))
    ft = _fit(d, data["title"], sk["title"][0], sk["title"][1], W - 30 * U)
    d.text((W / 2, 10 * U), data["title"], font=ft, fill=ink, anchor="ma")
    y = 10 * U + ft.size * 1.2 + 3 * U
    d.line([(W / 2 - 20 * U, y), (W / 2 + 20 * U, y)], fill=ink, width=int(1.2 * U))
    y += 4 * U
    if data["exhaust"]:
        f = font("arialbd.ttf", int(7 * U))
        t = "USAGE UNIQUE"
        bw = d.textlength(t, font=f) + 12 * U
        d.rounded_rectangle([W / 2 - bw / 2, y + 2 * U, W / 2 + bw / 2, y + 16 * U], 4 * U, fill=(255, 82, 82))
        d.text((W / 2, y + 9 * U), t, font=f, fill=(255, 255, 255), anchor="mm")
    if not neutral:
        _badges(d, data["effects"], stage, ink, veil, 148 * U)
    f = font("arialbd.ttf", int(7 * U))
    d.text((W / 2, 177 * U), label, font=f, fill=ink, anchor="ma")
    cards._border(im, sk["border"], rar, W, H)
    out = Image.new("RGBA", (W + 2 * MARGIN * U, H + 2 * MARGIN * U), (0, 0, 0, 0))
    out.paste(im.convert("RGBA"), (MARGIN * U, MARGIN * U), cards._rounded(W, H, 12 * U))
    d2 = ImageDraw.Draw(out)
    cx, cy = (MARGIN + 6) * U, (MARGIN + 6) * U
    r = 12 * U
    d2.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(13, 27, 42, 255), outline=(24, 255, 255, 255), width=int(1.2 * U))
    d2.text((cx, cy), str(data["cost"]), font=font("arialbd.ttf", int(12 * U)), fill=(255, 255, 255, 255), anchor="mm")
    return out


if __name__ == "__main__":
    sheet = Image.new("RGB", (5 * 330, len(motifs.PILOT) * 448), (23, 23, 29))
    for r, m in enumerate(motifs.PILOT):
        for s in range(5):
            c = card(m, s).resize((312, 424), Image.LANCZOS)
            sheet.paste(c, (s * 330, r * 448), c)
    path = work("pilot_cards_check.png")
    sheet.save(path)
    print(path)
