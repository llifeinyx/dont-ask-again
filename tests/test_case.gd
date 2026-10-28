class_name TestCase
extends RefCounted
## Base for unit tests. tests/run_tests.gd runs every method named test_* on a fresh instance.

var failures: PackedStringArray = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	# Compare types first: == between some different types is a runtime error, not false.
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s: expected %s, got %s" % [message, var_to_str(expected), var_to_str(actual)])
