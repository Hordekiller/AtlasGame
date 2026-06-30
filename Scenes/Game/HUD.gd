extends Control

const TOP_BAR_H: float = 64.0
const BOTTOM_BAR_H: float = 120.0

@onready var top_bar: Panel = $TopBar
@onready var city_label: Label = $TopBar/CitySection/CityLabel
@onready var city_icon: TextureRect = $TopBar/CitySection/CityIcon
@onready var resource_container: HBoxContainer = $TopBar/ResourceContainer
@onready var action_buttons: HBoxContainer = $TopBar/ActionButtons

@onready var bottom_bar: Panel = $BottomBar
@onready var bottom_content: Control = $BottomBar/BottomContent

@onready var building_info: Panel = $BuildingInfo
@onready var building_palette: Panel = $BottomBar/BottomContent/BuildingPalette
@onready var palette_scroll: ScrollContainer = $BottomBar/BottomContent/BuildingPalette/Scroll
@onready var palette_container: GridContainer = $BottomBar/BottomContent/BuildingPalette/Scroll/Grid

@onready var notification_label: Label = $NotificationLabel
@onready var time_label: Label = $TopBar/CitySection/TimeLabel
@onready var attack_alert: Panel = $AttackAlert

@onready var cat_buttons: HBoxContainer = $BottomBar/BottomContent/CategoryBar/HBox

@onready var advisor_bar: VBoxContainer = $AdvisorBar
@onready var town_btn: TextureButton = $AdvisorBar/TownBtn
@onready var commander_btn: TextureButton = $AdvisorBar/CommanderBtn
@onready var military_btn: TextureButton = $AdvisorBar/MilitaryBtn
@onready var research_btn: TextureButton = $AdvisorBar/ResearchBtn
@onready var quest_btn: TextureButton = $AdvisorBar/QuestBtn
@onready var event_btn: TextureButton = $AdvisorBar/EventBtn
@onready var diplomacy_btn: TextureButton = $AdvisorBar/DiplomacyBtn
@onready var alliance_btn: TextureButton = $AdvisorBar/AllianceBtn

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
	_setup_advisor_bar()
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	_update_responsive()

func _update_responsive() -> void:
	var s = ResponsiveLayout.scale_factor
	top_bar.custom_minimum_size.y = max(TOP_BAR_H, ResponsiveLayout.get_top_bar_h())
	bottom_bar.custom_minimum_size.y = max(BOTTOM_BAR_H, ResponsiveLayout.get_bottom_bar_h())
	palette_container.columns = ResponsiveLayout.get_building_grid_columns()
	var ts = ResponsiveLayout.MIN_TOUCH_TARGET * s
	for btn in action_buttons.get_children():
		if btn is TextureButton:
			btn.custom_minimum_size = Vector2(ts, ts)
	for rt in _resource_labels:
		var lbl = _resource_labels[rt]
		lbl.add_theme_font_size_override("font_size", ResponsiveLayout.font_size(12))
	for btn in advisor_bar.get_children():
		if btn is TextureButton:
			btn.custom_minimum_size = Vector2(max(88, ts), max(88, ts))

func _style_ui() -> void:
	UITheme.style_panel(top_bar)
	UITheme.style_panel(bottom_bar)
	_update_responsive()
	if ResourceLoader.exists("res://Assets/Textures/UI/city_icon.png"):
		city_icon.texture = ResourceLoader.load("res://Assets/Textures/UI/city_icon.png")

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
		{"name": "MapBtn", "icon": "res://Assets/Textures/UI/btn_world.png", "callback": "_on_map"},
		{"name": "MenuBtn", "icon": "res://Assets/Textures/UI/close.png", "callback": "_on_menu"},
	]

	for a in actions:
		var btn = TextureButton.new()
		btn.name = a.name
		var ts = ResponsiveLayout.MIN_TOUCH_TARGET * ResponsiveLayout.scale_factor
		btn.custom_minimum_size = Vector2(ts, ts)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		if ResourceLoader.exists(a.icon):
			btn.texture_normal = ResourceLoader.load(a.icon)
			btn.texture_pressed = btn.texture_normal

		var method = Callable(self, a.callback)
		btn.pressed.connect(method)
		action_buttons.add_child(btn)

