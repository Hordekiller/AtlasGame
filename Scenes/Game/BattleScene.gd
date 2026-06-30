extends Control

signal battle_completed(result: Dictionary)

@onready var attacker_label: Label = $TopBar/AttackerLabel
@onready var defender_label: Label = $TopBar/DefenderLabel
@onready var round_label: Label = $TopBar/RoundLabel
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var battlefield: Panel = $VBox/BattleField
@onready var attacker_units_node: Node2D = $VBox/BattleField/AttackerUnits
@onready var defender_units_node: Node2D = $VBox/BattleField/DefenderUnits
@onready var projectile_layer: Node2D = $VBox/BattleField/ProjectileLayer
@onready var retreat_btn: Button = $BottomBar/RetreatBtn
@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var result_panel: Panel = $VBox/ResultPanel
@onready var result_label: Label = $VBox/ResultPanel/ResultLabel

var _current_round: int = 0
var _round_timer: float = 300.0
var _battle_state = null
var _is_player_attacker: bool = false
var _animating: bool = false

const UNIT_COLORS: Dictionary = {
	"slinger": Color(0.8, 0.6, 0.3),
	"hoplite": Color(0.3, 0.5, 0.8),
	"archer": Color(0.2, 0.8, 0.3),
	"swordsman": Color(0.7, 0.3, 0.3),
	"cavalry": Color(0.9, 0.7, 0.2),
	"ship_ballista": Color(0.5, 0.3, 0.7),
	"default": Color(0.6, 0.6, 0.6)
}
const UNIT_ICONS: Dictionary = {
	"slinger": "🏹", "hoplite": "🗡️", "archer": "🏹",
	"swordsman": "⚔️", "cavalry": "🐴", "ship_ballista": "🚢"
}

func _ready() -> void:
	var tex_path = "res://Assets/Textures/UI/close.png"
	if ResourceLoader.exists(tex_path):
		close_btn.texture_normal = ResourceLoader.load(tex_path)
	close_btn.pressed.connect(_close)
	retreat_btn.pressed.connect(_retreat)
	var cr_btn = $VBox/ResultPanel/CloseReportBtn
	if cr_btn:
		cr_btn.pressed.connect(_close)
	result_panel.hide()
	hide()

func start_battle(battle_state_or_id, attacker_or_dict = null, defender_or_dict = null) -> void:
	if typeof(battle_state_or_id) == TYPE_OBJECT:
		_battle_state = battle_state_or_id
		var atk_id = _battle_state.attacker.get("city_id", "???")
		var def_id = _battle_state.defender.get("city_id", "???")
		_is_player_attacker = atk_id == GameState.selected_city_id or atk_id in GameState.current_cities
		attacker_label.text = "مهاجم: " + atk_id
		defender_label.text = "مدافع: " + def_id
	else:
		_battle_state = CombatSystem.create_battle(attacker_or_dict, defender_or_dict, battle_state_or_id)
		_is_player_attacker = attacker_or_dict.get("city_id", "") == GameState.selected_city_id
		var atk_name = attacker_or_dict.get("name", "???") if attacker_or_dict.get("name", "") != "" else attacker_or_dict.get("city_id", "???")
		var def_name = defender_or_dict.get("name", "???") if defender_or_dict.get("name", "") != "" else defender_or_dict.get("city_id", "???")
		attacker_label.text = "مهاجم: " + atk_name
		defender_label.text = "مدافع: " + def_name
	_current_round = 0
	round_label.text = "راند ۰"
	timer_label.text = "۵:۰۰"
	_show()
	_draw_initial_units()
	_next_round()

func _show() -> void:
	show()
	_check_retreat_button()

func _draw_initial_units() -> void:
	_clear_units()
	if not _battle_state:
		return
	_draw_army_icons(_battle_state.attacker.get("units", {}), attacker_units_node, true)
	_draw_army_icons(_battle_state.defender.get("units", {}), defender_units_node, false)

