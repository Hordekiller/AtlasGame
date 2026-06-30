extends Panel

@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var event_container: VBoxContainer = $VBox/Scroll/EventContainer

func _ready() -> void:
	UITheme.style_panel(self)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(hide)
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
	for child in event_container.get_children():
		child.queue_free()
	var events = EventSystem.get_active_events()
	if events.is_empty():
		var lbl = Label.new()
		lbl.text = "هیچ رویداد فعالی وجود ندارد"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		event_container.add_child(lbl)
	else:
		for eid in events:
			var defn = events[eid]
			var hbox = HBoxContainer.new()
			var label = Label.new()
			label.text = defn.get("name", eid) + "\n" + defn.get("description", "")
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			hbox.add_child(label)
			event_container.add_child(hbox)
