extends Panel

@onready var master_slider: HSlider = $VBox/MasterBox/MasterSlider
@onready var music_slider: HSlider = $VBox/MusicBox/MusicSlider
@onready var sfx_slider: HSlider = $VBox/SfxBox/SfxSlider
@onready var ui_slider: HSlider = $VBox/UiBox/UiSlider
@onready var language_options: OptionButton = $VBox/LangBox/LanguageOptions
@onready var master_val: Label = $VBox/MasterBox/MasterVal
@onready var music_val: Label = $VBox/MusicBox/MusicVal
@onready var sfx_val: Label = $VBox/SfxBox/SfxVal
@onready var ui_val: Label = $VBox/UiBox/UiVal
@onready var close_btn: Button = $VBox/CloseBtn
@onready var reset_btn: Button = $VBox/ResetBtn

func _ready() -> void:
	UITheme.style_panel(self)
	UITheme.style_button(close_btn)
	UITheme.style_button(reset_btn)

	close_btn.pressed.connect(_on_close)
	reset_btn.pressed.connect(_on_reset)

	master_slider.value = AudioManager.get_volume("Master")
	music_slider.value = AudioManager.get_volume("Music")
	sfx_slider.value = AudioManager.get_volume("SFX")
	ui_slider.value = AudioManager.get_volume("UI")
	_update_labels()

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	ui_slider.value_changed.connect(_on_ui_changed)

	language_options.add_item("فارسی", 0)
	language_options.add_item("English", 1)
	language_options.select(0)

	hide()
	get_viewport().size_changed.connect(_update_responsive)

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(400, vp.size.x * 0.8), min(350, vp.size.y * 0.7)))
	custom_minimum_size = sz
	size = sz

func _update_labels() -> void:
	master_val.text = "%d%%" % int(master_slider.value * 100)
	music_val.text = "%d%%" % int(music_slider.value * 100)
	sfx_val.text = "%d%%" % int(sfx_slider.value * 100)
	ui_val.text = "%d%%" % int(ui_slider.value * 100)

func _on_master_changed(v: float) -> void:
	AudioManager.set_volume("Master", v)
	_update_labels()

func _on_music_changed(v: float) -> void:
	AudioManager.set_volume("Music", v)
	_update_labels()

func _on_sfx_changed(v: float) -> void:
	AudioManager.set_volume("SFX", v)
	_update_labels()

func _on_ui_changed(v: float) -> void:
	AudioManager.set_volume("UI", v)
	_update_labels()

func _on_reset() -> void:
	master_slider.value = 0.8
	music_slider.value = 0.7
	sfx_slider.value = 0.6
	ui_slider.value = 0.6

func _on_close() -> void:
	AudioManager.play_button_click()
	hide()
