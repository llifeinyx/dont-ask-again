extends Node
## Debug only: saves screenshots at fixed moments of an automated run (--shots=<dir>).

var dir := ""
var shift
var plan: Array = []
var busy := false


func _process(_delta: float) -> void:
	if busy or shift == null or not is_instance_valid(shift) or plan.is_empty():
		return
	if float(shift.elapsed) < float(plan[0]["t"]):
		return
	busy = true
	_shoot(plan.pop_front())


func _shoot(s: Dictionary) -> void:
	if s.has("vent"):
		if bool(s["vent"]) and not shift.facing_vent:
			shift._show_vent()
		elif not bool(s["vent"]) and shift.facing_vent:
			shift._show_front()
	if s.has("tab"):
		shift.select_app(int(s["tab"]))
	if s.has("details") and shift.echo.selected != null and not shift.echo.details_open:
		shift.echo._toggle_details()
	if s.has("eyes"):
		shift.reflection.eyes = true
		shift.reflection.queue_redraw()
	if s.has("store"):
		shift.feed.view = "store"
	await capture(String(s["name"]))
	busy = false


func capture(shot_name: String) -> void:
	# Freeze game time while capturing: under a slow virtual display one frame can
	# span seconds of game time at smoke-test speed.
	var ts := Engine.time_scale
	Engine.time_scale = 0.0001
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	Engine.time_scale = ts
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(shot_name + ".png"))
	print("SHOT: " + shot_name)