func _setup_advisor_bar() -> void:
	var advisors = [
		{"node": town_btn, "icon": "res://Assets/Textures/UI/city_icon.png", "callback": "_on_town"},
		{"node": commander_btn, "icon": "res://Assets/Textures/UI/sword.png", "callback": "_on_commander"},
		{"node": military_btn, "icon": "res://Assets/Textures/UI/btn_world.png", "callback": "_on_military"},
		{"node": research_btn, "icon": "res://Assets/Textures/UI/scientist.png", "callback": "_on_research"},
		{"node": quest_btn, "icon": "res://Assets/Textures/UI/check.png", "callback": "_on_quest"},
		{"node": event_btn, "icon": "res://Assets/Textures/UI/time.png", "callback": "_on_event"},
		{"node": diplomacy_btn, "icon": "res://Assets/Textures/UI/ship_transport.png", "callback": "_on_diplomacy"},
		{"node": alliance_btn, "icon": "res://Assets/Textures/UI/close.png", "callback": "_on_alliance"},
	]
	for a in advisors:
		if ResourceLoader.exists(a.icon):
			a.node.texture_normal = ResourceLoader.load(a.icon)
		a.node.pressed.connect(Callable(self, a.callback))

func _connect_signals() -> void:
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.time_speed_changed.connect(_on_speed_changed)
	EventBus.city_selected.connect(_on_city_selected)
	EventBus.building_selected.connect(_on_building_selected_signal)
	EventBus.notification_added.connect(_on_notification)
	EventBus.game_loaded.connect(update_display)
	EventBus.battle_initiated.connect(_on_battle_initiated)
	EventBus.battle_completed.connect(_on_battle_completed)

func _setup_categories() -> void:
	var categories = [
		Globals.BuildingCategory.RESOURCE,
		Globals.BuildingCategory.PRODUCTION,
		Globals.BuildingCategory.STORAGE,
		Globals.BuildingCategory.INFRASTRUCTURE,
		Globals.BuildingCategory.RESEARCH,
		Globals.BuildingCategory.MILITARY,
		Globals.BuildingCategory.CULTURE,
		Globals.BuildingCategory.SPECIAL,
		Globals.BuildingCategory.REDUCTION
	]

	var names = {
		Globals.BuildingCategory.RESOURCE: "منابع",
		Globals.BuildingCategory.PRODUCTION: "تولید",
		Globals.BuildingCategory.STORAGE: "انبار",
		Globals.BuildingCategory.INFRASTRUCTURE: "زیرساخت",
		Globals.BuildingCategory.RESEARCH: "پژوهش",
		Globals.BuildingCategory.MILITARY: "نظامی",
		Globals.BuildingCategory.CULTURE: "فرهنگ",
		Globals.BuildingCategory.SPECIAL: "ویژه",
		Globals.BuildingCategory.REDUCTION: "تخفیف"
	}

	for cat in categories:
		var btn = Button.new()
		btn.text = names.get(cat, "")
		btn.toggle_mode = true
		btn.pressed.connect(_on_category_selected.bind(cat))
		UITheme.style_button(btn)
		var s = ResponsiveLayout.scale_factor
		btn.custom_minimum_size = Vector2(88, 36)
		btn.add_theme_font_size_override("font_size", ResponsiveLayout.font_size(11))
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
		Globals.BuildingCategory.CULTURE: [],
		Globals.BuildingCategory.SPECIAL: [],
		Globals.BuildingCategory.REDUCTION: []
	}

	for id in all_defs:
		var defn = all_defs[id]
		var cat = defn.get("category", Globals.BuildingCategory.RESOURCE)
		if not cat_order.has(cat):
			cat_order[cat] = []
		cat_order[cat].append(id)

	palette_container.columns = ResponsiveLayout.get_building_grid_columns()

	for cat in cat_order:
		_building_buttons[cat] = []
		for id in cat_order[cat]:
			var btn = TextureButton.new()
			var defn = all_defs[id]
			var tex = UITheme.get_building_icon(id)
			if tex:
				btn.texture_normal = tex
			btn.custom_minimum_size = Vector2(88, 88)
			btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			btn.tooltip_text = defn.get("name", id)
			btn.pressed.connect(_on_building_selected.bind(id))

			var bg = ColorRect.new()
			bg.color = Color(0.2, 0.25, 0.35, 0.6)
			bg.custom_minimum_size = Vector2(92, 92)
			bg.mouse_filter = Control.MOUSE_FILTER_PASS

			var container = CenterContainer.new()
			container.add_child(btn)
			bg.add_child(container)
			palette_container.add_child(bg)
			_building_buttons[cat].append(bg)
			bg.visible = (cat == _current_category)

