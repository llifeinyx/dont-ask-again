extends SceneTree
## Compares screenshots with what they must look like and exits with 1 on any mismatch:
##   godot --headless --path . --script res://tests/compare_shots.gd -- --shots=<dir> [--update-golden]
## - tests/reference/<shot>.png come from the source the shot must match at full size: front_* from
##   Blender (tools/blender/export_front.py), ndos_* from Figma (the ND-OS Desktop frame, 2:59).
## - tests/golden/<shot>.png are approved screenshots; they catch any change of look. Front goldens are
##   quarter size; ND-OS goldens stay full size, because halving averages away a changed digit.
##   --update-golden replaces them when a change is meant. Commit the new ones in the same change.
## Every reference and golden needs a shot of the same name, so a dropped shot cannot pass unnoticed.
## A heat map <shot>_reference_diff.png or <shot>_golden_diff.png is saved next to a shot that fails.

const REFERENCE_DIR := "res://tests/reference"
const GOLDEN_DIR := "res://tests/golden"
## Goldens are halved this many times, which averages away noise and keeps the files small. ND-OS has
## no noise (no light layers, no BC6H) and its small text must not average away.
const GOLDEN_HALVINGS: Dictionary[String, int] = {"front_": 2, "ndos_": 0}
## Heat map brightness per step of difference.
const HEAT_GAIN: int = 16


## Allowed differences in steps of 255: the mean over all channels, the 99.9th percentile, and how many
## pixels may be off by more than a step. The last one catches small parts of the frame (the indicator,
## the mug) that hardly move the mean; a few such pixels come from BC6H around bright spots.
class Limits:
	var mean: float
	var p999: int
	var outlier_step: int
	var outliers: int

	func _init(mean_limit: float, p999_limit: int, step: int, count: int) -> void:
		mean = mean_limit
		p999 = p999_limit
		outlier_step = step
		outliers = count


## Shot name prefix -> where its reference comes from.
const REFERENCE_SOURCES: Dictionary[String, String] = {"front_": "Blender", "ndos_": "Figma"}

## Figma and Godot rasterise text differently: Figma keeps the "ND-OS" title on a half pixel row and
## blurs it over one more row, and its antialiasing is a little softer. Those text pixels are the
## outliers; everything else (panels, icons, badges) matches within a step or two. Measured on M3:
## mean 0.03, 99.9% within 4, 438 pixels over 16; the limits leave about 20% on top.
var _reference_limits: Dictionary[String, Limits] = {
	"Blender": Limits.new(0.75, 6, 16, 32),
	"Figma": Limits.new(0.06, 6, 16, 520),
}
## ND-OS renders the same every time (0 pixels off between runs), so its full-size goldens are strict:
## a "3" that turns into an "8" on a badge changes only about 10 pixels.
var _golden_limits: Dictionary[String, Limits] = {
	"front_": Limits.new(0.5, 4, 8, 8),
	"ndos_": Limits.new(0.05, 1, 8, 2),
}


func _init() -> void:
	var shots_dir: String = ""
	var update: bool = false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
		elif arg == "--update-golden":
			update = true
	var shots: PackedStringArray = _pngs(shots_dir)
	var failed: int = 0
	for file: String in shots:
		var problems: PackedStringArray = _check(shots_dir, file, update)
		if problems.is_empty():
			print("PASS ", file)
		else:
			failed += 1
			print("FAIL ", file, ": ", "; ".join(problems))
	for dir: String in [REFERENCE_DIR, GOLDEN_DIR]:
		for file: String in _pngs(ProjectSettings.globalize_path(dir)):
			if not shots.has(file):
				failed += 1
				print("FAIL ", file, ": in %s but no shot has this name; shoot it or delete it" % dir)
	print("SHOTS: %d checked, %d failed" % [shots.size(), failed])
	quit(1 if failed > 0 or shots.is_empty() else 0)


static func _pngs(dir: String) -> PackedStringArray:
	var files: PackedStringArray = []
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".png") and not file.ends_with("_diff.png"):
			files.append(file)
	files.sort()
	return files


