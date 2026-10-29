extends Node
## Clicks through the whole frame the way a player does: for every launcher slot it moves the mouse to
## the window point that shows the slot's centre, checks that ND-OS hovers that slot, and clicks the
## open ones. Fullscreen, so the window has the virtual display's size:
##   xvfb-run -s "-screen 0 1920x1080x24" godot --path . res://tests/bots/click_bot.tscn
## Prints PASS/FAIL lines and "BOT: <checks> checked, <failed> failed", exits with 1 on any failure.

## Frames for the input to pass through the glass and for ND-OS to update.
const SETTLE_FRAMES: int = 3
## A window point on the wall, far from the glass.
const WALL := Vector2(4, 4)

var _checks: int = 0
var _failed: int = 0

@onready var _view: FrontView = $FrontView


func _ready() -> void:
	await _settle()
	var manifest: FrontManifest = load(FrontFrame.MANIFEST_PATH)
	var map := GlassMap.load_default(manifest)
	var to_window: Transform2D = get_viewport().get_final_transform()
	var desktop: NdosDesktop = _view.desktop
	var window_size: Vector2i = get_window().size
	for node: Node in desktop.find_children("*", "LauncherSlot"):
		var slot: LauncherSlot = node
		var name_in_log: String = "%s %s" % [window_size, NdosDesktop.Program.keys()[slot.program]]
		var center_uv: Vector2 = desktop.slot_rect(slot.program).get_center() / Vector2(NdosTokens.SCREEN_SIZE)
		var frame_point: Vector2 = map.ndos_to_frame(center_uv)
		var window_point: Vector2 = to_window * (frame_point - Vector2(map.view_origin))
		await _move(window_point)
		var hovered: Control = desktop.get_viewport().gui_get_hovered_control()
		var hovered_name: String = "nothing" if hovered == null else String(hovered.name)
		_check(hovered == slot, "%s hovered at window %s (got %s)" % [name_in_log, window_point.round(), hovered_name])
		if not slot.locked:
			await _click(window_point)
			_check(desktop.active_program == slot.program, "%s opens on click" % name_in_log)
	await _move(WALL)
	_check(desktop.get_viewport().gui_get_hovered_control() == null, "%s nothing hovered off the glass" % window_size)
	print("BOT: %d checked, %d failed" % [_checks, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _move(window_point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = window_point
	motion.global_position = window_point
	Input.parse_input_event(motion)
	await _settle()


func _click(window_point: Vector2) -> void:
	for pressed: bool in [true, false]:
		var button := InputEventMouseButton.new()
		button.position = window_point
		button.global_position = window_point
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = pressed
		Input.parse_input_event(button)
		await _settle()


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("PASS " if ok else "FAIL ", what)


func _settle() -> void:
	for i: int in SETTLE_FRAMES:
		await get_tree().process_frame
