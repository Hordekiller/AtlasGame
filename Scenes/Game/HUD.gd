extends Control

const TOP_BAR_H: float = 56.0
const BOTTOM_BAR_H: float = 88.0

@onready var top_bar: Panel = $TopBar
@onready var city_label: Label = $TopBar/CitySection/CityLabel
@onready var resource_container: HBoxContainer = $TopBar/ResourceContainer
@onready var action_buttons: HBoxContainer = $TopBar/ActionButtons

@onready var bottom_bar: Panel = $BottomBar
@onready var bottom_content: Control = $BottomBar/BottomContent

@onready var building_info: Panel = $BuildingInfo
@onready var building_palette: Panel = $BottomBar/BottomContent/BuildingPalette
@onready var palette_container: GridContainer = $BottomBar/BottomContent/BuildingPalette/Scroll/Grid

@onready var notification_label: Label = $NotificationLabel
@onready var time_label: Label = $TopBar/CitySection/TimeLabel

@onready var cat_buttons: HBoxContainer = $BottomBar/BottomContent/CategoryBar/HBox

var _resource_labels: Dictionary = {}
var _notification_timer: float = 0.0
var _current_category: int = Globals.BuildingCategory.RESOURCE
var _building_buttons: Dictionary = {}

func _ready() -> void:
	_style_ui()
	_setup_resource_display()
	_setup_categories()
	_setup_buildings()
	_connect_signals()
	_setup_action_buttons()

func _style_ui() -> void:
	UITheme.style_panel(top_bar)
	UITheme.style_panel(bottom_bar)
	top_bar.custom_minimum_size.y = TOP_BAR_H
	bottom_bar.custom_minimum_size.y = BOTTOM_BAR_H

func _setup_resource_display() -> void:
	var display_resources = [
		Globals.ResourceType.WOOD,
		Globals.ResourceType.GOLD,
		Globals.ResourceType.FOOD,
		Globals.ResourceType.POPULATION,
		Globals.ResourceType.WORKERS,
	]

	for rt in display_resources:
		var hb = HBoxContainer.new()
		hb.size_flags_horizontal = SIZE_SHRINK_CENTER

		var icon = UITheme.make_resource_icon(rt)
		hb.add_child(icon)

		var vbox = VBoxContainer.new()
		var val_label = Label.new()
		val_label.name = "Val_%d" % rt
		val_label.text = "0"
		val_label.add_theme_color_override("font_color", Globals.get_resource_color(rt))
		val_label.add_theme_font_size_override("font_size", 12)

		var name_label = Label.new()
		name_label.text = Globals.RESOURCE_DISPLAY_NAMES.get(rt, "")
		name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.7))
		name_label.add_theme_font_size_override("font_size", 9)

		vbox.add_child(val_label)
		vbox.add_child(name_label)
		hb.add_child(vbox)

		resource_container.add_child(hb)
		_resource_labels[rt] = val_label

func _setup_action_buttons() -> void:
	var actions = [
		{"name": "ResearchBtn", "icon": "res://Assets/Textures/UI/scientist.png", "callback": "_on_research"},
		{"name": "TradeBtn", "icon": "res://Assets/Textures/UI/ship_transport.png", "callback": "_on_trade"},
		{"name": "MapBtn", "icon": "res://Assets/Textures/UI/btn_world.png", "callback": "_on_map"},
		{"name": "MenuBtn", "icon": "res://Assets/Textures/UI/close.png", "callback": "_on_menu"},
	]

	for a in actions:
		var btn = TextureButton.new()
		btn.name = a.name
		btn.custom_minimum_size = Vector2(36, 36)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		if ResourceLoader.exists(a.icon):
			btn.texture_normal = ResourceLoader.load(a.icon)
			btn.texture_pressed = btn.texture_normal

		var method = Callable(self, a.callback)
		btn.pressed.connect(method)
		action_buttons.add_child(btn)

func _connect_signals() -> void:
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.time_speed_changed.connect(_on_speed_changed)
	EventBus.city_selected.connect(_on_city_selected)
	EventBus.building_selected.connect(_on_building_selected)
	EventBus.notification_added.connect(_on_notification)
	EventBus.game_loaded.connect(update_display)

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
		UITheme.style_button(btn)
		btn.custom_minimum_size = Vector2(70, 30)
		btn.add_theme_font_size_override("font_size", 11)
		cat_buttons.add_child(btn)

	if cat_buttons.get_child_count() > 0:
		cat_buttons.get_child(0).button_pressed = true

