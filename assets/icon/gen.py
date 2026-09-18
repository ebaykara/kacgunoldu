"""
"Kaç Gün Oldu?" — icon + splash source generation.

The mark is the app's own rhythm ring (RhythmRing widget): a thick arc,
flat (butt) ends, sweeping clockwise from 12 o'clock, with a symmetric
gap centered at top. A question mark — in the app's own display face,
Instrument Serif — rises up through that gap: the dot sits inside the
ring's hollow centre, the hook climbs out through the opening and past
the ring's own edge, literally the question the app asks ("kaç gün
oldu?") escaping the dial that tracks it.

Palette (theme/tokens.dart):
  primary      #B8492A  terracotta — icon background
  onPrimary    #FFF3EA  warm ivory — ring + mark stroke
  surface      #FBF5F0  paper      — splash background
"""
from PIL import Image, ImageDraw, ImageFont
import os

HERE = os.path.dirname(os.path.abspath(__file__))
FONT_PATH = "C:/dev/ne_zaman/assets/fonts/InstrumentSerif_400Regular.ttf"

PRIMARY = (0xB8, 0x49, 0x2A, 255)
ON_PRIMARY = (0xFF, 0xF3, 0xEA, 255)
SURFACE = (0xFB, 0xF5, 0xF0, 255)

# The launcher icon is deliberately louder than the in-app terracotta: a
# saturated orange -> raspberry diagonal with a pure-white mark, so it holds
# its own on a crowded home screen. In-app colours are untouched.
ICON_FROM = (0xFF, 0x8A, 0x3D)   # vivid orange, top-left
ICON_TO = (0xF2, 0x2E, 0x62)     # raspberry, bottom-right
ICON_MARK = (255, 255, 255, 255)

SIZE = 1024
CX = CY = SIZE / 2

RING_DIAMETER = 620
RING_STROKE = 140
GAP_DEG = 54
START_DEG = -90 + GAP_DEG / 2
END_DEG = START_DEG + (360 - GAP_DEG)


def draw_ring(draw, cx, cy, diameter, stroke, color, start=START_DEG, end=END_DEG):
    r = diameter / 2
    bbox = [cx - r, cy - r, cx + r, cy + r]
    draw.arc(bbox, start=start, end=end, fill=color, width=int(stroke))


def glyph_mask(char, font_size, font_path=FONT_PATH):
    """Renders one glyph at a generous size and returns a mask cropped
    tight to its own ink, so placement is computed from the glyph's real
    drawn extent rather than font metrics."""
    font = ImageFont.truetype(font_path, font_size)
    probe = Image.new("L", (font_size * 3, font_size * 4), 0)
    d = ImageDraw.Draw(probe)
    d.text((font_size, font_size), char, font=font, fill=255)
    bbox = probe.getbbox()
    return probe.crop(bbox)


def paste_question_mark(img, color, scale=1.0):
    """Composites a "?" rising through the ring's top gap: the dot inside
    the ring's hollow, the hook rising above the ring's outer edge.

    `scale` sizes the whole mark relative to the 1024 canvas, matching the
    ring diameter it is paired with.
    """
    glyph = glyph_mask("?", int(380 * scale))
    gw, gh = glyph.size

    tint = Image.new("RGBA", glyph.size, color)
    tint.putalpha(glyph)

    outer_r = RING_DIAMETER / 2 * scale + RING_STROKE / 2 * scale
    dot_y = CY - outer_r * 0.18
    top_y = dot_y - gh
    x = CX - gw / 2

    img.alpha_composite(tint, (int(x), int(top_y)))


def make_icon_background():
    """Diagonal gradient with a soft highlight glow in the upper left."""
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            t = (x + y) / (2 * (SIZE - 1))
            px[x, y] = tuple(
                round(ICON_FROM[i] + (ICON_TO[i] - ICON_FROM[i]) * t) for i in range(3)
            ) + (255,)
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gp = glow.load()
    for y in range(SIZE):
        for x in range(SIZE):
            d = ((x - SIZE * 0.25) ** 2 + (y - SIZE * 0.2) ** 2) ** 0.5 / (SIZE * 0.7)
            if d < 1:
                gp[x, y] = (255, 255, 255, int(60 * (1 - d) ** 2))
    return Image.alpha_composite(img, glow)


def make_icon_flat():
    img = make_icon_background()
    draw = ImageDraw.Draw(img)
    draw_ring(draw, CX, CY, RING_DIAMETER, RING_STROKE, ICON_MARK)
    paste_question_mark(img, ICON_MARK)
    return img


def make_icon_foreground():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_ring(draw, CX, CY, RING_DIAMETER, RING_STROKE, ICON_MARK)
    paste_question_mark(img, ICON_MARK)
    return img


def make_icon_monochrome():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    white = (255, 255, 255, 255)
    draw_ring(draw, CX, CY, RING_DIAMETER, RING_STROKE, white)
    paste_question_mark(img, white)
    return img


def make_splash_mark(diameter=340, stroke=76):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    scale = diameter / RING_DIAMETER
    draw_ring(draw, CX, CY, diameter, stroke, PRIMARY)
    paste_question_mark(img, PRIMARY, scale=scale)
    return img


def make_splash_mark_android12(diameter=220, stroke=50):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    scale = diameter / RING_DIAMETER
    draw_ring(draw, CX, CY, diameter, stroke, PRIMARY)
    paste_question_mark(img, PRIMARY, scale=scale)
    return img


if __name__ == "__main__":
    out = HERE
    make_icon_flat().save(os.path.join(out, "icon.png"))
    make_icon_background().save(os.path.join(out, "icon_background.png"))
    make_icon_foreground().save(os.path.join(out, "icon_foreground.png"))
    make_icon_monochrome().save(os.path.join(out, "icon_monochrome.png"))
    make_splash_mark().save(os.path.join(out, "splash_logo.png"))
    make_splash_mark_android12().save(os.path.join(out, "splash_logo_android12.png"))
    print("done, font exists:", os.path.exists(FONT_PATH))
