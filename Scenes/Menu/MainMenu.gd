extends Control

@onready var bg_texture: TextureRect = $BgTexture
@onready var overlay: ColorRect = $Overlay
@onready var title_icon: TextureRect = $CenterBox/TitleBox/TitleIcon
@onready var title_label: Label = $CenterBox/TitleBox/TitleLabel
@onready var subtitle_label: Label = $CenterBox/TitleBox/SubtitleLabel
@onready var new_game_btn: Button = $CenterBox/VBox/NewGameBtn
@onready var load_game_btn: Button = $CenterBox/VBox/LoadGameBtn
@onready var settings_btn: Button = $CenterBox/VBox/SettingsBtn
@onready var quit_btn: Button = $CenterBox/VBox/QuitBtn
@onready var version_label: Label = $VersionLabel
@onready var decor_top: TextureRect = $DecorTop
@onready var decor_bottom: TextureRect = $DecorBottom

var _advisors: Array = []
var _load_slot_container: VBoxContainer = null
var _load_dialog: Panel = null
var _settings_panel: Panel = null
var _load_slot_scene: PackedScene = null

func _ready() -> void:
	version_label.text = "v" + Globals.VERSION
	_load_bg()
	_style_buttons()
	_setup_advisors()
	_connect_signals()
	_setup_load_dialog()
	_setup_settings()
	get_viewport().size_changed.connect(_update_responsive)
	AudioManager.play_main_theme()

func _update_responsive() -> void:
	if _settings_panel and _settings_panel.visible and _settings_panel.has_method("_update_responsive"):
		_settings_panel._update_responsive()

func _load_bg() -> void:
	var bg_path = "res://Assets/Textures/Environment/city_bg.jpg"
	if ResourceLoader.exists(bg_path):
		bg_texture.texture = ResourceLoader.load(bg_path)

func _style_buttons() -> void:
	for btn in [new_game_btn, load_game_btn, settings_btn, quit_btn]:
		UITheme.style_button(btn)
		btn.add_theme_font_size_override("font_size", 16)
		btn.custom_minimum_size = Vector2(220, 48)
		var icon_path = ""
		match btn.name:
			"NewGameBtn": icon_path = "res://Assets/Textures/UI/city_icon.png"
			"LoadGameBtn": icon_path = "res://Assets/Textures/UI/check.png"
			"SettingsBtn": icon_path = "res://Assets/Textures/UI/time.png"
			"QuitBtn": icon_path = "res://Assets/Textures/UI/close.png"
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			btn.add_theme_icon_override("icon", ResourceLoader.load(icon_path))

func _setup_advisors() -> void:
	var advisor_data = [
		{"tex": "res://Assets/Textures/Advisor/mayor.png", "x": 0.05, "y": 0.5},
		{"tex": "res://Assets/Textures/Advisor/scientist.png", "x": 0.12, "y": 0.6},
		{"tex": "res://Assets/Textures/Advisor/general.png", "x": 0.07, "y": 0.35},
	]
	for ad in advisor_data:
		if ResourceLoader.exists(ad.tex):
			var tr = TextureRect.new()
			tr.texture = ResourceLoader.load(ad.tex)
			tr.anchor_left = ad.x
			tr.anchor_top = ad.y
			tr.anchor_right = ad.x + 0.08
			tr.anchor_bottom = ad.y + 0.2
			tr.modulate = Color(1, 1, 1, 0.15)
			add_child(tr)
			_advisors.append(tr)

	var decor_path = "res://Assets/Textures/UI/nav_bg.png"
	if ResourceLoader.exists(decor_path):
		var decor = ResourceLoader.load(decor_path)
		decor_top.texture = decor
		decor_bottom.texture = decor

func _setup_load_dialog() -> void:
	_load_slot_scene = ResourceLoader.load("res://Scenes/Menu/LoadSlot.tscn")

	_load_dialog = Panel.new()
	_load_dialog.visible = false
	_load_dialog.anchor_left = 0.5
	_load_dialog.anchor_top = 0.5
	_load_dialog.anchor_right = 0.5
	_load_dialog.anchor_bottom = 0.5
	_load_dialog.offset_left = -200
	_load_dialog.offset_top = -180
	_load_dialog.offset_right = 200
	_load_dialog.offset_bottom = 180
	add_child(_load_dialog)

	var outer_vbox = VBoxContainer.new()
	outer_vbox.anchor_right = 1.0
	outer_vbox.anchor_bottom = 1.0
	_load_dialog.add_child(outer_vbox)

	var title = Label.new()
	title.text = "بارگذاری بازی"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	_load_slot_container = VBoxContainer.new()
	_load_slot_container.anchor_right = 1.0
	scroll.add_child(_load_slot_container)

	var close_btn = Button.new()
	close_btn.text = "بستن"
	outer_vbox.add_child(close_btn)
	UITheme.style_button(close_btn)
	close_btn.pressed.connect(_close_load_dialog)

func _setup_settings() -> void:
	_settings_panel = ResourceLoader.load("res://Scenes/Menu/Settings.tscn").instantiate()
	add_child(_settings_panel)
	_settings_panel.hide()

func _refresh_save_slots() -> void:
	for child in _load_slot_container.get_children():
		child.queue_free()

	for i in range(5):
		var slot = _load_slot_scene.instantiate()
		slot.setup(i)
		slot.on_selected = _on_slot_selected
		slot.on_deleted = _on_slot_deleted
		_load_slot_container.add_child(slot)

func _on_slot_selected(slot: int) -> void:
	AudioManager.play_button_click()
	if SaveManager.load_game(slot):
		get_tree().change_scene_to_file("res://Scenes/Game/Game.tscn")

func _on_slot_deleted(slot: int) -> void:
	SaveManager.delete_save(slot)
	_refresh_save_slots()
	var any_exists = false
	for i in range(5):
		if SaveManager.save_exists(i):
			any_exists = true
			break
	load_game_btn.disabled = not any_exists

func _close_load_dialog() -> void:
	AudioManager.play_button_click()
	_load_dialog.hide()

func _connect_signals() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	load_game_btn.pressed.connect(_on_load_game)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	_update_load_button_state()

func _update_load_button_state() -> void:
	var any_exists = false
	for i in range(5):
		if SaveManager.save_exists(i):
			any_exists = true
			break
	load_game_btn.disabled = not any_exists

func _on_new_game() -> void:
	GameState.reset()
	WorldManager.generate_world()
	var city_id = WorldManager.create_player_city("شهر من", "island_0", 0)
	if not city_id.is_empty():
		GameState.selected_city_id = city_id
	get_tree().change_scene_to_file("res://Scenes/Game/Game.tscn")

func _on_load_game() -> void:
	AudioManager.play_button_click()
	_refresh_save_slots()
	_load_dialog.show()

func _on_settings() -> void:
	AudioManager.play_button_click()
	_settings_panel.show()
	_settings_panel._update_responsive()

func _on_quit() -> void:
	get_tree().quit()
