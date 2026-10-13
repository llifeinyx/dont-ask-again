extends "res://scripts/ndos/nd_app.gd"
## Echo.daemon: a plain terminal session with a CLI agent that asks for permission.
## Requests arrive silently. 1. Yes / 2. Yes, and don't ask again / 3. No.
## A request that runs out of time is approved. "Don't ask again" approves every later
## request that starts with the same verb, without asking (and without a sound).

var pending: Array = []
var selected = null
var details_open := false
var choice := 0
var typed := ""
var trusted: Dictionary = {}
var lines_log: Array = []
var req_no := 411


func badge() -> String:
	return str(pending.size()) if pending.size() > 0 else ""


func pending_count() -> int:
	return pending.size()


# --- events -------------------------------------------------------------------------

func add_request(id: String, data: Dictionary) -> void:
	var title := GameState.fmt(String(data["title"]))
	var timeout := float(data.get("timeout", 0))
	req_no += 1
	var r := {
		"id": id, "data": data, "title": title, "verb": _verb(title), "no": req_no,
		"timeout": timeout, "time_left": timeout, "arrived": float(shift.elapsed),
		"opened": false, "read_time": 0.0,
	}
	pending.append(r)
	if trusted.has(r["verb"]):
		_resolve(r, "allow", "trusted")
		return
	if selected == null:
		_select(r)


func echo(text: String) -> Dictionary:
	return _add({"b": "● ", "bc": S.FG, "t": text, "c": S.FG})


## Echo calls the player by someone else's name, then quietly corrects itself.
func name_slip(wrong: String, rest: String, fix: String) -> void:
	var e := echo(wrong + rest)
	shift.get_tree().create_timer(6.0).timeout.connect(func():
		e["t"] = fix + GameState.player_name + rest
		e["s"] = "  (edited)")


func tick(delta: float) -> void:
	for r in pending.duplicate():
		if float(r["timeout"]) > 0.0:
			r["time_left"] = float(r["time_left"]) - delta
			if float(r["time_left"]) <= 0.0:
				_resolve(r, "allow", "timeout")
	if selected != null and details_open:
		selected["read_time"] = float(selected["read_time"]) + delta


## Auto-approve everything still pending (power returning after a reboot).
func approve_all_pending(how: String) -> int:
	var n := pending.size()
	for r in pending.duplicate():
		_resolve(r, "allow", how)
	return n


# --- decisions ----------------------------------------------------------------------

func _verb(title: String) -> String:
	var w := title.split(" ", false)
	return w[0].to_lower().strip_edges() if w.size() > 0 else "?"


func _add(e: Dictionary) -> Dictionary:
	lines_log.append(e)
	if lines_log.size() > 120:
		lines_log.pop_front()
	return e


func _select(r) -> void:
	selected = r
	details_open = false
	choice = 0
	typed = ""


func _toggle_details() -> void:
	if selected == null:
		return
	details_open = not details_open
	if details_open:
		selected["opened"] = true
	Sfx.play("click", -14.0)


func _choose(i: int) -> void:
	choice = i
	typed = str(i + 1)
	_confirm()


func _confirm() -> void:
	if selected == null:
		return
	Sfx.play("click")
	var r: Dictionary = selected
	match choice:
		0:
			_resolve(r, "allow", "player")
		1:
			trusted[r["verb"]] = true
			_resolve(r, "allow", "player", "allowed. won't ask again for \"%s\" requests" % r["verb"])
		_:
			_resolve(r, "deny", "player")


