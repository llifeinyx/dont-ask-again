class_name Lut3D
extends RefCounted
## A 3D colour LUT over a log2 shaper, as tools/blender/export_front.py writes it:
## int32 size, float32 log2 range low and high, then float32 RGB for every [b][g][r].

const HEADER_BYTES: int = 12

var size: int
var lo: float
var hi: float
## One image per blue step; x is red, y is green.
var slices: Array[Image] = []
var texture: ImageTexture3D


## Returns null and reports an error when the file is missing or malformed.
static func load_file(path: String) -> Lut3D:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open LUT %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return null
	var lut := Lut3D.new()
	lut.size = file.get_32()
	lut.lo = file.get_float()
	lut.hi = file.get_float()
	var slice_bytes: int = lut.size * lut.size * 3 * 4
	if lut.size < 2 or lut.hi <= lut.lo or file.get_length() != HEADER_BYTES + slice_bytes * lut.size:
		push_error("LUT %s is malformed" % path)
		return null
	for b: int in lut.size:
		lut.slices.append(Image.create_from_data(lut.size, lut.size, false, Image.FORMAT_RGBF, file.get_buffer(slice_bytes)))
	lut.texture = ImageTexture3D.new()
	lut.texture.create(Image.FORMAT_RGBF, lut.size, lut.size, lut.size, false, lut.slices)
	return lut


## Sets the uniforms <prefix>, <prefix>_lo, <prefix>_hi and <prefix>_size, as the includes in
## game/shaders/ name them.
func apply_to(material: ShaderMaterial, prefix: String = "agx_lut") -> void:
	material.set_shader_parameter(prefix, texture)
	material.set_shader_parameter(prefix + "_lo", lo)
	material.set_shader_parameter(prefix + "_hi", hi)
	material.set_shader_parameter(prefix + "_size", float(size))


## The LUT at grid coordinates t (0..1 per channel), trilinear like the GPU.
func sample(t: Vector3) -> Vector3:
	var x: Vector3 = t.clamp(Vector3.ZERO, Vector3.ONE) * (size - 1)
	var i := Vector3i(x.floor()).mini(size - 2)
	var f: Vector3 = x - Vector3(i)
	var result := Vector3.ZERO
	for db: int in 2:
		for dg: int in 2:
			for dr: int in 2:
				var weight: float = (f.z if db else 1.0 - f.z) * (f.y if dg else 1.0 - f.y) * (f.x if dr else 1.0 - f.x)
				var c: Color = slices[i.z + db].get_pixel(i.x + dr, i.y + dg)
				result += Vector3(c.r, c.g, c.b) * weight
	return result
