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
	var counts: Dictionary[NdosDesktop.Program, int] = {}
	for node: Node in desktop.find_children("*", "LauncherSlot"):
		var slot: LauncherSlot = node
		counts[slot.program] = counts.get(slot.program, 0) + 1
	for program: NdosDesktop.Program in NdosDesktop.Program.values():
		if program != NdosDesktop.Program.NONE:
			check_eq(counts.get(program, 0), 1, "slots for %s" % NdosDesktop.Program.keys()[program])
	desktop.free()


func test_top_panel_height_is_the_token() -> void:
	var scene: PackedScene = load("res://game/ndos/top_panel.tscn")
	var panel: TopPanel = scene.instantiate()
	check_eq(int(panel.custom_minimum_size.y), NdosTokens.TOP_PANEL_HEIGHT, "top_panel.tscn height")
	panel.free()


func test_clock_shows_in_the_top_panel() -> void:
	var desktop := _desktop()
	var labels: Array[Node] = desktop.find_children("Clock", "Label", true, false)
	check_eq(labels.size(), 1, "one clock label")
	if labels.size() == 1:
		var label: Label = labels[0]
		check_eq(label.text, "10/17  9:00 AM", "the label shows the clock")
		desktop.clock.elapsed = 3600.0
		check_eq(label.text, "10/17  10:00 AM", "and follows it")
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
	check_eq(_badge_text(desktop, NdosDesktop.Program.CORPS), "3", "CORPS shows its count")
	check_eq(_badge_text(desktop, NdosDesktop.Program.OBSERVER), "!", "ObServer shows the alert")
	check_eq(_badge_text(desktop, NdosDesktop.Program.HUMANET), "", "no badge without new items")
	desktop.set_badge(NdosDesktop.Program.CORPS, 0)
	check_eq(_badge_text(desktop, NdosDesktop.Program.CORPS), "", "the badge hides at 0")
	desktop.free()


## The text on a program's count badge, or "" when the badge is hidden.
func _badge_text(desktop: NdosDesktop, program: NdosDesktop.Program) -> String:
	var badge: LauncherBadge = _slot(desktop, program).get_node("Content/Badge")
	var text: Label = badge.get_node("Text")
	return text.text if badge.visible and text.visible else ""
