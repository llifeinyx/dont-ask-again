class_name NdosDesktop
extends Control
## The ND-OS desktop: the top panel with the shift clock, the launcher and the empty program area.
## Runs on its own. Game code drives it through the methods below and listens to program_selected.

## A program slot was clicked and its program became active.
signal program_selected(program: Program)

enum Program { NONE, CORPS, OBSERVER, HUMANET, TERMINAL, FILES, SETTINGS }

## The program running in the program area.
var active_program: Program = Program.NONE

var _slots: Dictionary[Program, LauncherSlot] = {}

@onready var clock: ShiftClock = $Clock
@onready var _top_panel: TopPanel = $Layout/TopPanel


func _ready() -> void:
	for node: Node in find_children("*", "LauncherSlot"):
		var slot: LauncherSlot = node
		_slots[slot.program] = slot
		slot.pressed.connect(_on_slot_pressed.bind(slot.program))
	clock.changed.connect(_show_time)
	_show_time()


## Marks a program as the one running in the program area.
func select(program: Program) -> void:
	active_program = program
	for slot: LauncherSlot in _slots.values():
		slot.active = slot.program == program


## New items waiting in a program; 0 hides the badge.
func set_badge(program: Program, count: int) -> void:
	_slots[program].badge_count = count


## ObServer's red "!" on a program's badge.
func set_alert(program: Program, on: bool) -> void:
	_slots[program].alert = on


## Where a program's slot is, in the desktop's coordinates.
func slot_rect(program: Program) -> Rect2:
	var slot: LauncherSlot = _slots[program]
	return Rect2(slot.global_position - global_position, slot.size)


func _on_slot_pressed(program: Program) -> void:
	if program == active_program:
		return
	select(program)
	program_selected.emit(program)


func _show_time() -> void:
	_top_panel.time_text = clock.text()
