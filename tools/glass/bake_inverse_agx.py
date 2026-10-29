#!/usr/bin/env python3
"""Bakes the inverse of the AgX Punchy LUT, so ND-OS shows its Figma colours on the glass.

    python3 tools/glass/bake_inverse_agx.py

Reads assets/front/agx_punchy_65.bin (written by tools/blender/export_front.py) and writes
assets/front/agx_punchy_inverse_65.bin in the same layout (int32 size, float32 lo and hi, then float32 RGB
for every [b][g][r]). Here the input is display sRGB from lo = 0 to hi = 1 on a plain grid, and each
entry holds log2 of the linear light that AgX Punchy turns into that colour, found by Gauss-Newton on
the forward LUT. Colours AgX cannot reach get the closest one. Needs numpy.
"""
import os
import struct
import sys

import numpy as np

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
FORWARD = os.path.join(ROOT, "assets", "front", "agx_punchy_65.bin")
INVERSE = os.path.join(ROOT, "assets", "front", "agx_punchy_inverse_65.bin")
SIZE = 65
ITERATIONS = 60
# Damped steps keep Gauss-Newton stable where the LUT flattens out.
STEP = 0.7
DERIVATIVE_STEP = 1e-4
# Keeps the solve away from the LUT's flat ends, where nothing changes any more.
SHAPER_MARGIN = 1e-4


def load_forward(path):
	with open(path, "rb") as file:
		data = file.read()
	size, lo, hi = struct.unpack("<iff", data[:12])
	lut = np.frombuffer(data[12:], dtype="<f4").reshape(size, size, size, 3)
	return size, lo, hi, lut


def forward(lut, size, t):
	"""AgX Punchy of shaper coordinates t (N×3, 0..1), trilinear like the GPU."""
	x = np.clip(t, 0.0, 1.0) * (size - 1)
	i = np.minimum(np.floor(x).astype(int), size - 2)
	f = x - i
	out = np.zeros_like(t)
	for db in (0, 1):
		for dg in (0, 1):
			for dr in (0, 1):
				w = (np.where(db, f[:, 2], 1 - f[:, 2]) * np.where(dg, f[:, 1], 1 - f[:, 1])
					* np.where(dr, f[:, 0], 1 - f[:, 0]))
				out += w[:, None] * lut[i[:, 2] + db, i[:, 1] + dg, i[:, 0] + dr]
	return out


def main():
	size, lo, hi, lut = load_forward(FORWARD)
	axis = np.linspace(0.0, 1.0, SIZE)
	b, g, r = np.meshgrid(axis, axis, axis, indexing="ij")
	target = np.stack([r.ravel(), g.ravel(), b.ravel()], axis=1)
	t = np.full_like(target, 0.5)
	for _ in range(ITERATIONS):
		y = forward(lut, size, t)
		jacobian = np.empty((len(t), 3, 3))
		for j in range(3):
			moved = t.copy()
			moved[:, j] += DERIVATIVE_STEP
			jacobian[:, :, j] = (forward(lut, size, moved) - y) / DERIVATIVE_STEP
		step = np.einsum("nij,nj->ni", np.linalg.pinv(jacobian), y - target)
		t = np.clip(t - STEP * step, SHAPER_MARGIN, 1.0 - SHAPER_MARGIN)
	error = np.abs(forward(lut, size, t) - target).max(axis=1) * 255
	log_light = t * (hi - lo) + lo
	with open(INVERSE, "wb") as file:
		file.write(struct.pack("<iff", SIZE, 0.0, 1.0))
		file.write(log_light.astype("<f4").tobytes())
	print(f"wrote {INVERSE}: {SIZE}^3, error in 8-bit steps: median {np.median(error):.2f}, "
		f"99% {np.percentile(error, 99):.2f}, max {error.max():.2f} (unreachable colours)")
	return 0


if __name__ == "__main__":
	sys.exit(main())
