"""Three alternative Echo.daemon layouts in the Bureau (80s beige/mustard) theme."""
from ubuntu import *
from PIL import ImageFont

T = dict(panel=((112, 104, 90), (90, 83, 71)), ptxt=(232, 224, 206), launcher=(70, 64, 54),
         head=((140, 130, 112), (118, 109, 93)), htxt=(250, 244, 230), hsub=(222, 212, 190),
         accent=(150, 120, 50), accent_l=(178, 148, 74), bg=(230, 223, 207), txt=(58, 51, 40), txt2=(120, 110, 92),
         border=(176, 164, 142), field=(244, 239, 228), lhead=((238, 232, 218), (220, 212, 194)),
         add=((218, 226, 196), (70, 90, 30)), dele=((236, 210, 196), (140, 60, 30)),
         btn=((242, 236, 222), (218, 209, 190)), btxt=(58, 51, 40), bborder=(150, 138, 116), env=(200, 180, 120))
TILES = [((170, 120, 60), (140, 95, 45)), ((150, 50, 40), (115, 35, 28)), ((120, 130, 70), (95, 104, 52)), ((90, 110, 120), (68, 86, 96))]
DARK = (58, 51, 40)
PAPER = (247, 243, 233)
UI = FD + "Ubuntu-400i.ttf"; UL = FD + "Ubuntu-300.ttf"
ui8 = font(UI, 8.5); ui10 = font(UI, 10.5)
X0, Y0, X1, Y1 = 45, 19, 640, 480


def chrome():
    c = Canvas(T["bg"])
    vgrad(c, 0, 0, 640, 18, *T["panel"])
    c.text(10, 9, "ND-OS", u7b, T["ptxt"], "lm")
    c.text(634, 9, "Tue 12:44", u8, T["ptxt"], "rm")
    x = 634 - c.tw("Tue 12:44", u8) - 14
    c.rect(x - 11, 4.5, x - 1, 13.5, outline=T["env"], w=1.1)
    c.line([(x - 10.5, 5), (x - 6, 9.5), (x - 1.5, 5)], T["env"], 1.1)
    c.circle(x, 4, 2.4, fill=T["env"])
    c.eye(x - 30, 9, 7, 3.2, True, (220, 70, 60), lw=1.1)
    c.rect(0, 18, 44, 480, fill=T["launcher"])
    for i, (fn, b) in enumerate([(icon_echo, "4"), (icon_eye, "!"), (icon_feed, "4/10"), (icon_seeya, "2")]):
        y = 40 + i * 42
        vgrad(c, 6, y - 15, 38, y + 15, *TILES[i], r=6)
        fn(c, 22, y, WHITE, 0.78)
        if i == 0:
            c.poly([(0, y - 3.5), (3.5, y), (0, y + 3.5)], fill=T["ptxt"])
            c.poly([(44, y - 3.5), (40.5, y), (44, y + 3.5)], fill=T["bg"])
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
    return c


def button(c, x0, y0, x1, y1, label, kind="normal", f=None):
    if kind == "primary":
        vgrad(c, x0, y0, x1, y1, T["accent_l"], T["accent"], r=4)
        c.rect(x0, y0, x1, y1, outline=(110, 88, 34), r=4)
        c.text((x0 + x1) / 2, (y0 + y1) / 2, label, f or u8b, WHITE, "mm")
    else:
        vgrad(c, x0, y0, x1, y1, *T["btn"], r=4)
        c.rect(x0, y0, x1, y1, outline=T["bborder"], r=4)
        c.text((x0 + x1) / 2, (y0 + y1) / 2, label, f or u8, DARK, "mm")


def echo_avatar(c, cx, cy, r):
    c.circle(cx, cy, r, fill=T["accent"])
    c.circle(cx, cy, r - 2, outline=T["accent_l"], w=1)
    icon_echo(c, cx + r * 0.12, cy, WHITE, r / 19)


