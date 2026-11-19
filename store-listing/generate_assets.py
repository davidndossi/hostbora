#!/usr/bin/env python3
"""Compose Play / App Store listing graphics from images/host_bora_logo.png."""

from __future__ import annotations

from io import BytesIO
from pathlib import Path

import cairosvg
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
HERE = Path(__file__).resolve().parent
ASSETS = HERE / "assets"
FONTS = HERE / "fonts"
LOGO_SRC = ROOT / "images" / "host_bora_logo.png"
WORDMARK_LIGHT = ROOT / "website" / "assets" / "ui" / "wordmark-light.svg"

TEAL = (28, 110, 100)
TEAL_DEEP = (10, 52, 59)
TEAL_MID = (28, 110, 100)
TEAL_BRIGHT = (49, 212, 179)
HERO_TOP = (10, 41, 37)
INK = (31, 31, 31)
WHITE = (255, 255, 255)
LIME = (139, 213, 42)

SLIDES = {
    "en": [
        {
            "kicker": "Property management",
            "title": "One app for\nrent and BnB.",
            "sub": "Landlords, managers, and hosts in Tanzania.",
        },
        {
            "kicker": "Money",
            "title": "Who paid.\nWho owes.\nToday.",
            "sub": "TZS · M-Pesa · Mixx · Airtel Money",
        },
        {
            "kicker": "Tenants",
            "title": "WhatsApp\nreminders.",
            "sub": "Rent due and lease-end — sent from the app.",
        },
        {
            "kicker": "Tanzania",
            "title": "Works when\nthe network\nis weak.",
            "sub": "Record offline. Sync when you are back.",
        },
    ],
    "sw": [
        {
            "kicker": "Usimamizi wa majengo",
            "title": "App moja ya\nkodi na BnB.",
            "sub": "Kwa wamiliki, wasimamizi, na wenyeji Tanzania.",
        },
        {
            "kicker": "Pesa",
            "title": "Nani amelipa.\nNani anadaiwa.\nLeo.",
            "sub": "TZS · M-Pesa · Mixx · Airtel Money",
        },
        {
            "kicker": "Wapangaji",
            "title": "Vikumbusho\nvya WhatsApp.",
            "sub": "Kodi na mkataba — kutoka kwenye app.",
        },
        {
            "kicker": "Tanzania",
            "title": "Inafanya kazi\nmtandao ukiwa\ndhaifu.",
            "sub": "Rekodi nje ya mtandao. Sawazisha unaporejea.",
        },
    ],
}

HERO_DIR = ROOT / "website" / "assets" / "ui" / "hero"
WHATSAPP_ICON = ROOT / "website" / "assets" / "ui" / "icon-whatsapp.svg"
PHONE_MOCKUP = HERO_DIR / "phone-mockup.png"
WA_GREEN = (37, 211, 102)

FEATURE = {
    "en": {
        "title": "One app for\nrent and BnB.",
        "sub": "TZS payments · WhatsApp reminders\nWorks offline",
        "chips": [
            ("whatsapp", "WhatsApp reminders"),
            ("calendar", "Host Calendar"),
            ("receipt", "Daily Report"),
            ("key", "Guest Access"),
        ],
    },
    "sw": {
        "title": "App moja ya\nkodi na BnB.",
        "sub": "Malipo ya TZS · Vikumbusho vya WhatsApp\nInafanya kazi nje ya mtandao",
        "chips": [
            ("whatsapp", "Vikumbusho vya WhatsApp"),
            ("calendar", "Kalenda ya mwenyeji"),
            ("receipt", "Ripoti ya kila siku"),
            ("key", "Ufikiaji wa wageni"),
        ],
    },
}

CHIP_ICON_BG = {
    "whatsapp": WA_GREEN,
    "calendar": (245, 202, 188),
    "receipt": (220, 181, 243),
    "key": (216, 241, 184),
}


def inter(size: int, weight: int = 500) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONTS / "InterTight-Regular.ttf"), size)
    font.set_variation_by_axes([weight])
    return font


