extends SceneTree
## Loads every script, scene and resource in the project, so a file that nothing references yet still
## has to compile under the strict warnings. Exits with 1 on any error:
##   godot --headless --path . --script res://tests/compile_all.gd

const EXTENSIONS: PackedStringArray = ["gd", "tscn", "tres"]


func _init() -> void:
	var error_log := ErrorLog.new()
	OS.add_logger(error_log)
	var paths: PackedStringArray = []
	_collect("res://", paths)
	var broken: int = 0
	for path: String in paths:
		var start: int = error_log.count()
		var resource: Resource = load(path)
		var problems: PackedStringArray = error_log.errors_since(start)
		if resource == null and problems.is_empty():
			problems.append("does not load")
		if not problems.is_empty():
			broken += 1
			print("BROKEN ", path, ": ", "; ".join(problems))
	print("COMPILE: %d files, %d broken" % [paths.size(), broken])
	quit(1 if broken > 0 or paths.is_empty() else 0)


## Every file with one of EXTENSIONS under dir, skipping hidden folders such as .godot.
func _collect(dir: String, paths: PackedStringArray) -> void:
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() in EXTENSIONS:
			paths.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		if not sub.begins_with("."):
			_collect(dir.path_join(sub), paths)
