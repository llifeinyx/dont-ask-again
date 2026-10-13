extends Control
## One work shift: the closet photo with ND-OS on the CRT, the vent behind you,
## the scripted timeline of the day, power failures and the reboot lever.

signal finished(fired: bool)

const Ui := preload("res://scripts/ui.gd")
const NdOs := preload("res://scripts/ndos/ndos.gd")
const NdStyle := preload("res://scripts/ndos/nd_style.gd")
const CrtScreen := preload("res://scripts/crt_screen.gd")
const RoomProps := preload("res://scripts/room_props.gd")
const VentDraw := preload("res://scripts/vent_draw.gd")
const Reflection := preload("res://scripts/reflection.gd")
const Onboarding := preload("res://scripts/onboarding.gd")
const HintMarker := preload("res://scripts/hint_marker.gd")
const ROOM_TEX := preload("res://art/room_front.jpg")
const SPILL_TEX := preload("res://art/screen_spill.png")

const SHIFT_START_MIN := 9 * 60
const SHIFT_MINUTES := 8 * 60
const LEVER_HOLD_SECONDS := 3.0
const OUTAGE_AUTO_RESTORE := 50.0
const SPILL_COLOR := Color(0.55, 0.5, 0.42)

var day_file := "res://data/day1.json"
var content: Dictionary = {}
var elapsed := 0.0
var shift_length := 900.0
var timeline: Array = []
var next_event := 0
var power_on := true
var outage_time := 0.0
var facing_vent := false
var turning := false
var ended := false
var lever_holding := false
var lever_progress := 0.0
var autoplay := false
var autoplay_tabs := true
var autoplay_console_rate := 0.6
var autoplay_outage_delay := 0.0
var _auto_acc := 0.0

var front: Control
var vent: Control
var props
var vent_draw
var reflection
var screen_vp: SubViewport
var ndos
var crt
var spill: TextureRect
var dark_front: ColorRect
var dark_vent: ColorRect
var led: ColorRect
var hold_bar: ProgressBar
var note_popup: Label
var fader: ColorRect
var hint_marker
var turn_button: Control
var onboarding
var echo
var kontur
var feed
var seeya


func _ready() -> void:
	Ui.full_rect(self)
	content = JSON.parse_string(FileAccess.get_file_as_string(day_file))
	shift_length = float(content["shift_length"])
	GameState.labeling_quota = int(content["labeling_quota"])
	timeline = content["timeline"]
	timeline.sort_custom(func(a, b): return float(a["t"]) < float(b["t"]))
	_build_front()
	_build_vent()
	kontur.watch_left = float(content.get("kontur_first_watch", kontur.watch_left))

	hint_marker = Ui.full_rect(HintMarker.new())
	hint_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_marker.visible = false
	add_child(hint_marker)
	onboarding = Onboarding.new()
	onboarding.setup(self, content.get("onboarding", []))

	fader = ColorRect.new()
	fader.color = Color.BLACK
	fader.modulate.a = 0.0
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.full_rect(fader)
	add_child(fader)

	GameState.changed.connect(_on_state_changed)
	Sfx.facing_vent = false
	Sfx.set_hum(true, float(content.get("hum_fade_in", 0.0)))


# --- building the views --------------------------------------------------------

func _build_front() -> void:
	front = Ui.full_rect(Control.new())
	add_child(front)

	var bg := Ui.full_rect(TextureRect.new())
	bg.texture = ROOM_TEX
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(bg)

	# Light from the screen on the bezel, keyboard and mug.
	spill = Ui.full_rect(TextureRect.new())
	spill.texture = SPILL_TEX
	spill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spill.stretch_mode = TextureRect.STRETCH_SCALE
	spill.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spill.material = add
	front.add_child(spill)

	# ND-OS renders into its own supersampled viewport; the CRT shows it on the glass.
	screen_vp = SubViewport.new()
	screen_vp.size = Vector2i(int(NdStyle.W * NdStyle.K), int(NdStyle.H * NdStyle.K))
	screen_vp.disable_3d = true
	screen_vp.transparent_bg = false
	screen_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	screen_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(screen_vp)
	ndos = NdOs.new()
	ndos.setup(self, content)
	screen_vp.add_child(ndos)
	echo = ndos.echo
	kontur = ndos.kontur
	feed = ndos.feed
	seeya = ndos.seeya

	crt = CrtScreen.new()
	front.add_child(crt)
	crt.setup(screen_vp.get_texture(), ROOM_TEX, ndos)

	props = Ui.full_rect(RoomProps.new())
	props.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(props)

	dark_front = Ui.full_rect(ColorRect.new())
	dark_front.color = Color(0, 0, 0, 0)
	dark_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(dark_front)

	reflection = Ui.full_rect(Reflection.new())
	reflection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(reflection)

	turn_button = Ui.place(Ui.button("[ turn around ]", _turn_to_vent, 8), Rect2(276, 339, 88, 14))
	turn_button.modulate.a = 0.55
	front.add_child(turn_button)


