extends Node
## Procedural sound effects (autoload "Sfx"). No audio files needed for the prototype.
## Sounds that come from the vent are routed to "behind" buses (muffled, panned)
## while the player faces the terminal.

const RATE := 22050
const HUM_DB := -13.0

var sounds: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var hum_player: AudioStreamPlayer
var facing_vent: bool = false
var _rng := RandomNumberGenerator.new()
var _hum_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 7
	_add_bus("BehindL", -0.75)
	_add_bus("BehindR", 0.75)
	_build()
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	hum_player = AudioStreamPlayer.new()
	hum_player.stream = sounds["hum"]
	hum_player.volume_db = HUM_DB
	add_child(hum_player)


func play(id: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	_play(id, volume_db, pitch, "Master")


## A sound that originates in the vent behind the player.
func play_vent(id: String, volume_db: float = 0.0) -> void:
	if facing_vent:
		_play(id, volume_db + 3.0, 1.0, "Master")
	else:
		_play(id, volume_db, 1.0, "BehindL" if _rng.randf() < 0.5 else "BehindR")


## fade_in > 0 brings the hum up slowly from silence (the first minute of day 1).
func set_hum(on: bool, fade_in: float = 0.0) -> void:
	if _hum_tween != null:
		_hum_tween.kill()
		_hum_tween = null
	if on and not hum_player.playing:
		hum_player.volume_db = HUM_DB
		if fade_in > 0.0:
			hum_player.volume_db = -60.0
			_hum_tween = create_tween()
			_hum_tween.tween_property(hum_player, "volume_db", HUM_DB, fade_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		hum_player.play()
	elif not on:
		hum_player.stop()


func _play(id: String, volume_db: float, pitch: float, bus: String) -> void:
	if not sounds.has(id):
		push_warning("Unknown sound: " + id)
		return
	for p in players:
		if not p.playing:
			p.stream = sounds[id]
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.bus = bus
			p.play()
			return


func _add_bus(bus_name: String, pan: float) -> void:
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 1300.0
	AudioServer.add_bus_effect(idx, lp)
	var pn := AudioEffectPanner.new()
	pn.pan = pan
	AudioServer.add_bus_effect(idx, pn)
	AudioServer.set_bus_volume_db(idx, -3.0)


# --- synthesis -------------------------------------------------------------

func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)


func _wav(b: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(b.size() * 2)
	for i in b.size():
		data.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = b.size()
	return w


func _build() -> void:
	var b: PackedFloat32Array
	var lp := 0.0
	var ph := 0.0

	# Ventilation hum (loop).
	b = _buf(2.0)
	for i in b.size():
		var t := float(i) / RATE
		lp += (_noise() - lp) * 0.02
		b[i] = 0.10 * sin(TAU * 50.0 * t) + 0.05 * sin(TAU * 100.0 * t) + 0.025 * sin(TAU * 150.0 * t) + lp * 0.4
	sounds["hum"] = _wav(b, true)

	# KONTUR alert: harsh two-tone square buzz.
	b = _buf(0.5)
	for i in b.size():
		var t := float(i) / RATE
		var f := 880.0 if t < 0.19 else 622.0
		var gate := 1.0 if (t < 0.16 or (t > 0.22 and t < 0.46)) else 0.0
		var sq := 1.0 if sin(TAU * f * t) > 0.0 else -1.0
		b[i] = sq * 0.2 * gate
	sounds["alert"] = _wav(b)

	# Echo chime: the one pleasant sound in the game (used for auto-approvals).
	b = _buf(1.2)
	var notes: Array[float] = [784.0, 987.8, 1174.7]
	for i in b.size():
		var t := float(i) / RATE
		var v := 0.0
		for n in 3:
			var st := n * 0.09
			if t >= st:
				var tt := t - st
				v += sin(TAU * notes[n] * tt) * exp(-tt * 3.5) * 0.12
		b[i] = v
	sounds["chime"] = _wav(b)

	b = _buf(0.07)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * 1320.0 * t) * exp(-t * 50.0) * 0.18
	sounds["blip"] = _wav(b)

	b = _buf(0.03)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = _noise() * (1.0 - t / 0.03) * 0.25
	sounds["click"] = _wav(b)

	b = _buf(0.28)
	for i in b.size():
		var t := float(i) / RATE
		var sq := 1.0 if sin(TAU * 150.0 * t) > 0.0 else -1.0
		b[i] = sq * 0.16 * (1.0 - t / 0.28)
	sounds["error"] = _wav(b)

	# Scrape: filtered noise with grainy modulation.
	b = _buf(1.6)
	lp = 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_noise() - lp) * 0.08
		var env := sin(PI * t / 1.6)
		var grain := 0.5 + 0.5 * sin(TAU * 7.0 * t + sin(TAU * 1.3 * t) * 3.0)
		b[i] = lp * env * grain * 1.4
	sounds["scrape"] = _wav(b)

	# Breath: slow swell of soft noise.
	b = _buf(2.2)
	lp = 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_noise() - lp) * 0.03
		var env := pow(sin(PI * fmod(t, 1.1) / 1.1), 2.0)
		b[i] = lp * env * 1.2
	sounds["breath"] = _wav(b)

	b = _buf(0.3)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * (70.0 - 30.0 * t) * t) * exp(-t * 18.0) * 0.8 + _noise() * exp(-t * 90.0) * 0.3
	sounds["knock"] = _wav(b)

	b = _buf(0.8)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = clampf(sin(TAU * 48.0 * t) * exp(-t * 6.0) * 1.1 + _noise() * exp(-t * 20.0) * 0.7, -1.0, 1.0)
	sounds["bang"] = _wav(b)

	# Door lock clunk.
	b = _buf(0.7)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * 90.0 * t) * exp(-t * 14.0) * 0.7 + sin(TAU * 1240.0 * t) * exp(-t * 9.0) * 0.08 + _noise() * exp(-t * 60.0) * 0.4
	sounds["lock"] = _wav(b)

	b = _buf(1.2)
	ph = 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (420.0 * exp(-t * 2.5)) / RATE
		b[i] = sin(ph) * 0.25 * (1.0 - t / 1.2)
	sounds["power_down"] = _wav(b)

	b = _buf(1.0)
	ph = 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (60.0 + 300.0 * t) / RATE
		b[i] = sin(ph) * 0.2 * minf(1.0, t * 4.0) * (1.0 - t)
	sounds["power_up"] = _wav(b)

	b = _buf(0.15)
	ph = 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * maxf(300.0, 1700.0 - 5000.0 * t) / RATE
		b[i] = sin(ph) * exp(-t * 30.0) * 0.22
	sounds["drip"] = _wav(b)

	b = _buf(0.3)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = _noise() * exp(-t * 25.0) * 0.3 + sin(TAU * 310.0 * t) * exp(-t * 12.0) * 0.15 + sin(TAU * 467.0 * t) * exp(-t * 14.0) * 0.1
	sounds["lever"] = _wav(b)

	b = _buf(0.4)
	lp = 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_noise() - lp) * 0.12
		b[i] = lp * sin(PI * t / 0.4) * 0.6
	sounds["whoosh"] = _wav(b)
