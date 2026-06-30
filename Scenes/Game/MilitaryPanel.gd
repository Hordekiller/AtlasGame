extends Panel

@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var tabs: TabContainer = $VBox/Tabs
@onready var training_container: VBoxContainer = $VBox/Tabs/LandUnits/Scroll/Container
@onready var navy_container: VBoxContainer = $VBox/Tabs/Navy/Scroll/Container
@onready var city_units_label: Label = $VBox/CityUnitsLabel

var _current_city_id: String = ""

func _ready() -> void:
	UITheme.style_panel(self)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(_hide_panel)
	EventBus.resource_changed.connect(_on_resource_changed)
	hide()
	get_viewport().size_changed.connect(_update_responsive)

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(500, vp.size.x * 0.85), min(400, vp.size.y * 0.75)))
	custom_minimum_size = sz
	size = sz

func open(city_id: String) -> void:
	_current_city_id = city_id
	show()
	_refresh_all()

func _hide_panel() -> void:
	hide()

func _refresh_all() -> void:
	_refresh_training()
	_refresh_navy()
	_refresh_city_units()

func _refresh_training() -> void:
	for child in training_container.get_children():
		child.queue_free()

	var units = MilitaryManager.get_units_for_building("barracks")
	for unit_type in units:
		var defn = MilitaryManager.get_unit_def(unit_type)
		if defn.get("naval", false):
			continue
		_add_unit_row(training_container, unit_type, defn)

func _refresh_navy() -> void:
	for child in navy_container.get_children():
		child.queue_free()

	var all_units = MilitaryManager.get_units_for_building("shipyard")
	for unit_type in all_units:
		var defn = MilitaryManager.get_unit_def(unit_type)
		if not defn.get("naval", false):
			continue
		_add_unit_row(navy_container, unit_type, defn)

func _add_unit_row(container: VBoxContainer, unit_type: String, defn: Dictionary) -> void:
	var hbox = HBoxContainer.new()
	var city_data = GameState.current_cities.get(_current_city_id, {})
	var city_units = city_data.get("units", {})
	var existing = city_units.get(unit_type, {})
	var count = existing.get("count", 0)
	var training = existing.get("training", 0)

	var info = Label.new()
	var cost_str = ""
	var costs = defn.get("cost", {})
	for rtype in costs:
		if not cost_str.is_empty():
			cost_str += ", "
		cost_str += "%d %s" % [costs[rtype], Globals.RESOURCE_DISPLAY_NAMES.get(rtype, str(rtype))]

	var unit_name = defn.get("name", unit_type)
	var hp = defn.get("health", 0)
	var atk = defn.get("attack", 0)
	var dfs = defn.get("defense", 0)
	info.text = "%s [HP:%d ATK:%d DEF:%d]\nموجود: %d | در آموزش: %d\nهزینه: %s" % [unit_name, hp, atk, dfs, count, training, cost_str]
	info.add_theme_font_size_override("font_size", 10)
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	hbox.add_child(info)

	var can_afford = EconomyManager.can_afford(_current_city_id, costs)
	var train_btn = Button.new()
	train_btn.text = "آموزش ۱"
	train_btn.disabled = not can_afford
	UITheme.style_button(train_btn)
	train_btn.pressed.connect(_on_train_unit.bind(unit_type, 1))
	hbox.add_child(train_btn)

	var train5_btn = Button.new()
	train5_btn.text = "آموزش ۵"
	train5_btn.disabled = not can_afford
	UITheme.style_button(train5_btn)
	train5_btn.pressed.connect(_on_train_unit.bind(unit_type, 5))
	hbox.add_child(train5_btn)

	container.add_child(hbox)

func _on_train_unit(unit_type: String, count: int) -> void:
	var result = MilitaryManager.train_units(_current_city_id, unit_type, count)
	if result:
		AudioManager.play_build()
		UIManager.show_notification("آموزش واحد شروع شد!", "success")
		_refresh_all()
	else:
		UIManager.show_notification("منابع کافی نیست!", "error")

func _refresh_city_units() -> void:
	var city_data = GameState.current_cities.get(_current_city_id, {})
	var units = city_data.get("units", {})
	if units.is_empty():
		city_units_label.text = "هیچ واحد نظامی در شهر وجود ندارد"
		return
	var parts = []
	for unit_type in units:
		var defn = MilitaryManager.get_unit_def(unit_type)
		var name = defn.get("name", unit_type) if defn else unit_type
		var cnt = units[unit_type].get("count", 0)
		if cnt > 0:
			parts.append("%s: %d" % [name, cnt])
	city_units_label.text = "واحدهای شهر: " + ", ".join(parts)

func _on_resource_changed(city_id: String, _rtype: String, _new_amount: float, _delta: float) -> void:
	if city_id == _current_city_id and visible:
		_refresh_all()
