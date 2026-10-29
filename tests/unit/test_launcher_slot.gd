extends TestCase
## Real mouse input through a SubViewport, the way ND-OS gets it on the glass.

const INSIDE := Vector2(45, 36)
const OUTSIDE := Vector2(150, 150)

var _presses: int = 0


func _slot(locked: bool) -> LauncherSlot:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(200, 200)
	var tree: SceneTree = Engine.get_main_loop()
	tree.root.add_child(viewport)
	var scene: PackedScene = load("res://game/ndos/launcher_slot.tscn")
	var slot: LauncherSlot = scene.instantiate()
	slot.locked = locked
	viewport.add_child(slot)
	slot.pressed.connect(func() -> void: _presses += 1)
	return slot


func _move(slot: LauncherSlot, position: Vector2, held: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	_push(slot, motion)


func _button(slot: LauncherSlot, position: Vector2, down: bool) -> void:
	var button := InputEventMouseButton.new()
	button.position = position
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = down
	_push(slot, button)


func _push(slot: LauncherSlot, event: InputEvent) -> void:
	var viewport: SubViewport = slot.get_parent()
	viewport.push_input(event, true)
	# The renderer would send this on the next frame; the slot redraws on every draw mode change.
	slot.notification(CanvasItem.NOTIFICATION_DRAW)


func _look(slot: LauncherSlot) -> String:
	var hover: Control = slot.get_node("Hover")
	var content: Control = slot.get_node("Content")
	return "%s%s" % ["hover" if hover.visible else "plain", " pressed" if content.position.y > 0 else ""]


func test_hover_press_and_drag() -> void:
	var slot := _slot(false)
	_presses = 0
	_move(slot, INSIDE, false)
	check_eq(_look(slot), "hover", "mouse over")
	_button(slot, INSIDE, true)
	check_eq(_look(slot), "hover pressed", "held down")
	_move(slot, OUTSIDE, true)
	check_eq(_look(slot), "plain", "dragged out while held")
	_move(slot, INSIDE, true)
	check_eq(_look(slot), "hover pressed", "dragged back in")
	_button(slot, INSIDE, false)
	check_eq(_presses, 1, "released inside: one click")
	check_eq(_look(slot), "hover", "released")
	slot.get_parent().free()


func test_active_keeps_the_outline() -> void:
	var slot := _slot(false)
	slot.active = true
	slot.notification(CanvasItem.NOTIFICATION_DRAW)
	check_eq(_look(slot), "hover", "the active program is outlined")
	_move(slot, OUTSIDE, false)
	check_eq(_look(slot), "hover", "even without the mouse")
	slot.active = false
	slot.notification(CanvasItem.NOTIFICATION_DRAW)
	check_eq(_look(slot), "plain", "not once another program runs")
	slot.get_parent().free()


func test_locked_ignores_the_mouse() -> void:
	var slot := _slot(true)
	_presses = 0
	_move(slot, INSIDE, false)
	_button(slot, INSIDE, true)
	check_eq(_look(slot), "plain", "no hover or press")
	_button(slot, INSIDE, false)
	check_eq(_presses, 0, "no click")
	slot.get_parent().free()
