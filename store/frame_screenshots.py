"""
Turns raw phone screenshots into Play Store screenshots.

Play rejects phone screenshots whose long side is more than twice the short
side - a modern 1080x2400 capture is 2.22:1. This puts each capture, with
rounded corners and a soft shadow, on a 1080x1920 (9:16) card in the app's
gradient, under a one-line caption.

Usage (from the project root):
  1. Put captures in store/screenshots/raw/, named so they sort in order, e.g.
     01-kartlar.png. The caption is taken from store/screenshots/captions.txt
     (one line per file, same order) if present, else from the file name.
  2. python store/frame_screenshots.py
  3. Upload store/screenshots/play/*.png (2 to 8 of them) in Play Console.
"""
import glob
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "store", "screenshots", "raw")
OUT = os.path.join(ROOT, "store", "screenshots", "play")
CAPTIONS = os.path.join(ROOT, "store", "screenshots", "captions.txt")
SERIF = os.path.join(ROOT, "assets", "fonts", "InstrumentSerif_400Regular.ttf")

W, H = 1080, 1920
FROM = (0xFF, 0x8A, 0x3D)
TO = (0xF2, 0x2E, 0x62)


def background():
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        c = tuple(round(FROM[i] + (TO[i] - FROM[i]) * t) for i in range(3))
        for x in range(W):
            px[x, y] = c
    return img.convert("RGBA")


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def frame(path, caption):
    card = background()
    shot = Image.open(path).convert("RGB")
    # Fit the capture into the area under the caption.
    top, bottom, side = 300, 70, 110
    box_w, box_h = W - 2 * side, H - top - bottom
    scale = min(box_w / shot.width, box_h / shot.height)
    shot = shot.resize((round(shot.width * scale), round(shot.height * scale)), Image.LANCZOS)
    shot = rounded(shot, 44)
    x, y = (W - shot.width) // 2, top + (box_h - shot.height) // 2

    shadow = Image.new("RGBA", card.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, y + 24, x + shot.width, y + shot.height + 24), 44, fill=(60, 10, 20, 110)
    )
    card = Image.alpha_composite(card, shadow.filter(ImageFilter.GaussianBlur(28)))
    card.alpha_composite(shot, (x, y))

    draw = ImageDraw.Draw(card)
    size = 84
    font = ImageFont.truetype(SERIF, size)
    while draw.textlength(caption, font=font) > W - 120 and size > 48:
        size -= 4
        font = ImageFont.truetype(SERIF, size)
    tw = draw.textlength(caption, font=font)
    draw.text(((W - tw) / 2, 150 - size / 2), caption, font=font, fill=(255, 255, 255))
    return card.convert("RGB")


def main():
    files = sorted(glob.glob(os.path.join(RAW, "*.png")) + glob.glob(os.path.join(RAW, "*.jpg")))
    if not files:
        raise SystemExit(f"No captures in {RAW}")
    captions = []
    if os.path.exists(CAPTIONS):
        captions = [l.strip() for l in open(CAPTIONS, encoding="utf-8") if l.strip()]
    os.makedirs(OUT, exist_ok=True)
    for i, f in enumerate(files):
        name = os.path.splitext(os.path.basename(f))[0]
        caption = captions[i] if i < len(captions) else name.split("-", 1)[-1].replace("-", " ").capitalize()
        frame(f, caption).save(os.path.join(OUT, f"{i + 1:02d}.png"), optimize=True)
        print("framed", name, "->", f"{i + 1:02d}.png", f"({caption})")


if __name__ == "__main__":
    main()
