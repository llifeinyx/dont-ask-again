extends Node
## Clicks through the whole frame the way a player does: for every launcher slot it moves the mouse to
## the window point that shows the slot's centre, checks that ND-OS hovers that slot, and clicks the
## open ones; then it clicks the wall and lets a press go on the wall. Fullscreen, so the window has the virtual display's size:
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
	var map := GlassMap.load_default(manifest, _view.glass.fit)
	var to_window: Transform2D = get_viewport().get_final_transform()
	var desktop: NdosDesktop = _view.desktop
	var window_size: Vector2i = get_window().size
	_check(window_size == DisplayServer.screen_get_size(), "%s fills the display %s" % [window_size,
		DisplayServer.screen_get_size()])
	var slots: Array[Node] = desktop.find_children("*", "LauncherSlot")
	# Every program but NONE has a slot.
	_check(slots.size() == NdosDesktop.Program.size() - 1, "%s finds %d slots" % [window_size, slots.size()])
	var points: Dictionary[LauncherSlot, Vector2] = {}
	for node: Node in slots:
		var slot: LauncherSlot = node
		var name_in_log: String = "%s %s" % [window_size, NdosDesktop.Program.keys()[slot.program]]
		var center_uv: Vector2 = desktop.slot_rect(slot.program).get_center() / Vector2(NdosTokens.SCREEN_SIZE)
		var frame_point: Vector2 = map.ndos_to_frame(center_uv)
		if frame_point == Vector2(-1, -1):
			_check(false, "%s shows on the glass" % name_in_log)
			continue
		var window_point: Vector2 = to_window * (frame_point - Vector2(map.view_origin))
		points[slot] = window_point
		await _move(window_point)
		var hovered: Control = desktop.get_viewport().gui_get_hovered_control()
		var hovered_name: String = "nothing" if hovered == null else String(hovered.name)
		_check(hovered == slot, "%s hovered at window %s (got %s)" % [name_in_log, window_point.round(), hovered_name])
		if not slot.locked:
			await _click(window_point)
			_check(desktop.active_program == slot.program, "%s opens on click" % name_in_log)
	await _move(WALL)
	_check(_hovered(desktop) == null, "%s nothing hovered off the glass" % window_size)
	await _off_glass_releases(desktop, points, window_size)
	print("BOT: %d checked, %d failed" % [_checks, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


## A click on the wall after hovering a slot, and a press on a slot let go on the wall: neither may open
## a program or leave a slot hovered.
func _off_glass_releases(desktop: NdosDesktop, points: Dictionary[LauncherSlot, Vector2],
		window_size: Vector2i) -> void:
	var target: LauncherSlot = null
	for slot: LauncherSlot in points:
		if not slot.locked and slot.program != desktop.active_program:
			target = slot
	if target == null:
		_check(false, "%s has a second open slot to press" % window_size)
		return
	var active: NdosDesktop.Program = desktop.active_program
	await _move(points[target])
	await _move(WALL)
	await _click(WALL)
	_check(_hovered(desktop) == null and desktop.active_program == active,
		"%s a click on the wall changes nothing" % window_size)
	await _move(points[target])
	await _button(points[target], true)
	await _move(WALL)
	await _button(WALL, false)
	_check(_hovered(desktop) == null and desktop.active_program == active,
		"%s a press let go on the wall opens nothing" % window_size)


func _hovered(desktop: NdosDesktop) -> Control:
	return desktop.get_viewport().gui_get_hovered_control()


func _move(window_point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = window_point
	motion.global_position = window_point
	Input.parse_input_event(motion)
	await _settle()


func _click(window_point: Vector2) -> void:
	await _button(window_point, true)
	await _button(window_point, false)


func _button(window_point: Vector2, pressed: bool) -> void:
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
