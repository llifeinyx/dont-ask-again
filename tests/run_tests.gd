extends SceneTree
## Runs every res://tests/unit/test_*.gd and exits with 1 on any failure:
##   godot --headless --path . --script res://tests/run_tests.gd
## A test fails when a check fails or when it logs an error.

const UNIT_DIR := "res://tests/unit"

var _log := ErrorLog.new()
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	# Deferred: tests that load a scene need the root window in the tree, which happens after _init.
	_run.call_deferred()


func _run() -> void:
	OS.add_logger(_log)
	var files: PackedStringArray = DirAccess.get_files_at(UNIT_DIR)
	files.sort()
	for file: String in files:
		if file.begins_with("test_") and file.ends_with(".gd"):
			_run_file(file)
	print("TESTS: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 or _passed == 0 else 0)


func _run_file(file: String) -> void:
	var script: GDScript = load(UNIT_DIR.path_join(file))
	if script == null or not script.can_instantiate() or not _extends_test_case(script):
		_report(file, ["does not load or does not extend TestCase"])
		return
	var tests: int = 0
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if not method_name.begins_with("test_"):
			continue
		tests += 1
		var label: String = "%s.%s" % [file.get_basename(), method_name]
		var args: Array = method["args"]
		if not args.is_empty():
			_report(label, ["test methods take no arguments"])
			continue
		var start: int = _log.count()
		var test: TestCase = script.new()
		test.call(method_name)
		_report(label, test.failures + _log.errors_since(start))
	if tests == 0:
		_report(file, ["has no test_* methods"])


func _report(label: String, problems: PackedStringArray) -> void:
	if problems.is_empty():
		_passed += 1
		print("PASS ", label)
	else:
		_failed += 1
		print("FAIL ", label, ": ", "; ".join(problems))


func _extends_test_case(script: Script) -> bool:
	var base: Script = script
	while base != null:
		if base == TestCase:
			return true
		base = base.get_base_script()
	return false
