extends TestCase

var _selected: Array[NdosDesktop.Program] = []


func _desktop() -> NdosDesktop:
	var scene: PackedScene = load("res://game/ndos/desktop.tscn")
	var desktop: NdosDesktop = scene.instantiate()
	var tree: SceneTree = Engine.get_main_loop()
	tree.root.add_child(desktop)
	desktop.program_selected.connect(func(program: NdosDesktop.Program) -> void: _selected.append(program))
	return desktop


func _slot(desktop: NdosDesktop, program: NdosDesktop.Program) -> LauncherSlot:
	for node: Node in desktop.find_children("*", "LauncherSlot"):
		var slot: LauncherSlot = node
		if slot.program == program:
			return slot
	return null


func test_starts_empty() -> void:
	var desktop := _desktop()
	check_eq(desktop.active_program, NdosDesktop.Program.NONE, "nothing runs at first")
	for node: Node in desktop.find_children("*", "LauncherSlot"):
		var slot: LauncherSlot = node
		check(not slot.active, "%s is not active" % slot.name)
		check_eq(slot.badge_count, 0, "%s has no badge" % slot.name)
	desktop.free()


func test_every_program_has_one_slot() -> void:
	var desktop := _desktop()
	for program: NdosDesktop.Program in NdosDesktop.Program.values():
		if program != NdosDesktop.Program.NONE:
			check(_slot(desktop, program) != null, "slot for %s" % NdosDesktop.Program.keys()[program])
	desktop.free()


func test_click_selects_once() -> void:
	var desktop := _desktop()
	_selected.clear()
	var corps: LauncherSlot = _slot(desktop, NdosDesktop.Program.CORPS)
	corps.pressed.emit()
	check_eq(desktop.active_program, NdosDesktop.Program.CORPS, "CORPS is active")
	check(corps.active, "the CORPS slot shows it")
	corps.pressed.emit()
	check_eq(_selected.size(), 1, "clicking the active program again changes nothing")
	_slot(desktop, NdosDesktop.Program.HUMANET).pressed.emit()
	check(not corps.active, "only one program is active")
	check_eq(_selected, [NdosDesktop.Program.CORPS, NdosDesktop.Program.HUMANET] as Array[NdosDesktop.Program], "signals")
	desktop.free()


func test_locked_programs_ignore_clicks() -> void:
	var desktop := _desktop()
	for program: NdosDesktop.Program in [NdosDesktop.Program.TERMINAL, NdosDesktop.Program.FILES, NdosDesktop.Program.SETTINGS]:
		var slot: LauncherSlot = _slot(desktop, program)
		check(slot.locked and slot.disabled, "%s is locked" % slot.name)
	for program: NdosDesktop.Program in [NdosDesktop.Program.CORPS, NdosDesktop.Program.OBSERVER, NdosDesktop.Program.HUMANET]:
		check(not _slot(desktop, program).disabled, "%s opens" % NdosDesktop.Program.keys()[program])
	desktop.free()


func test_badges() -> void:
	var desktop := _desktop()
	desktop.set_badge(NdosDesktop.Program.CORPS, 3)
	desktop.set_alert(NdosDesktop.Program.OBSERVER, true)
	check_eq(_slot(desktop, NdosDesktop.Program.CORPS).badge_count, 3, "CORPS count")
	check(_slot(desktop, NdosDesktop.Program.OBSERVER).alert, "ObServer alert")
	desktop.free()
