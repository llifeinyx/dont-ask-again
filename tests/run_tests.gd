extends SceneTree
## Runs every res://tests/unit/test_*.gd and exits with 1 on any failure:
##   godot --headless --path . --script res://tests/run_tests.gd

const UNIT_DIR := "res://tests/unit"


func _init() -> void:
	var passed: int = 0
	var failed: int = 0
	var files: PackedStringArray = DirAccess.get_files_at(UNIT_DIR)
	files.sort()
	for file: String in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(UNIT_DIR.path_join(file))
		if script == null or not script.can_instantiate():
			failed += 1
			print("FAIL ", file, ": does not load")
			continue
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.call(method_name)
			var label: String = "%s.%s" % [file.get_basename(), method_name]
			if test.failures.is_empty():
				passed += 1
				print("PASS ", label)
			else:
				failed += 1
				print("FAIL ", label, ": ", "; ".join(test.failures))
	print("TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or passed == 0 else 0)
