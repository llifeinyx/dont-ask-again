extends Node
## Debug only (--inputtest): clicks and types through the real input path
## (viewport -> CRT warp -> ND-OS) and prints PASS/FAIL lines.

var shift
var done := false


func _process(_delta: float) -> void:
	if done or shift == null or not is_instance_valid(shift) or shift.elapsed < 3.0:
		return
	done = true
	_run()


## Finds the viewport point that the CRT maps onto a given ND-OS point.
func _screen_point(ui: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var best_d := 1e9
	for step in [2.0, 0.25, 0.03]:
		var lo := Vector2(120, 0) if step == 2.0 else best - Vector2(step, step) * 10.0
		var hi := Vector2(520, 360) if step == 2.0 else best + Vector2(step, step) * 10.0
		var y := lo.y
		while y <= hi.y:
			var x := lo.x
			while x <= hi.x:
				var q: Vector2 = shift.crt.to_ui(Vector2(x, y))
				if q.x >= 0.0 and q.distance_squared_to(ui) < best_d:
					best_d = q.distance_squared_to(ui)
					best = Vector2(x, y)
				x += step
			y += step
	return best


func _click_ui(ui: Vector2) -> void:
	# push_input expects window coordinates; the game viewport is stretched (640x360).
	var p: Vector2 = get_viewport().get_final_transform() * _screen_point(ui)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = p
	ev.global_position = p
	get_viewport().push_input(ev)
	var up := ev.duplicate()
	up.pressed = false
	get_viewport().push_input(up)


func _key(code: Key, unicode := 0, ctrl := false) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.unicode = unicode
	ev.ctrl_pressed = ctrl
	ev.pressed = true
	get_viewport().push_input(ev)


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)


func _run() -> void:
	var os = shift.ndos
	var c: Vector2 = shift.crt.to_ui(Vector2(shift.crt.ACTIVE.x, shift.crt.ACTIVE.y))
	_check("warp center maps to 320,240 (%s)" % c, c.distance_to(Vector2(320, 240)) < 0.5)
	# Launcher: click the Feed tile, then the Seeya tile.
	_click_ui(Vector2(22, 124))
	await get_tree().process_frame
	_check("click launcher -> Feed.di", os.active == 2)
	_click_ui(Vector2(22, 166))
	await get_tree().process_frame
	_check("click launcher -> Seeya.legacy", os.active == 3)
	_key(KEY_1, 0, true)
	await get_tree().process_frame
	_check("ctrl+1 -> Echo.daemon", os.active == 0)
	# Echo: a request should be pending by t=11 (t1). Wait for it, then answer with keys.
	while shift.echo.pending_count() == 0:
		await get_tree().process_frame
	var before: int = GameState.decisions.size()
	_key(KEY_3, 51)
	_key(KEY_ENTER)
	await get_tree().process_frame
	_check("keys 3 + enter -> deny", GameState.decisions.size() == before + 1 and String(GameState.decisions[-1]["decision"]) == "deny")
	# Click an option row with the mouse: find option 1 by drawing pass hits.
	while shift.echo.pending_count() == 0:
		await get_tree().process_frame
	await get_tree().process_frame
	var target = null
	for h in os.hits:
		var cb: Callable = h["cb"]
		if cb.get_method() == "_choose" and cb.get_bound_arguments() == [0]:
			target = (h["rect"] as Rect2).get_center()
	_check("option row has a click area", target != null)
	if target != null:
		before = GameState.decisions.size()
		_click_ui(target)
		await get_tree().process_frame
		_check("click option 1 -> allow", GameState.decisions.size() == before + 1 and String(GameState.decisions[-1]["decision"]) == "allow")
	# KONTUR attention check (t=84): answerable only inside Kontur.watchdog. Stay in
	# another program, check the alert plate is there, click it, then type the code.
	_click_ui(Vector2(22, 166))
	while shift.kontur.active == null:
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var alert = null
	for h in os.hits:
		if (h["cb"] as Callable).get_method() == "_kontur_alert_clicked":
			alert = (h["rect"] as Rect2).get_center()
	_check("kontur check shows an alert plate outside Kontur.watchdog", alert != null and os.active == 3)
	if alert != null:
		_click_ui(alert)
		await get_tree().process_frame
		_check("click the plate -> Kontur.watchdog", os.active == 1)
	for ch in "4471":
		_key(KEY_0 + int(ch), ch.unicode_at(0))
	_key(KEY_ENTER)
	await get_tree().process_frame
	_check("typed code accepted in Kontur.watchdog", shift.kontur.active == null and bool(GameState.kontur_results[-1]["ok"]))
	get_tree().quit()
