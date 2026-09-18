"""
Play Store graphics for "Kaç Gün Oldu?", generated from the app's own icon
sources so they always match it.

Run from the project root:  python store/make_graphics.py
Writes store/graphics/icon-512.png and store/graphics/feature-graphic.png.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "store", "graphics")
ICON = os.path.join(ROOT, "assets", "icon", "icon.png")
MARK = os.path.join(ROOT, "assets", "icon", "icon_foreground.png")
SERIF = os.path.join(ROOT, "assets", "fonts", "InstrumentSerif_400Regular.ttf")
SANS = os.path.join(ROOT, "assets", "fonts", "Archivo_600SemiBold.ttf")

# The icon's gradient (assets/icon/gen.py).
FROM = (0xFF, 0x8A, 0x3D)
TO = (0xF2, 0x2E, 0x62)


def gradient(w, h):
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / (w - 1)) * 0.75 + (y / (h - 1)) * 0.25
            px[x, y] = tuple(round(FROM[i] + (TO[i] - FROM[i]) * t) for i in range(3))
    return img


def icon_512():
    # Play wants 512x512, 32-bit PNG, no transparency needed (it rounds it).
    Image.open(ICON).convert("RGB").resize((512, 512), Image.LANCZOS).save(
        os.path.join(OUT, "icon-512.png"), optimize=True
    )


def feature_graphic():
    w, h = 1024, 500
    img = gradient(w, h).convert("RGBA")

    # Soft light in the upper left, as on the icon.
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gp = glow.load()
    for y in range(h):
        for x in range(w):
            d = ((x - w * 0.18) ** 2 + (y - h * 0.15) ** 2) ** 0.5 / (w * 0.55)
            if d < 1:
                gp[x, y] = (255, 255, 255, int(55 * (1 - d) ** 2))
    img = Image.alpha_composite(img, glow)

    # The mark (white ring + question mark), cropped to its ink.
    mark = Image.open(MARK).convert("RGBA")
    mark = mark.crop(mark.getbbox())
    mh = 300
    mark = mark.resize((round(mark.width * mh / mark.height), mh), Image.LANCZOS)
    img.alpha_composite(mark, (110, (h - mh) // 2 + 4))

    draw = ImageDraw.Draw(img)
    title = ImageFont.truetype(SERIF, 104)
    sub = ImageFont.truetype(SANS, 30)
    x = 110 + mark.width + 70
    draw.text((x, 150), "Kaç gün oldu?", font=title, fill=(255, 255, 255))
    draw.text((x + 4, 292), "Son ne zaman yaptığını hep bil.", font=sub,
              fill=(255, 255, 255, 235))

    img.convert("RGB").save(os.path.join(OUT, "feature-graphic.png"), optimize=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    icon_512()
    feature_graphic()
    print("wrote", OUT)
