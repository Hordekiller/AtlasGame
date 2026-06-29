extends Panel

var _target_island_id: String = ""
var _source_city_id: String = ""

@onready var title_label: Label = $VBox/TitleLabel
@onready var cost_label: Label = $VBox/CostLabel
@onready var city_name_input: LineEdit = $VBox/CityNameInput
@onready var colonize_btn: Button = $VBox/ColonizeBtn
@onready var cancel_btn: Button = $VBox/CancelBtn

func _ready() -> void:
	hide()
	UITheme.style_panel(self)
	UITheme.style_button(colonize_btn)
	UITheme.style_button(cancel_btn)
	cancel_btn.pressed.connect(_on_cancel)
	colonize_btn.pressed.connect(_on_colonize)
	city_name_input.add_theme_font_size_override("font_size", 14)

func show_for_island(island_id: String, source_cities: Array) -> void:
	_target_island_id = island_id
	var island = GameState.current_islands.get(island_id, {})
	title_label.text = "استعمار " + island.get("name", "")

	if source_cities.is_empty():
		title_label.text = "نیاز به بندر!"
		cost_label.text = "برای استعمار ابتدا یک بندر بسازید."
		colonize_btn.disabled = true
		return

	_source_city_id = source_cities[0]
	var cost = WorldManager.colony_cost()
	var cost_text = "هزینه استعمار: "
	for rtype in cost:
		cost_text += Globals.get_resource_name(rtype) + ": " + str(cost[rtype]) + "  "
	cost_label.text = cost_text

	var can_afford = EconomyManager.can_afford(_source_city_id, cost)
	colonize_btn.disabled = not can_afford
	if not can_afford:
		colonize_btn.text = "منابع کافی نیست"
	else:
		colonize_btn.text = "استعمار کن"

	city_name_input.text = island.get("name", "").trim_prefix("جزیره ").strip_edges() + " شهر"
	show()

func _on_colonize() -> void:
	var name_text = city_name_input.text.strip_edges()
	if name_text.is_empty():
		name_text = "شهر جدید"
	var result = WorldManager.colonize_island(_source_city_id, _target_island_id, name_text)
	if result != "":
		EventBus.notification_added.emit("شهر " + name_text + " تأسیس شد!", "success")
		hide()
		EventBus.city_selected.emit(result)
		var game = get_parent()
		if game and game.has_method("switch_to_city_view"):
			game.switch_to_city_view()
	else:
		EventBus.notification_added.emit("استعمار ناموفق!", "error")

func _on_cancel() -> void:
	hide()
