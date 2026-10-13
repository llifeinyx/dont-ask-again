"""Shared OS chrome (ND-OS): top system bar, left dock with icons, window frames, system toasts."""
from kit import *

BAR_H = 18
DOCK_W = 42
WIN = (54, 28, 628, 468)  # active window rect

f7 = font(INTER % "Medium", 7.5)
f7r = font(INTER % "Regular", 7.5)
f8 = font(INTER % "Regular", 8.5)
f8m = font(INTER % "Medium", 8.5)
f8s = font(INTER % "SemiBold", 8.5)


# ---------------------------------------------------------------- icons
def icon_lock(c, x, y, col=D1, s=1.0):
    c.arc(x, y - 2.2 * s, 2.2 * s, 180, 360, col, 1)
    c.rect(x - 3.2 * s, y - 2 * s, x + 3.2 * s, y + 2.8 * s, fill=col, r=0.8)


def icon_echo(c, x, y, col, s=1.0):
    c.circle(x - 5 * s, y, 2.4 * s, fill=col)
    for k, r in enumerate((5, 8.5, 12)):
        c.arc(x - 5 * s, y, r * s, -48, 48, col, 1.5 if k < 2 else 1.2)


def icon_eye(c, x, y, col, s=1.0, open_=True):
    c.eye(x, y, 10 * s, 5 * s, open_, col, lw=1.4)


def icon_feed(c, x, y, col, s=1.0):
    c.poly([(x - 10 * s, y - 3 * s), (x + 10 * s, y - 3 * s), (x + 2.5 * s, y + 5 * s), (x + 2.5 * s, y + 10 * s),
            (x - 2.5 * s, y + 10 * s), (x - 2.5 * s, y + 5 * s)], fill=col)
    for k, dx in enumerate((-6, 0, 6)):
        c.rect(x + (dx - 1.8) * s, y + (-10 + k % 2 * 2) * s, x + (dx + 1.8) * s, y + (-6.4 + k % 2 * 2) * s, fill=col)


def icon_seeya(c, x, y, col, s=1.0, bg=None):
    c.rect(x - 10 * s, y - 7 * s, x + 10 * s, y + 7 * s, outline=col, w=1.4, r=1.5)
    c.line([(x - 9 * s, y - 6 * s), (x, y + 1 * s), (x + 9 * s, y - 6 * s)], col, 1.4)


def icon_terminal(c, x, y, col, s=1.0):
    c.rect(x - 10 * s, y - 8 * s, x + 10 * s, y + 8 * s, outline=col, w=1.2, r=2)
    c.line([(x - 6 * s, y - 3 * s), (x - 2 * s, y), (x - 6 * s, y + 3 * s)], col, 1.2)
    c.line([(x, y + 4 * s), (x + 5 * s, y + 4 * s)], col, 1.2)


def icon_gear(c, x, y, col, s=1.0):
    for k in range(8):
        a = math.radians(k * 45)
        c.line([(x + math.cos(a) * 6 * s, y + math.sin(a) * 6 * s), (x + math.cos(a) * 9.5 * s, y + math.sin(a) * 9.5 * s)], col, 2.2)
    c.circle(x, y, 6.5 * s, outline=col, w=1.6)
    c.circle(x, y, 2.2 * s, fill=col)


def icon_files(c, x, y, col, s=1.0):
    c.poly([(x - 10 * s, y - 7 * s), (x - 3 * s, y - 7 * s), (x - 1 * s, y - 4.5 * s), (x + 10 * s, y - 4.5 * s),
            (x + 10 * s, y + 8 * s), (x - 10 * s, y + 8 * s)], outline=col, w=1.2)


ICONS = {"echo": icon_echo, "kontur": icon_eye, "feed": icon_feed, "seeya": icon_seeya,
         "terminal": icon_terminal, "settings": icon_gear, "files": icon_files}


