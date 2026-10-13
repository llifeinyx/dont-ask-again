"""Kontur.watchdog, Feed.di, Seeya.legacy and the KONTUR check, in the approved terminal style."""
import numpy as np
from PIL import Image, ImageDraw
from ub_echo_alts import T, TILES, DARK, X0, Y0, X1, Y1
from ubuntu import *
from kit import MONO, MONOB

TBG = (13, 13, 12)
FG_ = (198, 196, 188)
BRIGHT = (226, 222, 210)
DIM = (112, 109, 102)
FAINT = (70, 68, 63)
ACC = (205, 172, 92)
RED = (206, 92, 74)
RED_D = (130, 60, 50)
GREEN = (150, 190, 125)
TM = font(MONO, 7.8); TMB = font(MONOB, 7.8)
LH = 11.2
CW = TM.getlength("M") / S
LX = X0 + 12
COLS = int((X1 - X0 - 24) / CW)


# ------------------------------------------------------------------ chrome with any active app
def chrome(active=0, badges=("4", "!", "4/10", "2"), watching=True, mail=True):
    c = Canvas(T["bg"])
    vgrad(c, 0, 0, 640, 18, *T["panel"])
    c.text(10, 9, "ND-OS", u7b, T["ptxt"], "lm")
    c.text(634, 9, "Tue 12:44", u8, T["ptxt"], "rm")
    x = 634 - c.tw("Tue 12:44", u8) - 14
    c.rect(x - 11, 4.5, x - 1, 13.5, outline=T["env"], w=1.1)
    c.line([(x - 10.5, 5), (x - 6, 9.5), (x - 1.5, 5)], T["env"], 1.1)
    if mail:
        c.circle(x, 4, 2.4, fill=T["env"])
    c.eye(x - 30, 9, 7, 3.2, watching, (220, 70, 60) if watching else (150, 140, 120), lw=1.1)
    c.rect(0, 18, 44, 480, fill=T["launcher"])
    for i, (fn, b) in enumerate(zip([icon_echo, icon_eye, icon_feed, icon_seeya], badges)):
        y = 40 + i * 42
        vgrad(c, 6, y - 15, 38, y + 15, *TILES[i], r=6)
        fn(c, 22, y, WHITE, 0.78)
        if i == active:
            c.poly([(0, y - 3.5), (3.5, y), (0, y + 3.5)], fill=T["ptxt"])
            c.poly([(44, y - 3.5), (40.5, y), (44, y + 3.5)], fill=T["bg"])
        if not b:
            continue
        bw = c.tw(b, u7b) + 8
        red = b == "!"
        c.rect(40 - bw, y - 19, 41, y - 9, fill=(200, 50, 40) if red else (250, 246, 236), outline=(110, 100, 84), r=5)
        c.text(40.5 - bw / 2, y - 14, b, u7b, WHITE if red else DARK, "mm")
    for i, fn in enumerate([icon_terminal, icon_files, icon_gear]):
        y = 236 + i * 40
        c.rect(6, y - 15, 38, y + 15, fill=(56, 51, 43), outline=(90, 83, 71), r=6)
        fn(c, 22, y, (130, 120, 100), 0.7)
        c.circle(33, y + 10, 5.5, fill=(244, 239, 228))
        icon_lock(c, 33, y + 10.5, DARK, 0.7)
    c.rect(X0, Y0, X1, Y1, fill=TBG)
    return c


# ------------------------------------------------------------------ terminal grid helpers
def ry(row):
    return Y0 + 14 + row * LH


def cx(col):
    return LX + col * CW


def put(c, row, col, text, color=FG_, bold=False):
    c.text(cx(col), ry(row), text, TMB if bold else TM, color, "lm")


def segs(c, row, parts, col=0):
    for t, colr, *b in parts:
        put(c, row, col, t, colr, bool(b and b[0]))
        col += len(t)
    return col


def rput(c, row, text, color=FG_, bold=False, col=None):
    """right-aligned to the last column (or to `col`)"""
    end = COLS if col is None else col
    put(c, row, end - len(text), text, color, bold)


