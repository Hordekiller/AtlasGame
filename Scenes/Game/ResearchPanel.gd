extends Panel

@onready var branch_tabs: TabContainer = $VBox/BranchTabs
@onready var current_research_label: Label = $VBox/CurrentResearchLabel
@onready var progress_bar: ProgressBar = $VBox/ProgressBar
@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var icon: TextureRect = $VBox/Header/IconBox/Icon
@onready var detail_panel: Panel = $VBox/DetailPanel
@onready var detail_name: Label = $VBox/DetailPanel/DetailName
@onready var detail_desc: Label = $VBox/DetailPanel/DetailDesc
@onready var detail_cost: Label = $VBox/DetailPanel/DetailCost
@onready var detail_prereqs: Label = $VBox/DetailPanel/DetailPrereqs
@onready var start_btn: Button = $VBox/DetailPanel/StartBtn

var _current_tech_id: String = ""

func _ready() -> void:
	UITheme.style_panel(self)
	EventBus.research_completed.connect(_on_research_changed)
	EventBus.research_started.connect(_on_research_changed)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(_hide_panel)
	start_btn.pressed.connect(_on_start_research)
	hide()
	_build_branch_tabs()
	_update_current_research()
	if ResourceLoader.exists("res://Assets/Textures/UI/scientist.png"):
		icon.texture = ResourceLoader.load("res://Assets/Textures/UI/scientist.png")
	get_viewport().size_changed.connect(_update_responsive)
	detail_panel.hide()

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(600, vp.size.x * 0.9), min(500, vp.size.y * 0.85)))
	custom_minimum_size = sz
	size = sz

func show_panel() -> void:
	show()
	_build_branch_tabs()
	_update_current_research()

func _hide_panel() -> void:
	hide()
	detail_panel.hide()

func _build_branch_tabs() -> void:
	for child in branch_tabs.get_children():
		child.queue_free()

	var branch_ids = [
		Globals.TechCategory.ECONOMY,
		Globals.TechCategory.SCIENCE,
		Globals.TechCategory.MILITARY,
		Globals.TechCategory.CULTURE,
		Globals.TechCategory.NAVIGATION
	]
	var branch_names = {
		Globals.TechCategory.ECONOMY: "اقتصاد",
		Globals.TechCategory.SCIENCE: "علوم",
		Globals.TechCategory.MILITARY: "نظامی",
		Globals.TechCategory.CULTURE: "فرهنگ",
		Globals.TechCategory.NAVIGATION: "دریانوردی"
	}

	for cat in branch_ids:
		var tab = VBoxContainer.new()
		tab.name = branch_names.get(cat, str(cat))
		var scroll = ScrollContainer.new()
		scroll.size_flags_horizontal = SIZE_EXPAND_FILL
		scroll.size_flags_vertical = SIZE_EXPAND_FILL
		var list = VBoxContainer.new()
		list.size_flags_horizontal = SIZE_EXPAND_FILL

		var city_id = GameState.selected_city_id
		var completed = []
		var in_progress = ""
		if not city_id.is_empty():
			var city = GameState.current_cities.get(city_id, {})
			completed = city.get("research_completed", [])
			in_progress = city.get("research_in_progress", "")

		var tree = ResearchManager.get_all_research()
		var cat_nodes = []
		for tech_id in tree:
			if tree[tech_id].get("category", -1) == cat:
				cat_nodes.append(tech_id)

		cat_nodes.sort_custom(func(a, b): return tree[a].get("tier", 99) < tree[b].get("tier", 99))

		for tech_id in cat_nodes:
			var defn = tree[tech_id]
			var is_completed = tech_id in completed
			var is_active = tech_id == in_progress
			var can_start = tech_id in ResearchManager.get_available_research(city_id) and not is_active

			var hbox = HBoxContainer.new()
			var btn = Button.new()
			var tier_idx = clampi(defn.get("tier", 1), 0, 5)
			var tier_icon = ["", "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ"][tier_idx]
			btn.text = "%s %s" % [tier_icon, defn.get("name", tech_id)]
			btn.size_flags_horizontal = SIZE_EXPAND_FILL
			btn.flat = true

			if is_completed:
				btn.modulate = Color(0.4, 0.9, 0.4)
			elif is_active:
				btn.modulate = Color(0.9, 0.8, 0.2)
			elif can_start:
				btn.modulate = Color(1, 1, 1)
			else:
				btn.modulate = Color(0.4, 0.4, 0.4)

			btn.pressed.connect(_on_node_selected.bind(tech_id, defn))
			UITheme.style_button(btn)
			hbox.add_child(btn)
			list.add_child(hbox)

		scroll.add_child(list)
		tab.add_child(scroll)
		branch_tabs.add_child(tab)