# ---------------------------------------------------------------- chrome
def wallpaper(c):
    c.rect(DOCK_W, BAR_H, 640, 480, fill=(13, 14, 17))
    # faint corporate watermark
    c.text(340, 300, "N D", font(INTERD % "Black", 120), (17, 18, 22), "mm", track=6)


def top_bar(c, app_name, menus, kontur_alert=False, watching=True):
    c.rect(0, 0, 640, BAR_H, fill=(22, 24, 28))
    c.line([(0, BAR_H), (640, BAR_H)], D3)
    # OS logo + system name only: this is the system taskbar, not an app menu
    c.rect(8, 4, 18, 14, outline=FG, w=1.2, r=2)
    c.rect(11, 7, 15, 11, fill=FG)
    c.text(24, 9, "ND-OS", f8s, FG, "lm")
    c.text(24 + c.tw("ND-OS", f8s) + 10, 9, "operator 0419  ·  room 4-C", f7r, D2, "lm")
    # tray
    tx = 632
    c.text(tx, 9, "Tue 12:44", f7, FG, "rm")
    tx -= c.tw("Tue 12:44", f7) + 12
    # bell
    c.arc(tx - 4, 8, 3.6, 180, 360, D1, 1.2)
    c.line([(tx - 7.6, 8), (tx - 7.6, 11), (tx - 0.4, 11), (tx - 0.4, 8)], D1, 1.2)
    c.line([(tx - 9, 11.5), (tx + 1, 11.5)], D1, 1.2)
    c.circle(tx, 5, 2, fill=RED if kontur_alert else FG)
    tx -= 20
    # volume
    c.poly([(tx - 8, 7), (tx - 6, 7), (tx - 3, 4.5), (tx - 3, 13.5), (tx - 6, 11), (tx - 8, 11)], fill=D1)
    c.arc(tx - 3, 9, 3, -50, 50, D1, 1); c.arc(tx - 3, 9, 5.5, -50, 50, D1, 1)
    tx -= 22
    # network
    for r in (2, 4.5, 7):
        c.arc(tx - 3, 13, r, 225, 315, D1, 1.2)
    tx -= 24
    # kontur eye in tray
    c.eye(tx - 5, 9, 7, 3.2, watching, RED if kontur_alert else FG, lw=1.1)


def dock(c, active, running, badges):
    c.rect(0, BAR_H, DOCK_W, 480, fill=(16, 17, 20))
    c.line([(DOCK_W, BAR_H), (DOCK_W, 480)], D3)
    apps = [("echo", "Echo"), ("kontur", "Kontur"), ("feed", "Feed"), ("seeya", "Seeya")]
    for i, (k, lbl) in enumerate(apps):
        y = 40 + i * 50
        act = k == active
        c.rect(7, y - 14, 35, y + 14, fill=FG if act else (30, 33, 38), r=7)
        col = BG if act else (RED if k == "kontur" and badges.get("kontur") else FG)
        ICONS[k](c, 21, y, col, 0.82)
        if k in running:
            c.rect(1, y - 4, 3, y + 4, fill=FG, r=1)
        c.text(21, y + 21, lbl, font(INTER % "Medium", 6.5), FG if act else D2, "mm")
        b = badges.get(k)
        if b:
            bw = c.tw(b, f7) + 7
            c.rect(37 - bw + 2, y - 18, 39, y - 7, fill=RED if b == "!" else FG, r=5.5)
            c.text(39 - (bw - 2) / 2 - 0.5, y - 12.5, b, f7, BG, "mm")
    # separator + locked system apps
    c.line([(10, 236), (32, 236)], D3)
    for i, k in enumerate(["terminal", "files", "settings"]):
        y = 260 + i * 40
        c.rect(7, y - 14, 35, y + 14, fill=(22, 24, 28), r=7)
        ICONS[k](c, 21, y, D2, 0.72)
        c.rect(27, y + 4, 37, y + 15, fill=(16, 17, 20), r=3)
        icon_lock(c, 32, y + 10, D1, 0.8)
    c.text(21, 470, "ND-OS", font(INTER % "SemiBold", 6), D2, "mm")