def frame(c, r0, r1, c0=0, c1=None, color=FAINT):
    c1 = COLS if c1 is None else c1
    c.rect(cx(c0 + 0.5), ry(r0), cx(c1 - 0.5), ry(r1), outline=color, w=0.8, r=4)


def hline(c, row, color=FAINT):
    c.line([(LX, ry(row)), (X1 - 12, ry(row))], color, 0.6)


def bar(c, row, col, ncols, frac, color, back=FAINT):
    x0, x1 = cx(col), cx(col + ncols)
    y = ry(row)
    c.rect(x0, y - 2.5, x1, y + 2.5, fill=(30, 29, 27))
    c.rect(x0, y - 2.5, x0 + (x1 - x0) * frac, y + 2.5, fill=color)


def inverse(c, row, col0, col1, color):
    c.rect(cx(col0), ry(row) - LH / 2 + 0.6, cx(col1), ry(row) + LH / 2 - 0.6, fill=color)


def cursor(c, row, col):
    c.rect(cx(col), ry(row) - 5, cx(col) + CW, ry(row) + 5, fill=FG_)


def footer(c, left, right=""):
    yb = Y1 - 34
    c.line([(LX, yb - 8), (X1 - 12, yb - 8)], FAINT, 0.6)
    c.text(LX, Y1 - 14, left, TM, FAINT, "lm")
    if right:
        c.text(X1 - 12, Y1 - 14, right, TM, DIM, "rm")
    return yb


# ================================================================== Kontur.watchdog
def kontur():
    c = chrome(active=1, badges=("4", "!", "4/10", "2"))
    segs(c, 0, [("kontur.watchdog 4.0", DIM), ("  ·  operator 0419  ·  room 4-C", FAINT)])
    rput(c, 0, "OBSERVING", RED, True)
    c.eye(cx(COLS - 9) - 8, ry(0), 5.5, 2.6, True, RED, lw=1)

    stats = [("status", "present", FG_), ("violations", "1 / 6", ACC),
             ("response", "2.4 s avg", FG_), ("turned away", "3  (logged)", FG_),
             ("shift time", "00:44:10", FG_), ("next check", "irregular", DIM)]
    for i, (k, v, col) in enumerate(stats):
        r, half = 2 + i // 2, (i % 2) * 40
        put(c, r, half, k, DIM)
        put(c, r, half + 13, v, col)
    hline(c, 5.5)

    log = [("12:01:07", "Operator Mira (#0419) registered. Shift 1. Workplace: room 4-C.", DIM),
           ("12:03:40", "Attention check. Enter code 4471.", DIM),
           ("12:03:46", "> 4471", "you"),
           ("12:03:46", "Accepted. Response time 6.1 s.", DIM),
           ("12:09:12", "Rate your current condition from 1 to 10.", DIM),
           ("12:09:20", "> 7", "you"),
           ("12:09:20", "Recorded. The previous operator of room 4-C also answered 7.", DIM),
           ("12:14:55", "Operator turned away from the workstation (4.2 s). Logged.", RED_D),
           ("12:31:02", "Violation 1/6: request #0412 approved without review.", RED)]
    r = 7
    for t, msg, kind in log:
        put(c, r, 0, t, FAINT)
        if kind == "you":
            put(c, r, 10, "you", DIM)
            put(c, r, 18, msg, FG_)
        else:
            put(c, r, 10, "kontur", RED_D if kind is not RED else RED)
            put(c, r, 18, msg, kind if kind in (RED, RED_D) else DIM)
        r += 1

    # open question, framed like the Echo permission box
    r += 1
    put(c, r, 0, "12:44:10", FAINT); put(c, r, 10, "kontur", RED, True)
    put(c, r, 18, "Question 7", BRIGHT, True)
    r += 1
    top = r
    frame(c, top, top + 9, 2, COLS, RED_D)
    put(c, top + 1, 4, "A sound was recorded in your room at 12:07.", BRIGHT)
    put(c, top + 2, 4, "Describe it.", BRIGHT)
    put(c, top + 4, 4, "answer must be typed  ·  min 3 words", DIM)
    put(c, top + 6, 4, "> ", DIM)
    put(c, top + 6, 6, "it was the vent. something moving i", FG_)
    cursor(c, top + 6, 6 + len("it was the vent. something moving i"))
    put(c, top + 8, 4, "no answer in 34s = violation", DIM)
    bar(c, top + 8, 34, 30, 0.62, RED_D)

    footer(c, "type answer · enter send · silence = violation", "1 open")
    return c


