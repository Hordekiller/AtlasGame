extends Panel

@onready var building_icon: TextureRect = $VBox/Header/IconBox/BuildingIcon
@onready var name_label: Label = $VBox/Header/NameLabel
@onready var level_label: Label = $VBox/LevelLabel
@onready var status_label: Label = $VBox/StatusLabel
@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var progress_bar: ProgressBar = $VBox/ProgressBar
@onready var desc_label: Label = $VBox/DescLabel
@onready var worker_hbox: HBoxContainer = $VBox/WorkerHBox
@onready var worker_dec_btn: TextureButton = $VBox/WorkerHBox/WorkerDec
@onready var worker_count_label: Label = $VBox/WorkerHBox/WorkerCount
@onready var worker_inc_btn: TextureButton = $VBox/WorkerHBox/WorkerInc
@onready var upgrade_btn: Button = $VBox/UpgradeBtn
@onready var demolish_btn: Button = $VBox/DemolishBtn
@onready var production_container: VBoxContainer = $VBox/ProductionContainer

var _current_city_id: String = ""
var _current_grid_pos: Vector2i = Vector2i(-1, -1)
var _current_building_data: Dictionary = {}
var _current_defn: Dictionary = {}

func _ready() -> void:
	UITheme.style_panel(self)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(hide)
	upgrade_btn.pressed.connect(_on_upgrade)
	demolish_btn.pressed.connect(_on_demolish)
	worker_dec_btn.pressed.connect(_on_worker_dec)
	worker_inc_btn.pressed.connect(_on_worker_inc)
	EventBus.building_upgrade_progress.connect(_on_progress_update)
	EventBus.building_construct_progress.connect(_on_progress_update)
	EventBus.resource_changed.connect(_on_resource_changed_for_workers)
	UITheme.style_button(upgrade_btn)
	UITheme.style_button(demolish_btn)
	_style_worker_buttons()
	hide()

func _style_worker_buttons() -> void:
	for btn in [worker_dec_btn, worker_inc_btn]:
		if ResourceLoader.exists("res://Assets/Textures/UI/btn_min.png"):
			btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/btn_min.png")
		if ResourceLoader.exists("res://Assets/Textures/UI/btn_max.png"):
			btn.texture_pressed = ResourceLoader.load("res://Assets/Textures/UI/btn_max.png")

func show_for_building(city_id: String, grid_pos: Vector2i) -> void:
	_current_city_id = city_id
	_current_grid_pos = grid_pos
	var city = GameState.current_cities.get(city_id)
	if not city:
		return
	var bd = city.get("buildings", {}).get(grid_pos)
	if not bd:
		return
	var defn = BuildingManager.get_building_def(bd.get("id", ""))
	if not defn:
		return
	_current_building_data = bd
	_current_defn = defn
	_update_all()
	show()

func _update_all() -> void:
	name_label.text = _current_defn.get("name", "ساختمان")
	var tex = UITheme.get_building_icon(_current_building_data.get("id", ""))
	if tex:
		building_icon.texture = tex

	var constructing = _current_building_data.get("constructing", false)
	var upgrading = _current_building_data.get("upgrading", false)
	var level = _current_building_data.get("level", 1)

	if constructing:
		status_label.text = "در حال ساخت..."
		status_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
		level_label.text = ""
		progress_bar.show()
		var total = _current_building_data.get("construct_time_total", 1.0)
		var left = _current_building_data.get("construct_time_left", total)
		progress_bar.value = 1.0 - (left / max(total, 0.01))
		progress_bar.max_value = 1.0
	elif upgrading:
		status_label.text = "در حال ارتقاء..."
		status_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1))
		level_label.text = "سطح %d → %d" % [level, _current_building_data.get("target_level", level + 1)]
		progress_bar.show()
		var total = _current_building_data.get("upgrade_time_total", 1.0)
		var left = _current_building_data.get("upgrade_time_left", total)
		progress_bar.value = 1.0 - (left / max(total, 0.01))
		progress_bar.max_value = 1.0
	else:
		status_label.text = "فعال"
		status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		level_label.text = "سطح %d/%d" % [level, _current_defn.get("max_level", 10)]
		progress_bar.hide()

	desc_label.text = _current_defn.get("description", "")

	upgrade_btn.disabled = constructing or upgrading
	if constructing:
		upgrade_btn.text = "در حال ساخت..."
	elif upgrading:
		upgrade_btn.text = "در حال ارتقاء..."
	elif level >= _current_defn.get("max_level", 10):
		upgrade_btn.disabled = true
		upgrade_btn.text = "حداکثر سطح"
	else:
		upgrade_btn.text = "ارتقاء ⬆"

	demolish_btn.disabled = constructing or upgrading

	_update_worker_display()
	_update_production_display()