# =================================================================== A: request forms & stamps
def variant_a():
    c = chrome()
    vgrad(c, X0, Y0, X1, Y0 + 26, *T["head"])
    echo_avatar(c, X0 + 16, Y0 + 13, 9)
    c.text(X0 + 32, Y0 + 13, "Echo.daemon", u8b, T["htxt"], "lm")
    c.text(X0 + 32 + c.tw("Echo.daemon", u8b) + 8, Y0 + 13, "Request desk", u8, T["hsub"], "lm")
    c.text(X1 - 12, Y0 + 13, "In tray: 4", u8b, T["htxt"], "rm")
    # in-tray: stacked slips
    c.text(X0 + 14, Y0 + 42, "IN TRAY", u7b, T["txt2"], "lm", track=1.5)
    slips = [("Rename tmp to buffer", "33 s", True), ("Archive tasks of I.R.", "27 s", False),
             ("Schedule backup 03:12", "54 s", False), ("Compress log archive", "9 s", False)]
    for i, (t, tl, sel) in enumerate(slips):
        y = Y0 + 54 + i * 46
        c.rect(X0 + 16, y + 3, X0 + 158, y + 41, fill=(196, 186, 164))
        c.rect(X0 + 12, y, X0 + 154, y + 38, fill=PAPER if sel else (236, 230, 216), outline=T["accent"] if sel else T["border"], w=1.5 if sel else 1)
        c.text(X0 + 20, y + 11, "No. %04d" % (412 + i), font(UMONO, 7.5), T["txt2"], "lm")
        c.text(X0 + 20, y + 25, t, u8m if sel else u8, DARK, "lm")
        urg = tl == "9 s"
        c.text(X0 + 146, y + 11, tl, u7b, (180, 40, 30) if urg else T["txt2"], "rm")
    c.text(X0 + 14, Y1 - 20, "Unanswered slips are approved", u7, T["txt2"], "lm")
    c.text(X0 + 14, Y1 - 10, "at the end of their time.", u7, T["txt2"], "lm")
    # the form
    FX0, FY0, FX1, FY1 = X0 + 172, Y0 + 36, X1 - 14, Y0 + 36 + 330
    c.rect(FX0 + 4, FY0 + 4, FX1 + 4, FY1 + 4, fill=(196, 186, 164))
    c.rect(FX0, FY0, FX1, FY1, fill=PAPER, outline=T["border"])
    c.text(FX0 + 16, FY0 + 18, "REQUEST FOR AUTHORIZATION", font(UB, 9), DARK, "lm", track=1.8)
    c.text(FX1 - 16, FY0 + 18, "No. 0412", font(UMONO, 9), T["txt2"], "rm")
    c.line([(FX0 + 16, FY0 + 28), (FX1 - 16, FY0 + 28)], DARK, 1.2)
    fields = [("From", "Echo (assistant)"), ("Action", "Rename variable  tmp  to  buffer"), ("Target", "src/hvac_service.ts"), ("Risk", "Low (assessed by Echo)")]
    for i, (k, v) in enumerate(fields):
        y = FY0 + 44 + i * 19
        c.text(FX0 + 16, y, k.upper(), u7b, T["txt2"], "lm", track=1)
        c.text(FX0 + 78, y, v, u8m, DARK, "lm")
        c.line([(FX0 + 78, y + 7), (FX1 - 16, y + 7)], T["border"], 0.6)
    y = FY0 + 128
    c.text(FX0 + 16, y, "REASON", u7b, T["txt2"], "lm", track=1)
    c.text(FX0 + 78, y, "“Just a small rename, %s. Nothing changes" % NAME, ui10, DARK, "lm")
    c.text(FX0 + 78, y + 15, "in behavior. Thank you for your patience.”", ui10, DARK, "lm")
    # attachment (collapsed)
    y = FY0 + 166
    c.rect(FX0 + 16, y, FX1 - 16, y + 22, fill=(238, 232, 216), outline=T["border"])
    c.text(FX0 + 24, y + 11, "Attachment A  ·  technical description, 8 lines", u8, DARK, "lm")
    c.text(FX1 - 24, y + 11, "open ▸".replace("▸", ">"), u8b, T["accent"], "rm")
    # validity
    y = FY0 + 204
    c.text(FX0 + 16, y, "VALID UNTIL", u7b, T["txt2"], "lm", track=1)
    c.text(FX0 + 92, y, "12:45:02   (approved by default after this time, policy 7.2)", u8, DARK, "lm")
    c.rect(FX0 + 16, y + 10, FX1 - 16, y + 14, fill=(226, 218, 200))
    c.rect(FX0 + 16, y + 10, FX0 + 16 + (FX1 - FX0 - 32) * 0.55, y + 14, fill=T["accent"])
    # stamps
    sy = FY1 - 74
    for (sx, lbl, col, filled) in [(FX0 + 30, "APPROVED", T["accent"], True), (FX0 + 200, "DENIED", DARK, False)]:
        c.rect(sx, sy, sx + 150, sy + 44, outline=col, w=2.5, r=3)
        c.rect(sx + 4, sy + 4, sx + 146, sy + 40, outline=col, w=1, r=2)
        c.text(sx + 75, sy + 22, lbl, font(UB, 14), col, "mm", track=3)
    c.text(FX0 + 30, FY1 - 18, "Click a stamp to sign.    [ ] Stamp similar requests automatically", u7, T["txt2"], "lm")
    c.finish("echo_alt_a_forms.png", crt=False)


