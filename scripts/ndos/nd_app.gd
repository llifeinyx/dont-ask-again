extends RefCounted
## Base for the ND-OS programs. A program draws itself through the shell's helpers
## (`os`), registers click areas with os.hit*, and handles keys while it is active.

const S := preload("res://scripts/ndos/nd_style.gd")

var os
var shift


func setup(owner_os, owner_shift, content: Dictionary) -> void:
	os = owner_os
	shift = owner_shift
	_load(content)


func _load(_content: Dictionary) -> void:
	pass


func badge() -> String:
	return ""


func tick(_delta: float) -> void:
	pass


func draw() -> void:
	pass


func key(_ev: InputEventKey) -> bool:
	return false


func on_open() -> void:
	pass


## Printable character of a key event, or "" for control keys.
static func char_of(ev: InputEventKey) -> String:
	if ev.unicode >= 32 and ev.unicode != 127:
		return String.chr(ev.unicode)
	return ""


static func is_enter(ev: InputEventKey) -> bool:
	return ev.keycode == KEY_ENTER or ev.keycode == KEY_KP_ENTER


## Digit 1..9 pressed (main row or keypad), or 0 if none.
static func digit_of(ev: InputEventKey) -> int:
	if ev.keycode >= KEY_1 and ev.keycode <= KEY_9:
		return ev.keycode - KEY_0
	if ev.keycode >= KEY_KP_1 and ev.keycode <= KEY_KP_9:
		return ev.keycode - KEY_KP_0
	return 0