def serif(size: int, italic: bool = False) -> ImageFont.FreeTypeFont:
    name = "InstrumentSerif-Italic.ttf" if italic else "InstrumentSerif-Regular.ttf"
    return ImageFont.truetype(str(FONTS / name), size)


def trim_white(im: Image.Image, threshold: int = 8) -> Image.Image:
    bg = Image.new("RGB", im.size, WHITE)
    diff = ImageChops.difference(im.convert("RGB"), bg)
    diff = diff.point(lambda p: 0 if p < threshold else 255)
    bbox = diff.getbbox()
    if not bbox:
        return im
    return im.crop(bbox)


def logo_rgba() -> Image.Image:
    im = Image.open(LOGO_SRC).convert("RGBA")
    return trim_white(im)


def raster_wordmark(width: int) -> Image.Image:
    buf = BytesIO()
    cairosvg.svg2png(url=str(WORDMARK_LIGHT), write_to=buf, output_width=width)
    return Image.open(buf).convert("RGBA")


def vertical_gradient(size: tuple[int, int], top=HERO_TOP, bot=TEAL_BRIGHT) -> Image.Image:
    w, h = size
    t = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    rgb = np.empty((h, w, 3), dtype=np.uint8)
    for i in range(3):
        col = top[i] + (bot[i] - top[i]) * t
        rgb[:, :, i] = np.broadcast_to(col.astype(np.uint8), (h, w))
    return Image.fromarray(rgb, "RGB")


def paste_center(base: Image.Image, overlay: Image.Image, box: tuple[int, int, int, int], pad: float = 0.16) -> None:
    x0, y0, x1, y1 = box
    bw, bh = x1 - x0, y1 - y0
    max_w, max_h = int(bw * (1 - pad)), int(bh * (1 - pad))
    ow, oh = overlay.size
    scale = min(max_w / ow, max_h / oh)
    nw, nh = max(1, int(ow * scale)), max(1, int(oh * scale))
    fitted = overlay.resize((nw, nh), Image.Resampling.LANCZOS)
    px = x0 + (bw - nw) // 2
    py = y0 + (bh - nh) // 2
    base.alpha_composite(fitted, (px, py))


def rounded_white_card(size: int, radius: int) -> Image.Image:
    card = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(card)
    d.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=(*WHITE, 255))
    return card


def draw_wrapped(draw: ImageDraw.ImageDraw, text: str, font, fill, x: int, y: int, max_width: int, align="left") -> int:
    lines: list[str] = []
    for para in text.split("\n"):
        words = para.split(" ")
        line = ""
        for word in words:
            trial = word if not line else f"{line} {word}"
            if draw.textlength(trial, font=font) <= max_width:
                line = trial
            else:
                if line:
                    lines.append(line)
                line = word
        lines.append(line)
    top = y
    for line in lines:
        w = draw.textlength(line, font=font)
        lx = x if align == "left" else x - int(w // 2)
        draw.text((lx, top), line, font=font, fill=fill)
        bbox = font.getbbox(line)
        top += bbox[3] - bbox[1] + int(font.size * 0.18)
    return top


def compose_icon(size: int) -> Image.Image:
    canvas = Image.new("RGB", (size, size), WHITE)
    layer = canvas.convert("RGBA")
    mark = logo_rgba()
    paste_center(layer, mark, (0, 0, size, size), pad=0.18)
    return layer.convert("RGB")


def radial_glow(size: tuple[int, int], center: tuple[int, int], radius: int, color, alpha: int) -> Image.Image:
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt((xx - center[0]) ** 2 + (yy - center[1]) ** 2) / radius
    a = np.clip(1.0 - d, 0, 1) ** 2 * alpha
    layer = np.zeros((h, w, 4), dtype=np.uint8)
    layer[:, :, 0], layer[:, :, 1], layer[:, :, 2] = color
    layer[:, :, 3] = a.astype(np.uint8)
    return Image.fromarray(layer, "RGBA")


def dashed_rounded_rect(
    draw: ImageDraw.ImageDraw,
    box: tuple[float, float, float, float],
    radius: float,
    fill,
    width: int,
    dash: float,
    gap: float,
) -> None:
    """Dashed outline for a pill / rounded rect, walked as a polyline."""
    import math

    x0, y0, x1, y1 = box
    r = min(radius, (x1 - x0) / 2, (y1 - y0) / 2)
    pts: list[tuple[float, float]] = []
    steps = 14

    def arc(cx, cy, a0, a1):
        for i in range(steps + 1):
            a = math.radians(a0 + (a1 - a0) * i / steps)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))

    pts.append((x0 + r, y0))
    pts.append((x1 - r, y0))
    arc(x1 - r, y0 + r, -90, 0)
    pts.append((x1, y1 - r))
    arc(x1 - r, y1 - r, 0, 90)
    pts.append((x0 + r, y1))
    arc(x0 + r, y1 - r, 90, 180)
    pts.append((x0, y0 + r))
    arc(x0 + r, y0 + r, 180, 270)
    pts.append(pts[0])

    # Resample the path into dash segments
    on = True
    remain = dash
    prev = pts[0]
    seg_start = prev
    for cur in pts[1:]:
        sx, sy = prev
        ex, ey = cur
        dist = math.hypot(ex - sx, ey - sy)
        if dist == 0:
            continue
        ux, uy = (ex - sx) / dist, (ey - sy) / dist
        pos = 0.0
        while pos < dist:
            step = min(remain, dist - pos)
            nx, ny = sx + ux * (pos + step), sy + uy * (pos + step)
            if on:
                draw.line([seg_start, (nx, ny)], fill=fill, width=width)
            pos += step
            remain -= step
            seg_start = (nx, ny)
            if remain <= 1e-6:
                on = not on
                remain = dash if on else gap
        prev = cur