# ================================================================== Feed.di
def bayer4():
    b = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32)
    return (b + 0.5) / 16


def corridor_image(w, h, seed=2):
    """grayscale [0..1] picture: a long corridor with a faint figure at the end"""
    rng = np.random.default_rng(seed)
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    vx, vy = w * 0.53, h * 0.46
    dx, dy = (xs - vx) / w, (ys - vy) / h
    # depth: distance to vanishing point in "corridor space" (box tunnel)
    d = np.maximum(np.abs(dx) / 0.5, np.abs(dy) / 0.5)
    depth = 1.0 / np.maximum(d, 0.04)
    img = np.zeros((h, w), np.float32)
    wall = np.abs(dx) / 0.5 > np.abs(dy) / 0.5
    floor = (~wall) & (dy > 0)
    ceil = (~wall) & (dy < 0)
    # lighting: lamps every few meters along the ceiling, falloff with depth
    seg = (depth * 1.2) % 1.0
    lamp = np.exp(-((seg - 0.5) ** 2) / 0.02)
    base = 0.36 / (1 + depth * 0.2)
    img = base * (0.55 + 0.45 * lamp)
    img[floor] *= 0.75 + 0.25 * ((depth[floor] * 3) % 1.0 > 0.92)
    img[ceil] *= 0.6
    img[ceil] += 0.5 * (lamp[ceil] > 0.95) * (np.abs(dx[ceil]) < 0.09 * d[ceil]) / (1 + depth[ceil] * 0.1)
    # doors on the walls
    doorband = ((depth * 0.8) % 1.0 < 0.18) & wall & (np.abs(dy) < 0.32 * d)
    img[doorband] *= 0.55
    # end of the corridor: a dim rectangle
    end = d < 0.08
    img[end] = 0.12
    # the figure: a faint silhouette slightly darker than the end wall, off-center
    fx, fy = vx + w * 0.02, vy + h * 0.035
    head = ((xs - fx) / (w * 0.011)) ** 2 + ((ys - (fy - h * 0.085)) / (h * 0.017)) ** 2 < 1
    body = (np.abs(xs - fx) < w * 0.016 * (1 + 0.6 * (ys - fy + h * 0.07) / (h * 0.16))) & (ys > fy - h * 0.068) & (ys < fy + h * 0.09)
    img[head | body] = 0.02
    img += rng.normal(0, 0.012, img.shape).astype(np.float32)
    return np.clip(img, 0, 1)


