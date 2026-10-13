extends RefCounted
## Procedural, dithered placeholder images for labeling tasks.
## Every image is described by data (scene + figure), so real art can replace it later.

const PALETTE := [Color8(13, 13, 12), Color8(52, 51, 47), Color8(104, 101, 95), Color8(160, 157, 148), Color8(205, 202, 192)]
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


static func scene(spec: Dictionary, w: int = 120, h: int = 72) -> ImageTexture:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var kind: String = spec.get("scene", "office")
	var figure: String = spec.get("figure", "none")
	var s: float = float(spec.get("seed", 1))
	for y in h:
		for x in w:
			var v := _shade(kind, x, y, w, h, s)
			v = _figure(figure, kind, v, x, y, w, h)
			img.set_pixel(x, y, _quantize(v, x, y))
	return ImageTexture.create_from_image(img)


static func tile(kind: String, s: float, size: int = 32) -> ImageTexture:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var fx := float(x) / size
			var fy := float(y) / size
			var v := 0.16 + _hash(x * 3.1 + y * 7.7 + s) * 0.08
			match kind:
				"vent", "vent_eyes":
					if fx > 0.12 and fx < 0.88 and fy > 0.12 and fy < 0.88:
						v = 0.46 if y % 5 < 2 else 0.03
					elif fx > 0.08 and fx < 0.92 and fy > 0.08 and fy < 0.92:
						v = 0.32
					if kind == "vent_eyes" and absf(fy - 0.53) < 0.05 and (absf(fx - 0.4) < 0.04 or absf(fx - 0.6) < 0.04):
						v = 0.97
				"pipe":
					var d := absf(fy - 0.5)
					if d < 0.18:
						v = 0.3 + (0.18 - d) * 2.0
				"door":
					if fx > 0.25 and fx < 0.75 and fy > 0.1:
						v = 0.3
					if absf(fx - 0.66) < 0.04 and absf(fy - 0.55) < 0.04:
						v = 0.8
			img.set_pixel(x, y, _quantize(v, x, y))
	return ImageTexture.create_from_image(img)


static func _hash(n: float) -> float:
	var v := sin(n * 12.9898) * 43758.5453
	return v - floor(v)


static func _quantize(v: float, x: int, y: int) -> Color:
	v = clampf(v, 0.0, 0.999) * float(PALETTE.size() - 1)
	var base := int(floor(v))
	var frac := v - base
	var th := (float(BAYER[(y % 4) * 4 + (x % 4)]) + 0.5) / 16.0
	if frac > th:
		return PALETTE[base + 1]
	return PALETTE[base]


static func _shade(kind: String, x: int, y: int, w: int, h: int, s: float) -> float:
	var fx := float(x) / w
	var fy := float(y) / h
	match kind:
		"street":
			var horizon := 0.62
			if fy < horizon:
				var col := int(fx * 9.0)
				var bh := 0.2 + _hash(col + s) * 0.35
				if fy > horizon - bh:
					var lit := (x % 6 < 2) and (y % 7 < 3) and _hash(x * 0.37 + y * 1.1 + s) > 0.6
					return 0.62 if lit else 0.12
				return 0.55 - fy * 0.4
			return 0.28 - (fy - horizon) * 0.3
		"office":
			if fy > 0.78:
				return 0.08
			if fx > 0.08 and fx < 0.38 and fy > 0.12 and fy < 0.5:
				return 0.8 - fy * 0.4
			if fx > 0.55 and fx < 0.75 and fy > 0.5 and fy < 0.76:
				return 0.6
			return 0.35 + fy * 0.1
		"corridor":
			var dx := absf(fx - 0.5) * 2.0
			var dy := absf(fy - 0.48) * 2.0
			var d := maxf(dx, dy)
			if d < 0.14:
				return 0.04
			var c := 0.08 + d * 0.45
			if fy < 0.48 and dx < d * 0.25 and int(d * 14.0) % 2 == 0:
				c += 0.35
			return c
		"closet":
			var glow := maxf(0.0, 1.0 - Vector2(fx - 0.5, fy - 0.45).length() * 2.2)
			if fy > 0.78:
				return 0.05 + glow * 0.1
			if fx > 0.38 and fx < 0.62 and fy > 0.3 and fy < 0.62:
				return 0.78
			return 0.06 + glow * 0.32
		"vent":
			if fx < 0.12 or fx > 0.88 or fy < 0.12 or fy > 0.88:
				return 0.3
			return 0.42 if y % 6 < 3 else 0.03
	return 0.3


static func _figure(figure: String, kind: String, v: float, x: int, y: int, w: int, h: int) -> float:
	if figure == "none":
		return v
	var fx := float(x) / w
	var fy := float(y) / h
	var aspect := float(w) / h
	if figure == "eyes":
		if absf(fy - 0.45) < 0.025 and (absf(fx - 0.46) < 0.012 or absf(fx - 0.54) < 0.012):
			return 0.97
		return v
	var cx := 0.32 if kind == "street" else 0.5
	var head := Vector2((fx - cx) * aspect, fy - 0.36).length() < 0.075
	var body := fy > 0.44 and absf(fx - cx) * aspect < 0.11 + (fy - 0.44) * 0.25
	if head or body:
		match figure:
			"clear":
				return 0.0 if v > 0.15 else 0.3
			"faint":
				return v * 0.72
			"back":
				return 0.015
	return v