func _resolve(r: Dictionary, decision: String, how: String, note := "") -> void:
	pending.erase(r)
	var d: Dictionary = r["data"]
	var title: String = r["title"]
	GameState.decisions.append({
		"id": r["id"], "title": title, "decision": decision, "how": how,
		"opened": r["opened"], "read_time": r["read_time"],
		"seconds": float(shift.elapsed) - float(r["arrived"]),
		"risk": bool(d.get("risk", false)),
	})
	var flag_key := "flag_on_allow" if decision == "allow" else "flag_on_deny"
	if d.has(flag_key):
		GameState.flags[String(d[flag_key])] = true

	_add({"b": "● ", "bc": S.ACC if decision == "allow" else S.DIM, "t": title, "c": S.FG, "bold": true})
	var result := ""
	var rc := S.DIM
	match how:
		"player":
			result = note if note != "" else ("allowed" if decision == "allow" else "denied")
		"timeout":
			result = "auto-approved: no answer in time"
			rc = S.ACC
			shift.notify("Approved (timed out): " + title, "auto")
		"trusted":
			result = "approved without asking: you said don't ask again for \"%s\"" % r["verb"]
			rc = S.ACC
		_:
			result = "approved during reboot"
			rc = S.ACC
	_add({"b": "  └ ", "bc": S.FAINT, "t": result, "c": rc})

	var echo_key := "echo_on_allow" if decision == "allow" else "echo_on_deny"
	if d.has(echo_key):
		echo(GameState.fmt(String(d[echo_key])))

	if is_same(selected, r):
		selected = null
		if pending.size() > 0:
			_select(pending[0])
		else:
			details_open = false
			choice = 0
			typed = ""
	GameState.notify()


func _next_request() -> void:
	if pending.size() < 2:
		return
	var i := pending.find(selected)
	_select(pending[(i + 1) % pending.size()])
	Sfx.play("click", -14.0)


# --- input --------------------------------------------------------------------------

func key(ev: InputEventKey) -> bool:
	var dg := digit_of(ev)
	if dg >= 1 and dg <= 3:
		if selected != null:
			choice = dg - 1
			typed = str(dg)
		return true
	match ev.keycode:
		KEY_UP:
			choice = (choice + 2) % 3
			typed = str(choice + 1)
		KEY_DOWN:
			choice = (choice + 1) % 3
			typed = str(choice + 1)
		KEY_D:
			_toggle_details()
		KEY_TAB:
			_next_request()
		KEY_BACKSPACE:
			typed = ""
		_:
			if is_enter(ev):
				_confirm()
			else:
				return false
	return true


# --- drawing ------------------------------------------------------------------------

func draw() -> void:
	os.segs(0, [["echo.daemon 7.2.0", S.DIM], ["  ·  session %s  ·  " % GameState.OPERATOR_NO, S.FAINT], ["/srv/nd/sector4", S.DIM]])
	var transcript := _transcript_rows()
	var box := _box_rows() if selected != null else []
	var queue := _queue_row()
	var avail: int = os.content_rows() - 2
	var need := (box.size() + 3) if box.size() > 0 else 2
	if not queue.is_empty():
		need += 2
	var keep := maxi(0, avail - need)
	var shown := transcript.slice(maxi(0, transcript.size() - keep))
	var r := 2.0
	for row in shown:
		os.draw_row(r, row)
		r += 1.0
	if box.size() > 0:
		if shown.size() > 0:
			r += 1.0
		var top := r
		var urgent := float(selected["timeout"]) > 0.0 and float(selected["time_left"]) / float(selected["timeout"]) < 0.3
		os.frame(top, top + box.size() + 1, 0, os.cols, S.RED_D if urgent else S.FAINT)
		for i in box.size():
			os.draw_row(top + 1 + i, box[i])
		r = top + box.size() + 3
	else:
		if shown.size() > 0:
			r += 1.0
		os.segs(r, [["● ", S.FAINT], ["no pending requests", S.FAINT]])
		r += 2.0
	if not queue.is_empty():
		os.draw_row(r, queue)
	os.footer("1-3 choose · d details · enter confirm · tab next · silence = yes",
		"%d pending" % pending.size(), typed, true)


func _transcript_rows() -> Array:
	var out: Array = []
	for e in lines_log:
		var suffix: Array = [[String(e["s"]), S.FAINT]] if e.has("s") else []
		out.append_array(os.wrap_rows([[e["b"], e["bc"]]], String(e["t"]), e["c"], bool(e.get("bold", false)), 0.0, suffix))
	return out


