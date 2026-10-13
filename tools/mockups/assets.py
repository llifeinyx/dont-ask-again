"""Export assets for the Godot ND-OS port into the project."""
import os, shutil
import numpy as np, cv2
from PIL import Image, ImageDraw
from ub_echo_alts import T, TILES
from ubuntu import *

PRJ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")) + "/"
os.makedirs(PRJ + "art/icons", exist_ok=True)
os.makedirs(PRJ + "fonts", exist_ok=True)

# ---------------------------------------------------------------- background (16:9 crop)
CROP = (0, 355, 1067, 955)
room = Image.open(PRJ + "art/source/room_front_original.jpg").convert("RGB").crop(CROP)
room = Image.eval(room, lambda v: int(v * 0.92))
room.save(PRJ + "art/room_front.jpg", quality=93)

# ---------------------------------------------------------------- light spill map
W, H = room.size
a = np.asarray(room).astype(np.float32) / 255
ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
GCX, GCY, GHX, GHY = 535.5, 655.0 - 355, 321.0, 256.0
ACX, ACY, AHX, AHY = 535.5, 648.0 - 355, 288.0, 216.0
act = ((np.abs((xs - ACX) / AHX) ** 12 + np.abs((ys - ACY) / AHY) ** 12) < 1).astype(np.float32)
glass = np.clip((1 - (np.abs((xs - GCX) / GHX) ** 7 + np.abs((ys - GCY) / GHY) ** 7)) / 0.03, 0, 1)
glass = cv2.GaussianBlur(glass, (0, 0), 1.5)
g1 = cv2.GaussianBlur(act, (0, 0), 28)
g2 = cv2.resize(cv2.GaussianBlur(cv2.resize(act, (W // 4, H // 4), interpolation=cv2.INTER_AREA), (0, 0), 40), (W, H))
lum = a.mean(axis=2)
albedo = np.clip(lum * 2.2, 0, 1)
spill = albedo * (g1 * 2.6 + g2 * 4.0) * (1 - glass) + g2 * 0.08
spill = spill / spill.max()
Image.fromarray((np.clip(spill, 0, 1) ** 0.85 * 255).astype(np.uint8), "L").save(PRJ + "art/screen_spill.png")
print("spill max ok, size", W, H)

# ---------------------------------------------------------------- launcher tiles (2x)
def crop_tile(c, y):
    return c.im.crop((6 * S, (y - 15) * S, 38 * S, (y + 15) * S))

apps = [("echo", icon_echo), ("kontur", icon_eye), ("feed", icon_feed), ("seeya", icon_seeya)]
for i, (name, fn) in enumerate(apps):
    c = Canvas(T["launcher"])
    y = 40
    vgrad(c, 6, y - 15, 38, y + 15, *TILES[i], r=6)
    fn(c, 22, y, WHITE, 0.78)
    crop_tile(c, y).save(PRJ + "art/icons/app_%s.png" % name)
for name, fn in [("terminal", icon_terminal), ("files", icon_files), ("settings", icon_gear)]:
    c = Canvas(T["launcher"])
    y = 40
    c.rect(6, y - 15, 38, y + 15, fill=(56, 51, 43), outline=(90, 83, 71), r=6)
    fn(c, 22, y, (130, 120, 100), 0.7)
    c.circle(33, y + 10, 5.5, fill=(244, 239, 228))
    icon_lock(c, 33, y + 10.5, (58, 51, 40), 0.7)
    crop_tile(c, y).save(PRJ + "art/icons/locked_%s.png" % name)


# ---------------------------------------------------------------- panel glyphs: white with alpha
def mask_png(draw_fn, w, h, out):
    c = Canvas((0, 0, 0))
    draw_fn(c)
    im = c.im.crop((0, 0, w * S, h * S)).convert("L")
    rgba = Image.new("RGBA", im.size, (255, 255, 255, 0))
    rgba.putalpha(im)
    rgba.save(out)

mask_png(lambda c: c.eye(8, 5, 7, 3.2, True, WHITE, lw=1.1), 16, 10, PRJ + "art/icons/eye_open.png")
mask_png(lambda c: c.eye(8, 4, 7, 3.2, False, WHITE, lw=1.1), 16, 10, PRJ + "art/icons/eye_closed.png")
def env(c):
    c.rect(1, 1.5, 11, 10.5, outline=WHITE, w=1.1)
    c.line([(1.5, 2), (6, 6.5), (10.5, 2)], WHITE, 1.1)
mask_png(env, 13, 12, PRJ + "art/icons/envelope.png")

# ---------------------------------------------------------------- fonts + licenses
for f in ["Ubuntu-400.ttf", "Ubuntu-500.ttf", "Ubuntu-700.ttf"]:
    shutil.copy(FD + f, PRJ + "fonts/" + f)
print("ok")