func _on_node_selected(tech_id: String, defn: Dictionary) -> void:
	_current_tech_id = tech_id
	detail_panel.show()
	detail_name.text = defn.get("name", tech_id)
	detail_desc.text = defn.get("description", "توضیحاتی موجود نیست")

	var cost = defn.get("cost", 0)
	detail_cost.text = "هزینه: %d امتیاز پژوهش" % cost

	var prereqs = defn.get("prerequisites", [])
	if prereqs.is_empty():
		detail_prereqs.text = "پیش‌نیاز: ندارد"
	else:
		var names = []
		var city_id = GameState.selected_city_id
		var completed = []
		if not city_id.is_empty():
			completed = GameState.current_cities.get(city_id, {}).get("research_completed", [])
		for p in prereqs:
			var pdef = ResearchManager.get_research_def(p)
			var pname = pdef.get("name", p)
			var done = p in completed
			names.append(("%s ✅" if done else "%s ❌") % pname)
		detail_prereqs.text = "پیش‌نیاز: " + ", ".join(names)

	var city_id = GameState.selected_city_id
	var is_in_progress = false
	var is_completed = false
	if not city_id.is_empty():
		var city = GameState.current_cities.get(city_id, {})
		is_completed = tech_id in city.get("research_completed", [])
		is_in_progress = city.get("research_in_progress", "") == tech_id

	var can_start = tech_id in ResearchManager.get_available_research(city_id) and not is_in_progress
	start_btn.disabled = not can_start or is_completed
	if is_completed:
		start_btn.text = "تکمیل شده ✅"
	elif is_in_progress:
		start_btn.text = "در حال انجام"
	elif can_start:
		start_btn.text = "شروع تحقیق"
	else:
		start_btn.text = "پیش‌نیازها تکمیل نیست"

func _on_start_research() -> void:
	if _current_tech_id.is_empty():
		return
	var city_id = GameState.selected_city_id
	if city_id.is_empty():
		return
	var result = ResearchManager.start_research(city_id, _current_tech_id)
	if result:
		AudioManager.play_upgrade()
		EventBus.notification_added.emit("تحقیق شروع شد!", "success")
		_build_branch_tabs()
		_update_current_research()
		detail_panel.hide()
	else:
		AudioManager.play_error()
		EventBus.notification_added.emit("امتیاز پژوهش کافی نیست", "error")

func _update_current_research() -> void:
	var city_id = GameState.selected_city_id
	if city_id.is_empty():
		current_research_label.text = "هیچ تحقیقی در حال انجام نیست"
		progress_bar.value = 0.0
		return

	var city = GameState.current_cities.get(city_id)
	if not city:
		return

	var in_progress = city.get("research_in_progress", "")
	if not in_progress.is_empty():
		var defn = ResearchManager.get_research_def(in_progress)
		current_research_label.text = defn.get("name", in_progress)
		progress_bar.value = city.get("research_progress", 0.0)
		progress_bar.max_value = city.get("research_duration", 30.0)
	else:
		current_research_label.text = "هیچ تحقیقی در حال انجام نیست"
		progress_bar.value = 0.0

func _on_research_changed(_tech_id: String = "") -> void:
	_build_branch_tabs()
	_update_current_research()

func _process(_delta: float) -> void:
	if visible:
		var city_id = GameState.selected_city_id
		if not city_id.is_empty():
			var city = GameState.current_cities.get(city_id)
			if city and not city.get("research_in_progress", "").is_empty():
				progress_bar.value = city.get("research_progress", 0.0)