func _build_vent() -> void:
	vent = Ui.full_rect(Control.new())
	vent.visible = false
	add_child(vent)
	vent_draw = Ui.full_rect(VentDraw.new())
	vent.add_child(vent_draw)
	props.vent_state = vent_draw.state

	var lever_area := Ui.place(Control.new(), VentDraw.LEVER_RECT)
	lever_area.mouse_filter = Control.MOUSE_FILTER_STOP
	lever_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	lever_area.gui_input.connect(_on_lever_input)
	vent.add_child(lever_area)

	var note_area := Ui.place(Control.new(), VentDraw.NOTE_RECT.grow(4))
	note_area.mouse_filter = Control.MOUSE_FILTER_STOP
	note_area.gui_input.connect(_on_note_input)
	vent.add_child(note_area)

	dark_vent = Ui.full_rect(ColorRect.new())
	dark_vent.color = Color(0, 0, 0, 0.3)
	dark_vent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vent.add_child(dark_vent)

	led = Ui.place(ColorRect.new(), Rect2(541, 158, 3, 3))
	led.color = Color(0.1, 0.4, 0.15)
	led.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vent.add_child(led)

	hold_bar = Ui.place(Ui.bar(), Rect2(486, 276, 70, 3))
	hold_bar.value = 0.0
	hold_bar.visible = false
	vent.add_child(hold_bar)

	note_popup = Ui.place(Ui.wrap_label("", 300, 10, Color(0.85, 0.82, 0.72)), Rect2(170, 240, 300, 40))
	note_popup.visible = false
	vent.add_child(note_popup)

	var back := Ui.place(Ui.button("[ turn back ]", _turn_back, 8), Rect2(280, 340, 80, 14))
	back.modulate.a = 0.7
	vent.add_child(back)


# --- main loop -----------------------------------------------------------------

func _process(delta: float) -> void:
	if ended:
		return
	elapsed += delta
	while next_event < timeline.size() and float(timeline[next_event]["t"]) <= elapsed:
		_run_event(timeline[next_event])
		next_event += 1
		if ended:
			return

	ndos.tick(delta)
	onboarding.tick(delta)
	if not power_on:
		outage_time += delta
		led.visible = fmod(outage_time, 1.0) < 0.5
		if outage_time > OUTAGE_AUTO_RESTORE:
			_restore_power(true)
	var fl := 0.975 + 0.025 * sin(elapsed * 7.3) * sin(elapsed * 2.1 + 1.0)
	crt.flicker = fl
	spill.modulate = SPILL_COLOR * (0.16 * fl if power_on else 0.0)
	spill.modulate.a = 1.0
	_update_lever(delta)
	if autoplay:
		_autoplay(delta)
	_check_end()


func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or ended or turning or facing_vent or not power_on:
		return
	if ndos.handle_key(k):
		get_viewport().set_input_as_handled()


func _run_event(e: Dictionary) -> void:
	match String(e["type"]):
		"echo":
			echo.echo(format_text(String(e["text"])))
		"request":
			var id := String(e["id"])
			echo.add_request(id, content["requests"][id])
		"kontur":
			var kid := String(e["id"])
			kontur.add_message(kid, content["kontur"][kid])
		"mail":
			seeya.add_mail(String(e["id"]))
		"labeling_unlock":
			feed.unlock()
		"name_slip":
			echo.name_slip(String(e["wrong"]), String(e["rest"]), String(e["fix"]))
		"vent_sound":
			Sfx.play_vent(String(e["sound"]), float(e.get("volume", -8.0)))
		"vent_state":
			vent_draw.state[String(e["key"])] = e["value"]
			vent_draw.queue_redraw()
			props.queue_redraw()
		"outage":
			_start_outage()
		_:
			push_warning("Unknown event type: %s" % e["type"])