func _draw_army_icons(units: Dictionary, parent: Node2D, is_attacker: bool) -> void:
	var idx = 0
	for utype in units:
		var count = 0
		var val = units[utype]
		if typeof(val) == TYPE_DICTIONARY:
			count = val.get("count", 0)
		else:
			count = int(val)
		if count <= 0:
			continue
		var sprite = Sprite2D.new()
		sprite.name = utype
		var icon = UNIT_ICONS.get(utype, "⚔️")
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var fnt_size = 20
		var font = ThemeDB.fallback_font
		var fnt = font as Font
		if fnt:
			var fw = fnt.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, fnt_size).x
			var fh = fnt.get_height(fnt_size)
			var offset_x = (32 - fw) / 2.0
			var offset_y = (32 - fh) / 2.0
			fnt.draw_char(img, Vector2(offset_x, offset_y), icon, fnt_size, UNIT_COLORS.get(utype, Color.WHITE))
		var tex = ImageTexture.create_from_image(img)
		sprite.texture = tex
		sprite.scale = Vector2(1.5, 1.5)
		var spacing = 60
		var cols = 5
		var row = idx / cols
		var col = idx % cols
		sprite.position = Vector2(col * spacing - 100, row * spacing - 80)
		sprite.modulate = Color(1, 1, 1, 0.9)
		parent.add_child(sprite)

		var hp_bar = ColorRect.new()
		hp_bar.name = "HP_%s" % utype
		hp_bar.size = Vector2(40, 6)
		hp_bar.color = Color(0.2, 0.8, 0.2)
		hp_bar.position = sprite.position + Vector2(-20, 20)
		hp_bar.modulate = Color(1, 1, 1, 0.8)
		var bg_bar = ColorRect.new()
		bg_bar.name = "HPBG_%s" % utype
		bg_bar.size = Vector2(40, 6)
		bg_bar.color = Color(0.3, 0.1, 0.1)
		bg_bar.position = hp_bar.position
		bg_bar.modulate = Color(1, 1, 1, 0.5)
		parent.add_child(bg_bar)
		parent.add_child(hp_bar)

		var count_label = Label.new()
		count_label.name = "Cnt_%s" % utype
		count_label.text = str(count)
		count_label.add_theme_font_size_override("font_size", 10)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.position = sprite.position + Vector2(-10, -30)
		parent.add_child(count_label)
		idx += 1

func _update_unit_counts(parent: Node2D, units: Dictionary) -> void:
	for utype in units:
		var count = 0
		var val = units[utype]
		if typeof(val) == TYPE_DICTIONARY:
			count = val.get("count", 0)
		else:
			count = int(val)
		var cnt_label = parent.get_node_or_null("Cnt_%s" % utype)
		if cnt_label:
			cnt_label.text = str(count)
		var hp_bar = parent.get_node_or_null("HP_%s" % utype)
		if hp_bar:
			var max_hp = 100
			var current_hp = max(0, count * 10)
			hp_bar.size.x = 40.0 * clampf(float(current_hp) / max_hp, 0.0, 1.0)
			if current_hp < max_hp * 0.3:
				hp_bar.color = Color(0.8, 0.2, 0.2)
			elif current_hp < max_hp * 0.6:
				hp_bar.color = Color(0.8, 0.8, 0.2)

func _clear_units() -> void:
	for c in attacker_units_node.get_children():
		c.queue_free()
	for c in defender_units_node.get_children():
		c.queue_free()
	for c in projectile_layer.get_children():
		c.queue_free()

func _next_round() -> void:
	if _animating:
		return
	if not _battle_state or _battle_state.status != "ongoing":
		_show_result()
		return
	CombatSystem.simulate_round(_battle_state)
	_current_round = _battle_state.current_round
	round_label.text = "راند %d" % _current_round
	_round_timer = 300.0
	_animate_round(_battle_state.rounds_log[-1])

