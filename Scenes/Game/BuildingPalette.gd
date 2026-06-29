extends Control

@onready var building_list: VBoxContainer = $ScrollContainer/BuildingList
@onready var category_buttons: HBoxContainer = $CategoryButtons

var _current_category: int = -1
var _building_buttons: Dictionary = {}

func _ready() -> void:
	_setup_categories()
	_setup_buildings()

func _setup_categories() -> void:
	var categories = [
		Globals.BuildingCategory.RESOURCE,
		Globals.BuildingCategory.PRODUCTION,
		Globals.BuildingCategory.STORAGE,
		Globals.BuildingCategory.INFRASTRUCTURE,
		Globals.BuildingCategory.RESEARCH,
		Globals.BuildingCategory.MILITARY,
		Globals.BuildingCategory.CULTURE
	]

	var names = {
		Globals.BuildingCategory.RESOURCE: "منابع",
		Globals.BuildingCategory.PRODUCTION: "تولید",
		Globals.BuildingCategory.STORAGE: "انبار",
		Globals.BuildingCategory.INFRASTRUCTURE: "زیرساخت",
		Globals.BuildingCategory.RESEARCH: "پژوهش",
		Globals.BuildingCategory.MILITARY: "نظامی",
		Globals.BuildingCategory.CULTURE: "فرهنگ"
	}

	for cat in categories:
		var btn = Button.new()
		btn.text = names.get(cat, "")
		btn.toggle_mode = true
		btn.pressed.connect(_on_category_selected.bind(cat))
		category_buttons.add_child(btn)

func _setup_buildings() -> void:
	var all_defs = BuildingManager.get_all_building_defs()
	for id in all_defs:
		var defn = all_defs[id]
		var btn = Button.new()
		btn.text = defn.get("name", id)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.tooltip_text = defn.get("description", "")
		btn.pressed.connect(_on_building_selected.bind(id))

		var category = defn.get("category", -1)
		if not _building_buttons.has(category):
			_building_buttons[category] = []
		_building_buttons[category].append(btn)
		building_list.add_child(btn)
		btn.hide()

func _on_category_selected(cat: int) -> void:
	for btn in category_buttons.get_children():
		if btn is Button:
			btn.button_pressed = btn.is_pressed()

	_current_category = cat
	_filter_buildings()

func _filter_buildings() -> void:
	for cat in _building_buttons:
		var visible = cat == _current_category
		for btn in _building_buttons[cat]:
			btn.visible = visible

func _on_building_selected(building_id: String) -> void:
	var city_id = GameState.selected_city_id
	if city_id.is_empty():
		return

	var city_view = get_tree().get_first_node_in_group("city_view")
	if city_view:
		city_view.enter_placement_mode(building_id)
		UIManager.show_notification("مکان ساختمان را انتخاب کنید", "info")
