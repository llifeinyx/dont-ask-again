extends "res://scripts/ndos/nd_app.gd"
## Kontur.watchdog: the control system. Asks questions that need typed answers in time,
## logs violations, and watches the operator only some of the time (the eye in the panel).
## Attention checks ("code") open a modal over everything that cannot be dismissed.

const WATCH_ON := Vector2(14.0, 30.0)     # seconds KONTUR keeps watching
const WATCH_OFF := Vector2(22.0, 55.0)    # seconds between watching windows
const GRACE := 1.5                         # seconds to turn back once the eye opens

var queue: Array = []
var active = null
var buffer := ""
var lines_log: Array = []
var question_no := 0
var response_times: Array = []
var watching := false
var watch_left := 12.0
var forced_watch := 0.0
var grace := -1.0
var asked_at := 0.0


func badge() -> String:
	return "!" if active != null or queue.size() > 0 else ""


func pending_count() -> int:
	return queue.size() + (1 if active != null else 0)


# --- messages -----------------------------------------------------------------------

func add_message(id: String, data: Dictionary) -> void:
	var text: String = shift.format_text(String(data["text"]))
	var kind := String(data.get("kind", "notice"))
	if kind == "notice":
		log_line("kontur", text, S.DIM)
		shift.notify(text, "kontur")
		return
	var timeout := float(data.get("timeout", 20))
	queue.append({"id": id, "data": data, "text": text, "kind": kind, "time_left": timeout, "timeout": timeout})
	if kind != "code":
		shift.notify("Response required. Open Kontur.watchdog.", "kontur")
	if active == null:
		_activate_next()


func log_line(who: String, text: String, color: Color) -> void:
	lines_log.append({"t": shift.clock_text(), "who": who, "text": text, "c": color})
	if lines_log.size() > 80:
		lines_log.pop_front()


func warning(reason: String) -> void:
	log_line("kontur", "Warning: " + reason, S.ACC)
	shift.notify(reason, "kontur")


func violation(reason: String) -> void:
	GameState.violations += 1
	print("KONTUR violation %d: %s (at %s)" % [GameState.violations, reason, shift.clock_text()])
	log_line("kontur", "Violation %d/%d: %s" % [GameState.violations, GameState.FIRE_LIMIT, reason], S.RED)
	shift.notify("Violation %d/%d. %s" % [GameState.violations, GameState.FIRE_LIMIT, reason], "kontur")
	forced_watch = maxf(forced_watch, 20.0)
	GameState.notify()


func _activate_next() -> void:
	active = queue.pop_front() if queue.size() > 0 else null
	buffer = ""
	if active == null:
		if os.modal == self:
			os.modal = null
		return
	question_no += 1
	asked_at = float(shift.elapsed)
	if String(active["kind"]) == "code":
		os.modal = self
		Sfx.play("alert", -2.0)
	else:
		os.modal = null


func tick(delta: float) -> void:
	_tick_watch(delta)
	if active == null:
		return
	active["time_left"] = float(active["time_left"]) - delta
	if float(active["time_left"]) <= 0.0:
		_finish(false, "timeout", "")


func _submit() -> void:
	if active == null:
		return
	var answer := buffer.strip_edges()
	var d: Dictionary = active["data"]
	var ok := false
	match String(active["kind"]):
		"code":
			ok = answer == String(d["code"])
		"number":
			ok = answer.is_valid_int() and int(answer) >= 1 and int(answer) <= 10
		"type":
			ok = _norm(answer) == _norm(String(d["expect"]))
		"free":
			ok = answer.length() >= 2
	if answer != "":
		log_line("you", "> " + answer, S.FG)
	if ok:
		_finish(true, "answered", answer)
	else:
		Sfx.play("error")
		log_line("kontur", "Input rejected.", S.RED_D)
		buffer = ""


func _finish(ok: bool, how: String, answer: String) -> void:
	GameState.kontur_results.append({"id": active["id"], "ok": ok, "how": how, "answer": answer, "text": active["text"]})
	var secs := float(shift.elapsed) - asked_at
	var kind := String(active["kind"])
	active = null
	if ok:
		response_times.append(secs)
		Sfx.play("click")
		var extra := ""
		if kind == "number":
			extra = " The previous operator of room 4-C gave the same answer."
		log_line("kontur", "Accepted. Response time %.1f s.%s" % [secs, extra], S.DIM)
	else:
		violation("No response to a control request.")
	_activate_next()


func _norm(s: String) -> String:
	return s.to_lower().strip_edges().trim_suffix(".")


# --- watching -----------------------------------------------------------------------

