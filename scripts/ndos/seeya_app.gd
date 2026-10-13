extends "res://scripts/ndos/nd_app.gd"
## Seeya.legacy: an old mail/messenger client, about to be retired.
## Other operators write here. Some messages can be answered (1-3); the third option
## lets Echo write the reply for you, in your name.

var thread_info: Dictionary = {}
var mails: Dictionary = {}
var threads: Dictionary = {}       # id -> {"from","meta","msgs","unread","last","reply"}
var selected := ""
var _counter := 0


func _load(content: Dictionary) -> void:
	thread_info = content.get("mail_threads", {})
	mails = content.get("mail", {})
	for id in content.get("mail_initial", []):
		add_mail(String(id), true)


func badge() -> String:
	var n := unread_count()
	return str(n) if n > 0 else ""


func unread_count() -> int:
	var n := 0
	for t in threads.values():
		if bool(t["unread"]):
			n += 1
	return n


func on_open() -> void:
	_mark_read()


# --- mail ---------------------------------------------------------------------------

func _thread(tid: String) -> Dictionary:
	if not threads.has(tid):
		var info: Dictionary = thread_info.get(tid, {"from": tid, "meta": ""})
		threads[tid] = {"from": String(info["from"]), "meta": String(info.get("meta", "")), "msgs": [],
			"unread": false, "last": 0, "reply": null}
	return threads[tid]


func add_mail(id: String, initial := false) -> void:
	if not mails.has(id):
		push_warning("Unknown mail: " + id)
		return
	var d: Dictionary = mails[id]
	var tid := String(d["thread"])
	var t := _thread(tid)
	var who := String(t["from"]).split(" ")[0]
	_push(t, String(d.get("time", "" if initial else shift.clock_text())), who, GameState.fmt(String(d["text"])), S.FG)
	if d.has("reply"):
		t["reply"] = d["reply"]
	if selected == "":
		selected = tid
	if initial:
		return
	t["unread"] = true
	if os.active == 3 and selected == tid:
		t["unread"] = false
	shift.notify("%s: %s" % [who, GameState.fmt(String(d["text"]))], "mail")


func _push(t: Dictionary, time_label: String, who: String, text: String, color: Color, suffix := "") -> void:
	_counter += 1
	t["last"] = _counter
	(t["msgs"] as Array).append({"time": time_label, "who": who, "text": text, "c": color, "s": suffix})


func _order() -> Array:
	var ids := threads.keys()
	ids.sort_custom(func(a, b): return int(threads[a]["last"]) > int(threads[b]["last"]))
	return ids


func _mark_read() -> void:
	if threads.has(selected):
		threads[selected]["unread"] = false


func _select(tid: String) -> void:
	selected = tid
	_mark_read()
	Sfx.play("click", -14.0)


func _reply(i: int) -> void:
	if not threads.has(selected):
		return
	var t: Dictionary = threads[selected]
	var r = t["reply"]
	if r == null:
		return
	var opts: Array = r["options"]
	if i < 0 or i >= opts.size():
		return
	var by_echo: bool = i == 2 and r.has("echo_text")
	var text := GameState.fmt(String(r["echo_text"])) if by_echo else String(opts[i])
	_push(t, shift.clock_text(), "you", text, S.BRIGHT, "  (written by Echo)" if by_echo else "")
	t["reply"] = null
	var flags: Array = r.get("flags", [])
	if i < flags.size() and String(flags[i]) != "":
		GameState.flags[String(flags[i])] = true
	GameState.flags["mail_replied_" + selected] = true
	Sfx.play("click")
	var responses: Array = r.get("responses", [])
	if i < responses.size() and responses[i] != null and String(responses[i]) != "":
		var tid := selected
		var who := String(t["from"]).split(" ")[0]
		var resp := GameState.fmt(String(responses[i]))
		shift.get_tree().create_timer(5.0).timeout.connect(func():
			var th: Dictionary = threads[tid]
			_push(th, shift.clock_text(), who, resp, S.FG)
			th["unread"] = not (os.active == 3 and selected == tid)
			shift.notify("%s: %s" % [who, resp], "mail"))


# --- input --------------------------------------------------------------------------

