class_name Lut3D
extends RefCounted
## A 3D colour LUT over a log2 shaper, as tools/blender/export_front.py writes it:
## int32 size, float32 log2 range low and high, then float32 RGB for every [b][g][r].

const HEADER_BYTES: int = 12

var size: int
var lo: float
var hi: float
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
	var slices: Array[Image] = []
	for b: int in lut.size:
		slices.append(Image.create_from_data(lut.size, lut.size, false, Image.FORMAT_RGBF, file.get_buffer(slice_bytes)))
	lut.texture = ImageTexture3D.new()
	lut.texture.create(Image.FORMAT_RGBF, lut.size, lut.size, lut.size, false, slices)
	return lut


## Sets the uniforms of game/shaders/agx_punchy.gdshaderinc.
func apply_to(material: ShaderMaterial) -> void:
	material.set_shader_parameter("agx_lut", texture)
	material.set_shader_parameter("agx_lut_lo", lo)
	material.set_shader_parameter("agx_lut_hi", hi)
	material.set_shader_parameter("agx_lut_size", float(size))