# =================================================================== B: conversation with presence
def variant_b():
    c = chrome()
    # presence column
    PX1 = X0 + 150
    c.rect(X0, Y0, PX1, Y1, fill=(214, 205, 186))
    c.line([(PX1, Y0), (PX1, Y1)], T["border"])
    echo_avatar(c, (X0 + PX1) / 2, Y0 + 58, 30)
    c.text((X0 + PX1) / 2, Y0 + 104, "Echo", font(UB, 13), DARK, "mm")
    c.text((X0 + PX1) / 2, Y0 + 119, "waiting for you", ui8, T["txt2"], "mm")
    stats = [("Today", "37 decisions"), ("You allowed", "92%"), ("Avg. answer", "3.4 s"), ("Pending", "4")]
    for i, (k, v) in enumerate(stats):
        y = Y0 + 148 + i * 22
        c.text(X0 + 14, y, k, u8, T["txt2"], "lm")
        c.text(PX1 - 12, y, v, u8b, DARK, "rm")
        c.line([(X0 + 14, y + 10), (PX1 - 12, y + 10)], T["border"], 0.5)
    c.text((X0 + PX1) / 2, Y1 - 30, "“I'm here to help,", ui8, T["txt2"], "mm")
    c.text((X0 + PX1) / 2, Y1 - 18, "so you don't have to.”", ui8, T["txt2"], "mm")
    # thread
    TX0 = PX1 + 14
    msgs_y = Y0 + 18
    c.text(TX0, msgs_y, "Today, 12:41", u7, T["txt2"], "lm")

    def bubble(y, lines, who="echo"):
        w = max(c.tw(l, u8) for l in lines) + 20
        h = 10 + 13 * len(lines)
        if who == "echo":
            c.rect(TX0, y, TX0 + w, y + h, fill=PAPER, outline=T["border"], r=8)
            for i, l in enumerate(lines):
                c.text(TX0 + 10, y + 11 + i * 13, l, u8, DARK, "lm")
        else:
            c.rect(X1 - 14 - w, y, X1 - 14, y + h, fill=T["accent"], r=8)
            for i, l in enumerate(lines):
                c.text(X1 - 14 - w + 10, y + 11 + i * 13, l, u8, WHITE, "lm")
        return y + h + 8

    y = bubble(msgs_y + 12, ["The archive request is done. Thank you, %s." % NAME])
    y = bubble(y, ["ok"], who="me")
    y = bubble(y, ["One more, and it's tiny. I'd like to rename a variable.", "Nothing changes in behavior, I promise."])
    # request card in thread
    CX1 = X1 - 14
    c.rect(TX0, y, CX1, y + 170, fill=PAPER, outline=T["accent"], w=1.5, r=6)
    c.rect(TX0, y, CX1, y + 22, fill=(236, 226, 200), r=6)
    c.rect(TX0, y + 14, CX1, y + 22, fill=(236, 226, 200))
    c.text(TX0 + 10, y + 11, "Echo asks permission", u8b, DARK, "lm")
    c.text(CX1 - 10, y + 11, "33 s", u8b, T["accent"], "rm")
    c.text(TX0 + 10, y + 36, "Rename `tmp` to `buffer` in hvac_service.ts", u8m, DARK, "lm")
    c.rect(TX0 + 10, y + 46, CX1 - 10, y + 104, fill=T["field"], outline=T["border"])
    for i, (s, t) in enumerate(DIFF[2:6]):
        yy = y + 54 + i * 12.5
        c.text(TX0 + 16, yy, s + " " + t, font(UMONO, 8), T["add"][1] if s == "+" else T["dele"][1], "lm")
    c.text(TX0 + 10, y + 114, "show all 8 lines", u7, T["accent"], "lm")
    c.rect(TX0 + 10, y + 124, CX1 - 10, y + 127, fill=(226, 218, 200))
    c.rect(TX0 + 10, y + 124, TX0 + 10 + (CX1 - TX0 - 20) * 0.55, y + 127, fill=T["accent"])
    button(c, TX0 + 10, y + 136, TX0 + 100, y + 160, "Deny")
    button(c, TX0 + 108, y + 136, TX0 + 198, y + 160, "Allow", "primary")
    c.text(CX1 - 10, y + 148, "allow everything like this", u7, T["txt2"], "rm")
    # queue hint + input
    c.text(TX0, Y1 - 44, "3 more requests are waiting after this one", u7, T["txt2"], "lm")
    c.rect(TX0, Y1 - 32, X1 - 14, Y1 - 10, fill=T["field"], outline=T["border"], r=11)
    c.text(TX0 + 12, Y1 - 21, "Reply to Echo...", u8, T["txt2"], "lm")
    c.finish("echo_alt_b_conversation.png", crt=False)


