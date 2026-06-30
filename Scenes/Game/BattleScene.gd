extends Control

signal battle_completed(result: Dictionary)

@onready var attacker_label: Label = $TopBar/AttackerLabel
@onready var defender_label: Label = $TopBar/DefenderLabel
@onready var round_label: Label = $TopBar/RoundLabel
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var anim_attacker: Node2D = $BattleField/AttackerSide
@onready var anim_defender: Node2D = $BattleField/DefenderSide
@onready var retreat_btn: Button = $BottomBar/RetreatBtn
@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var result_panel: Panel = $ResultPanel

var _current_round: int = 0
var _round_timer: float = 300.0
var _battle_state = null
var _is_player_attacker: bool = false

func _ready() -> void:
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(_close)
	retreat_btn.pressed.connect(_retreat)
	result_panel.hide()
	hide()

func start_battle(battle_id: String, attacker: Dictionary, defender: Dictionary) -> void:
	_battle_state = CombatSystem.create_battle(attacker, defender, battle_id)
	_is_player_attacker = attacker.get("city_id", "") == GameState.selected_city_id
	attacker_label.text = "مهاجم: " + attacker.get("name", "???")
	defender_label.text = "مدافع: " + defender.get("name", "???")
	_current_round = 0
	round_label.text = "راند ۰"
	timer_label.text = "۵:۰۰"
	_show()
	_next_round()

func _show() -> void:
	show()
	_check_retreat_button()

func _next_round() -> void:
	if _battle_state.status != "ongoing":
		_show_result()
		return
	CombatSystem.simulate_round(_battle_state)
	_current_round = _battle_state.current_round
	round_label.text = "راند %d" % _current_round
	_round_timer = 300.0
	_animate_round(_battle_state.rounds_log[-1])
	_check_retreat_button()

func _animate_round(round_data: Dictionary) -> void:
	if _battle_state.status != "ongoing":
		_show_result()

func _on_timer_timeout() -> void:
	if _battle_state and _battle_state.status == "ongoing":
		_next_round()

func _check_retreat_button() -> void:
	retreat_btn.visible = CombatSystem.can_retreat(_battle_state) if _battle_state else false
	retreat_btn.disabled = not retreat_btn.visible

func _retreat() -> void:
	if _battle_state:
		CombatSystem.retreat(_battle_state)
		_show_result()

func _show_result() -> void:
	result_panel.show()
	var status = _battle_state.status if _battle_state else "unknown"
	var result_text = ""
	match status:
		"attacker_win": result_text = "پیروزی مهاجم!"
		"defender_win": result_text = "پیروزی مدافع!"
		"retreated": result_text = "عقب‌نشینی"
		"draw": result_text = "تساوی"
		_: result_text = status
	$ResultPanel/ResultLabel.text = result_text
	var result_data = {
		"status": status,
		"rounds": _battle_state.rounds_log if _battle_state else [],
		"attacker_units_remaining": CombatSystem._count_units(_battle_state.attacker) if _battle_state else 0,
		"defender_units_remaining": CombatSystem._count_units(_battle_state.defender) if _battle_state else 0
	}
	battle_completed.emit(result_data)

func _close() -> void:
	hide()
	get_parent().get_node_or_null("CombatReport").show()