func _on_category_selected(cat: int) -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	for btn in cat_buttons.get_children():
		if btn is Button:
			btn.button_pressed = (btn.get_index() == cat_buttons.get_children().find(btn) and btn.is_pressed())

	_current_category = cat
	for c in _building_buttons:
		var vis = c == cat
		for bg in _building_buttons[c]:
			bg.visible = vis

func _on_building_selected(building_id: String) -> void:
	HapticManager.button_press()
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
	var speed_names = {0.5: "آهسته", 1.0: "عادی", 2.0: "سریع", 3.0: "خیلی سریع"}
	UIManager.show_notification("سرعت: " + speed_names.get(speed, str(speed)), "info")

func _on_battle_initiated(_attacker_id: String, defender_id: String) -> void:
	if defender_id == GameState.selected_city_id:
		attack_alert.visible = true
		AudioManager.play_error()

func _on_battle_completed(_battle_id: String, _winner: String) -> void:
	attack_alert.visible = false
	_update_all_attack_alerts()

func _update_all_attack_alerts() -> void:
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		if city.get("under_attack", false):
			attack_alert.visible = true
			return
	attack_alert.visible = false

func _on_notification(message: String, _type: String) -> void:
	notification_label.text = message
	notification_label.modulate = Color(1, 1, 1, 1)
	_notification_timer = 3.0

func _on_town() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	building_info.hide()
	var game = get_parent()
	if game and game.has_method("switch_to_city_view"):
		game.switch_to_city_view()

func _on_commander() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	var cp = get_parent().get_node_or_null("CommanderPanel")
	if cp:
		cp.visible = not cp.visible
		if cp.visible and cp.has_method("open"):
			cp.open()

func _on_quest() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	var qp = get_parent().get_node_or_null("QuestPanel")
	if qp:
		qp.visible = not qp.visible
		if qp.visible and qp.has_method("open"):
			qp.open()

func _on_event() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	var ep = get_parent().get_node_or_null("EventPanel")
	if ep:
		ep.visible = not ep.visible
		if ep.visible and ep.has_method("open"):
			ep.open()

func _on_research() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	var rp = get_parent().get_node_or_null("ResearchPanel")
	if rp:
		rp.visible = not rp.visible
		if rp.visible and rp.has_method("show_panel"):
			rp.show_panel()

func _on_military() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	var mp = get_parent().get_node_or_null("MilitaryPanel")
	if mp:
		mp.visible = not mp.visible
		if mp.visible and mp.has_method("open"):
			mp.open(GameState.selected_city_id)

func _on_diplomacy() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	var tp = get_parent().get_node_or_null("TradePanel")
	if tp:
		tp.visible = not tp.visible
		if tp.visible and tp.has_method("open"):
			tp.open(GameState.selected_city_id)

func _on_alliance() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	get_parent().get_node_or_null("AllyPanel").visible = not get_parent().get_node_or_null("AllyPanel").visible if get_parent().get_node_or_null("AllyPanel") else null

func _on_map() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
	var game = get_parent()
	if game and game.has_method("switch_to_world_map"):
		game.switch_to_world_map()

func _on_menu() -> void:
	AudioManager.play_button_click()
	HapticManager.button_press()
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

	if attack_alert.visible:
		attack_alert.modulate = Color(1, 1, 1, 0.7 + sin(GameState.game_time * 4.0) * 0.3)
