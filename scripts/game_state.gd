extends Node
## Global run state (autoload "GameState"). Reset at the start of every run.

signal changed

const FIRE_LIMIT := 6
const OPERATOR_NO := "0419"

var player_name: String = "Operator"
var violations: int = 0
var turns: int = 0
var turns_seen: int = 0
var credits: int = 0
var rating: int = 0
var labeled: int = 0
var labeling_quota: int = 10
var flags: Dictionary = {}
var owned: Dictionary = {}

## Hidden experiment data.
var decisions: Array = []
var kontur_results: Array = []
var labeling_results: Array = []
var contract_seconds: float = 0.0
var contract_scrolled: bool = false


func reset() -> void:
	player_name = "Operator"
	violations = 0
	turns = 0
	turns_seen = 0
	credits = 0
	rating = 0
	labeled = 0
	labeling_quota = 10
	flags = {}
	owned = {}
	decisions = []
	kontur_results = []
	labeling_results = []
	contract_seconds = 0.0
	contract_scrolled = false


func fmt(text: String) -> String:
	return text.replace("{name}", player_name).replace("{no}", OPERATOR_NO)


func notify() -> void:
	changed.emit()
