extends RefCounted
## First-day onboarding: points at the place to click until the player has done it once.
## Steps come from data ("onboarding" in day*.json), in priority order; the first step
## whose "when" holds is shown. A step is done for good once its "until" holds, or after
## it has been on screen for "max" seconds. "after" holds a step back until that shift second,
## "after_step" until another step is done.
## Targets are ND-OS anchors (see ndos.anchor) or "turn_around" / "lever" in the room.

const ROOM_TARGETS := ["turn_around", "lever"]

var shift
var steps: Array = []
var done: Dictionary = {}       # step id -> true
var shown: Dictionary = {}      # step id -> seconds on screen
var seen_apps: Dictionary = {}  # app index -> true, once the player had it open
var current := ""


func setup(owner_shift, data: Array) -> void:
	shift = owner_shift
	steps = data


func tick(delta: float) -> void:
	seen_apps[int(shift.ndos.active)] = true
	var step := _pick()
	current = String(step.get("id", ""))
	if step.is_empty():
		shift.ndos.hint = {}
		shift.hint_marker.hide_hint()
		return
	shown[current] = float(shown.get(current, 0.0)) + delta
	var target := String(step["target"])
	var text := String(step.get("text", ""))
	if target in ROOM_TARGETS:
		shift.ndos.hint = {}
		shift.hint_marker.show_hint(shift.room_target_rect(target), text)
	else:
		shift.hint_marker.hide_hint()
		shift.ndos.hint = {"target": target, "text": text}


func _pick() -> Dictionary:
	for s in steps:
		var id := String(s["id"])
		if done.has(id):
			continue
		if _holds(String(s.get("until", "")), s):
			done[id] = true
			continue
		if s.has("max") and float(shown.get(id, 0.0)) >= float(s["max"]):
			done[id] = true
			continue
		if float(shift.elapsed) < float(s.get("after", 0.0)):
			continue
		if s.has("after_step") and not done.has(String(s["after_step"])):
			continue
		if _holds(String(s["when"]), s):
			return s
	return {}


func _holds(cond: String, step: Dictionary) -> bool:
	var os = shift.ndos
	var echo = shift.echo
	var kontur = shift.kontur
	var calm: bool = shift.power_on and not shift.facing_vent and not shift.turning and os.modal == null
	var question: bool = kontur.active != null and String(kontur.active["kind"]) != "code"
	match cond:
		"":
			return false
		"echo_request":
			return calm and os.active == 0 and echo.selected != null
		"decided":
			return _player_decisions() >= 1
		"decided_twice":
			return _player_decisions() >= 2
		"details_opened":
			if echo.details_open:
				return true
			for d in GameState.decisions:
				if bool(d["opened"]):
					return true
			return false
		"code_check":
			return shift.power_on and os.modal != null
		"code_answered":
			return _shown_and_gone(step, os.modal == null)
		"question_elsewhere":
			return calm and question and os.active != 1
		"question_here":
			return calm and question and os.active == 1
		"question_answered":
			return _shown_and_gone(step, kontur.active == null)
		"feed_elsewhere":
			return calm and shift.feed.unlocked and os.active != 2
		"feed_seen":
			return seen_apps.has(2)
		"feed_here":
			return calm and shift.feed.unlocked and os.active == 2 and String(shift.feed.view) == "label"
		"labeled":
			return GameState.labeled >= 1
		"mail_unread":
			return calm and shift.seeya.unread_count() > 0 and os.active != 3
		"mail_seen":
			return seen_apps.has(3)
		"watching":
			return calm and kontur.watching
		"front":
			return calm
		"turned":
			return GameState.turns >= 1
		"outage_front":
			return not shift.power_on and not shift.facing_vent and not shift.turning
		"outage_vent":
			return not shift.power_on and shift.facing_vent and not shift.turning
		"power_back":
			return _shown_and_gone(step, shift.power_on)
	push_warning("Unknown onboarding condition: " + cond)
	return false


## True once the step has been on screen and the situation it pointed at is over.
func _shown_and_gone(step: Dictionary, over: bool) -> bool:
	return over and shown.has(String(step["id"]))


func _player_decisions() -> int:
	var n := 0
	for d in GameState.decisions:
		if String(d["how"]) == "player":
			n += 1
	return n