def paste_dithered(c, img, x0, y0, levels=4, px=1.0, tint=FG_):
    """img in logical pixels; each logical px drawn as px logical size, ordered-dithered"""
    h, w = img.shape
    b = bayer4()
    th = np.tile(b, (h // 4 + 1, w // 4 + 1))[:h, :w]
    q = np.floor(np.clip(img * 1.6, 0, 1) * (levels - 1) + th) / (levels - 1)
    q = np.clip(q, 0, 1)
    t = np.array(tint, np.float32) / 255
    bg = np.array(TBG, np.float32) / 255
    rgb = bg + (t - bg) * q[..., None]
    im = Image.fromarray((rgb * 255).astype(np.uint8))
    im = im.resize((int(w * px * S), int(h * px * S)), Image.NEAREST)
    c.im.paste(im, (int(x0 * S), int(y0 * S)))


def feed():
    c = chrome(active=2)
    segs(c, 0, [("feed.di 3.1", DIM), ("  ·  batch 0417-C  ·  stream: endless", FAINT)])
    rput(c, 0, "rating 2.4  ·  credits 4", DIM)
    put(c, 2, 0, "today", DIM)
    bar(c, 2, 7, 30, 0.4, ACC)
    put(c, 2, 39, "4 / 10", FG_)
    put(c, 2, 47, "quota", DIM)
    rput(c, 2, "pace: normal", DIM)

    # picture
    pc0, pc1, pr0, pr1 = 0, 58, 4, 26
    x0, y0 = cx(pc0 + 1.2), ry(pr0) + 6
    pw, ph = int(cx(pc1 - 1.2) - x0), int(ry(pr1) - 6 - y0)
    paste_dithered(c, corridor_image(pw // 1, ph // 1), x0, y0, levels=5, px=1.0)
    frame(c, pr0, pr1, pc0, pc1)
    put(c, pr1 + 1, 1, "img 0417-C-0005.png  ·  320x240  ·  cam 4-B-corr", FAINT)

    # question at the right of the picture
    qc = pc1 + 3
    put(c, 5, qc, "item 5", DIM)
    put(c, 7, qc, "Is there a person", BRIGHT, True)
    put(c, 8, qc, "in this image?", BRIGHT, True)
    put(c, 10, qc, "> 1. Yes", ACC, True)
    put(c, 11, qc, "  2. No", FG_)
    put(c, 12, qc, "  3. Unsure", FG_)
    put(c, 14, qc, "time on item  2.1 s", DIM)
    put(c, 16, qc, "items answered faster", FAINT)
    put(c, 17, qc, "than 1.5 s are flagged.", FAINT)
    put(c, 18, qc, "some items are control", FAINT)
    put(c, 19, qc, "items. you are not told", FAINT)
    put(c, 20, qc, "which.", FAINT)

    # history
    r = pr1 + 3
    put(c, r, 0, "recent", DIM); r += 1
    hist = [("0004", "office    ", "Is there a person?", "No", "2.8 s", ""),
            ("0003", "text      ", "Is this message friendly?", "Yes", "3.0 s", ""),
            ("0002", "office    ", "Is there a person?", "No", "2.6 s", ""),
            ("0001", "street    ", "Is there a person?", "Yes", "3.4 s", "control ok")]
    for n, kind, q, a, t, note in hist:
        segs(c, r, [(n + "  ", FAINT), (kind, DIM), (q.ljust(30), DIM), (a.ljust(6), FG_), (t.ljust(8), FAINT), (note, GREEN)])
        r += 1
    r += 1
    segs(c, r, [("archive  ", DIM), ("1 file unlocked", FG_), ("  [a]", ACC), ("      store  ", DIM), ("3 items", FG_), ("  [s]", ACC)])

    footer(c, "1-3 label · a archive · s store", "next: 0006")
    return c


# ================================================================== Seeya.legacy
def seeya():
    c = chrome(active=3, badges=("4", "", "4/10", "2"), watching=False)
    BAR = (150, 128, 74)
    inverse(c, 0, -0.5, COLS - 0.5, BAR)
    put(c, 0, 0, "SEEYA.LEGACY 2.0", TBG, True)
    put(c, 0, 19, "INBOX   6 messages, 2 new", TBG)
    rput(c, 0, "retired on 31.10 ", TBG)
    segs(c, 1.2, [("! ", ACC), ("This client is deprecated. Your account will move to Seeya Next. Unsent drafts will be lost.", DIM)])

    msgs = [("N", "12:38", "dana.v (room 4-D)", "you hear that knocking too?", True),
            ("N", "12:20", "HR, Sector 4", "Welcome aboard, Mira", False),
            (" ", "12:02", "I.R.", "Re: shift handover  [auto-reply]", False),
            (" ", "11:58", "Echo", "hi! I can draft replies for you :)", False),
            (" ", "12.10", "Facilities", "Ventilation maintenance, Sector 4: postponed", False),
            (" ", "10.10", "Seeya", "Your account will be migrated", False)]
    r = 3
    for flag, t, who, subj, sel in msgs:
        if sel:
            inverse(c, r, -0.5, COLS - 0.5, ACC)
        col = TBG if sel else (FG_ if flag == "N" else DIM)
        segs(c, r, [(flag + "  ", col, flag == "N"), (t.ljust(8), col), (who.ljust(22), col, flag == "N"), (subj, col)])
        r += 1
    hline(c, r + 0.4)

    # open thread
    r += 2
    segs(c, r, [("dana.v", BRIGHT, True), ("  room 4-D  ·  operator 0412  ·  last seen 1 min ago", DIM)])
    r += 2
    chat = [("12:36", "dana.v", "hey. you're the new one in 4-C?"),
            ("12:36", "dana.v", "does your kontur ask about sounds too"),
            ("12:38", "dana.v", "you hear that knocking too?"),
            ("12:38", "dana.v", "it goes along the duct. towards your side i think"),
            ("12:41", "dana.v", "don't turn around too often. it counts")]
    for t, who, msg in chat:
        segs(c, r, [(t + "  ", FAINT), (who.ljust(8), DIM), (msg, FG_)])
        r += 1
    r += 1
    top = r
    frame(c, top, top + 9, 2, COLS)
    put(c, top + 1, 4, "Reply to dana.v", FG_, True)
    put(c, top + 3, 4, "> 1. yes. what is it?", ACC, True)
    put(c, top + 4, 4, "  2. no. nothing here.", FG_)
    put(c, top + 5, 4, "  3. Echo, write the reply", FG_)
    put(c, top + 7, 4, "no reply needed. dana.v will see 'read'", DIM)

    footer(c, "up/down select · enter open · 1-3 reply", "2 new")
    return c


# ================================================================== KONTUR check over any app
def kontur_check(under_png):
    c = Canvas()
    c.im = Image.open(under_png).convert("RGB").copy()
    c.d = ImageDraw.Draw(c.im)
    # dim everything, panel included; the eye in the panel stays lit
    shade = Image.new("RGBA", c.im.size, (0, 0, 0, 170))
    c.im.paste(shade, (0, 0), shade)
    x = 634 - c.tw("Tue 12:44", u8) - 14
    c.eye(x - 30, 9, 7, 3.2, True, (240, 80, 64), lw=1.1)

    w, h = 60, 12          # in cells
    bx0 = (X0 + X1) / 2 - w * CW / 2
    by0 = 168
    bx1, by1 = bx0 + w * CW, by0 + h * LH
    c.rect(bx0 - 3, by0 - 3, bx1 + 3, by1 + 3, fill=TBG)
    c.rect(bx0, by0, bx1, by1, fill=TBG, outline=RED, w=1)
    c.rect(bx0 + 2.5, by0 + 2.5, bx1 - 2.5, by1 - 2.5, outline=RED_D, w=0.6)
    c.rect(bx0 + 2.5, by0 + 2.5, bx1 - 2.5, by0 + LH + 4, fill=RED)

    def bput(r, col, t, color, bold=False):
        c.text(bx0 + (col + 1.5) * CW, by0 + 8 + r * LH, t, TMB if bold else TM, color, "lm")

    bput(0, 0, "KONTUR  ·  ATTENTION CHECK", TBG, True)
    c.text(bx1 - 1.5 * CW, by0 + 8, "11s", TMB, TBG, "rm")
    bput(2, 0, "Operator 0419, confirm your presence.", BRIGHT)
    bput(3, 0, "Enter code ", BRIGHT); bput(3, 11, "4471", RED, True)
    bput(5, 0, "code  [", DIM)
    bput(5, 7, "44", BRIGHT, True)
    c.rect(bx0 + (9 + 1.5) * CW, by0 + 8 + 5 * LH - 5, bx0 + (10 + 1.5) * CW, by0 + 8 + 5 * LH + 5, fill=FG_)
    bput(5, 13, "]", DIM)
    by = by0 + 8 + 7 * LH
    c.rect(bx0 + 1.5 * CW, by - 2.5, bx1 - 1.5 * CW, by + 2.5, fill=(30, 29, 27))
    c.rect(bx0 + 1.5 * CW, by - 2.5, bx0 + 1.5 * CW + (bx1 - bx0 - 3 * CW) * 0.73, by + 2.5, fill=RED)
    bput(9, 0, "this check cannot be dismissed", DIM)
    bput(10, 0, "no answer = violation 2/6", RED_D)
    return c


if __name__ == "__main__":
    kontur().finish("nd_kontur.png", crt=False)
    feed().finish("nd_feed.png", crt=False)
    seeya().finish("nd_seeya.png", crt=False)
    kontur_check("echo_term.png").finish("nd_check.png", crt=False)
    print("ok")