def feature_chip(kind: str, label: str, scale: int) -> Image.Image:
    """Floating pill with dashed ring, matching the website hero chips."""
    s = scale
    font = inter(15 * s, 600)
    tmp = ImageDraw.Draw(Image.new("RGBA", (4, 4)))
    text_w = int(tmp.textlength(label, font=font))
    icon_d = 34 * s
    pad = 6 * s
    gap = 9 * s
    pill_w = pad + icon_d + gap + text_w + 16 * s
    pill_h = icon_d + pad * 2
    ring_pad = 6 * s
    w, h = pill_w + ring_pad * 2 + 8 * s, pill_h + ring_pad * 2 + 16 * s
    chip = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    ox, oy = ring_pad + 4 * s, ring_pad + 4 * s
    # Soft drop shadow
    sh = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(
        (ox, oy + 5 * s, ox + pill_w, oy + pill_h + 5 * s), radius=pill_h // 2, fill=(0, 20, 18, 90)
    )
    chip.alpha_composite(sh.filter(ImageFilter.GaussianBlur(7 * s)))

    d = ImageDraw.Draw(chip)
    # Dashed ring (translucent white)
    dashed_rounded_rect(
        d,
        (ox - ring_pad, oy - ring_pad, ox + pill_w + ring_pad, oy + pill_h + ring_pad),
        radius=(pill_h + ring_pad * 2) / 2,
        fill=(255, 255, 255, 170),
        width=max(1, int(1.2 * s)),
        dash=5 * s,
        gap=4 * s,
    )
    # Pill
    d.rounded_rectangle((ox, oy, ox + pill_w, oy + pill_h), radius=pill_h // 2, fill=(255, 255, 255, 238))
    # Icon disc
    ix, iy = ox + pad, oy + pad
    d.ellipse((ix, iy, ix + icon_d, iy + icon_d), fill=(*CHIP_ICON_BG[kind], 255))
    icon_px = int(icon_d * (0.56 if kind == "whatsapp" else 0.54))
    src = WHATSAPP_ICON if kind == "whatsapp" else HERO_DIR / f"icon-{kind}.svg"
    buf = BytesIO()
    cairosvg.svg2png(url=str(src), write_to=buf, output_width=icon_px, output_height=icon_px)
    icon = Image.open(buf).convert("RGBA")
    chip.alpha_composite(icon, (ix + (icon_d - icon_px) // 2, iy + (icon_d - icon_px) // 2))
    # Label
    d.text((ix + icon_d + gap, oy + pill_h // 2), label, font=font, fill=INK, anchor="lm")
    return chip


def phone_cutout(height: int) -> Image.Image:
    """App phone from the website hero, trimmed of its empty canvas."""
    src = Image.open(PHONE_MOCKUP).convert("RGBA")
    # Opaque phone bounds are (1550, 347)-(2556, 2421).
    crop = src.crop((1490, 290, 2620, 2480))

    # The mockup ships with a grey baked-in drop shadow that smears on a dark
    # background. Keep only the phone silhouette (feathered), then add our own.
    alpha = crop.split()[3]
    body = alpha.point(lambda a: 255 if a > 200 else 0)
    body = body.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.GaussianBlur(2))
    clean_alpha = ImageChops.multiply(alpha, body)
    crop.putalpha(clean_alpha)

    ratio = height / crop.height
    return crop.resize((int(crop.width * ratio), height), Image.Resampling.LANCZOS)


def with_drop_shadow(phone: Image.Image, blur: int, offset: tuple[int, int], opacity: int) -> Image.Image:
    pad = blur * 3
    out = Image.new("RGBA", (phone.width + pad * 2, phone.height + pad * 2), (0, 0, 0, 0))
    shadow = Image.new("RGBA", phone.size, (0, 12, 10, 0))
    shadow.putalpha(phone.split()[3].point(lambda a: a * opacity // 255))
    shadow_canvas = Image.new("RGBA", out.size, (0, 0, 0, 0))
    shadow_canvas.alpha_composite(shadow, (pad + offset[0], pad + offset[1]))
    shadow_canvas = shadow_canvas.filter(ImageFilter.GaussianBlur(blur))
    out.alpha_composite(shadow_canvas)
    out.alpha_composite(phone, (pad, pad))
    return out


def compose_feature(lang: str) -> Image.Image:
    S = 2  # supersample, downscale at the end
    w, h = 1024 * S, 500 * S
    copy = FEATURE[lang]

    bg = vertical_gradient((w, h), HERO_TOP, (24, 118, 104)).convert("RGBA")
    px, py = int(790 * S), int(250 * S)  # visual centre of the phone cluster
    bg.alpha_composite(radial_glow((w, h), (px, int(210 * S)), int(430 * S), (49, 212, 179), 150))
    bg.alpha_composite(radial_glow((w, h), (int(120 * S), int(60 * S)), int(380 * S), (28, 110, 100), 110))

    # Concentric dashed-style rings behind the phone
    ring = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    for r, a in ((175, 70), (260, 48), (350, 30)):
        rr = r * S
        rd.ellipse((px - rr, py - rr, px + rr, py + rr), outline=(255, 255, 255, a), width=max(1, S))
    bg.alpha_composite(ring)
    im = bg

    # Phone: bleeds off the bottom edge
    phone_h = int(610 * S)
    phone = phone_cutout(phone_h)
    phone = with_drop_shadow(phone, blur=int(18 * S), offset=(int(-10 * S), int(14 * S)), opacity=150)
    phone = phone.rotate(-5, resample=Image.Resampling.BICUBIC, expand=True)
    phone_x = px - phone.width // 2 - int(8 * S)
    phone_y = int(-26 * S)  # padded shadow canvas starts above the frame; phone top lands near y≈50
    im.paste(phone, (phone_x, phone_y), phone)

    # Floating feature chips
    chips = [feature_chip(kind, label, S) for kind, label in copy["chips"]]
    right_edge = w - int(30 * S)
    placements = [
        (px - int(300 * S), int(112 * S)),  # WhatsApp: upper-left of the phone
        (px - int(250 * S), int(318 * S)),  # Calendar: lower-left
        (right_edge - chips[2].width, int(150 * S)),  # Report: upper-right
        (right_edge - chips[3].width + int(6 * S), int(332 * S)),  # Access: lower-right
    ]
    for chip, (cx, cy) in zip(chips, placements):
        im.alpha_composite(chip, (cx, cy))

    # Left column: logo mark + wordmark, headline, sub
    left = int(60 * S)
    mark = logo_rgba()
    mark_h = int(52 * S)
    mark = mark.resize((int(mark.width * mark_h / mark.height), mark_h), Image.Resampling.LANCZOS)
    tile = rounded_white_card(mark_h + int(14 * S), radius=int(14 * S))
    im.alpha_composite(tile, (left, int(54 * S)))
    paste_center(im, mark, (left, int(54 * S), left + tile.width, int(54 * S) + tile.height), pad=0.2)
    word = raster_wordmark(int(150 * S))
    im.alpha_composite(word, (left + tile.width + int(14 * S), int(54 * S) + (tile.height - word.height) // 2))

    draw = ImageDraw.Draw(im)
    title_font = serif(int(70 * S))
    ty = int(150 * S)
    end = draw_wrapped(draw, copy["title"], title_font, WHITE, left, ty, int(480 * S))
    sub_font = inter(int(19 * S), 500)
    draw_wrapped(draw, copy["sub"], sub_font, (214, 244, 236), left, end + int(22 * S), int(400 * S))

    return im.convert("RGB").resize((1024, 500), Image.Resampling.LANCZOS)


def compose_phone(size: tuple[int, int], lang: str, slide: dict) -> Image.Image:
    w, h = size
    rgb = vertical_gradient(size, HERO_TOP, TEAL_BRIGHT)
    im = rgb.convert("RGBA")
    draw = ImageDraw.Draw(im)

    # Logo card
    card_size = int(w * 0.42)
    card = rounded_white_card(card_size, radius=int(card_size * 0.22))
    cx = (w - card_size) // 2
    cy = int(h * 0.14)
    shadow = Image.new("RGBA", (card_size + 40, card_size + 40), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (10, 16, card_size + 10, card_size + 22),
        radius=int(card_size * 0.24),
        fill=(0, 0, 0, 50),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    im.alpha_composite(shadow, (cx - 10, cy - 6))
    im.alpha_composite(card, (cx, cy))
    paste_center(im, logo_rgba(), (cx, cy, cx + card_size, cy + card_size), pad=0.16)

    word = raster_wordmark(int(w * 0.52))
    wx = (w - word.size[0]) // 2
    wy = cy + card_size + int(h * 0.035)
    im.alpha_composite(word, (wx, wy))

    kicker_font = inter(int(w * 0.032), 600)
    title_font = serif(int(w * 0.078))
    sub_font = inter(int(w * 0.036), 500)

    ky = wy + word.size[1] + int(h * 0.04)
    draw.text((w // 2, ky), slide["kicker"].upper(), font=kicker_font, fill=LIME, anchor="mt")
    ty = ky + int(h * 0.038)
    title_end = draw_wrapped(
        draw,
        slide["title"],
        title_font,
        WHITE,
        w // 2,
        ty,
        int(w * 0.82),
        align="center",
    )
    draw_wrapped(
        draw,
        slide["sub"],
        sub_font,
        (230, 245, 240),
        w // 2,
        title_end + int(h * 0.028),
        int(w * 0.78),
        align="center",
    )
    return im.convert("RGB")


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    compose_icon(512).save(ASSETS / "icon-512.png", "PNG")
    compose_icon(1024).save(ASSETS / "icon-1024.png", "PNG")
    for lang in ("en", "sw"):
        compose_feature(lang).save(ASSETS / f"feature-graphic-{lang}.png", "PNG")
        for i, slide in enumerate(SLIDES[lang], start=1):
            compose_phone((1080, 1920), lang, slide).save(
                ASSETS / f"phone-play-{lang}-{i}.png", "PNG"
            )
            compose_phone((1290, 2796), lang, slide).save(
                ASSETS / f"phone-ios-{lang}-{i}.png", "PNG"
            )
    print("Wrote", len(list(ASSETS.glob("*.png"))), "files to", ASSETS)


if __name__ == "__main__":
    main()