func key(ev: InputEventKey) -> bool:
	var order := _order()
	var i := order.find(selected)
	match ev.keycode:
		KEY_UP:
			if i > 0:
				_select(order[i - 1])
			return true
		KEY_DOWN:
			if i >= 0 and i < order.size() - 1:
				_select(order[i + 1])
			return true
	var dg := digit_of(ev)
	if dg >= 1 and dg <= 3:
		_reply(dg - 1)
		return true
	return false


# --- drawing ------------------------------------------------------------------------

func draw() -> void:
	var order := _order()
	var unread := unread_count()
	os.row_bg(0, -0.5, os.cols - 0.5, Color8(150, 128, 74))
	os.put(0, 0, "SEEYA.LEGACY 2.0", S.TBG, true)
	os.put(0, 19, "INBOX   %d conversations, %d new" % [order.size(), unread], S.TBG)
	os.rput(0, "retired on 31.10 ", S.TBG)
	os.segs(1.2, [["! ", S.ACC], ["This client is deprecated. Your account will move to Seeya Next. Unsent drafts will be lost.", S.DIM]])

	var r := 3.0
	for tid in order.slice(0, 8):
		var t: Dictionary = threads[tid]
		var msgs: Array = t["msgs"]
		var last: Dictionary = msgs[msgs.size() - 1]
		var sel: bool = tid == selected
		var is_new := bool(t["unread"])
		if sel:
			os.row_bg(r, -0.5, os.cols - 0.5, S.ACC)
		var col := S.TBG if sel else (S.FG if is_new else S.DIM)
		var subj := String(last["text"]) if String(last["who"]) != "you" else "you: " + String(last["text"])
		if t["reply"] != null:
			subj = "[reply] " + subj
		os.segs(r, [["N  " if is_new else "   ", col, is_new], [String(last["time"]).rpad(11), col],
			[S.clip(String(t["from"]), 21).rpad(23), col, is_new], [S.clip(subj, os.cols - 40), col]])
		os.hit_row(r, 0, os.cols, _select.bind(tid))
		r += 1.0
	os.hline(r + 0.4)
	r += 2.0

	if threads.has(selected):
		var t: Dictionary = threads[selected]
		os.segs(r, [[String(t["from"]).split(" ")[0], S.BRIGHT, true], ["  " + String(t["meta"]), S.DIM]])
		r += 2.0
		var box := _reply_rows(t)
		var rows: Array = []
		for m in t["msgs"]:
			var suffix: Array = [[String(m["s"]), S.FAINT]] if String(m["s"]) != "" else []
			var tl := String(m["time"])
			rows.append_array(os.wrap_rows([[(tl + "  ") if tl != "" else "", S.FAINT], [String(m["who"]).rpad(8), S.DIM]],
				String(m["text"]), m["c"], false, 0.0, suffix))
		var avail := int(os.content_rows() - r) - (box.size() + 3 if box.size() > 0 else 0)
		for row in rows.slice(maxi(0, rows.size() - avail)):
			os.draw_row(r, row)
			r += 1.0
		if box.size() > 0:
			r += 1.0
			os.frame(r, r + box.size() + 1, 2, os.cols)
			for i in box.size():
				os.draw_row(r + 1 + i, box[i])
	os.footer("up/down select · 1-3 reply · ctrl+1-4 switch program", "%d new" % unread, "", false)


func _reply_rows(t: Dictionary) -> Array:
	var r = t["reply"]
	if r == null:
		return []
	var rows: Array = [{"parts": [["Reply to " + String(t["from"]).split(" ")[0], S.FG, true]], "col": 4.0}, {}]
	var opts: Array = r["options"]
	for i in opts.size():
		var label := String(opts[i])
		rows.append({"parts": [["%d. " % (i + 1), S.ACC, true], [label, S.FG]], "col": 4.0, "hit": _reply.bind(i)})
	rows.append({})
	rows.append({"parts": [["no answer needed. they will see that you read it.", S.FAINT]], "col": 4.0})
	return rows


# --- smoke test ---------------------------------------------------------------------

func autoplay_reply() -> void:
	for tid in threads:
		if threads[tid]["reply"] != null:
			selected = tid
			_reply(randi() % 3)
			return
