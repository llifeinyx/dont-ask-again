"""ND-OS in the style of Ubuntu 12.04 (Unity launcher + Ambiance theme)."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageOps
from kit import Canvas, font, W, H, S, DIFF, QUEUE, NAME
from osk import icon_echo, icon_eye, icon_feed, icon_seeya, icon_terminal, icon_files, icon_gear, icon_lock

import os
FD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fonts") + "/"
U = FD + "Ubuntu-400.ttf"; UM = FD + "Ubuntu-500.ttf"; UB = FD + "Ubuntu-700.ttf"; UMONO = FD + "UbuntuMono-400.ttf"
u7 = font(U, 7.5); u8 = font(U, 8.5); u8m = font(UM, 8.5); u8b = font(UB, 8.5); u7b = font(UB, 7.5)
u11b = font(UB, 11); mono = font(UMONO, 8.5)

ORANGE = (233, 84, 32); ORANGE_L = (240, 119, 70)
PANEL_TXT = (223, 219, 210)
TXT = (60, 60, 60); TXT2 = (110, 108, 104)
BGL = (242, 241, 240); BORDER = (182, 178, 171); WHITE = (255, 255, 255)


def vgrad(c, x0, y0, x1, y1, top, bot, r=0):
    """Vertical gradient rectangle (optionally rounded)."""
    w, h = int((x1 - x0) * S), int((y1 - y0) * S)
    t = np.linspace(0, 1, h)[:, None]
    arr = (np.array(top)[None, None, :] * (1 - t[..., None]) + np.array(bot)[None, None, :] * t[..., None])
    arr = np.repeat(arr, w, axis=1).astype(np.uint8)
    tile = Image.fromarray(arr, "RGB")
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], radius=int(r * S), fill=255)
    c.im.paste(tile, (int(x0 * S), int(y0 * S)), mask)


def wallpaper(c):
    h, w = H * S, W * S
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    nx, ny = xx / w, yy / h
    base = np.stack([48 + 0 * nx, 10 + 0 * nx, 36 + 0 * nx], -1)
    glow = np.exp(-(((nx - 0.15) / 0.55) ** 2 + ((ny - 1.05) / 0.45) ** 2))
    glow2 = np.exp(-(((nx - 0.75) / 0.6) ** 2 + ((ny - 0.25) / 0.5) ** 2))
    wave = np.clip(1 - np.abs(ny - (0.85 - 0.5 * nx + 0.08 * np.sin(nx * 6))) / 0.05, 0, 1) * 0.35
    col = base + glow[..., None] * np.array([190, 70, 20]) + glow2[..., None] * np.array([70, 20, 70]) + wave[..., None] * np.array([255, 150, 120])
    c.im.paste(Image.fromarray(np.clip(col, 0, 255).astype(np.uint8), "RGB"), (0, 0))


def top_panel(c, mail=True, watching=True):
    vgrad(c, 0, 0, 640, 18, (80, 79, 74), (60, 59, 55))
    c.line([(0, 18), (640, 18)], (34, 33, 30))
    c.text(10, 9, "ND-OS", u7b, PANEL_TXT, "lm")
    x = 634
    # session cog
    icon_gear(c, x - 6, 9, PANEL_TXT, 0.48); x -= 22
    c.text(x, 9, "Tue 12:44", u8, PANEL_TXT, "rm"); x -= c.tw("Tue 12:44", u8) + 14
    # sound
    c.poly([(x - 9, 7), (x - 7, 7), (x - 4, 4.5), (x - 4, 13.5), (x - 7, 11), (x - 9, 11)], fill=PANEL_TXT)
    c.arc(x - 4, 9, 3, -50, 50, PANEL_TXT, 1); c.arc(x - 4, 9, 5.5, -50, 50, PANEL_TXT, 1); x -= 22
    # messaging envelope: lights up when there is mail
    env = (110, 170, 230) if mail else PANEL_TXT
    c.rect(x - 11, 4.5, x - 1, 13.5, outline=env, w=1.1)
    c.line([(x - 10.5, 5), (x - 6, 9.5), (x - 1.5, 5)], env, 1.1); x -= 22
    # network
    for r in (2, 4.5, 7):
        c.arc(x - 5, 13, r, 225, 315, PANEL_TXT, 1.2)
    x -= 22
    # Kontur indicator
    c.eye(x - 6, 9, 7, 3.2, watching, (240, 90, 80) if watching else PANEL_TXT, lw=1.1)


def launcher(c, active="echo", badges=None):
    badges = badges or {}
    lay = Image.new("RGBA", c.im.size, (0, 0, 0, 0))
    ImageDraw.Draw(lay).rectangle([0, 18 * S, 44 * S, H * S], fill=(30, 28, 27, 225))
    c.im.paste(lay, (0, 0), lay)
    c.line([(44, 18), (44, 480)], (70, 68, 64), 0.6)
    # dash button
    vgrad(c, 6, 23, 38, 53, (90, 88, 84), (55, 53, 50), r=6)
    c.circle(22, 38, 8, outline=WHITE, w=1.6)
    c.text(22, 38, "nd", font(UB, 7), WHITE, "mm")
    apps = [("echo", icon_echo, (233, 84, 32), (196, 60, 18)), ("kontur", icon_eye, (200, 40, 40), (150, 25, 25)),
            ("feed", icon_feed, (115, 168, 60), (80, 130, 40)), ("seeya", icon_seeya, (66, 120, 190), (40, 85, 150))]
    for i, (k, fn, top, bot) in enumerate(apps):
        y = 76 + i * 40
        vgrad(c, 6, y - 15, 38, y + 15, top, bot, r=6)
        # glossy highlight
        hl = Image.new("RGBA", c.im.size, (0, 0, 0, 0))
        ImageDraw.Draw(hl).rounded_rectangle([7 * S, (y - 14) * S, 37 * S, (y - 2) * S], radius=5 * S, fill=(255, 255, 255, 38))
        c.im.paste(hl, (0, 0), hl)
        fn(c, 22, y, WHITE, 0.78)
        # running pip (left) and focus pip (right)
        c.poly([(0, y - 3.5), (3.5, y), (0, y + 3.5)], fill=WHITE)
        if k == active:
            c.poly([(44, y - 3.5), (40.5, y), (44, y + 3.5)], fill=WHITE)
        b = badges.get(k)
        if b:
            bw = c.tw(b, u7b) + 8
            c.rect(40 - bw, y - 19, 41, y - 9, fill=(250, 250, 250), outline=(120, 118, 114), r=5)
            c.text(40.5 - bw / 2, y - 14, b, u7b, (60, 60, 60), "mm")
    # locked system apps
    for i, (fn, top, bot) in enumerate([(icon_terminal, (60, 60, 60), (30, 30, 30)), (icon_files, (210, 140, 60), (170, 100, 30)), (icon_gear, (110, 108, 104), (80, 78, 74))]):
        y = 248 + i * 40
        vgrad(c, 6, y - 15, 38, y + 15, top, bot, r=6)
        fn(c, 22, y, WHITE, 0.7)
        dim = Image.new("RGBA", c.im.size, (0, 0, 0, 0))
        ImageDraw.Draw(dim).rounded_rectangle([6 * S, (y - 15) * S, 38 * S, (y + 15) * S], radius=6 * S, fill=(20, 18, 18, 150))
        c.im.paste(dim, (0, 0), dim)
        c.circle(33, y + 10, 5.5, fill=(250, 250, 250))
        icon_lock(c, 33, y + 10.5, (60, 60, 60), 0.7)
    # trash
    y = 456
    vgrad(c, 6, y - 15, 38, y + 15, (75, 73, 70), (50, 48, 45), r=6)
    c.rect(15, y - 6, 29, y + 9, outline=WHITE, w=1.2)
    c.line([(13, y - 8), (31, y - 8)], WHITE, 1.4)


def window(c, x0, y0, x1, y1, title, protected=False, focused=True):
    sh = Image.new("RGBA", c.im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([(x0 - 2) * S, (y0 + 2) * S, (x1 + 2) * S, (y1 + 5) * S], radius=6 * S, fill=(0, 0, 0, 120))
    sh = sh.filter(ImageFilter.GaussianBlur(6))
    c.im.paste(sh, (0, 0), sh)
    vgrad(c, x0, y0, x1, y0 + 22, (88, 86, 80) if focused else (70, 69, 65), (60, 59, 55), r=5)
    c.rect(x0, y0 + 16, x1, y0 + 22, fill=(60, 59, 55))
    # window buttons on the left, Ubuntu style
    if protected:
        c.circle(x0 + 12, y0 + 11, 6, fill=(110, 108, 104))
        icon_lock(c, x0 + 12, y0 + 11.5, (50, 50, 50), 0.6)
    else:
        vgrad(c, x0 + 6, y0 + 5, x0 + 18, y0 + 17, (246, 156, 118), ORANGE, r=6)
        c.line([(x0 + 9.5, y0 + 8.5), (x0 + 14.5, y0 + 13.5)], (60, 30, 20), 1.3)
        c.line([(x0 + 14.5, y0 + 8.5), (x0 + 9.5, y0 + 13.5)], (60, 30, 20), 1.3)
    for k, sym in enumerate(["min", "max"]):
        cx = x0 + 27 + k * 15
        vgrad(c, cx - 6, y0 + 5, cx + 6, y0 + 17, (130, 128, 122), (85, 83, 78), r=6)
        if sym == "min":
            c.line([(cx - 3, y0 + 13), (cx + 3, y0 + 13)], (40, 40, 40), 1.3)
        else:
            c.rect(cx - 3, y0 + 8, cx + 3, y0 + 14, outline=(40, 40, 40), w=1.1)
    c.text((x0 + x1) / 2, y0 + 11, title, u8b, PANEL_TXT if focused else (160, 158, 152), "mm")
    c.rect(x0, y0 + 22, x1, y1, fill=BGL)
    return x0, y0 + 22, x1, y1


def gtk_button(c, x0, y0, x1, y1, label, default=False, f=None):
    vgrad(c, x0, y0, x1, y1, (252, 252, 251), (224, 222, 219), r=3)
    c.rect(x0, y0, x1, y1, outline=(150, 146, 140) if not default else ORANGE, w=1, r=3)
    c.text((x0 + x1) / 2, (y0 + y1) / 2, label, f or u8, TXT, "mm")


def gtk_entry(c, x0, y0, x1, y1, text="", caret=True):
    c.rect(x0, y0, x1, y1, fill=WHITE, outline=(150, 146, 140), r=2)
    c.line([(x0 + 1, y0 + 1.5), (x1 - 1, y0 + 1.5)], (220, 218, 214), 1)
    c.text(x0 + 5, (y0 + y1) / 2, text, mono, TXT, "lm")
    if caret:
        cx = x0 + 5 + c.tw(text, mono) + 1
        c.line([(cx, y0 + 4), (cx, y1 - 4)], TXT, 0.9)


def progress(c, x0, y0, x1, y1, frac):
    c.rect(x0, y0, x1, y1, fill=(220, 218, 214), outline=(160, 156, 150), r=2)
    vgrad(c, x0 + 1, y0 + 1, x0 + 1 + (x1 - x0 - 2) * frac, y1 - 1, ORANGE_L, (205, 70, 25), r=2)


def notify_osd(c, x0, y0, w, icon_fn, icon_col, title, body):
    h = 46
    lay = Image.new("RGBA", c.im.size, (0, 0, 0, 0))
    ImageDraw.Draw(lay).rounded_rectangle([x0 * S, y0 * S, (x0 + w) * S, (y0 + h) * S], radius=7 * S, fill=(25, 25, 25, 215))
    c.im.paste(lay, (0, 0), lay)
    icon_fn(c, x0 + 20, y0 + 23, icon_col, 0.9)
    c.text(x0 + 40, y0 + 15, title, u8b, WHITE, "lm")
    c.text(x0 + 40, y0 + 30, body, u8, (220, 220, 220), "lm")