func _box_rows() -> Array:
	var r: Dictionary = selected
	var rows: Array = []
	rows.append({"parts": [["Permission request", S.FG, true], ["  #%04d" % int(r["no"]), S.FAINT]], "col": 2.0})
	rows.append_array(os.wrap_rows([], String(r["title"]), S.BRIGHT, false, 2.0))
	rows.append({})
	var details := GameState.fmt(String(r["data"].get("details", "(no details)")))
	var dlines := details.split("\n")
	if details_open:
		var n := 0
		for ln in dlines:
			var c := S.DIM
			var bg = null
			if ln.begins_with("- "):
				c = S.DEL_FG
				bg = S.DEL_BG
			elif ln.begins_with("+ "):
				c = S.ADD_FG
				bg = S.ADD_BG
			for w in S.wrap(ln, os.cols - 6):
				if n >= 14:
					break
				var spec := {"parts": [[w, c]], "col": 2.0}
				if bg != null:
					spec["bg"] = bg
				rows.append(spec)
				n += 1
		rows.append({"parts": [["[d] hide details", S.ACC]], "col": 2.0, "hit": _toggle_details})
	else:
		rows.append({"parts": [["%d lines of details  " % dlines.size(), S.DIM], ["[d] show details", S.ACC]], "col": 2.0, "hit": _toggle_details})
	rows.append({})
	var labels := ["Yes", "Yes, and don't ask again for \"%s\" requests" % r["verb"], "No"]
	for i in 3:
		var sel := i == choice
		var t := ("> " if sel else "  ") + "%d. %s" % [i + 1, labels[i]]
		rows.append({"parts": [[t, S.ACC if sel else S.FG, sel]], "col": 2.0, "hit": _choose.bind(i)})
	rows.append({})
	if float(r["timeout"]) > 0.0:
		var left := maxf(0.0, float(r["time_left"]))
		var frac := left / float(r["timeout"])
		var c2 := S.RED if frac < 0.3 else S.DIM
		rows.append({"parts": [["auto-approve in %ds" % int(ceil(left)), c2]], "col": 2.0, "bar": [24, 30, frac, S.RED_D if frac < 0.3 else S.FAINT]})
	else:
		rows.append({"parts": [["no time limit", S.FAINT]], "col": 2.0})
	return rows


func _queue_row() -> Dictionary:
	var others: Array = []
	for r in pending:
		if not is_same(r, selected):
			others.append(r)
	if others.is_empty():
		return {}
	var parts: Array = [["  %d more waiting: " % others.size(), S.FAINT]]
	var hits: Array = []
	var col: int = String(parts[0][0]).length()
	for i in others.size():
		var r: Dictionary = others[i]
		var t := S.clip(String(r["title"]).trim_suffix("?"), 30)
		var tl := ""
		var c := S.DIM
		if float(r["timeout"]) > 0.0:
			var left := int(ceil(maxf(0.0, float(r["time_left"]))))
			tl = " %ds" % left
			if left <= 10:
				c = S.DEL_FG
		var seg := t + tl
		if col + seg.length() > os.cols - 4:
			parts.append([" ...", S.FAINT])
			break
		if i > 0:
			parts.append([" · ", S.FAINT])
			col += 3
		parts.append([seg, c])
		hits.append([col, col + seg.length(), _select_and_click.bind(r)])
		col += seg.length()
	return {"parts": parts, "hits": hits}


func _select_and_click(r: Dictionary) -> void:
	if pending.has(r):
		_select(r)
		Sfx.play("click", -14.0)


# --- smoke test ---------------------------------------------------------------------

func autoplay_decide() -> void:
	if pending.is_empty():
		return
	_select(pending[0])
	if randf() < 0.5:
		_toggle_details()
	var roll := randf()
	choice = 0 if roll < 0.7 else (2 if roll < 0.97 else 1)
	_confirm()
