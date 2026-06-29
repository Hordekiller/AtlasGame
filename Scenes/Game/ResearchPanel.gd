extends Panel

@onready var research_list: VBoxContainer = $VBox/Scroll/ResearchList
@onready var current_research_label: Label = $VBox/CurrentResearchLabel
@onready var progress_bar: ProgressBar = $VBox/ProgressBar
@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var icon: TextureRect = $VBox/Header/IconBox/Icon

func _ready() -> void:
	UITheme.style_panel(self)
	EventBus.research_completed.connect(_on_research_completed)
	EventBus.research_started.connect(_on_research_started)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(_hide_panel)
	hide()
	_update_available()
	if ResourceLoader.exists("res://Assets/Textures/UI/scientist.png"):
		icon.texture = ResourceLoader.load("res://Assets/Textures/UI/scientist.png")

func show_panel() -> void:
	show()
	_update_available()

func _hide_panel() -> void:
	hide()

func _update_available() -> void:
	for child in research_list.get_children():
		child.queue_free()

	var city_id = GameState.selected_city_id
	if city_id.is_empty():
		return

	var city = GameState.current_cities.get(city_id)
	if not city:
		return

	var in_progress = city.get("research_in_progress", "")
	var available = ResearchManager.get_available_research(city_id)

	if not in_progress.is_empty():
		var defn = ResearchManager.get_research_def(in_progress)
		current_research_label.text = defn.get("name", in_progress)
		progress_bar.value = city.get("research_progress", 0.0)
		progress_bar.max_value = city.get("research_duration", 30.0)
	else:
		current_research_label.text = "هیچ تحقیقی در حال انجام نیست"
		progress_bar.value = 0.0

	for tech_id in available:
		var defn = ResearchManager.get_research_def(tech_id)
		var btn = Button.new()
		btn.text = defn.get("name", tech_id)
		btn.tooltip_text = defn.get("description", "")
		btn.pressed.connect(_on_research_selected.bind(tech_id))
		UITheme.style_button(btn)
		research_list.add_child(btn)

func _on_research_selected(tech_id: String) -> void:
	var city_id = GameState.selected_city_id
	if city_id.is_empty():
		return

	var result = ResearchManager.start_research(city_id, tech_id)
	if result:
		EventBus.notification_added.emit("تحقیق شروع شد!", "success")
		_update_available()
	else:
		EventBus.notification_added.emit("امتیاز پژوهش کافی نیست", "error")

func _on_research_completed(_tech_id: String) -> void:
	EventBus.notification_added.emit("تحقیق کامل شد!", "success")
	_update_available()

func _on_research_started(_tech_id: String, _duration: float) -> void:
	_update_available()

func _process(_delta: float) -> void:
	if visible:
		var city_id = GameState.selected_city_id
		if not city_id.is_empty():
			var city = GameState.current_cities.get(city_id)
			if city and not city.get("research_in_progress", "").is_empty():
				progress_bar.value = city.get("research_progress", 0.0)
