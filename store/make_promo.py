"""
9:16 promo video for "Kaç Gün Oldu?", built from the app's real screenshots,
icon and fonts, so it always matches the shipped app.

Run from the project root:  python store/make_promo.py
Needs: Pillow, numpy, imageio-ffmpeg (bundles ffmpeg).
Writes store/video/promo.mp4 (1080x1920, 30 fps, H.264 + silent AAC track).
"""
import math
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "store", "screenshots", "raw")
OUT_DIR = os.path.join(ROOT, "store", "video")
FONTS = os.path.join(ROOT, "assets", "fonts")
SERIF = os.path.join(FONTS, "InstrumentSerif_400Regular.ttf")
SANS = os.path.join(FONTS, "Archivo_500Medium.ttf")
SANS_SB = os.path.join(FONTS, "Archivo_600SemiBold.ttf")
SANS_B = os.path.join(FONTS, "Archivo_700Bold.ttf")

W, H, FPS = 1080, 1920, 30

# Brand: the icon's gradient (assets/icon/gen.py) and the app's own surfaces.
FROM = np.array([0xFF, 0x8A, 0x3D], np.float32)
TO = np.array([0xF2, 0x2E, 0x62], np.float32)
CREAM = (251, 245, 240)
INK = (38, 28, 24)
ACCENT = (185, 74, 44)
WHITE = (255, 255, 255)


# ---------------------------------------------------------------- helpers
def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def prog(t, start, dur):
    return clamp((t - start) / dur)


def out_cubic(x):
    return 1 - (1 - x) ** 3


def in_out(x):
    return 4 * x ** 3 if x < 0.5 else 1 - (-2 * x + 2) ** 3 / 2


def out_back(x, s=1.4):
    x -= 1
    return 1 + (s + 1) * x ** 3 + s * x ** 2


_fonts = {}


def font(path, size):
    key = (path, size)
    if key not in _fonts:
        _fonts[key] = ImageFont.truetype(path, size)
    return _fonts[key]


def with_alpha(layer, a):
    if a >= 0.999:
        return layer
    out = layer.copy()
    out.putalpha(layer.getchannel("A").point(lambda v: int(v * a)))
    return out


def over(canvas, layer, x=0, y=0, a=1.0):
    """Composite an RGBA layer at an integer position with extra opacity."""
    if a <= 0.001:
        return
    canvas.alpha_composite(with_alpha(layer, a), (int(round(x)), int(round(y))))


def place(layer, cx, cy, scale=1.0, a=1.0):
    """Layer centred at (cx, cy), scaled, with sub-pixel smoothness."""
    lw, lh = layer.size
    # Output pixel (X, Y) samples input ((X - ox) / s, (Y - oy) / s).
    ox, oy = cx - lw * scale / 2, cy - lh * scale / 2
    inv = 1 / scale
    out = layer.transform(
        (W, H), Image.AFFINE, (inv, 0, -ox * inv, 0, inv, -oy * inv),
        resample=Image.BICUBIC,
    )
    return with_alpha(out, a)