func _check_end() -> void:
	if ended or not power_on:
		return
	var done: bool = next_event >= timeline.size() and echo.pending_count() == 0 and kontur.pending_count() == 0
	if (elapsed >= shift_length and done) or elapsed >= shift_length + 120.0:
		_end_shift(false)


func _on_state_changed() -> void:
	if not ended and GameState.violations >= GameState.FIRE_LIMIT:
		_end_shift(true)


func _end_shift(fired: bool) -> void:
	ended = true
	lever_holding = false
	hint_marker.hide_hint()
	Sfx.set_hum(false)
	Sfx.facing_vent = false
	finished.emit(fired)


# --- helpers used by the programs -------------------------------------------------

func clock_at(t: float) -> String:
	var minutes := SHIFT_START_MIN + int(clampf(t, 0.0, shift_length) / shift_length * SHIFT_MINUTES)
	return "%02d:%02d" % [int(minutes / 60.0), minutes % 60]


func clock_text() -> String:
	return clock_at(elapsed)


## Replaces {name}, {no} and {clock:SECONDS} placeholders.
func format_text(text: String) -> String:
	var out := GameState.fmt(text)
	var re := RegEx.new()
	re.compile("\\{clock:(\\d+)\\}")
	for m in re.search_all(out):
		out = out.replace(m.get_string(0), clock_at(float(m.get_string(1))))
	return out


## A notification inside ND-OS. "kontur" = loud, "auto" = quiet chime, "mail" = soft blip.
func notify(text: String, kind: String) -> void:
	if not power_on or ended:
		return
	ndos.toast(text, kind)
	match kind:
		"kontur":
			Sfx.play("alert", -2.0)
		"mail":
			Sfx.play("blip", -9.0)
		_:
			Sfx.play("chime", -4.0)


func quality_issue(reason: String) -> void:
	if GameState.flags.has("quality_warned"):
		kontur.violation(reason)
	else:
		GameState.flags["quality_warned"] = true
		kontur.warning(reason + " This is a warning.")


func on_purchase(_id: String) -> void:
	props.queue_redraw()
	_apply_darkness()


func select_app(i: int) -> void:
	ndos.open_app(i)


## Room-view rects the onboarding can point at (outside the monitor).
func room_target_rect(target: String) -> Rect2:
	match target:
		"lever":
			return VentDraw.LEVER_RECT
		_:
			return turn_button.get_rect()


# --- turning around ----------------------------------------------------------------

func _turn_to_vent() -> void:
	if turning or facing_vent or ended:
		return
	turning = true
	Sfx.play("whoosh", -8.0)
	var tw := create_tween()
	tw.tween_property(fader, "modulate:a", 1.0, 0.3)
	tw.tween_callback(_show_vent)
	tw.tween_property(fader, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_turn_done)


func _turn_back() -> void:
	if turning or not facing_vent:
		return
	turning = true
	lever_holding = false
	Sfx.play("whoosh", -8.0)
	var tw := create_tween()
	tw.tween_property(fader, "modulate:a", 1.0, 0.3)
	tw.tween_callback(_show_front)
	tw.tween_property(fader, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_turn_done)


func _show_vent() -> void:
	front.visible = false
	vent.visible = true
	facing_vent = true
	Sfx.facing_vent = true
	note_popup.visible = false
	if power_on:
		kontur.on_turned_away()


func _show_front() -> void:
	vent.visible = false
	front.visible = true
	facing_vent = false
	Sfx.facing_vent = false


func _turn_done() -> void:
	turning = false


# --- power failure and the lever --------------------------------------------------

func _start_outage() -> void:
	if not power_on:
		return
	power_on = false
	outage_time = 0.0
	lever_progress = 0.0
	ndos.clear_toasts()
	ndos.power_on = false
	kontur.stop_watching()
	crt.power = 0.0
	Sfx.play("power_down")
	Sfx.set_hum(false)
	reflection.eyes = true
	reflection.queue_redraw()
	get_tree().create_timer(2.6).timeout.connect(_hide_reflection_eyes)
	props.power_on = false
	props.queue_redraw()
	led.color = Ui.RED
	_apply_darkness()