def window(c, title, icon_key, protected=False, rect=WIN, legacy=False):
    x0, y0, x1, y1 = rect
    c.rect(x0 + 4, y0 + 5, x1 + 4, y1 + 5, fill=(0, 0, 0), r=8)
    c.rect(x0, y0, x1, y1, fill=BG, outline=D3, r=8)
    c.rect(x0, y0, x1, y0 + 20, fill=(26, 28, 33), r=8)
    c.rect(x0 + 1, y0 + 12, x1 - 1, y0 + 20, fill=(26, 28, 33))
    c.line([(x0, y0 + 20), (x1, y0 + 20)], D3)
    ICONS[icon_key](c, x0 + 14, y0 + 10, FG, 0.5)
    c.text(x0 + 26, y0 + 10, title, f8m, FG, "lm")
    # window controls
    bx = x1 - 12
    if protected:
        c.circle(bx, y0 + 10, 4, fill=(40, 43, 49))
        icon_lock(c, bx, y0 + 10.5, D2, 0.55)
        c.text(bx - 10, y0 + 10, "protected process", f7r, D2, "rm")
    else:
        for k in range(3):
            c.circle(bx - k * 13, y0 + 10, 4, outline=D1, w=1)
    return (x0 + 1, y0 + 21, x1 - 1, y1 - 1)


def toast(c, x1, y0, w, app_title, icon_key, lines, alert=True, input_text=None, time="now", seconds=None):
    x0 = x1 - w
    h = 34 + 12 * len(lines) + (26 if input_text is not None else 0)
    c.rect(x0 + 3, y0 + 4, x1 + 3, y0 + h + 4, fill=(0, 0, 0), r=9)
    c.rect(x0, y0, x1, y0 + h, fill=(30, 32, 37), outline=RED if alert else D2, w=1, r=9)
    ICONS[icon_key](c, x0 + 15, y0 + 13, RED if alert else FG, 0.55)
    c.text(x0 + 27, y0 + 13, app_title, f7, RED if alert else D1, "lm")
    c.text(x1 - 10, y0 + 13, time if seconds is None else "%ds" % seconds, f7, RED if alert else D2, "rm")
    for i, l in enumerate(lines):
        c.text(x0 + 12, y0 + 30 + i * 12, l, f8m if i == 0 else f8, FG if i == 0 else D1, "lm")
    if input_text is not None:
        iy = y0 + 30 + 12 * len(lines) + 2
        c.rect(x0 + 12, iy, x1 - 52, iy + 18, fill=BG, outline=D2, r=4)
        c.text(x0 + 18, iy + 9, input_text, font(MONO, 8.5), FG, "lm")
        c.rect(x1 - 46, iy, x1 - 12, iy + 18, fill=RED if alert else FG, r=4)
        c.text(x1 - 29, iy + 9, "Send", f7, BG, "mm")


def menubar(c, X0, Y0, X1, items, legacy=False):
    """Menu bar that belongs to the window itself (under its title bar)."""
    if legacy:
        c.rect(X0, Y0, X1, Y0 + 15, fill=(58, 60, 66))
        c.line([(X0, Y0 + 15), (X1, Y0 + 15)], (14, 15, 17))
        f = font("/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf", 7.6)
        x = X0 + 8
        for it in items:
            c.text(x, Y0 + 7.5, it[0], font("/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf", 7.6), FG, "lm")
            c.line([(x, Y0 + 11.5), (x + c.tw(it[0], f), Y0 + 11.5)], FG, 0.6)
            c.text(x + c.tw(it[0], f), Y0 + 7.5, it[1:], f, FG, "lm")
            x += c.tw(it, f) + 14
    else:
        c.rect(X0, Y0, X1, Y0 + 15, fill=(18, 19, 23))
        c.line([(X0, Y0 + 15), (X1, Y0 + 15)], D3)
        x = X0 + 10
        for it in items:
            c.text(x, Y0 + 7.5, it, f7r, D1, "lm")
            x += c.tw(it, f7r) + 14
    return Y0 + 16