def rich_lines(lines, size, path=SERIF, spacing=1.08, max_w=940):
    """Centred multi-line text; each line is [(text, colour), ...]."""
    f = font(path, size)
    widths = [sum(f.getlength(s) for s, _ in ln) for ln in lines]
    if max(widths) > max_w:
        return rich_lines(lines, int(size * max_w / max(widths)), path, spacing, max_w)
    lh = int(size * spacing)
    img = Image.new("RGBA", (W, lh * len(lines) + size // 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, ln in enumerate(lines):
        x = (W - widths[i]) / 2
        for s, col in ln:
            d.text((x, i * lh), s, font=f, fill=col)
            x += f.getlength(s)
    return img


def text(s, size, col, path=SERIF, spacing=1.08, tracking=0):
    if tracking:
        f = font(path, size)
        total = sum(f.getlength(c) for c in s) + tracking * (len(s) - 1)
        img = Image.new("RGBA", (W, int(size * 1.5)), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        x = (W - total) / 2
        for c in s:
            d.text((x, 0), c, font=f, fill=col)
            x += f.getlength(c) + tracking
        return img
    return rich_lines([[(ln, col)] for ln in s.split("\n")], size, path, spacing)


# ------------------------------------------------------------ backgrounds
_yy, _xx = np.mgrid[0:H, 0:W].astype(np.float32)
_base_t = (_xx / (W - 1)) * 0.35 + (_yy / (H - 1)) * 0.65


def gradient_bg(t):
    """The icon's gradient with a soft light that slowly drifts."""
    g = _base_t[..., None]
    rgb = FROM + (TO - FROM) * g
    gx = W * (0.25 + 0.12 * math.sin(t * 0.5))
    gy = H * (0.18 + 0.06 * math.cos(t * 0.4))
    d = np.sqrt((_xx - gx) ** 2 + (_yy - gy) ** 2) / (W * 0.95)
    glow = np.clip(1 - d, 0, 1) ** 2 * 60
    rgb = np.clip(rgb + glow[..., None], 0, 255).astype(np.uint8)
    return Image.fromarray(rgb, "RGB").convert("RGBA")


def cream_bg():
    return Image.new("RGBA", (W, H), CREAM + (255,))


# ----------------------------------------------------------------- assets
def load_icon(size):
    ic = Image.open(os.path.join(ROOT, "assets", "icon", "icon.png")).convert("RGBA")
    ic = ic.resize((size, size), Image.LANCZOS)
    m = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size * 4 - 1, size * 4 - 1),
                                        radius=int(size * 4 * 0.23), fill=255)
    ic.putalpha(m.resize((size, size), Image.LANCZOS))
    pad = size // 3
    out = Image.new("RGBA", (size + pad * 2, size + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", out.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(
        (pad, pad + size // 14, pad + size, pad + size + size // 14),
        radius=int(size * 0.23), fill=(120, 20, 40, 110))
    out.alpha_composite(sh.filter(ImageFilter.GaussianBlur(size // 10)))
    out.alpha_composite(ic, (pad, pad))
    return out


SCREEN_W = 580
SCREEN_H = round(SCREEN_W * 2400 / 1080)
BEZEL = 16
SCREEN_R = 58


def clean_screen(name):
    """Real screenshot with a tidy status bar and gesture pill."""
    im = Image.open(os.path.join(RAW, name)).convert("RGB")
    bg = im.getpixel((540, 110))
    dark = sum(bg) < 300
    fg = (235, 230, 226) if dark else (30, 24, 22)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 1080, 108), fill=bg)
    d.rectangle((0, 2278, 1080, 2400), fill=bg)
    d.text((70, 30), "9:41", font=font(SANS_SB, 44), fill=fg)
    # signal, wifi-ish bars and battery
    x = 858
    for i in range(4):
        h = 12 + i * 7
        d.rounded_rectangle((x + i * 13, 66 - h, x + i * 13 + 8, 66), radius=2, fill=fg)
    d.rounded_rectangle((930, 40, 990, 68), radius=8, outline=fg, width=3)
    d.rounded_rectangle((936, 46, 976, 62), radius=4, fill=fg)
    d.rounded_rectangle((993, 49, 998, 59), radius=2, fill=fg)
    d.rounded_rectangle((540 - 140, 2350, 540 + 140, 2362), radius=6, fill=fg)
    return im.resize((SCREEN_W, SCREEN_H), Image.LANCZOS)


def phone_parts():
    pw, ph = SCREEN_W + BEZEL * 2, SCREEN_H + BEZEL * 2
    pad = 120
    body = Image.new("RGBA", (pw + pad * 2, ph + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", body.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(
        (pad + 10, pad + 40, pad + pw - 10, pad + ph + 30),
        radius=SCREEN_R + BEZEL, fill=(90, 10, 30, 120))
    body.alpha_composite(sh.filter(ImageFilter.GaussianBlur(45)))
    ImageDraw.Draw(body).rounded_rectangle(
        (pad, pad, pad + pw, pad + ph), radius=SCREEN_R + BEZEL, fill=(22, 20, 22, 255))
    ImageDraw.Draw(body).rounded_rectangle(
        (pad + 2, pad + 2, pad + pw - 2, pad + ph - 2), radius=SCREEN_R + BEZEL - 2,
        outline=(70, 66, 70, 255), width=2)
    m = Image.new("L", (SCREEN_W * 3, SCREEN_H * 3), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, SCREEN_W * 3 - 1, SCREEN_H * 3 - 1),
                                        radius=SCREEN_R * 3, fill=255)
    mask = m.resize((SCREEN_W, SCREEN_H), Image.LANCZOS)
    return body, mask, (pad + BEZEL, pad + BEZEL)


# ----------------------------------------------------------------- scenes
ICON = load_icon(300)
ICON_SMALL = load_icon(230)
SCREENS = {k: clean_screen(v) for k, v in {
    "grid": "01-kartlar.png", "list": "02-liste.png", "ocean": "03-okyanus.png",
    "night": "04-gece.png", "start": "05-baslangic.png"}.items()}
PHONE, SCREEN_MASK, SCREEN_AT = phone_parts()


def scene_intro(t):
    c = gradient_bg(t)
    p = out_back(prog(t, 0.1, 0.8))
    c.alpha_composite(place(ICON, W / 2, 760, 0.55 + 0.45 * p, prog(t, 0.1, 0.35)))
    a = out_cubic(prog(t, 0.6, 0.7))
    title = text("Kaç gün oldu?", 150, WHITE)
    over(c, title, 0, 1010 + 50 * (1 - a), a)
    b = out_cubic(prog(t, 1.0, 0.7))
    sub = text("Son ne zaman yaptığını hep bil.", 46, WHITE, SANS)
    over(c, sub, 0, 1210 + 40 * (1 - b), b * 0.92)
    return c


QUESTIONS = [
    [[("Saçını ", INK), ("en son", ACCENT)], [("ne zaman", ACCENT), (" kestirdin?", INK)]],
    [[("Çarşafları", INK)], [("ne zaman", ACCENT), (" değiştirdin?", INK)]],
    [[("Anneni ", INK), ("en son", ACCENT)], [("ne zaman", ACCENT), (" aradın?", INK)]],
]
Q_LAYERS = [rich_lines(q, 124) for q in QUESTIONS]
BRIDGE = rich_lines([[("Artık", INK)], [("hep bileceksin.", ACCENT)]], 150)
EYEBROW = text("HATIRLIYOR MUSUN?", 36, ACCENT, SANS_B, tracking=7)


def scene_questions(t):
    c = cream_bg()
    ea = prog(t, 0.2, 0.4) * (1 - prog(t, 3.9, 0.3))
    over(c, EYEBROW, 0, 700, ea)
    for i, layer in enumerate(Q_LAYERS):
        s = 0.3 + i * 1.3
        if s - 0.1 <= t <= s + 1.35:
            a_in = out_cubic(prog(t, s, 0.4))
            a_out = prog(t, s + 1.0, 0.3)
            y = 830 + 60 * (1 - a_in) - 50 * in_out(a_out)
            over(c, layer, 0, y, a_in * (1 - a_out))
    b = out_cubic(prog(t, 4.2, 0.5))
    over(c, BRIDGE, 0, 780 + 60 * (1 - b), b)
    return c


CAPTIONS = [
    # (start, end, title, subtitle)
    (0.3, 3.7, "Kaç gün olduğunu\ntek bakışta gör", "Gecikenler hemen göze çarpar"),
    (3.9, 6.9, "Izgara ya da liste,\nsen seç", "Kartları sürükleyerek sırala"),
    (7.1, 10.1, "Altı renk teması", "Gece için koyu tema dahil"),
    (10.3, 14.6, "Önerilerle\nhemen başla", "İlk kartın birkaç saniyede hazır"),
]
CAP_LAYERS = [(s, e, text(a, 104, WHITE), text(b, 40, WHITE, SANS), "\n" in a)
              for s, e, a, b in CAPTIONS]


def screen_at(t):
    """Screen content over the phone segment: slides and cross-fades."""
    S = SCREENS

    def blend(a, b, x):
        return Image.blend(S[a], S[b], in_out(x)) if x > 0 else S[a]

    def slide(a, b, x):
        x = in_out(x)
        if x <= 0:
            return S[a]
        out = S[a].copy()
        off = int(round(SCREEN_W * x))
        out.paste(S[a], (-off, 0))
        out.paste(S[b], (SCREEN_W - off, 0))
        return out

    if t < 3.6:
        return S["grid"]
    if t < 6.9:
        return slide("grid", "list", prog(t, 3.6, 0.55))
    if t < 8.6:
        return blend("list", "ocean", prog(t, 6.9, 0.45))
    if t < 10.2:
        return blend("ocean", "night", prog(t, 8.6, 0.45))
    return slide("night", "start", prog(t, 10.2, 0.55))


def scene_phone(t):
    c = gradient_bg(t + 3)
    for s, e, title, sub, two in CAP_LAYERS:
        if s - 0.1 <= t <= e + 0.1:
            a = out_cubic(prog(t, s, 0.45)) * (1 - prog(t, e - 0.25, 0.25))
            dy = 40 * (1 - out_cubic(prog(t, s, 0.45)))
            lines = 2 if two else 1
            ty = 290 - (lines * 112 + 70) / 2
            over(c, title, 0, ty + dy, a)
            over(c, sub, 0, ty + lines * 112 + 30 + dy, a * 0.9)
    body = PHONE.copy()
    body.paste(screen_at(t), SCREEN_AT, SCREEN_MASK)
    enter = out_cubic(prog(t, 0.0, 0.9))
    scale = 0.97 + 0.03 * (t / 14.6)
    cy = 1205 + 1300 * (1 - enter)
    c.alpha_composite(place(body, W / 2, cy, scale))
    return c


PRIVACY = [text("Hesap yok.", 130, INK), text("Reklam yok.", 130, INK),
           text("Her şey\ntelefonunda.", 130, ACCENT)]


def scene_privacy(t):
    c = cream_bg()
    over(c, EYEBROW_PRIV, 0, 560, prog(t, 0.1, 0.4))
    ys = [680, 850, 1020]
    for i, layer in enumerate(PRIVACY):
        a = out_cubic(prog(t, 0.25 + i * 0.45, 0.45))
        over(c, layer, 0, ys[i] + 50 * (1 - a), a)
    return c


EYEBROW_PRIV = text("GİZLİLİK ÖNCE GELİR", 36, ACCENT, SANS_B, tracking=7)
OUT_TITLE = text("Kaç gün oldu?", 150, WHITE)
OUT_SUB = text("Son ne zaman yaptığını hep bil.", 46, WHITE, SANS)


def cta_pill():
    f = font(SANS_B, 46)
    label = "Hemen indir"
    tw = f.getlength(label)
    pw, ph = int(tw + 140), 118
    pad = 40
    img = Image.new("RGBA", (pw + pad * 2, ph + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((pad, pad + 12, pad + pw, pad + ph + 12),
                                         radius=ph // 2, fill=(120, 20, 40, 90))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(18)))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((pad, pad, pad + pw, pad + ph), radius=ph // 2, fill=WHITE)
    d.text((pad + (pw - tw) / 2, pad + ph / 2), label, font=f, fill=(226, 64, 78),
           anchor="lm")
    return img


CTA = cta_pill()


def scene_outro(t):
    c = gradient_bg(t + 20)
    p = out_back(prog(t, 0.1, 0.8))
    c.alpha_composite(place(ICON_SMALL, W / 2, 720, 0.55 + 0.45 * p, prog(t, 0.1, 0.35)))
    a = out_cubic(prog(t, 0.45, 0.7))
    over(c, OUT_TITLE, 0, 920 + 50 * (1 - a), a)
    b = out_cubic(prog(t, 0.8, 0.7))
    over(c, OUT_SUB, 0, 1120 + 40 * (1 - b), b * 0.92)
    k = prog(t, 1.3, 0.7)
    pulse = 1 + 0.025 * math.sin(max(0, t - 2.2) * 3.2) * (t > 2.2)
    c.alpha_composite(place(CTA, W / 2, 1400, (0.8 + 0.2 * out_back(k)) * pulse,
                            prog(t, 1.3, 0.3)))
    return c


TIMELINE = [  # (start, duration, scene)
    (0.0, 3.0, scene_intro),
    (2.7, 5.5, scene_questions),
    (7.9, 14.6, scene_phone),
    (22.2, 2.6, scene_privacy),
    (24.5, 4.5, scene_outro),
]
XFADE = 0.3
TOTAL = TIMELINE[-1][0] + TIMELINE[-1][1]


def frame(t):
    active = [(s, d, f) for s, d, f in TIMELINE if s <= t < s + d]
    s, d, f = active[0]
    img = f(t - s)
    if len(active) > 1:
        s2, _, f2 = active[1]
        img = Image.blend(img, f2(t - s2), in_out(prog(t, s2, XFADE)))
    return img.convert("RGB")


def main():
    import imageio_ffmpeg

    os.makedirs(OUT_DIR, exist_ok=True)
    out = os.path.join(OUT_DIR, "promo.mp4")
    if len(sys.argv) > 1 and sys.argv[1] == "--stills":
        for t in [float(x) for x in sys.argv[2:]]:
            frame(t).save(os.path.join(OUT_DIR, f"still_{t:05.2f}.png"))
        return
    n = int(round(TOTAL * FPS))
    cmd = [imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS),
           "-i", "-", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
           "-shortest", "-c:v", "libx264", "-preset", "slow", "-crf", "17",
           "-pix_fmt", "yuv420p", "-profile:v", "high", "-c:a", "aac", "-b:a", "128k",
           "-movflags", "+faststart", out]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    for i in range(n):
        proc.stdin.write(frame(i / FPS).tobytes())
        if i % 60 == 0:
            print(f"{i}/{n}", flush=True)
    proc.stdin.close()
    proc.wait()
    print("wrote", out)


if __name__ == "__main__":
    main()
