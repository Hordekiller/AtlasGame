extends Panel

@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var title_label: Label = $VBox/Title
@onready var result_label: Label = $VBox/Result
@onready var loot_container: VBoxContainer = $VBox/LootContainer
@onready var casualties_container: VBoxContainer = $VBox/CasualtiesContainer
@onready var rounds_container: VBoxContainer = $VBox/RoundsScroll/RoundsContainer
@onready var attacker_label: Label = $VBox/AttackerLabel
@onready var defender_label: Label = $VBox/DefenderLabel
@onready var rounds_scroll: ScrollContainer = $VBox/RoundsScroll
@onready var round_tab_btn: Button = $VBox/TabBar/RoundTab
@onready var casualty_tab_btn: Button = $VBox/TabBar/CasualtyTab
@onready var loot_tab_btn: Button = $VBox/TabBar/LootTab

var _battle_result: Dictionary = {}

func _ready() -> void:
	UITheme.style_panel(self)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(_close)
	EventBus.battle_result.connect(_on_battle_result)
	round_tab_btn.pressed.connect(_show_rounds)
	casualty_tab_btn.pressed.connect(_show_casualties)
	loot_tab_btn.pressed.connect(_show_loot)
	hide()
	get_viewport().size_changed.connect(_update_responsive)

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(600, vp.size.x * 0.9), min(500, vp.size.y * 0.85)))
	custom_minimum_size = sz
	size = sz

func _on_battle_result(battle_id: String, winner: String, loot: Dictionary, casualties: Dictionary) -> void:
	var city = GameState.current_cities.get(winner, {})
	var winner_name = city.get("name", winner) if city else winner
	var loser_id = battle_id.split("_vs_")[1] if "_vs_" in battle_id else ""
	var loser_city = GameState.current_cities.get(loser_id, {})
	var loser_name = loser_city.get("name", loser_id) if loser_city else loser_id

	title_label.text = "گزارش نبرد"

	var is_attacker_win = true
	if "_vs_" in battle_id:
		var parts = battle_id.split("_vs_")
		if parts.size() > 1:
			is_attacker_win = parts[0] == winner

	if is_attacker_win:
		result_label.text = "پیروزی! %s" % winner_name
		result_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		result_label.text = "شکست! %s" % winner_name
		result_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	attacker_label.text = "مهاجم: " + (battle_id.split("_vs_")[0] if "_vs_" in battle_id else "")
	defender_label.text = "مدافع: " + loser_name

	_battle_result = {"battle_id": battle_id, "winner": winner, "loot": loot, "casualties": casualties}
	_show_casualties()

func _show_rounds() -> void:
	round_tab_btn.button_pressed = true
	casualty_tab_btn.button_pressed = false
	loot_tab_btn.button_pressed = false
	rounds_scroll.show()
	loot_container.hide()
	casualties_container.hide()

	for child in rounds_container.get_children():
		child.queue_free()
	for r in _battle_result.get("rounds", []):
		var lbl = Label.new()
		lbl.text = "راند %d: مهاجم %d | مدافع %d" % [r.get("round", 0), r.get("attacker_units_remaining", 0), r.get("defender_units_remaining", 0)]
		lbl.add_theme_font_size_override("font_size", 11)
		var skills = r.get("skills_triggered", [])
		if not skills.is_empty():
			lbl.text += " 🎯 " + ", ".join(skills)
		rounds_container.add_child(lbl)

func _show_casualties() -> void:
	round_tab_btn.button_pressed = false
	casualty_tab_btn.button_pressed = true
	loot_tab_btn.button_pressed = false
	rounds_scroll.hide()
	loot_container.hide()
	casualties_container.show()

	for child in casualties_container.get_children():
		child.queue_free()

	var casualties = _battle_result.get("casualties", {})
	if casualties.is_empty():
		var lbl = Label.new()
		lbl.text = "تلفاتی گزارش نشده"
		casualties_container.add_child(lbl)
	else:
		var title_lbl = Label.new()
		title_lbl.text = "تلفات:"
		title_lbl.add_theme_font_size_override("font_size", 14)
		casualties_container.add_child(title_lbl)

		var atk_losses = casualties.get("attacker_losses", {})
		if not atk_losses.is_empty():
			var lbl = Label.new()
			lbl.text = "مهاجم:"
			lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
			casualties_container.add_child(lbl)
			for utype in atk_losses:
				var defn = MilitaryManager.get_unit_def(utype)
				var uname = defn.get("name", utype) if defn else utype
				var clbl = Label.new()
				clbl.text = "%s: %d" % [uname, atk_losses[utype]]
				casualties_container.add_child(clbl)

		var def_losses = casualties.get("defender_losses", {})
		if not def_losses.is_empty():
			var lbl = Label.new()
			lbl.text = "مدافع:"
			lbl.add_theme_color_override("font_color", Color(0.3, 0.5, 0.9))
			casualties_container.add_child(lbl)
			for utype in def_losses:
				var defn = MilitaryManager.get_unit_def(utype)
				var uname = defn.get("name", utype) if defn else utype
				var clbl = Label.new()
				clbl.text = "%s: %d" % [uname, def_losses[utype]]
				casualties_container.add_child(clbl)

func _show_loot() -> void:
	round_tab_btn.button_pressed = false
	casualty_tab_btn.button_pressed = false
	loot_tab_btn.button_pressed = true
	rounds_scroll.hide()
	loot_container.show()
	casualties_container.hide()

	for child in loot_container.get_children():
		child.queue_free()

	var loot = _battle_result.get("loot", {})
	if loot.is_empty():
		var lbl = Label.new()
		lbl.text = "غارتی وجود ندارد"
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		loot_container.add_child(lbl)
	else:
		var title_lbl = Label.new()
		title_lbl.text = "غارت:"
		title_lbl.add_theme_font_size_override("font_size", 14)
		loot_container.add_child(title_lbl)
		for rtype in loot:
			var lbl = Label.new()
			var rname = Globals.RESOURCE_DISPLAY_NAMES.get(int(rtype), str(rtype))
			lbl.text = "%s: %d" % [rname, loot[rtype]]
			lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
			loot_container.add_child(lbl)

func _close() -> void:
	hide()
