extends Control
## Run flow: contract -> shift -> KONTUR report -> observation log -> night -> end card.
## Debug keys: F2 = speed x1/x4, F3 = skip 60 s of the shift, F4 = CRT strength,
## F11 = fullscreen.

const Ui := preload("res://scripts/ui.gd")
const NameEntry := preload("res://scripts/name_entry.gd")
const Shift := preload("res://scripts/shift.gd")
const CrtScreen := preload("res://scripts/crt_screen.gd")
const NdStyle := preload("res://scripts/ndos/nd_style.gd")
const BASE_SIZE := Vector2i(640, 360)   # logical viewport; the window is a whole multiple of it

var fader: ColorRect
var screen: Control
var shift_node = null
var smoke := false
var debug_label: Label
var shots = null
var input_test = null


func _ready() -> void:
	theme = Ui.make_theme()
	smoke = "--smoke" in OS.get_cmdline_user_args()
	if smoke:
		Engine.time_scale = 8.0
	if "--inputtest" in OS.get_cmdline_user_args():
		input_test = preload("res://scripts/debug_input_test.gd").new()
		add_child(input_test)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots = preload("res://scripts/debug_shots.gd").new()
			shots.dir = arg.trim_prefix("--shots=")
			add_child(shots)
	_setup_window()
	NdStyle.set_scale(_screen_pixels_per_unit())
	var bg := Ui.full_rect(ColorRect.new())
	bg.color = Color.BLACK
	add_child(bg)
	fader = Ui.full_rect(ColorRect.new())
	fader.color = Color.BLACK
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fader)
	debug_label = Ui.place(Ui.label("", 8, Ui.AMBER), Rect2(4, 348, 200, 12))
	add_child(debug_label)
	_start()


## The game is drawn in 640x360 logical units and scaled to the window, so on a big
## monitor it has to fill the screen: a 1280x720 window on a 1440p display halves the
## size of every glyph on the CRT. Default is fullscreen; --windowed gives the largest
## whole multiple of 640x360 that fits the screen instead.
func _setup_window() -> void:
	if DisplayServer.get_name() == "headless" or smoke or input_test != null:
		return
	if "--resolution" in OS.get_cmdline_args():
		return
	if "--windowed" in OS.get_cmdline_user_args():
		_fit_window()
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Real pixels one ND-OS unit gets here: the CRT picture is only ~260 of the 360 logical
## rows tall and holds 480 ND-OS rows, so the screen viewport needs more than 1:1 to stay
## sharp. Fullscreen 1080p -> 1.6, 1440p -> 2.2, 4K -> 3.2. Read once at startup.
func _screen_pixels_per_unit() -> float:
	if DisplayServer.get_name() == "headless":
		return 2.0
	var h := float(DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()).y)
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		h = minf(h, float(DisplayServer.window_get_size().y))
	var picture_rows: float = 2.0 * CrtScreen.ACTIVE.w
	return h / float(BASE_SIZE.y) * picture_rows / NdStyle.H


func _fit_window() -> void:
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var k := maxi(1, mini(usable.size.x / BASE_SIZE.x, usable.size.y / BASE_SIZE.y))
	var win := BASE_SIZE * k
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(win)
	DisplayServer.window_set_position(usable.position + (usable.size - win) / 2)


func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_F2:
			Engine.time_scale = 4.0 if Engine.time_scale == 1.0 else 1.0
			debug_label.text = "" if Engine.time_scale == 1.0 else "DEBUG SPEED x%d" % int(Engine.time_scale)
		KEY_F3:
			if shift_node != null and is_instance_valid(shift_node):
				shift_node.elapsed += 60.0
		KEY_F4:
			if shift_node != null and is_instance_valid(shift_node):
				debug_label.text = shift_node.crt.cycle_clarity()
		KEY_F11:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				_fit_window()
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _set_screen(c: Control) -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	screen = c
	add_child(c)
	move_child(fader, -1)
	move_child(debug_label, -1)


