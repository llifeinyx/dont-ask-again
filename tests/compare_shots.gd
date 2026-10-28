extends SceneTree
## Compares screenshots with what they must look like and exits with 1 on any mismatch:
##   godot --headless --path . --script res://tests/compare_shots.gd -- --shots=<dir> [--update-golden]
## - tests/reference/<shot>.png come from Blender (tools/blender/export_front.py). Where one exists, the
##   shot must match it closely at full size.
## - tests/golden/<shot>.png are approved screenshots at quarter size; they catch any change of look.
##   --update-golden replaces them when a change is meant. Commit the new ones in the same change.
## A heat map <shot>_diff.png is saved next to every shot that fails.

const REFERENCE_DIR := "res://tests/reference"
const GOLDEN_DIR := "res://tests/golden"
## Goldens are halved this many times, which averages away noise and keeps the files small.
const GOLDEN_HALVINGS: int = 2
## Allowed differences in steps of 255: the mean over all channels and the 99.9th percentile.
const REFERENCE_MEAN: float = 0.75
const REFERENCE_P999: int = 6
const GOLDEN_MEAN: float = 0.5
const GOLDEN_P999: int = 4
## Heat map brightness per step of difference.
const HEAT_GAIN: int = 16


func _init() -> void:
	var shots_dir: String = ""
	var update: bool = false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
		elif arg == "--update-golden":
			update = true
	var shots: PackedStringArray = []
	for file: String in DirAccess.get_files_at(shots_dir):
		if file.ends_with(".png") and not file.ends_with("_diff.png"):
			shots.append(file)
	shots.sort()
	var failed: int = 0
	for file: String in shots:
		var problems: PackedStringArray = _check(shots_dir, file, update)
		if problems.is_empty():
			print("PASS ", file)
		else:
			failed += 1
			print("FAIL ", file, ": ", "; ".join(problems))
	print("SHOTS: %d checked, %d failed" % [shots.size(), failed])
	quit(1 if failed > 0 or shots.is_empty() else 0)


func _check(shots_dir: String, file: String, update: bool) -> PackedStringArray:
	var problems: PackedStringArray = []
	var shot := Image.load_from_file(shots_dir.path_join(file))
	shot.convert(Image.FORMAT_RGB8)
	var heat_path: String = shots_dir.path_join(file.get_basename() + "_diff.png")

	var reference_path: String = ProjectSettings.globalize_path(REFERENCE_DIR.path_join(file))
	if FileAccess.file_exists(reference_path):
		var problem: String = _compare(shot, Image.load_from_file(reference_path), REFERENCE_MEAN, REFERENCE_P999, heat_path)
		if not problem.is_empty():
			problems.append("against Blender: " + problem)

	var small: Image = shot.duplicate()
	for i: int in GOLDEN_HALVINGS:
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
		var problem: String = _compare(small, Image.load_from_file(golden_path), GOLDEN_MEAN, GOLDEN_P999, heat_path)
		if not problem.is_empty():
			problems.append("against golden: " + problem)
	return problems


## Empty when the images match within the limits; otherwise what differs. Saves a heat map on failure.
func _compare(actual: Image, expected: Image, mean_limit: float, p999_limit: int, heat_path: String) -> String:
	expected.convert(Image.FORMAT_RGB8)
	if actual.get_size() != expected.get_size():
		return "size %s, expected %s" % [actual.get_size(), expected.get_size()]
	var a: PackedByteArray = actual.get_data()
	var b: PackedByteArray = expected.get_data()
	var histogram := PackedInt64Array()
	histogram.resize(256)
	var total: int = 0
	for i: int in a.size():
		var difference: int = absi(a[i] - b[i])
		histogram[difference] += 1
		total += difference
	var mean: float = float(total) / a.size()
	var p999: int = _percentile(histogram, a.size(), 0.999)
	var summary: String = "mean %.2f (limit %.2f), 99.9%% within %d (limit %d), max %d" % [
		mean, mean_limit, p999, p999_limit, _percentile(histogram, a.size(), 1.0)]
	print("  ", heat_path.get_file().trim_suffix("_diff.png"), ": ", summary)
	if mean <= mean_limit and p999 <= p999_limit:
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