func _setup_buildings() -> void:
	var all_defs = BuildingManager.get_all_building_defs()
	var cat_order = {
		Globals.BuildingCategory.RESOURCE: [],
		Globals.BuildingCategory.PRODUCTION: [],
		Globals.BuildingCategory.STORAGE: [],
		Globals.BuildingCategory.INFRASTRUCTURE: [],
		Globals.BuildingCategory.RESEARCH: [],
		Globals.BuildingCategory.MILITARY: [],
		Globals.BuildingCategory.CULTURE: []
	}

	for id in all_defs:
		var defn = all_defs[id]
		var cat = defn.get("category", Globals.BuildingCategory.RESOURCE)
		if not cat_order.has(cat):
			cat_order[cat] = []
		cat_order[cat].append(id)

	palette_container.columns = 4

	for cat in cat_order:
		_building_buttons[cat] = []
		for id in cat_order[cat]:
			var btn = TextureButton.new()
			var defn = all_defs[id]
			var tex = UITheme.get_building_icon(id)
			if tex:
				btn.texture_normal = tex
			btn.custom_minimum_size = Vector2(64, 64)
			btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			btn.tooltip_text = defn.get("name", id)
			btn.pressed.connect(_on_building_selected.bind(id))

			var bg = ColorRect.new()
			bg.color = Color(0.2, 0.25, 0.35, 0.6)
			bg.custom_minimum_size = Vector2(68, 68)
			bg.mouse_filter = Control.MOUSE_FILTER_PASS

			var container = CenterContainer.new()
			container.add_child(btn)
			bg.add_child(container)
			palette_container.add_child(bg)
			_building_buttons[cat].append(bg)
			bg.visible = (cat == _current_category)

func _on_category_selected(cat: int) -> void:
	for btn in cat_buttons.get_children():
		if btn is Button:
			btn.button_pressed = (btn.get_index() == cat_buttons.get_children().find(btn) and btn.is_pressed())

	_current_category = cat
	for c in _building_buttons:
		var vis = c == cat
		for bg in _building_buttons[c]:
			bg.visible = vis

func _on_building_selected(building_id: String) -> void:
	var city_id = GameState.selected_city_id
	if city_id.is_empty():
		return
	var city_view = get_tree().get_first_node_in_group("city_view")
	if city_view and city_view.has_method("enter_placement_mode"):
		city_view.enter_placement_mode(building_id)
		EventBus.notification_added.emit("مکان ساختمان را انتخاب کنید", "info")

func update_display() -> void:
	var city_id = GameState.selected_city_id
	if city_id.is_empty():
		return
	var city = GameState.current_cities.get(city_id)
	if not city:
		return

	city_label.text = city.get("name", "شهر")

	var resources = city.get("resources", {})
	for rt in resources:
		var rti = int(rt)
		if _resource_labels.has(rti):
			var val = resources[rt]
			var lbl = _resource_labels[rti]
			if rti == Globals.ResourceType.WORKERS:
				var used = city.get("total_workers_used", 0)
				lbl.text = "%d/%d" % [used, int(val)]
			elif rti == Globals.ResourceType.POPULATION:
				lbl.text = "%d" % int(val)
			else:
				lbl.text = _fmt(val)

func _fmt(val) -> String:
	if val >= 10000:
		return "%dk" % int(val / 1000)
	elif val >= 1000:
		return "%.1fk" % (val / 1000)
	elif val >= 1:
		return "%d" % int(val)
	return "%.1f" % val

func _on_resource_changed(city_id: String, rtype: String, new_amount: float, _delta: float) -> void:
	if city_id != GameState.selected_city_id:
		return
	var rti = int(rtype)
	if _resource_labels.has(rti):
		var lbl = _resource_labels[rti]
		if rti == Globals.ResourceType.WORKERS:
			var city = GameState.current_cities.get(city_id, {})
			var used = city.get("total_workers_used", 0)
			lbl.text = "%d/%d" % [used, int(new_amount)]
		elif rti == Globals.ResourceType.POPULATION:
			lbl.text = "%d" % int(new_amount)
		else:
			lbl.text = _fmt(new_amount)

func _on_city_selected(city_id: String) -> void:
	GameState.selected_city_id = city_id
	update_display()

func _on_building_selected_signal(city_id: String, grid_pos: Vector2i) -> void:
	if city_id != GameState.selected_city_id:
		return
	if building_info and building_info.has_method("show_for_building"):
		building_info.show_for_building(city_id, grid_pos)

func _on_speed_changed(speed: float) -> void:
	pass

func _on_notification(message: String, _type: String) -> void:
	notification_label.text = message
	notification_label.modulate = Color(1, 1, 1, 1)
	_notification_timer = 3.0

func _on_research() -> void:
	var rp = get_parent().get_node_or_null("ResearchPanel")
	if rp:
		rp.visible = not rp.visible
		if rp.visible and rp.has_method("show_panel"):
			rp.show_panel()

func _on_trade() -> void:
	var tp = get_parent().get_node_or_null("TradePanel")
	if tp:
		tp.visible = not tp.visible
		if tp.visible and tp.has_method("open"):
			tp.open(GameState.selected_city_id)

func _on_map() -> void:
	var game = get_parent()
	if game and game.has_method("switch_to_world_map"):
		game.switch_to_world_map()

func _on_menu() -> void:
	SaveManager.save_game(0)
	get_tree().change_scene_to_file("res://Scenes/Menu/MainMenu.tscn")

func _process(delta: float) -> void:
	var total_seconds = int(GameState.game_time)
	var hours = (total_seconds / 3600) % 24
	var minutes = (total_seconds / 60) % 60
	var secs = total_seconds % 60
	time_label.text = "روز %d  %02d:%02d" % [GameState.current_day, hours, minutes]

	if _notification_timer > 0:
		_notification_timer -= delta
		if _notification_timer <= 0:
			notification_label.text = ""