func _fade(to_alpha: float, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(fader, "modulate:a", to_alpha, seconds)
	await tw.finished


func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout


func _start() -> void:
	GameState.reset()
	var entry := NameEntry.new()
	_set_screen(entry)
	entry.submitted.connect(_on_signed)
	await _fade(0.0, 1.0)
	if smoke or input_test != null:
		await _wait(1.0)
		entry.edit.text = "Smoke Tester"
		if shots != null:
			await shots.capture("00_contract")
		entry.sign_contract()


func _on_signed(player_name: String) -> void:
	GameState.player_name = player_name
	Sfx.play("click")
	await _fade(1.0, 1.2)
	Sfx.play("lock")
	await _wait(1.6)
	var s := Shift.new()
	s.autoplay = smoke
	shift_node = s
	if input_test != null:
		input_test.shift = s
	if shots != null:
		s.autoplay_tabs = false
		s.autoplay_console_rate = 0.12
		s.autoplay_outage_delay = 4.0
		shots.shift = s
		shots.plan = [
			{"t": 26, "tab": 0, "name": "01_echo"},
			{"t": 84.3, "name": "02_kontur_alert"},
			{"t": 86.0, "tab": 1, "name": "02b_kontur_answer"},
			{"t": 200.4, "tab": 1, "name": "03_kontur"},
			{"t": 320.3, "tab": 0, "details": true, "name": "04_echo_diff"},
			{"t": 362.5, "tab": 0, "name": "05_name_slip"},
			{"t": 400, "tab": 2, "name": "06_feed"},
			{"t": 436, "tab": 3, "name": "07_seeya"},
			{"t": 545, "tab": 2, "store": true, "name": "08_store"},
			{"t": 622, "vent": true, "name": "09_vent_glint"},
			{"t": 623, "vent": false, "tab": 0, "name": "10_front"},
			{"t": 660.2, "eyes": true, "name": "11_outage_reflection"},
			{"t": 664.6, "name": "12_outage_vent"},
		]
	_set_screen(s)
	s.finished.connect(_on_shift_finished)
	await _fade(0.0, 2.0)


func _on_shift_finished(fired: bool) -> void:
	await _fade(1.0, 1.5)
	shift_node = null
	if fired:
		await _page(_fired_lines(), "ACCEPT NEW OPERATOR")
	else:
		await _page(_summary_lines(), "CONTINUE")
		await _page(_report_lines(), "CONTINUE")
		await _night()
		await _page([
			["END OF DAY 1", Ui.GREEN, 12],
			["Prototype build. The night continues in a later version.", Ui.MUTED],
			["Thank you for testing.", Ui.MUTED],
		], "ACCEPT NEW OPERATOR")
	if smoke:
		_print_smoke_summary(fired)
		get_tree().quit()
		return
	_start()


## lines: Array of [text, color] or [text, color, font_size].
func _page(lines: Array, button_text: String) -> void:
	var center := Ui.full_rect(CenterContainer.new())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	center.add_child(v)
	for ln in lines:
		var font_px := int(ln[2]) if ln.size() > 2 else 9
		v.add_child(Ui.wrap_label(String(ln[0]), 480, font_px, ln[1]))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	v.add_child(gap)
	var b := Ui.button("  " + button_text + "  ", _noop)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(b)
	_set_screen(center)
	await _fade(0.0, 0.8)
	if shots != null:
		await shots.capture("page_" + str(Time.get_ticks_msec()))
	if smoke:
		await _wait(0.5)
	else:
		await b.pressed
	Sfx.play("click")
	await _fade(1.0, 0.8)


func _noop() -> void:
	pass


func _count(how: String, decision: String = "") -> int:
	var n := 0
	for d in GameState.decisions:
		if String(d["how"]) == how and (decision == "" or String(d["decision"]) == decision):
			n += 1
	return n


func _summary_lines() -> Array:
	var labels_line := "Labeling: %d / %d" % [GameState.labeled, GameState.labeling_quota]
	if GameState.labeled < GameState.labeling_quota:
		labels_line += "   QUOTA NOT MET"
	return [
		["KONTUR // SHIFT REPORT", Ui.RED, 11],
		["Operator %s  #%s   Shift 1" % [GameState.player_name, GameState.OPERATOR_NO], Ui.TEXT],
		["Decisions: %d allowed, %d denied." % [_count("player", "allow"), _count("player", "deny")], Ui.TEXT],
		["Approved without a decision: %d (time limit), %d (during reboot), %d (\"don't ask again\")." % [_count("timeout"), _count("reboot"), _count("trusted")], Ui.AMBER],
		[labels_line, Ui.TEXT],
		["Violations: %d / %d.   Rating: %d.   Credits: %d." % [GameState.violations, GameState.FIRE_LIMIT, GameState.rating, GameState.credits], Ui.TEXT],
		["Your performance has been recorded. Rest is mandatory.", Ui.MUTED],
	]


func _report_lines() -> Array:
	var approved := 0
	var approved_read := 0
	var total_seconds := 0.0
	var risky := 0
	var risky_caught := 0
	var unmade: Array = []
	for d in GameState.decisions:
		if String(d["decision"]) == "allow":
			approved += 1
			if bool(d["opened"]):
				approved_read += 1
		if String(d["how"]) == "player":
			total_seconds += float(d["seconds"])
		else:
			unmade.append(String(d["title"]))
		if bool(d["risk"]):
			risky += 1
			if String(d["decision"]) == "deny":
				risky_caught += 1
	var made := maxi(1, _count("player"))
	var lines: Array = [
		["OBSERVATION LOG. NOT FOR THE OPERATOR.", Ui.AMBER, 11],
		["Contract signed after %d s. Scrolled to the end: %s." % [int(GameState.contract_seconds), "yes" if GameState.contract_scrolled else "no"], Ui.TEXT],
		["You approved %d actions. You opened the details of %d of them." % [approved, approved_read], Ui.TEXT],
		["Average time per decision: %.1f s." % (total_seconds / made), Ui.TEXT],
		["Requests with consequences in the fine print: %d. You denied: %d." % [risky, risky_caught], Ui.TEXT],
		["You turned around %d times. KONTUR saw %d of them." % [GameState.turns, GameState.turns_seen], Ui.TEXT],
	]
	if unmade.size() > 0:
		lines.append(["Decisions you did not make: " + ", ".join(unmade.slice(0, 6)) + ("..." if unmade.size() > 6 else ""), Ui.MUTED, 8])
	for r in GameState.kontur_results:
		if String(r["id"]) == "k_sound" and bool(r["ok"]):
			lines.append(["You described the sound as: \"%s\"" % String(r["answer"]), Ui.MUTED, 8])
		if String(r["id"]) == "k_quiet" and bool(r["ok"]):
			lines.append(["You typed: \"%s\"" % String(r["answer"]), Ui.MUTED, 8])
	return lines


func _fired_lines() -> Array:
	return [
		["YOU ARE FIRED.", Ui.RED, 14],
		["Thank you for your cooperation. Your resume has been saved in our database.", Ui.TEXT],
		["[Prototype: final screen pending. The apartment from the prologue. The laptop is still on. Rejections keep arriving.]", Ui.MUTED, 8],
	]


func _night() -> void:
	var c := Ui.full_rect(Control.new())
	c.add_child(Ui.place(Ui.label("NIGHT 1", 8, Color(0.3, 0.3, 0.3)), Rect2(8, 8, 100, 12)))
	if not GameState.flags.has("lights_off"):
		var glow := Ui.place(ColorRect.new(), Rect2(33, 28, 6, 6))
		glow.color = Color(0.35, 0.3, 0.18)
		c.add_child(glow)
	_set_screen(c)
	await _fade(0.0, 2.0)
	var danger := false
	for f in ["sector4_unlocked", "ir_deleted", "4b_cleared", "intake_open"]:
		if GameState.flags.has(f):
			danger = true
	Sfx.facing_vent = false
	Sfx.set_hum(true)
	await _wait(3.0)
	Sfx.play_vent("drip", -12.0)
	await _wait(2.5)
	Sfx.play_vent("drip", -12.0)
	await _wait(3.0)
	for i in 3:
		Sfx.play_vent("knock", -10.0)
		await _wait(0.9)
	await _wait(2.5)
	for i in 3:
		Sfx.play_vent("knock", -1.0 if danger else -6.0)
		await _wait(0.7)
	if danger:
		await _wait(1.5)
		Sfx.play_vent("scrape", -1.0)
		await _wait(2.0)
	await _wait(2.5)
	Sfx.set_hum(false)
	await _fade(1.0, 1.5)


func _print_smoke_summary(fired: bool) -> void:
	print("SMOKE: run finished. fired=%s" % fired)
	print("SMOKE: decisions=%d violations=%d labeled=%d credits=%d rating=%d" % [
		GameState.decisions.size(), GameState.violations, GameState.labeled, GameState.credits, GameState.rating])
	print("SMOKE: kontur_results=%d flags=%s owned=%s" % [GameState.kontur_results.size(), GameState.flags.keys(), GameState.owned.keys()])
	for line in _report_lines():
		print("SMOKE REPORT: " + String(line[0]))
