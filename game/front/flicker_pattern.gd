class_name FlickerPattern
extends Resource
## A failing lamp: a faint steady waver with sudden short dips. sample() is deterministic, so a
## screenshot at a given time is always the same.

## Primes that keep the random numbers of different seeds and streams apart.
const SEED_STRIDE: int = 1000003
const STREAM_STRIDE: int = 7919
## rand_from_seed() gives a 32-bit unsigned number; dividing by this maps it to [0, 1).
const RANDOM_RANGE: float = 4294967296.0

## How far the waver pulls the lamp down, as a share of its brightness.
@export_range(0.0, 1.0) var waver_depth: float = 0.08
## Waver changes per second.
@export_range(0.1, 60.0) var waver_rate: float = 12.0
## Length of one dip in seconds; time is cut into slots of this length.
@export_range(0.02, 2.0) var dip_length: float = 0.12
## Chance that a slot holds a dip.
@export_range(0.0, 1.0) var dip_chance: float = 0.2
## Lamp brightness at the bottom of a dip.
@export_range(0.0, 1.0) var dip_level: float = 0.1
@export var noise_seed: int = 1


## Lamp brightness at time seconds, from 0 to 1.
func sample(time: float) -> float:
	var slot: int = floori(time / dip_length)
	var dip: float = 0.0
	if _random(slot, 0) < dip_chance:
		# Filament inertia: the dip eases in and out within its slot.
		dip = sin(PI * (time / dip_length - slot))
	var waver: float = waver_depth * _smooth_noise(time * waver_rate)
	return clampf((1.0 - waver) * lerpf(1.0, dip_level, dip), 0.0, 1.0)


func _smooth_noise(x: float) -> float:
	var cell: int = floori(x)
	return lerpf(_random(cell, 1), _random(cell + 1, 1), smoothstep(0.0, 1.0, x - cell))


## Repeatable random number in [0, 1) for an integer and a stream.
func _random(n: int, stream: int) -> float:
	return float(rand_from_seed(noise_seed * SEED_STRIDE + stream * STREAM_STRIDE + n)[0]) / RANDOM_RANGE
