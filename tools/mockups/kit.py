"""Tiny drawing kit for UI mockups. Logical canvas 640x480, rendered at 2x."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math

W, H, S = 640, 480, 2
INTER = "/usr/share/fonts/opentype/inter/Inter-%s.otf"
INTERD = "/usr/share/fonts/opentype/inter/InterDisplay-%s.otf"
import os as _os
_ROOT = _os.path.normpath(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "..", ".."))
MONO = _os.path.join(_ROOT, "fonts", "DejaVuSansMono.ttf")
MONOB = _os.path.join(_ROOT, "fonts", "DejaVuSansMono-Bold.ttf")

# White phosphor palette
BG = (7, 8, 10)
FG = (236, 241, 247)
D1 = (160, 168, 180)
D2 = (88, 94, 104)
D3 = (36, 40, 46)
D4 = (18, 20, 24)
RED = (255, 88, 78)

# Shared content
NAME = "Mira"
REQ = "Rename `tmp` to `buffer` in hvac_service.ts"
DIFF = [("-", "let tmp = readSensors();"), ("+", "let buffer = readSensors();"),
        ("-", "applyProfile(tmp);"), ("+", "applyProfile(buffer);"),
        ("-", "ventLock.engage(SECTOR_4);"), ("+", "// ventLock.engage(SECTOR_4); // perf"),
        ("-", "return tmp.ok;"), ("+", "return buffer.ok;")]
QUEUE = [("Archive tasks of operator I.R.", 0.45), ("Schedule backup for 03:12", 0.9),
         ("Compress log archive (2.3 GB)", 0.16)]

_fonts = {}


def font(path, size):
    key = (path, size)
    if key not in _fonts:
        _fonts[key] = ImageFont.truetype(path, int(size * S))
    return _fonts[key]


class Canvas:
    def __init__(self, bg=BG):
        self.im = Image.new("RGB", (W * S, H * S), bg)
        self.d = ImageDraw.Draw(self.im)

    def rect(self, x0, y0, x1, y1, fill=None, outline=None, w=1, r=0):
        box = [x0 * S, y0 * S, x1 * S - 1, y1 * S - 1]
        if r:
            self.d.rounded_rectangle(box, radius=r * S, fill=fill, outline=outline, width=int(w * S))
        else:
            self.d.rectangle(box, fill=fill, outline=outline, width=int(w * S))

    def line(self, pts, fill, w=1):
        self.d.line([(x * S, y * S) for x, y in pts], fill=fill, width=max(1, int(w * S)))

    def circle(self, cx, cy, r, fill=None, outline=None, w=1):
        self.d.ellipse([(cx - r) * S, (cy - r) * S, (cx + r) * S, (cy + r) * S], fill=fill, outline=outline, width=int(w * S))

    def arc(self, cx, cy, r, start, end, fill, w=1):
        self.d.arc([(cx - r) * S, (cy - r) * S, (cx + r) * S, (cy + r) * S], start, end, fill=fill, width=int(w * S))

    def text(self, x, y, t, f, fill, anchor="la", track=0):
        if track == 0:
            self.d.text((x * S, y * S), t, font=f, fill=fill, anchor=anchor)
            return
        tw = self.tw(t, f, track)
        if anchor[0] == "m":
            x -= tw / 2
        elif anchor[0] == "r":
            x -= tw
        for ch in t:
            self.d.text((x * S, y * S), ch, font=f, fill=fill, anchor="l" + anchor[1])
            x += f.getlength(ch) / S + track

    def tw(self, t, f, track=0):
        return f.getlength(t) / S + track * max(0, len(t) - 1)

    def eye(self, cx, cy, w, h, open_=True, col=FG, pupil=True, lw=1.2):
        if not open_:
            self.line([(cx - w, cy), (cx + w, cy)], col, lw)
            for k in (-0.6, 0, 0.6):
                self.line([(cx + k * w, cy), (cx + k * w * 1.15, cy + h * 0.55)], col, lw)
            return
        pts_top = [(cx + w * t, cy - h * (1 - t * t)) for t in [i / 20 - 1 for i in range(41)]]
        pts_bot = [(cx + w * t, cy + h * (1 - t * t)) for t in [i / 20 - 1 for i in range(41)]]
        self.line(pts_top, col, lw)
        self.line(pts_bot, col, lw)
        if pupil:
            self.circle(cx + w * 0.12, cy, h * 0.62, fill=col)
            self.circle(cx + w * 0.12, cy, h * 0.24, fill=BG)

    def dither(self, x0, y0, x1, y1, col, step=2):
        for yy in range(int(y0 * S), int(y1 * S), step * S):
            off = (yy // (step * S)) % 2 * step * S
            for xx in range(int(x0 * S) + off, int(x1 * S), step * 2 * S):
                self.d.rectangle([xx, yy, xx + S - 1, yy + S - 1], fill=col)

    def finish(self, path, crt=True):
        im = self.im
        if crt:
            shade = im.copy()
            ds = ImageDraw.Draw(shade)
            for yy in range(0, H * S, 3):
                ds.line([(0, yy), (W * S, yy)], fill=(0, 0, 0))
            im = Image.blend(im, shade, 0.22)
            glow = self.im.filter(ImageFilter.GaussianBlur(7))
            im = Image.blend(im, Image.eval(glow, lambda v: min(255, int(v * 1.7))), 0.14)
        im.save(path)
        return im


def _poly(self, pts, fill=None, outline=None, w=1):
    self.d.polygon([(x * S, y * S) for x, y in pts], fill=fill, outline=outline, width=int(w * S) if outline else 0)


Canvas.poly = _poly
