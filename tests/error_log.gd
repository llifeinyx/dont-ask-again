class_name ErrorLog
extends Logger
## Collects every error Godot reports. A runtime error doesn't stop a script, so test tools ask this log
## whether anything went wrong. Register with OS.add_logger().

var _mutex := Mutex.new()
var _errors: PackedStringArray = []


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	var text: String = code if rationale.is_empty() else rationale
	_mutex.lock()
	_errors.append("%s (%s:%d in %s)" % [text, file, line, function])
	_mutex.unlock()


func count() -> int:
	_mutex.lock()
	var result: int = _errors.size()
	_mutex.unlock()
	return result


## Errors logged after count() returned start.
func errors_since(start: int) -> PackedStringArray:
	_mutex.lock()
	var result: PackedStringArray = _errors.slice(start)
	_mutex.unlock()
	return result
