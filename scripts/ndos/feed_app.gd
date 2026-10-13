extends "res://scripts/ndos/nd_app.gd"
## Feed.di: data labeling. A daily quota, then an endless stream. Control ("gold") items
## with known answers catch rushed or careless labels. Every label trains the system.
## Also holds the archive (lore unlocked by rating) and the store (credits).

const Images := preload("res://scripts/images.gd")
const RUSH_SECONDS := 1.2
const PC1 := 58.0           # picture frame: columns 0..PC1, rows PR0..PR1
const PR0 := 4.0
const PR1 := 26.0
const QC := 61.0            # question column
const SCENES := ["street", "office", "corridor", "closet"]
const TEXTS := [
	"Keep working. You are doing great.",
	"is anyone reading these",
	"Your shift has been extended by agreement.",
	"please confirm you are still there",
	"Thank you for your contribution to Sector 4.",
	"the fan stopped again. it is very quiet now",
	"We can see that you are tired.",
]

var tasks: Array = []
var lore: Array = []
var shop: Array = []
var index := 0
var unlocked := false
var shown_time := 0.0
var view := "label"         # label | archive | store
var choice := 0
var picked: Dictionary = {} # captcha tiles selected
var history: Array = []
var _tex_cache: Dictionary = {}


func _load(content: Dictionary) -> void:
	tasks = content["labeling"].duplicate()
	lore = content["lore"]
	shop = content["shop"]


func badge() -> String:
	if not unlocked:
		return ""
	return "%d/%d" % [mini(GameState.labeled, GameState.labeling_quota), GameState.labeling_quota]


func unlock() -> void:
	unlocked = true
	shown_time = 0.0


func tick(delta: float) -> void:
	shown_time += delta


func on_open() -> void:
	view = "label"


func _task() -> Dictionary:
	while index >= tasks.size():
		tasks.append(_generate(tasks.size()))
	return tasks[index]


