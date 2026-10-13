"""Echo.daemon as a plain terminal session with a CLI agent asking for permission."""
from ub_echo_alts import chrome, X0, Y0, X1, Y1, FD
from ubuntu import *
from PIL import ImageFont
from kit import MONO, MONOB, DIFF

TBG = (13, 13, 12)
FG_ = (198, 196, 188)
DIM = (112, 109, 102)
FAINT = (70, 68, 63)
ACC = (205, 172, 92)        # mustard selection, from the Bureau theme
ADD_BG = (24, 34, 22); ADD_FG = (150, 190, 125)
DEL_BG = (40, 22, 20); DEL_FG = (200, 130, 115)
TM = font(MONO, 7.8); TMB = font(MONOB, 7.8)
LH = 11.2
CW = TM.getlength("M") / S
LX = X0 + 12


def put(c, row, col, text, color=FG_, bold=False, top=None):
    y = (top if top is not None else Y0 + 14) + row * LH
    c.text(LX + col * CW, y, text, TMB if bold else TM, color, "lm")


def segs(c, row, parts, top=None):
    col = 0
    for t, colr, *b in parts:
        put(c, row, col, t, colr, bool(b and b[0]), top)
        col += len(t)


def frame(c, r0, r1, cols):
    top = Y0 + 14 + r0 * LH
    bot = Y0 + 14 + r1 * LH
    c.rect(LX + 0.5 * CW, top, LX + (cols - 0.5) * CW, bot, outline=FAINT, w=0.8, r=4)


def screen(expanded):
    c = chrome()
    c.rect(X0, Y0, X1, Y1, fill=TBG)
    cols = int((X1 - X0 - 24) / CW)
    r = 0
    segs(c, r, [("echo.daemon 7.2.0", DIM), ("  ·  session 0419  ·  ", FAINT), ("/srv/nd/sector4", DIM)]); r += 2
    segs(c, r, [("> ", DIM), ("ok", FG_)]); r += 2
    segs(c, r, [("● ", FG_), ("Archive(operator: I.R.)", FG_, True)]); r += 1
    segs(c, r, [("  └ ", FAINT), ("7 tasks archived. 1 task was still open: ", DIM), ("exit room", FG_), (" (closed)", DIM)]); r += 2
    segs(c, r, [("● ", FG_), ("Next one is small. Just a rename, nothing changes in behavior.", FG_)]); r += 2
    segs(c, r, [("● ", ACC), ("Edit(src/hvac_service.ts)", FG_, True)]); r += 1

    # permission box
    lines = []
    box_top = r
    inner = []
    inner.append([("Edit file", FG_, True)])
    inner.append([("src/hvac_service.ts", DIM)])
    inner.append([])
    if expanded:
        nums = [112, 112, 113, 113, 117, 117, 121, 121]
        for (s, t), n in zip(DIFF, nums):
            inner.append(("DIFF", s, "%4d %s %s" % (n, s, t)))
        inner.append([])
    else:
        inner.append([("8 lines changed  ", DIM), ("[d] show diff", ACC)])
        inner.append([])
    inner.append([("Do you want to make this edit to hvac_service.ts?", FG_)])
    inner.append([("> 1. Yes", ACC, True)])
    inner.append([("  2. Yes, and don't ask again for edits like this", FG_)])
    inner.append([("  3. No", FG_)])
    inner.append([])
    inner.append([("auto-approve in 33s", DIM)])
    box_bot = box_top + len(inner) + 1
    # diff backgrounds first
    for i, item in enumerate(inner):
        if isinstance(item, tuple):
            row = box_top + 1 + i
            y = Y0 + 14 + row * LH
            c.rect(LX + 2 * CW, y - LH / 2 + 0.5, LX + (cols - 2) * CW, y + LH / 2 - 0.5, fill=ADD_BG if item[1] == "+" else DEL_BG)
    frame(c, box_top, box_bot, cols)
    for i, item in enumerate(inner):
        row = box_top + 1 + i
        if isinstance(item, tuple):
            put(c, row, 2, item[2], ADD_FG if item[1] == "+" else DEL_FG)
        else:
            col = 2
            for t, colr, *b in item:
                put(c, row, col, t, colr, bool(b and b[0]))
                col += len(t)
    r = box_bot + 2
    segs(c, r, [("  3 more waiting: ", FAINT), ("Archive tasks of I.R. 27s", DIM), (" · ", FAINT), ("Schedule backup 54s", DIM),
                (" · ", FAINT), ("Compress logs ", DIM), ("9s", DEL_FG)])

    # input line at the bottom
    yb = Y1 - 34
    c.line([(LX, yb - 8), (X1 - 12, yb - 8)], FAINT, 0.6)
    c.text(LX, yb, ">", TM, DIM, "lm")
    c.rect(LX + 2 * CW, yb - 5, LX + 2 * CW + CW, yb + 5, fill=FG_)
    c.line([(LX, yb + 8), (X1 - 12, yb + 8)], FAINT, 0.6)
    c.text(LX, Y1 - 14, "1-3 choose · d diff · enter confirm · silence = yes", TM, FAINT, "lm")
    c.text(X1 - 12, Y1 - 14, "4 pending", TM, DIM, "rm")
    return c


screen(False).finish("echo_term.png", crt=False)
screen(True).finish("echo_term_open.png", crt=False)

names = ["echo_term", "echo_term_open"]
labels = ["details collapsed", "details open (d)"]
sheet = Image.new("RGB", (2 * 640 + 30, 520), (14, 13, 12)); d = ImageDraw.Draw(sheet)
f = ImageFont.truetype(FD + "Ubuntu-700.ttf", 22)
for i, n in enumerate(names):
    im = Image.open(n + ".png").resize((640, 480), Image.LANCZOS); x = 10 + i * 650
    sheet.paste(im, (x, 36)); d.text((x, 6), labels[i], font=f, fill=(230, 224, 210))
sheet.save("echo_term_sheet.png")
print("ok")
