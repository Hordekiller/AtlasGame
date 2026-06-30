extends Panel

@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var quest_container: VBoxContainer = $VBox/Scroll/QuestContainer
@onready var tab_active: Button = $VBox/TabBar/ActiveBtn
@onready var tab_completed: Button = $VBox/TabBar/CompletedBtn

var _show_completed: bool = false

func _ready() -> void:
	UITheme.style_panel(self)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(hide)
	tab_active.pressed.connect(_show_active)
	tab_completed.pressed.connect(_show_completed_only)
	EventBus.game_loaded.connect(_refresh)
	hide()
	get_viewport().size_changed.connect(_update_responsive)

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(500, vp.size.x * 0.85), min(400, vp.size.y * 0.75)))
	custom_minimum_size = sz
	size = sz

func open() -> void:
	show()
	_refresh()

func _refresh() -> void:
	for child in quest_container.get_children():
		child.queue_free()
	var quests = QuestSystem.get_all_quests()
	var to_display = _show_completed if _show_completed else null
	for qid in quests:
		var is_completed = QuestSystem.is_quest_completed(qid)
		if _show_completed and not is_completed:
			continue
		if not _show_completed and is_completed:
			continue
		if not _show_completed and not QuestSystem.is_quest_active(qid) and not QuestSystem.is_available(qid):
			continue
		_add_quest_row(qid, quests[qid], is_completed)

func _add_quest_row(qid: String, defn: Dictionary, completed: bool) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = defn.get("name", qid)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	if completed:
		label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		label.text += " ✅"
	hbox.add_child(label)

	if not completed:
		if QuestSystem.is_quest_active(qid):
			var prog = "فعال"
			label.text += " (" + prog + ")"
		elif QuestSystem.is_available(qid):
			var start_btn = Button.new()
			start_btn.text = "شروع"
			UITheme.style_button(start_btn)
			start_btn.pressed.connect(_start_quest.bind(qid))
			hbox.add_child(start_btn)
	quest_container.add_child(hbox)

func _start_quest(qid: String) -> void:
	if QuestSystem.start_quest(qid):
		AudioManager.play_upgrade()
		_refresh()

func _show_active() -> void:
	_show_completed = false
	tab_active.button_pressed = true
	tab_completed.button_pressed = false
	_refresh()

func _show_completed_only() -> void:
	_show_completed = true
	tab_active.button_pressed = false
	tab_completed.button_pressed = true
	_refresh()