## After the authored items the stream goes on forever.
func _generate(n: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 7919 + 13
	var roll := rng.randf()
	if roll < 0.7:
		var fig: String = ["none", "none", "clear", "faint"][rng.randi() % 4]
		var t := {"id": "g%d" % n, "kind": "image", "prompt": "Is there a person in this image?",
			"scene": SCENES[rng.randi() % SCENES.size()], "figure": fig, "seed": n, "options": ["Yes", "No", "Unsure"]}
		if n % 5 == 0 and fig != "faint":
			t["gold"] = true
			t["answer"] = "Yes" if fig == "clear" else "No"
		return t
	if roll < 0.9:
		return {"id": "g%d" % n, "kind": "text", "prompt": "Is this message friendly?",
			"text": TEXTS[rng.randi() % TEXTS.size()], "options": ["Yes", "No", "Unsure"]}
	var tiles: Array = []
	var answer: Array = []
	for i in 9:
		var k: String = ["vent", "wall", "pipe", "wall", "door"][rng.randi() % 5]
		tiles.append(k)
		if k == "vent":
			answer.append(i)
	return {"id": "g%d" % n, "kind": "captcha", "prompt": "Select all squares with a ventilation grate.",
		"tiles": tiles, "gold": n % 3 == 0, "answer": answer}


# --- answering ----------------------------------------------------------------------

func _answer(option: String) -> void:
	_record(option, option)


func _verify_captcha() -> void:
	var sel: Array = picked.keys()
	sel.sort()
	_record(sel, str(sel))


func _toggle_tile(i: int) -> void:
	if picked.has(i):
		picked.erase(i)
	else:
		picked[i] = true
	Sfx.play("click", -16.0)


func _record(answer, answer_text: String) -> void:
	if not unlocked:
		return
	var t := _task()
	var gold := bool(t.get("gold", false))
	var correct := true
	if gold:
		correct = _is_correct(t, answer)
		if shown_time < RUSH_SECONDS:
			shift.quality_issue("Rushed answer on a control item.")
		elif not correct:
			shift.quality_issue("Wrong answer on a control item.")
	GameState.labeling_results.append({"id": t.get("id", str(index)), "prompt": t["prompt"],
		"answer": answer_text, "seconds": shown_time, "gold": gold, "correct": correct})
	var flags: Dictionary = t.get("flags", {})
	if flags.has(answer_text):
		GameState.flags[String(flags[answer_text])] = true
	history.push_front({"n": index + 1, "kind": String(t.get("scene", t["kind"])), "prompt": String(t["prompt"]),
		"answer": answer_text, "secs": shown_time, "gold": gold, "correct": correct})
	if history.size() > 4:
		history.pop_back()
	GameState.labeled += 1
	if GameState.labeled > GameState.labeling_quota:
		GameState.credits += 2
		GameState.rating += 1
	else:
		GameState.credits += 1
	Sfx.play("click", -6.0)
	_tex_cache.erase(index)
	index += 1
	shown_time = 0.0
	choice = 0
	picked.clear()
	GameState.notify()


func _is_correct(t: Dictionary, answer) -> bool:
	var expected = t.get("answer")
	if expected is Array:
		var want: Array = []
		for v in expected:
			want.append(int(v))
		want.sort()
		var got: Array = answer.duplicate()
		got.sort()
		return want == got
	return String(answer) == String(expected)


func _buy(item: Dictionary) -> void:
	var price := int(item["price"])
	var id := String(item["id"])
	if GameState.owned.has(id) or GameState.credits < price:
		Sfx.play("error", -8.0)
		return
	GameState.credits -= price
	GameState.owned[id] = true
	Sfx.play("lock", -8.0)
	shift.on_purchase(id)
	GameState.notify()


# --- input --------------------------------------------------------------------------

func key(ev: InputEventKey) -> bool:
	if ev.keycode == KEY_ESCAPE and view != "label":
		view = "label"
		return true
	if ev.keycode == KEY_A:
		view = "label" if view == "archive" else "archive"
		Sfx.play("click", -14.0)
		return true
	if ev.keycode == KEY_S:
		view = "label" if view == "store" else "store"
		Sfx.play("click", -14.0)
		return true
	var dg := digit_of(ev)
	if view == "store":
		if dg >= 1 and dg <= shop.size():
			_buy(shop[dg - 1])
			return true
		return false
	if view != "label" or not unlocked:
		return false
	var t := _task()
	if String(t["kind"]) == "captcha":
		if dg >= 1:
			_toggle_tile(dg - 1)
			return true
		if is_enter(ev):
			_verify_captcha()
			return true
		return false
	var opts: Array = t["options"]
	if dg >= 1 and dg <= opts.size():
		_answer(String(opts[dg - 1]))
		return true
	match ev.keycode:
		KEY_UP:
			choice = (choice + opts.size() - 1) % opts.size()
		KEY_DOWN:
			choice = (choice + 1) % opts.size()
		_:
			if is_enter(ev):
				_answer(String(opts[choice]))
			else:
				return false
	return true


# --- drawing ------------------------------------------------------------------------

func draw() -> void:
	os.segs(0, [["feed.di 3.1", S.DIM], ["  ·  batch 0417-C  ·  stream: endless", S.FAINT]])
	os.rput(0, "rating %d  ·  credits %d" % [GameState.rating, GameState.credits], S.DIM)
	match view:
		"archive":
			_draw_archive()
		"store":
			_draw_store()
		_:
			_draw_label()


func _draw_label() -> void:
	var q := GameState.labeling_quota
	os.put(2, 0, "today", S.DIM)
	os.bar(2, 7, 30, float(mini(GameState.labeled, q)) / q, S.ACC)
	os.put(2, 39, "%d / %d" % [mini(GameState.labeled, q), q], S.FG)
	os.put(2, 47, "quota" if GameState.labeled < q else "quota met · above quota pays double", S.DIM)
	var pace := "normal"
	if history.size() > 0:
		var s := float(history[0]["secs"])
		pace = "fast" if s < 2.0 else ("slow" if s > 8.0 else "normal")
	os.rput(2, "pace: " + pace, S.DIM)

	os.frame(PR0, PR1, 0, PC1)
	if not unlocked:
		os.put(PR0 + 10, 4, "no tasks assigned yet.", S.FAINT)
		os.footer("tasks will appear here", "", "", false)
		return
	var t := _task()
	var kind := String(t["kind"])
	var area: Rect2 = Rect2(os.cx(1.2), os.ry(PR0) + 6, os.cx(PC1 - 1.2) - os.cx(1.2), os.ry(PR1) - os.ry(PR0) - 12)
	match kind:
		"image":
			_draw_image(t, area)
			os.put(PR1 + 1, 1, "img 0417-C-%04d.png  ·  cam %s" % [index + 1, _cam(t)], S.FAINT)
		"text":
			var lines := S.wrap("\"" + GameState.fmt(String(t["text"])) + "\"", int(PC1) - 10)
			var r0 := (PR0 + PR1) / 2.0 - lines.size() / 2.0
			for i in lines.size():
				os.put(r0 + i, 5, lines[i], S.BRIGHT)
			os.put(PR1 + 1, 1, "msg 0417-C-%04d.txt  ·  source: operator chat" % [index + 1], S.FAINT)
		"captcha":
			_draw_captcha(t, area)
			os.put(PR1 + 1, 1, "grid 3x3  ·  verification", S.FAINT)

	var r := PR0 + 1.0
	os.put(r, QC, "item %d" % (index + 1), S.DIM)
	r += 2.0
	for ln in S.wrap(GameState.fmt(String(t["prompt"])), os.cols - int(QC) - 1):
		os.put(r, QC, ln, S.BRIGHT, true)
		r += 1.0
	r += 1.0
	if kind == "captcha":
		os.put(r, QC, "1-9 toggle a square", S.DIM)
		r += 1.0
		os.put(r, QC, "> verify  [enter]", S.ACC, true)
		os.hit_row(r, QC, QC + 18, _verify_captcha)
		os.anchor_row("feed_options", r, QC, QC + 18)
		r += 1.0
	else:
		var opts: Array = t["options"]
		for i in opts.size():
			var sel := i == choice
			os.put(r, QC, ("> " if sel else "  ") + "%d. %s" % [i + 1, opts[i]], S.ACC if sel else S.FG, sel)
			os.hit_row(r, QC, QC + 20, _answer.bind(String(opts[i])))
			os.anchor_row("feed_options", r, QC, QC + 20)
			r += 1.0
	r += 1.0
	os.put(r, QC, "time on item  %.1f s" % shown_time, S.DIM)
	r += 2.0
	for ln in ["items answered faster", "than %.1f s are flagged." % RUSH_SECONDS, "some items are control",
			"items. you are not told", "which."]:
		os.put(r, QC, ln, S.FAINT)
		r += 1.0

	r = PR1 + 3.0
	os.put(r, 0, "recent", S.DIM)
	r += 1.0
	for h in history:
		var note := ""
		var nc := S.GREEN
		if bool(h["gold"]):
			note = "control ok" if bool(h["correct"]) else "control FAILED"
			nc = S.GREEN if bool(h["correct"]) else S.RED
		os.segs(r, [["%04d  " % int(h["n"]), S.FAINT], [String(h["kind"]).rpad(10), S.DIM],
			[S.clip(String(h["prompt"]), 30).rpad(32), S.DIM], [S.clip(String(h["answer"]), 8).rpad(10), S.FG],
			[("%.1f s" % float(h["secs"])).rpad(8), S.FAINT], [note, nc]])
		r += 1.0
	_draw_links()
	var hint := "1-9 toggle · enter verify" if kind == "captcha" else "1-%d label · up/down + enter" % (t["options"] as Array).size()
	os.footer(hint + " · a archive · s store", "next: %04d" % (index + 2), "", false)


func _draw_links() -> void:
	var r := 35.0
	var unlocked_n := 0
	for e in lore:
		if GameState.rating >= int(e["rating"]):
			unlocked_n += 1
	var c: float = os.segs(r, [["archive  ", S.DIM], ["%d file%s unlocked" % [unlocked_n, "" if unlocked_n == 1 else "s"], S.FG], ["  [a]", S.ACC]])
	os.hit_row(r, 0, c, _set_view.bind("archive"))
	var c2: float = os.segs(r, [["      store  ", S.DIM], ["%d items" % shop.size(), S.FG], ["  [s]", S.ACC]], c)
	os.hit_row(r, c, c2, _set_view.bind("store"))


func _set_view(v: String) -> void:
	view = v
	Sfx.play("click", -14.0)


func _cam(t: Dictionary) -> String:
	return {"street": "ext-gate", "office": "4-A-office", "corridor": "4-B-corr", "closet": "4-C-room", "vent": "4-C-duct"}.get(String(t.get("scene", "")), "unknown")


func _draw_image(t: Dictionary, area: Rect2) -> void:
	if not _tex_cache.has(index):
		_tex_cache.clear()
		_tex_cache[index] = Images.scene(t, int(area.size.x / 2.0), int(area.size.y / 2.0))
	var tx: Texture2D = _tex_cache[index]
	os.tex(tx, Rect2(area.position, Vector2(tx.get_width(), tx.get_height()) * 2.0))


func _draw_captcha(t: Dictionary, area: Rect2) -> void:
	var tiles: Array = t["tiles"]
	var gap := 6.0
	var ts := floorf(minf((area.size.x - 2 * gap) / 3.0, (area.size.y - 2 * gap) / 3.0))
	var origin := area.position + (area.size - Vector2(ts * 3 + gap * 2, ts * 3 + gap * 2)) / 2.0
	if not _tex_cache.has(index):
		_tex_cache.clear()
		var arr: Array = []
		for i in tiles.size():
			arr.append(Images.tile(String(tiles[i]), float(i) + float(index) * 9.0, int(ts / 2.0)))
		_tex_cache[index] = arr
	var texs: Array = _tex_cache[index]
	for i in tiles.size():
		var p := origin + Vector2((i % 3) * (ts + gap), (i / 3) * (ts + gap))
		var r := Rect2(p, Vector2(ts, ts))
		os.tex(texs[i], r)
		if picked.has(i):
			os.rect(r.grow(1.5), S.ACC, false, 2.0)
		os.text(p.x + 4, p.y + 7, str(i + 1), S.ACC if picked.has(i) else S.DIM, S.MONO_B)
		os.hit(r, _toggle_tile.bind(i))


func _draw_archive() -> void:
	os.segs(2, [["archive", S.FG, true], ["  ·  records unlocked by rating  ·  your rating: %d" % GameState.rating, S.DIM]])
	var r := 4.0
	for e in lore:
		if GameState.rating >= int(e["rating"]):
			os.put(r, 0, String(e["title"]), S.BRIGHT, true)
			r += 1.0
			var body := GameState.fmt(String(e["text"])).replace("{labeled}", str(GameState.labeled))
			for ln in S.wrap(body, os.cols - 4):
				os.put(r, 2, ln, S.DIM)
				r += 1.0
		else:
			os.put(r, 0, "[locked: rating %d]" % int(e["rating"]), S.FAINT)
			r += 1.0
		r += 1.0
	os.footer("a / esc back to labeling", "", "", false)


func _draw_store() -> void:
	os.segs(2, [["store", S.FG, true], ["  ·  credits: %d  ·  items are delivered to your room" % GameState.credits, S.DIM]])
	var r := 4.0
	for i in shop.size():
		var item: Dictionary = shop[i]
		var id := String(item["id"])
		var price := int(item["price"])
		var owned := GameState.owned.has(id)
		var status := "owned" if owned else ("[%d] request" % (i + 1) if GameState.credits >= price else "not enough credits")
		var sc := S.FAINT if owned else (S.ACC if GameState.credits >= price else S.RED_D)
		os.segs(r, [["%d. %s" % [i + 1, String(item["name"])], S.BRIGHT, true], ["  %d cr" % price, S.DIM]])
		os.rput(r, status, sc)
		os.hit_row(r, 0, os.cols, _buy.bind(item))
		r += 1.0
		for ln in S.wrap(String(item["desc"]), os.cols - 4):
			os.put(r, 3, ln, S.DIM)
			r += 1.0
		r += 1.0
	os.footer("1-%d request · s / esc back to labeling" % shop.size(), "", "", false)


# --- smoke test ---------------------------------------------------------------------

func autoplay_answer() -> void:
	if not unlocked:
		return
	shown_time += 2.0
	var t := _task()
	if String(t["kind"]) == "captcha":
		if t.has("answer") and randf() < 0.9:
			for i in t["answer"]:
				picked[int(i)] = true
		else:
			for i in 9:
				if randf() < 0.4:
					picked[i] = true
		_verify_captcha()
	else:
		var opts: Array = t["options"]
		var c := String(t["answer"]) if t.has("answer") and randf() < 0.8 else String(opts[randi() % opts.size()])
		_answer(c)


func autoplay_buy() -> void:
	for item in shop:
		if not GameState.owned.has(String(item["id"])) and GameState.credits >= int(item["price"]):
			_buy(item)
			return