func _update_worker_display() -> void:
	var level = _current_building_data.get("level", 1)
	var assigned = _current_building_data.get("workers_assigned", 0)
	var needed = BuildingManager.get_workers_needed(_current_building_data.get("id", ""), level)
	var not_constructing = not _current_building_data.get("constructing", false)

	worker_hbox.visible = not_constructing

	if not_constructing:
		var city = GameState.current_cities.get(_current_city_id, {})
		var total_pop = int(city.get("resources", {}).get(Globals.ResourceType.POPULATION, 0))
		var total_used = city.get("total_workers_used", 0)
		var available = max(0, total_pop - total_used + assigned)

		worker_count_label.text = "%d / %d" % [assigned, needed]
		worker_dec_btn.disabled = assigned <= 0
		worker_inc_btn.disabled = assigned >= needed or available <= 0

func _update_production_display() -> void:
	for child in production_container.get_children():
		child.queue_free()

	var level = _current_building_data.get("level", 1)
	var assigned = _current_building_data.get("workers_assigned", 0)
	var needed = BuildingManager.get_workers_needed(_current_building_data.get("id", ""), level)
	var ratio = 1.0
	if needed > 0:
		ratio = float(assigned) / float(needed)

	var prod = _current_defn.get("production", {})
	for rtype in prod:
		var amount = prod[rtype] * level * ratio
		var label = Label.new()
		label.text = "+%.1f %s" % [amount, Globals.RESOURCE_DISPLAY_NAMES.get(rtype, str(rtype))]
		label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		label.add_theme_font_size_override("font_size", 11)
		production_container.add_child(label)

	var cons = _current_defn.get("consumption", {})
	for rtype in cons:
		var amount = cons[rtype] * level * ratio
		var label = Label.new()
		label.text = "-%.1f %s" % [amount, Globals.RESOURCE_DISPLAY_NAMES.get(rtype, str(rtype))]
		label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		label.add_theme_font_size_override("font_size", 11)
		production_container.add_child(label)

	if ratio < 1.0:
		var eff = Label.new()
		eff.text = "⏳ بازده: %d%%" % (ratio * 100)
		eff.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
		eff.add_theme_font_size_override("font_size", 10)
		production_container.add_child(eff)

	var constructing = _current_building_data.get("constructing", false)
	var upgrading = _current_building_data.get("upgrading", false)
	if not constructing and not upgrading:
		var upgrade_costs = _current_defn.get("upgrade_costs", {})
		if not upgrade_costs.is_empty() and level < _current_defn.get("max_level", 10):
			var costs_text = ""
			var first = true
			for rtype in upgrade_costs:
				if not first:
					costs_text += ", "
				var amount = upgrade_costs[rtype] * level
				costs_text += "%.0f %s" % [amount, Globals.RESOURCE_DISPLAY_NAMES.get(rtype, str(rtype))]
				first = false
			var cost_label = Label.new()
			cost_label.text = "🏗 " + costs_text
			cost_label.add_theme_font_size_override("font_size", 10)
			cost_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
			production_container.add_child(cost_label)

func _on_worker_inc() -> void:
	if _current_grid_pos.x < 0:
		return
	var assigned = _current_building_data.get("workers_assigned", 0)
	var needed = BuildingManager.get_workers_needed(_current_building_data.get("id", ""), _current_building_data.get("level", 1))
	if assigned < needed:
		BuildingManager.set_workers(_current_city_id, _current_grid_pos, assigned + 1)
		_update_worker_display()
		_update_production_display()
		_update_building_scene_workers()

func _on_worker_dec() -> void:
	if _current_grid_pos.x < 0:
		return
	var assigned = _current_building_data.get("workers_assigned", 0)
	if assigned > 0:
		BuildingManager.set_workers(_current_city_id, _current_grid_pos, assigned - 1)
		_update_worker_display()
		_update_production_display()
		_update_building_scene_workers()

func _update_building_scene_workers() -> void:
	var city_view = get_tree().get_first_node_in_group("city_view")
	if city_view and is_instance_valid(city_view):
		var key = Vector2i(_current_grid_pos.x, _current_grid_pos.y)
		if city_view._building_nodes.has(key):
			var b = city_view._building_nodes[key]
			if b and is_instance_valid(b) and b.has_method("update_workers"):
				b.update_workers()

func _on_resource_changed_for_workers(_city_id: String, _rtype: String, _new_amount: float, _delta: float) -> void:
	if _city_id == _current_city_id and is_visible_in_tree():
		_update_worker_display()

func _on_progress_update(city_id: String, grid_pos: Vector2i, _progress: float, _total: float) -> void:
	if city_id == _current_city_id and grid_pos == _current_grid_pos:
		var city = GameState.current_cities.get(city_id)
		if city:
			var bd = city.get("buildings", {}).get(grid_pos, {})
			if not bd.is_empty():
				_current_building_data = bd
				_update_all()

func _on_upgrade() -> void:
	if _current_grid_pos.x >= 0:
		var result = BuildingManager.upgrade_building(_current_city_id, _current_grid_pos)
		if result:
			UIManager.show_notification("ارتقاء شروع شد!", "success")
		else:
			UIManager.show_notification("خطا در ارتقاء ساختمان", "error")

func _on_demolish() -> void:
	if _current_grid_pos.x >= 0:
		var result = BuildingManager.demolish_building(_current_city_id, _current_grid_pos)
		if result:
			UIManager.show_notification("ساختمان تخریب شد", "info")
			hide()