func _check(shots_dir: String, file: String, update: bool) -> PackedStringArray:
	var problems: PackedStringArray = []
	var shot := Image.load_from_file(shots_dir.path_join(file))
	shot.convert(Image.FORMAT_RGB8)
	var heat_path: String = shots_dir.path_join(file.get_basename() + "_%s_diff.png")

	var reference_path: String = ProjectSettings.globalize_path(REFERENCE_DIR.path_join(file))
	if FileAccess.file_exists(reference_path):
		var source: String = _reference_source(file)
		if source.is_empty():
			problems.append("has a reference but no known source for its name")
		else:
			var limits: Limits = _reference_limits[source]
			var problem: String = _compare(shot, Image.load_from_file(reference_path), limits, heat_path % "reference")
			if not problem.is_empty():
				problems.append("against %s: %s" % [source, problem])

	var small: Image = shot.duplicate()
	for i: int in GOLDEN_HALVINGS[_family(file)]:
		small.shrink_x2()
	var golden_path: String = ProjectSettings.globalize_path(GOLDEN_DIR.path_join(file))
	if update:
		DirAccess.make_dir_recursive_absolute(golden_path.get_base_dir())
		var error: Error = small.save_png(golden_path)
		if error != OK:
			problems.append("cannot write golden: " + error_string(error))
	elif not FileAccess.file_exists(golden_path):
		problems.append("no golden yet; check the shot and run with --update-golden")
	else:
		var limits: Limits = _golden_limits[_family(file)]
		var problem: String = _compare(small, Image.load_from_file(golden_path), limits, heat_path % "golden")
		if not problem.is_empty():
			problems.append("against golden: " + problem)
	return problems


## Which part of the game a shot shows, as the prefix of its name; anything unknown counts as front.
static func _family(file: String) -> String:
	return "ndos_" if file.begins_with("ndos_") else "front_"


static func _reference_source(file: String) -> String:
	for prefix: String in REFERENCE_SOURCES:
		if file.begins_with(prefix):
			return REFERENCE_SOURCES[prefix]
	return ""


## Empty when the images match within the limits; otherwise what differs. Saves a heat map on failure.
func _compare(actual: Image, expected: Image, limits: Limits, heat_path: String) -> String:
	expected.convert(Image.FORMAT_RGB8)
	if actual.get_size() != expected.get_size():
		return "size %s, expected %s" % [actual.get_size(), expected.get_size()]
	var a: PackedByteArray = actual.get_data()
	var b: PackedByteArray = expected.get_data()
	var histogram := PackedInt64Array()
	histogram.resize(256)
	var total: int = 0
	var outliers: int = 0
	for pixel: int in actual.get_width() * actual.get_height():
		var worst: int = 0
		for i: int in range(pixel * 3, pixel * 3 + 3):
			var difference: int = absi(a[i] - b[i])
			histogram[difference] += 1
			total += difference
			worst = maxi(worst, difference)
		if worst > limits.outlier_step:
			outliers += 1
	var mean: float = float(total) / a.size()
	var p999: int = _percentile(histogram, a.size(), 0.999)
	var summary: String = "mean %.2f (limit %.2f), 99.9%% within %d (limit %d), %d pixels over %d (limit %d), max %d" % [
		mean, limits.mean, p999, limits.p999, outliers, limits.outlier_step, limits.outliers, _percentile(histogram, a.size(), 1.0)]
	print("  ", heat_path.get_file().trim_suffix("_diff.png"), ": ", summary)
	if mean <= limits.mean and p999 <= limits.p999 and outliers <= limits.outliers:
		return ""
	_save_heat_map(a, b, actual.get_size(), heat_path)
	return summary


static func _percentile(histogram: PackedInt64Array, count: int, share: float) -> int:
	var needed: int = ceili(count * share)
	var seen: int = 0
	for value: int in histogram.size():
		seen += histogram[value]
		if seen >= needed:
			return value
	return histogram.size() - 1


static func _save_heat_map(a: PackedByteArray, b: PackedByteArray, size: Vector2i, path: String) -> void:
	var heat := PackedByteArray()
	heat.resize(a.size())
	for i: int in a.size():
		heat[i] = mini(255, absi(a[i] - b[i]) * HEAT_GAIN)
	Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGB8, heat).save_png(path)