func _tick_watch(delta: float) -> void:
	forced_watch = maxf(0.0, forced_watch - delta)
	var want := watching
	watch_left -= delta
	if watch_left <= 0.0:
		want = not watching
		watch_left = randf_range(WATCH_ON.x, WATCH_ON.y) if want else randf_range(WATCH_OFF.x, WATCH_OFF.y)
	if active != null or forced_watch > 0.0:
		want = true
	if want != watching:
		_set_watching(want)
	if grace >= 0.0:
		grace -= delta
		if grace < 0.0 and watching and shift.facing_vent:
			_seen_turn()


func _set_watching(on: bool) -> void:
	watching = on
	if on:
		Sfx.play("blip", -18.0)
		if shift.facing_vent:
			grace = GRACE
	else:
		grace = -1.0


func stop_watching() -> void:
	watching = false
	grace = -1.0


## The player turned to the vent. Only counts if KONTUR is watching right now.
func on_turned_away() -> void:
	GameState.turns += 1
	if watching:
		_seen_turn()


func _seen_turn() -> void:
	grace = -1.0
	GameState.turns_seen += 1
	if GameState.turns_seen == 1:
		warning("Operator turned away from the workstation. This is a warning.")
	else:
		violation("Operator turned away from the workstation (%d)." % GameState.turns_seen)


# --- input --------------------------------------------------------------------------

func key(ev: InputEventKey) -> bool:
	if active == null or String(active["kind"]) == "code":
		return false
	return _type(ev, 64)


func modal_key(ev: InputEventKey) -> void:
	if active != null:
		_type(ev, 8)


func _type(ev: InputEventKey, max_len: int) -> bool:
	if is_enter(ev):
		_submit()
		return true
	if ev.keycode == KEY_BACKSPACE:
		buffer = buffer.substr(0, maxi(0, buffer.length() - 1))
		return true
	var ch := char_of(ev)
	if ch != "" and buffer.length() < max_len:
		buffer += ch
		Sfx.play("click", -22.0)
		return true
	return false


# --- drawing ------------------------------------------------------------------------

func draw() -> void:
	os.segs(0, [["kontur.watchdog 4.0", S.DIM], ["  ·  operator %s  ·  room 4-C" % GameState.OPERATOR_NO, S.FAINT]])
	if watching:
		os.rput(0, "OBSERVING", S.RED, true)
		os.tex(os.EYE_OPEN, Rect2(os.cx(os.cols - 9) - 15, os.ry(0) - 4, 13, 8), S.RED)
	else:
		os.rput(0, "idle", S.FAINT)

	var avg := 0.0
	for t in response_times:
		avg += float(t)
	avg = avg / response_times.size() if response_times.size() > 0 else 0.0
	var vcol := S.RED if GameState.violations >= GameState.FIRE_LIMIT - 2 else S.ACC
	var secs := int(shift.elapsed)
	var stats := [
		["status", "away" if shift.facing_vent else "present", S.FG],
		["violations", "%d / %d" % [GameState.violations, GameState.FIRE_LIMIT], vcol],
		["response", ("%.1f s avg" % avg) if response_times.size() > 0 else "-", S.FG],
		["turned away", "%d  (logged)" % GameState.turns_seen, S.FG],
		["shift time", "%02d:%02d:%02d" % [secs / 3600, (secs / 60) % 60, secs % 60], S.FG],
		["next check", "irregular", S.DIM],
	]
	for i in stats.size():
		var row := 2.0 + floorf(i / 2.0)
		var col := 0.0 if i % 2 == 0 else 40.0
		os.put(row, col, stats[i][0], S.DIM)
		os.put(row, col + 13.0, stats[i][1], stats[i][2])
	os.hline(5.5)

	var q := _question_rows()
	var log_rows: Array = []
	for e in lines_log:
		var who := String(e["who"])
		var wc := S.DIM if who == "you" else (S.RED if e["c"] == S.RED else S.RED_D)
		log_rows.append_array(os.wrap_rows([[String(e["t"]) + "  ", S.FAINT], [who.rpad(8), wc]], String(e["text"]), e["c"]))
	var first := 7.0
	var avail := int(os.content_rows() - first)
	var need := q.size() + (3 if q.size() > 0 else 2)
	var shown := log_rows.slice(maxi(0, log_rows.size() - maxi(0, avail - need)))
	var r := first
	for row in shown:
		os.draw_row(r, row)
		r += 1.0
	r += 1.0
	if active == null:
		os.segs(r, [["no open questions. remain at your workstation.", S.FAINT]])
	elif String(active["kind"]) == "code":
		os.segs(r, [["attention check in progress", S.RED]])
	else:
		os.segs(r, [[asked_clock() + "  ", S.FAINT], ["kontur  ", S.RED, true], ["Question %d" % question_no, S.BRIGHT, true]])
		var top := r + 1.0
		os.frame(top, top + q.size() + 1, 2, os.cols, S.RED_D)
		for i in q.size():
			os.draw_row(top + 1 + i, q[i])
	var hint := "type answer · enter send · silence = violation" if active != null else "nothing to answer"
	os.footer(hint, "%d open" % pending_count(), "", false)


