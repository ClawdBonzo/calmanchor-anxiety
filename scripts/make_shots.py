#!/usr/bin/env python3
"""
CalmAnchor App Store screenshot compositor (no AI, pure PIL).
Produces polished 6.9" (1320x2868) frames:
  - subtle navy gradient bg + soft teal glow behind device
  - hand-built rounded device frame with metal rim + soft drop shadow
  - dynamic-island pill
  - heavy headline (verb + descriptor) with teal accent bar
  - optional "breakout" panel: a band cropped from the screen, scaled up,
    floated over the bezel with its own drop shadow
"""
import argparse, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1320, 2868
FONT = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
TEAL = (0, 201, 183)

# device geometry
SCREEN_W = 855
BEZEL = 26
BODY_W = SCREEN_W + 2 * BEZEL
BODY_R = 130          # device body corner radius
SCREEN_R = 104        # screen corner radius
DEVICE_TOP = 928      # y of device body top


def hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def vgrad(top, bot):
    base = Image.new("RGB", (1, H))
    for y in range(H):
        t = y / H
        base.putpixel((0, y), tuple(int(top[i] + (bot[i]-top[i]) * t) for i in range(3)))
    return base.resize((W, H))


def radial_glow(cx, cy, radius, color, max_a):
    g = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(g)
    steps = 60
    for i in range(steps, 0, -1):
        r = radius * i / steps
        a = int(max_a * (1 - i / steps))
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=a)
    glow = Image.new("RGB", (W, H), color)
    out = Image.new("RGB", (W, H))
    return Image.composite(glow, Image.new("RGB", (W, H), (0, 0, 0)), g), g


def rounded_mask(w, h, r):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w-1, h-1], radius=r, fill=255)
    return m


def fit_font(text, max_w, smax, smin):
    d = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    for s in range(smax, smin-1, -4):
        f = ImageFont.truetype(FONT, s)
        if d.textlength(text, font=f) <= max_w:
            return f
    return ImageFont.truetype(FONT, smin)


def draw_center(draw, cx, y, text, font, fill="white"):
    b = draw.textbbox((0, 0), text, font=font, anchor="lt")
    draw.text((cx, y), text, font=font, fill=fill, anchor="mt")
    return y + (b[3]-b[1])


def compose(bg, verb, desc, shot_path, out, breakout=None):
    bg = hx(bg)
    top = tuple(min(255, c+18) for c in bg)
    canvas = vgrad(top, tuple(max(0, c-8) for c in bg)).convert("RGBA")

    # teal glow behind device top
    glow, gmask = radial_glow(W//2, DEVICE_TOP+120, 760, TEAL, 46)
    canvas = Image.composite(glow.convert("RGBA"), canvas, gmask.point(lambda a: int(a*0.5)))

    draw = ImageDraw.Draw(canvas)

    # ---- headline ----
    cx = W//2
    verb_f = fit_font(verb.upper(), int(W*0.74), 250, 150)
    desc_f = ImageFont.truetype(FONT, 96)
    # teal accent bar
    draw.rounded_rectangle([cx-70, 150, cx+70, 168], radius=9, fill=TEAL)
    y = 210
    y = draw_center(draw, cx, y, verb.upper(), verb_f)
    y += 14
    for line in wrap(desc.upper(), desc_f, int(W*0.78)):
        y = draw_center(draw, cx, y, line, desc_f)
        y += 8

    device_x = (W - BODY_W)//2

    # ---- device drop shadow ----
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(
        [device_x, DEVICE_TOP+30, device_x+BODY_W, H+200], radius=BODY_R, fill=(0, 0, 0, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(55))
    canvas = Image.alpha_composite(canvas, sh)

    # ---- device body (black) with subtle rim ----
    body = Image.new("RGBA", (BODY_W, H-DEVICE_TOP+200), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle([0, 0, BODY_W-1, H-DEVICE_TOP+199], radius=BODY_R, fill=(12, 14, 18, 255))
    # thin lighter rim
    bd.rounded_rectangle([0, 0, BODY_W-1, H-DEVICE_TOP+199], radius=BODY_R, outline=(60, 66, 78, 255), width=3)
    canvas.alpha_composite(body, (device_x, DEVICE_TOP))

    # ---- screen ----
    screen_x = device_x + BEZEL
    screen_y = DEVICE_TOP + BEZEL
    shot = Image.open(shot_path).convert("RGB")
    sc = SCREEN_W / shot.width
    shot = shot.resize((SCREEN_W, int(shot.height*sc)), Image.LANCZOS)
    screen_h = H - screen_y
    screen = Image.new("RGB", (SCREEN_W, screen_h), (0, 0, 0))
    screen.paste(shot, (0, 0))
    sm = rounded_mask(SCREEN_W, screen_h, SCREEN_R)
    canvas.paste(screen, (screen_x, screen_y), sm)

    # ---- dynamic island ----
    iw, ih = 340, 96
    ix = cx - iw//2
    iy = screen_y + 34
    isl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(isl).rounded_rectangle([ix, iy, ix+iw, iy+ih], radius=ih//2, fill=(0, 0, 0, 255))
    canvas = Image.alpha_composite(canvas, isl)

    # ---- breakout panel ----
    if breakout:
        y0f, y1f = breakout
        src = Image.open(shot_path).convert("RGB")
        y0, y1 = int(src.height*y0f), int(src.height*y1f)
        pad = int(src.width*0.04)
        crop = src.crop((pad, y0, src.width-pad, y1))
        scale = (SCREEN_W*1.28) / crop.width
        cw, ch = int(crop.width*scale), int(crop.height*scale)
        crop = crop.resize((cw, ch), Image.LANCZOS)
        r = 42
        pm = rounded_mask(cw, ch, r)
        panel = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        panel.paste(crop, (0, 0), pm)
        # subtle border
        ImageDraw.Draw(panel).rounded_rectangle([0, 0, cw-1, ch-1], radius=r, outline=(255, 255, 255, 40), width=2)
        # place vertically aligned with original position on screen
        py = screen_y + int((y0/src.height)*screen_h) - int(ch*0.08)
        px = cx - cw//2
        # shadow
        psh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(psh).rounded_rectangle([px, py+18, px+cw, py+ch+18], radius=r, fill=(0, 0, 0, 165))
        psh = psh.filter(ImageFilter.GaussianBlur(34))
        canvas = Image.alpha_composite(canvas, psh)
        canvas.alpha_composite(panel, (px, py))

    canvas.convert("RGB").save(out)
    print(f"✓ {out}")


def wrap(text, font, max_w):
    d = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = f"{cur} {w}".strip()
        if d.textlength(t, font=font) <= max_w:
            cur = t
        else:
            lines.append(cur); cur = w
    if cur:
        lines.append(cur)
    return lines


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--bg", required=True); p.add_argument("--verb", required=True)
    p.add_argument("--desc", required=True); p.add_argument("--shot", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--breakout", help="y0,y1 fractions e.g. 0.40,0.56")
    a = p.parse_args()
    bo = tuple(float(x) for x in a.breakout.split(",")) if a.breakout else None
    compose(a.bg, a.verb, a.desc, a.shot, a.out, bo)
