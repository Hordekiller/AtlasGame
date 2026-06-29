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

func _ready() -> void:
	version_label.text = "v" + Globals.VERSION
	_load_bg()
	_style_buttons()
	_setup_advisors()
	_connect_signals()

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

func _connect_signals() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	load_game_btn.pressed.connect(_on_load_game)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	if not SaveManager.save_exists(0):
		load_game_btn.disabled = true

func _on_new_game() -> void:
	GameState.reset()
	WorldManager.generate_world()
	var city_id = WorldManager.create_player_city("شهر من", "island_0", 0)
	if not city_id.is_empty():
		GameState.selected_city_id = city_id
	get_tree().change_scene_to_file("res://Scenes/Game/Game.tscn")

func _on_load_game() -> void:
	if SaveManager.load_game(0):
		get_tree().change_scene_to_file("res://Scenes/Game/Game.tscn")
	else:
		pass

func _on_settings() -> void:
	UIManager.show_notification("تنظیمات به زودی", "info")

func _on_quit() -> void:
	get_tree().quit()