func asked_clock() -> String:
	return shift.clock_at(asked_at)


func _question_rows() -> Array:
	if active == null or String(active["kind"]) == "code":
		return []
	var rows: Array = []
	rows.append_array(os.wrap_rows([], String(active["text"]), S.BRIGHT, false, 4.0))
	rows.append({})
	var hint: String = {"number": "a number from 1 to 10", "type": "type the text exactly",
		"free": "describe it in your own words"}.get(String(active["kind"]), "")
	rows.append({"parts": [[hint, S.DIM]], "col": 4.0})
	rows.append({})
	var blink := "_" if fmod(os.time, 1.0) < 0.6 else " "
	rows.append({"parts": [["> ", S.DIM], [buffer + blink, S.FG]], "col": 4.0})
	rows.append({})
	var left := maxf(0.0, float(active["time_left"]))
	var frac := left / float(active["timeout"])
	rows.append({"parts": [["no answer in %ds = violation" % int(ceil(left)), S.DIM]], "col": 4.0, "bar": [34, 30, frac, S.RED_D]})
	return rows


## The attention check, drawn by the shell above everything else.
func draw_modal() -> void:
	if active == null:
		return
	var w := 60.0
	var h := 12.0
	var bx0: float = (S.X0 + S.X1) / 2.0 - w * os.cw / 2.0
	var by0 := 168.0
	var bw: float = w * os.cw
	var bh := h * S.LH
	os.rect(Rect2(bx0 - 3, by0 - 3, bw + 6, bh + 6), S.TBG)
	os.rect(Rect2(bx0, by0, bw, bh), S.TBG)
	os.rect(Rect2(bx0, by0, bw, bh), S.RED, false, 1.0)
	os.rect(Rect2(bx0 + 2.5, by0 + 2.5, bw - 5, bh - 5), S.RED_D, false, 0.6)
	os.rect(Rect2(bx0 + 2.5, by0 + 2.5, bw - 5, S.LH + 1.5), S.RED)
	var line_y := func(r: float) -> float: return by0 + 8.0 + r * S.LH
	var tx: float = bx0 + 1.5 * os.cw
	var left := maxf(0.0, float(active["time_left"]))
	os.text(tx, line_y.call(0), "KONTUR  ·  ATTENTION CHECK", S.TBG, S.MONO_B)
	os.text(bx0 + bw - 1.5 * os.cw, line_y.call(0), "%ds" % int(ceil(left)), S.TBG, S.MONO_B, S.MONO_PX, 2)
	os.text(tx, line_y.call(2), "Operator %s, confirm your presence." % GameState.OPERATOR_NO, S.BRIGHT)
	os.text(tx, line_y.call(3), "Enter code ", S.BRIGHT)
	os.text(tx + 11 * os.cw, line_y.call(3), String(active["data"]["code"]), S.RED, S.MONO_B)
	os.text(tx, line_y.call(5), "code  [", S.DIM)
	os.text(tx + 7 * os.cw, line_y.call(5), buffer, S.BRIGHT, S.MONO_B)
	if fmod(os.time, 1.0) < 0.6:
		os.rect(Rect2(tx + (7 + buffer.length()) * os.cw, line_y.call(5) - 5, os.cw, 10), S.FG)
	os.text(tx + 13 * os.cw, line_y.call(5), "]", S.DIM)
	var by: float = line_y.call(7)
	var bar_w: float = bw - 3.0 * os.cw
	os.rect(Rect2(tx, by - 2.5, bar_w, 5), S.BAR_BG)
	os.rect(Rect2(tx, by - 2.5, bar_w * left / float(active["timeout"]), 5), S.RED)
	os.text(tx, line_y.call(9), "this check cannot be dismissed", S.DIM)
	os.text(tx, line_y.call(10), "no answer = violation %d/%d" % [GameState.violations + 1, GameState.FIRE_LIMIT], S.RED_D)


# --- smoke test ---------------------------------------------------------------------

func autoplay_answer() -> void:
	if active == null:
		return
	var d: Dictionary = active["data"]
	match String(active["kind"]):
		"code":
			buffer = String(d["code"])
		"number":
			buffer = str(randi_range(1, 10))
		"type":
			buffer = String(d["expect"])
		_:
			buffer = "a scraping sound in the vent"
	if randf() < 0.1:
		buffer = "wrong"
	_submit()
