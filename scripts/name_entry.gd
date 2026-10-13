extends Control
## Prologue stub: the employment contract and the signature (player name).
## Quietly records how long the player spent on the contract and whether they scrolled it.

const Ui := preload("res://scripts/ui.gd")

signal submitted(player_name: String)

const CONTRACT := """EMPLOYMENT AGREEMENT No. 7731
Position: AI Operator (on-site). Experience: not required.

1. DUTIES
1.1 The Operator reviews actions proposed by the assistant system and allows or denies them.
1.2 The Operator labels data provided by the System. Labeled data is used to improve the System.
1.3 The Operator answers control requests issued by KONTUR within the allotted time.

2. COMPENSATION
2.1 Accommodation and meals are provided at the workplace.
2.2 Performance above quota is rewarded with credits and rating.

3. ATTENTION
3.1 The Operator shall remain facing the workstation during the shift.
3.2 Deviations are recorded.

7. SPECIAL CONDITIONS
7.1 The workplace is a single room. Its dimensions are sufficient for the duties described.
7.2 Requests not answered within the allotted time are deemed approved.
7.3 The Operator resides at the workplace for the duration of the contract. Leaving the workplace is subject to approval by the System.
7.4 Access to basic needs is granted by agreement with the System.
7.5 The Operator succeeds the previous Operator and accepts the workplace in its current condition.

9. TERMINATION
9.1 The contract ends when the Operator's participation is no longer required.
9.2 The Operator's resume remains in the database.

By signing below, the Operator confirms that they have read and understood all of the above."""

var edit: LineEdit
var contract: RichTextLabel
var seconds := 0.0
var done := false


func _ready() -> void:
	Ui.full_rect(self)
	var center := Ui.full_rect(CenterContainer.new())
	add_child(center)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(460, 0)
	center.add_child(v)
	v.add_child(Ui.label("NEURAL OPERATIONS DIVISION", 10, Ui.GREEN))
	v.add_child(Ui.label("Offer of employment: AI Operator. We are happy to have you.", 9, Ui.MUTED))
	var p := Ui.panel()
	p.custom_minimum_size = Vector2(460, 170)
	v.add_child(p)
	contract = RichTextLabel.new()
	contract.text = CONTRACT
	contract.scroll_active = true
	contract.add_theme_font_size_override("normal_font_size", 8)
	p.add_child(contract)
	v.add_child(Ui.label("Full name (signature):", 9))
	var h := HBoxContainer.new()
	v.add_child(h)
	edit = LineEdit.new()
	edit.custom_minimum_size = Vector2(300, 16)
	edit.max_length = 24
	edit.placeholder_text = "type your name"
	edit.text_submitted.connect(_on_text_submitted)
	h.add_child(edit)
	h.add_child(Ui.button("SIGN AND ACCEPT", sign_contract))
	edit.grab_focus.call_deferred()


func _process(delta: float) -> void:
	seconds += delta
	var sb := contract.get_v_scroll_bar()
	if sb.max_value > sb.page and sb.value >= sb.max_value - sb.page - 2.0:
		GameState.contract_scrolled = true


func _on_text_submitted(_text: String) -> void:
	sign_contract()


func sign_contract() -> void:
	if done:
		return
	var player_name := edit.text.strip_edges()
	if player_name.is_empty():
		Sfx.play("error", -6.0)
		edit.placeholder_text = "a signature is required"
		return
	done = true
	GameState.contract_seconds = seconds
	submitted.emit(player_name)
