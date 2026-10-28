extends TestCase
## Lut3D reads the file tools/blender/export_front.py writes.

const PATH := "user://test_lut_3d.bin"


func _write(size: int, lo: float, hi: float, values: PackedFloat32Array) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_32(size)
	file.store_float(lo)
	file.store_float(hi)
	for value: float in values:
		file.store_float(value)
	file.close()


## Every entry holds its own (r, g, b) index, so swapped axes show.
func _index_lut(size: int) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	for b: int in size:
		for g: int in size:
			for r: int in size:
				values.append_array(PackedFloat32Array([r, g, b]))
	return values


func test_reads_red_along_x_and_blue_across_slices() -> void:
	_write(2, -1.0, 3.0, _index_lut(2))
	var lut := Lut3D.load_file(PATH)
	check_eq(lut.size, 2, "size")
	check_eq(lut.lo, -1.0, "log2 low")
	check_eq(lut.hi, 3.0, "log2 high")
	check_eq(lut.slices.size(), 2, "slices")
	for b: int in 2:
		for g: int in 2:
			for r: int in 2:
				check_eq(lut.slices[b].get_pixel(r, g), Color(r, g, b), "entry r%d g%d b%d" % [r, g, b])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_rejects_bad_files() -> void:
	# These errors are the point of the test; keep them out of the log, where any error fails a test.
	Engine.print_error_messages = false
	check(Lut3D.load_file("user://no_such_lut.bin") == null, "missing file")
	_write(2, -1.0, 3.0, PackedFloat32Array([0.0, 0.0, 0.0]))
	check(Lut3D.load_file(PATH) == null, "file cut short")
	_write(2, 3.0, -1.0, _index_lut(2))
	check(Lut3D.load_file(PATH) == null, "log2 range upside down")
	_write(1, -1.0, 3.0, _index_lut(1))
	check(Lut3D.load_file(PATH) == null, "a single entry")
	Engine.print_error_messages = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