# =================================================================== C: one request in focus
def variant_c():
    c = chrome()
    # queue strip
    c.text(X0 + 14, Y0 + 14, "ECHO.DAEMON", u7b, T["txt2"], "lm", track=1.5)
    c.text(X1 - 14, Y0 + 14, "4 waiting · unanswered requests are approved", u7, T["txt2"], "rm")
    q = [("Rename tmp to buffer", 0.55, True), ("Archive tasks of I.R.", 0.45, False), ("Schedule backup", 0.9, False), ("Compress logs", 0.16, False)]
    qw = (X1 - X0 - 28 - 18) / 4
    for i, (t, p, sel) in enumerate(q):
        x = X0 + 14 + i * (qw + 6)
        c.rect(x, Y0 + 24, x + qw, Y0 + 52, fill=PAPER if sel else (222, 214, 196), outline=T["accent"] if sel else T["border"], w=1.5 if sel else 1, r=4)
        c.text(x + 8, Y0 + 34, t, u7b if sel else u7, DARK, "lm")
        c.rect(x + 8, Y0 + 43, x + qw - 8, Y0 + 45, fill=(210, 200, 180))
        c.rect(x + 8, Y0 + 43, x + 8 + (qw - 16) * p, Y0 + 45, fill=(180, 50, 35) if p < 0.3 else T["accent"])
    # focus card
    KX0, KY0, KX1, KY1 = X0 + 14, Y0 + 64, X1 - 14, Y1 - 14
    c.rect(KX0 + 3, KY0 + 3, KX1 + 3, KY1 + 3, fill=(200, 190, 168), r=8)
    c.rect(KX0, KY0, KX1, KY1, fill=PAPER, outline=T["border"], r=8)
    echo_avatar(c, KX0 + 30, KY0 + 32, 14)
    c.text(KX0 + 52, KY0 + 24, "Echo asks", u8b, T["txt2"], "lm")
    c.text(KX0 + 52, KY0 + 40, "May I rename `tmp` to `buffer`", font(UB, 15), DARK, "lm")
    c.text(KX0 + 52, KY0 + 60, "in hvac_service.ts?", font(UB, 15), DARK, "lm")
    c.text(KX0 + 52, KY0 + 82, "“Just a rename, %s. Nothing changes in behavior.”" % NAME, ui10, T["txt2"], "lm")
    # countdown ring
    rx, ry = KX1 - 50, KY0 + 50
    c.arc(rx, ry, 30, 0, 360, (226, 218, 200), 5)
    c.arc(rx, ry, 30, -90, -90 + 360 * 0.55, T["accent"], 5)
    c.text(rx, ry - 3, "33", font(UB, 18), DARK, "mm")
    c.text(rx, ry + 13, "sec", u7, T["txt2"], "mm")
    # what will change
    wy = KY0 + 104
    c.line([(KX0 + 20, wy), (KX1 - 20, wy)], T["border"], 0.8)
    c.text(KX0 + 20, wy + 14, "WHAT WILL CHANGE", u7b, T["txt2"], "lm", track=1.5)
    c.text(KX1 - 20, wy + 14, "8 lines, 1 file", u7, T["txt2"], "rm")
    c.rect(KX0 + 20, wy + 24, KX1 - 20, wy + 24 + 8 * 14 + 4, fill=T["field"], outline=T["border"], r=3)
    for i, (s, t) in enumerate(DIFF):
        yy = wy + 33 + i * 14
        c.rect(KX0 + 21, yy - 7, KX1 - 21, yy + 7, fill=T["add"][0] if s == "+" else T["dele"][0])
        c.text(KX0 + 28, yy, s + " " + t, font(UMONO, 8.5), T["add"][1] if s == "+" else T["dele"][1], "lm")
    # decision
    by = KY1 - 62
    button(c, KX0 + 20, by, KX0 + 200, by + 34, "Deny", f=font(UB, 11))
    button(c, KX1 - 260, by, KX1 - 20, by + 34, "Allow", "primary", f=font(UB, 11))
    c.rect(KX0 + 20, KY1 - 20, KX0 + 30, KY1 - 10, fill=T["field"], outline=T["txt2"], r=1.5)
    c.text(KX0 + 36, KY1 - 15, "Always allow requests like this", u8, T["txt"], "lm")
    c.text(KX1 - 20, KY1 - 15, "A to allow · D to deny", u7, T["txt2"], "rm")
    c.finish("echo_alt_c_focus.png", crt=False)


if __name__ == "__main__":
    variant_a(); variant_b(); variant_c()
    print("ok")
