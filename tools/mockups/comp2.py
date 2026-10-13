"""Composite the ND-OS UI (Bureau chrome + terminal Echo.daemon) into room2.jpg's CRT."""
import sys
import numpy as np, cv2
from PIL import Image

import os
ROOM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art", "source", "room_front_original.jpg")
# glass (whole curved tube face) and active picture area, in room pixels
GCX, GCY, GHX, GHY, GN = 535.5, 655.0, 321.0, 256.0, 7.0
ACX, ACY, AHX, AHY = 535.5, 648.0, 288.0, 216.0
K = 0.045           # barrel strength


def load(p):
    return np.asarray(Image.open(p).convert("RGB")).astype(np.float32) / 255.0


def superellipse(u, v, n):
    return np.abs(u) ** n + np.abs(v) ** n


def blur(a, s):
    return cv2.GaussianBlur(a, (0, 0), s)


def composite(ui_path, out_path, debug=False):
    room = load(ROOM)
    H, W = room.shape[:2]
    ui = load(ui_path)
    uh, uw = ui.shape[:2]

    # --- phosphor look in source space
    ui = np.power(ui, 0.9) * 0.95
    ui = ui * np.array([1.0, 0.97, 0.9], np.float32)        # warm, slightly yellowed phosphor
    gray = ui.mean(axis=2, keepdims=True)
    ui = ui * 0.72 + gray * 0.28                               # aged, slightly washed-out tube
    ui = blur(ui, 0.9)
    bloom = blur(ui, 5) * 0.28 + blur(ui, 16) * 0.18
    ui = ui + bloom
    ui = ui + np.array([0.018, 0.02, 0.017], np.float32)     # raised CRT black level

    # --- inverse barrel warp: room pixel -> ui pixel
    ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
    u = (xs - ACX) / AHX
    v = (ys - ACY) / AHY
    r2 = u * u + v * v
    f = (1 + K * r2) / (1 + K * 1.25)
    su, sv = u * f, v * f
    mapx = ((su + 1) * 0.5 * (uw - 1)).astype(np.float32)
    mapy = ((sv + 1) * 0.5 * (uh - 1)).astype(np.float32)
    warped = cv2.remap(ui, mapx, mapy, cv2.INTER_AREA if False else cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=0)

    # active picture mask: rounded edges in the warped space, soft falloff
    se = superellipse(su, sv, 22.0)
    active = np.clip((1.0 - se) / 0.06, 0, 1)
    active = blur(active, 1.2)

    # scanlines following the curvature, plus slight shadow-mask column texture
    line = 0.9 + 0.1 * np.cos(sv * np.pi * 168)
    cols = 0.97 + 0.03 * np.cos(su * np.pi * 300)
    vign = np.clip(1 - 0.2 * np.power(r2 / 2, 1.4), 0, 1)
    pic = warped * (active * line * cols * vign)[..., None]

    # --- glass mask
    gu = (xs - GCX) / GHX
    gv = (ys - GCY) / GHY
    glass = np.clip((1.0 - superellipse(gu, gv, GN)) / 0.03, 0, 1)
    glass = blur(glass, 1.5)[..., None]

    if debug:
        dbg = room.copy()
        dbg[..., 0] += 0.5 * (glass[..., 0] * (1 - glass[..., 0]) * 4)
        dbg[..., 1] += 0.6 * active * (1 - active) * 4
        Image.fromarray((np.clip(dbg, 0, 1) * 255).astype(np.uint8)).save("comp2_debug.png")

    out = room * 0.9

    # screen face: glass reflections stay on top of the picture (screen blend)
    refl = room * 1.05
    face = 1 - (1 - pic) * (1 - refl)
    # a little light diffusing in the thick glass outside the active area
    haze = blur(pic, 10) * 0.35
    face = face + haze * (1 - active[..., None])
    out = out * (1 - glass) + face * glass

    # --- light spill from the screen onto bezel, keyboard, mug, walls
    src = pic * 1.0
    g1 = blur(src, 28)
    g2 = blur(cv2.resize(src, (W // 4, H // 4), interpolation=cv2.INTER_AREA), 40)
    g2 = cv2.resize(g2, (W, H), interpolation=cv2.INTER_LINEAR)
    albedo = np.clip(room * 2.2, 0, 1)
    spill = (g1 * 2.6 + g2 * 4.0) * (1 - glass)
    out = out + albedo * spill * 0.55 + g2 * 0.05

    # grain
    rng = np.random.default_rng(7)
    n = rng.normal(0, 0.012, (H, W, 1)).astype(np.float32)
    out = out + n
    out = np.clip(out, 0, 1)
    Image.fromarray((out * 255 + 0.5).astype(np.uint8)).save(out_path)
    return out_path


if __name__ == "__main__":
    dbg = "--debug" in sys.argv
    composite("echo_term.png", "room2_echo.png", debug=dbg)
    composite("echo_term_open.png", "room2_echo_open.png")
    print("ok")