func _hide_reflection_eyes() -> void:
	reflection.eyes = false
	reflection.queue_redraw()


func _restore_power(automatic: bool) -> void:
	power_on = true
	lever_holding = false
	lever_progress = 0.0
	hold_bar.visible = false
	Sfx.play("power_up")
	Sfx.set_hum(true)
	ndos.power_on = true
	crt.power = 1.0
	props.power_on = true
	props.queue_redraw()
	led.visible = true
	led.color = Color(0.1, 0.4, 0.15)
	_apply_darkness()
	vent_draw.lever_progress = 0.0
	vent_draw.queue_redraw()
	var n: int = echo.approve_all_pending("reboot")
	if n > 0:
		notify("Approved during reboot: %d request(s)." % n, "auto")
	if automatic:
		kontur.violation("Power restored automatically. Operator did not respond.")
	else:
		kontur.log_line("kontur", "Power restored. Reboot completed by operator.", kontur.S.DIM)


func _apply_darkness() -> void:
	if power_on:
		dark_front.color.a = 0.0
		dark_vent.color.a = 0.3
	else:
		dark_front.color.a = 0.86
		dark_vent.color.a = 0.6 if GameState.owned.has("flashlight") else 0.9


func _on_lever_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		if power_on:
			Sfx.play("error", -6.0)
			return
		lever_holding = true
		Sfx.play("lever")
	else:
		lever_holding = false


func _update_lever(delta: float) -> void:
	if power_on:
		return
	if lever_holding and facing_vent:
		lever_progress += delta / LEVER_HOLD_SECONDS
		if lever_progress > 0.8 and not GameState.flags.has("lever_scare"):
			GameState.flags["lever_scare"] = true
			Sfx.play_vent("bang", 2.0)
			_shake(vent)
		if lever_progress >= 1.0:
			_restore_power(false)
			return
	else:
		lever_progress = maxf(0.0, lever_progress - delta * 0.6)
	hold_bar.visible = lever_progress > 0.0
	hold_bar.value = lever_progress
	vent_draw.lever_progress = lever_progress
	vent_draw.queue_redraw()


func _shake(node: Control) -> void:
	var tw := create_tween()
	for i in 6:
		tw.tween_property(node, "position", Vector2(randf_range(-4, 4), randf_range(-3, 3)), 0.03)
	tw.tween_property(node, "position", Vector2.ZERO, 0.05)


func _on_note_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb == null or not mb.pressed or not vent_draw.state.get("note", false):
		return
	GameState.flags["note_read"] = true
	note_popup.text = String(content.get("note_text", "..."))
	note_popup.visible = true
	Sfx.play("click", -8.0)
	get_tree().create_timer(6.0).timeout.connect(_hide_note)


func _hide_note() -> void:
	if is_instance_valid(note_popup):
		note_popup.visible = false


# --- smoke test autoplay -----------------------------------------------------------

func _autoplay(delta: float) -> void:
	_auto_acc += delta
	if turning:
		return
	if not power_on:
		if outage_time < autoplay_outage_delay:
			return
		if not facing_vent:
			_turn_to_vent()
		else:
			lever_holding = true
		return
	if facing_vent:
		_turn_back()
		return
	if _auto_acc < 1.5:
		return
	_auto_acc = 0.0
	if kontur.active != null:
		# A check cannot be answered from another program: notice it, switch, then type.
		if elapsed - kontur.asked_at < 2.0:
			return
		if ndos.active != 1:
			ndos.open_app(1)
		elif elapsed - kontur.asked_at > 3.5:
			kontur.autoplay_answer()
		return
	if echo.pending_count() > 0 and randf() < autoplay_console_rate:
		echo.autoplay_decide()
	if feed.unlocked and randf() < autoplay_console_rate * 0.5:
		feed.autoplay_answer()
	if randf() < 0.05:
		feed.autoplay_buy()
	if randf() < 0.05:
		seeya.autoplay_reply()
	if autoplay_tabs and randf() < 0.1:
		ndos.open_app(randi() % 4)
	if randf() < 0.004:
		_turn_to_vent()