func _animate_round(round_data: Dictionary) -> void:
	_animating = true
	_update_unit_counts(attacker_units_node, round_data.get("attacker_units_remaining", {}))
	_update_unit_counts(defender_units_node, round_data.get("defender_units_remaining", {}))

	var atk_losses = round_data.get("attacker_losses", {})
	var def_losses = round_data.get("defender_losses", {})

	var atk_pos = attacker_units_node.global_position + Vector2(100, 0)
	var def_pos = defender_units_node.global_position + Vector2(-100, 0)

	for utype in def_losses:
		var count = def_losses[utype]
		for i in range(min(count, 3)):
			_spawn_projectile(atk_pos, def_pos + Vector2(randf_range(-60, 60), randf_range(-30, 30)))

	var tween = create_tween()
	tween.tween_callback(_shake_units.bind(defender_units_node, def_losses))
	tween.tween_interval(0.5)
	for utype in atk_losses:
		var count = atk_losses[utype]
		for i in range(min(count, 3)):
			_spawn_projectile(def_pos, atk_pos + Vector2(randf_range(-60, 60), randf_range(-30, 30)))
	tween.tween_callback(_shake_units.bind(attacker_units_node, atk_losses))
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		_animating = false
		if _battle_state and _battle_state.status != "ongoing":
			_show_result()
		else:
			_check_retreat_button()
	)

func _spawn_projectile(from: Vector2, to: Vector2) -> void:
	var proj = ColorRect.new()
	proj.size = Vector2(8, 8)
	proj.color = Color(1.0, 0.8, 0.2, 0.9)
	proj.position = from - Vector2(4, 4)
	projectile_layer.add_child(proj)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(proj, "position", to - Vector2(4, 4), 0.6).set_ease(Tween.EASE_IN)
	tween.tween_property(proj, "color", Color(1.0, 0.8, 0.2, 0.0), 0.5).set_delay(0.1)
	tween.tween_callback(proj.queue_free)

func _shake_units(parent: Node2D, _losses: Dictionary) -> void:
	for child in parent.get_children():
		if child is Sprite2D:
			var orig = child.position
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(child, "position", orig + Vector2(randf_range(-8, 8), randf_range(-4, 4)), 0.05)
			tween.tween_property(child, "position", orig, 0.15).set_delay(0.05)

func _on_timer_timeout() -> void:
	if _battle_state and _battle_state.status == "ongoing":
		_next_round()

func _process(delta: float) -> void:
	if _battle_state and _battle_state.status == "ongoing" and not _animating:
		_round_timer -= delta * TimeManager.time_speed
		var mins = int(_round_timer) / 60
		var secs = int(_round_timer) % 60
		timer_label.text = "%d:%02d" % [mins, secs]
		if _round_timer <= 0:
			_next_round()

func _check_retreat_button() -> void:
	var can_retreat = _battle_state and CombatSystem.can_retreat(_battle_state)
	retreat_btn.visible = can_retreat
	retreat_btn.disabled = not can_retreat

func _retreat() -> void:
	if _battle_state:
		CombatSystem.retreat(_battle_state)
		_show_result()

func _show_result() -> void:
	_animating = false
	result_panel.show()
	var status = _battle_state.status if _battle_state else "unknown"
	match status:
		"attacker_win": result_label.text = "پیروزی مهاجم!"
		"defender_win": result_label.text = "پیروزی مدافع!"
		"retreated": result_label.text = "عقب‌نشینی"
		"draw": result_label.text = "تساوی"
		_: result_label.text = status
	var log = _battle_state.rounds_log if _battle_state else []
	var atk_rem = CombatSystem.count_units(_battle_state.attacker) if _battle_state else 0
	var def_rem = CombatSystem.count_units(_battle_state.defender) if _battle_state else 0
	battle_completed.emit({
		"status": status, "rounds": log,
		"attacker_units_remaining": atk_rem,
		"defender_units_remaining": def_rem
	})
	if _is_player_attacker:
		var npc_id = _battle_state.defender.get("city_id", "")
		if npc_id.begins_with("npc_"):
			GameState.current_npc_cities.erase(npc_id)
			EventBus.notification_added.emit("شهر دشمن نابود شد!", "success")

func _close() -> void:
	hide()
	var cr = get_parent().get_node_or_null("CombatReport")
	if cr:
		cr.show()
