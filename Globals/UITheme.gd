extends Node

const TOP_BAR_HEIGHT: float = 56.0
const BOTTOM_BAR_HEIGHT: float = 88.0
const PANEL_PADDING: int = 8
const BUTTON_MIN_SIZE: int = 44

static func get_top_bar_h() -> float:
	if not ResponsiveLayout:
		return TOP_BAR_HEIGHT
	return ResponsiveLayout.get_top_bar_h()

static func get_bottom_bar_h() -> float:
	if not ResponsiveLayout:
		return BOTTOM_BAR_HEIGHT
	return ResponsiveLayout.get_bottom_bar_h()

static func get_tile_sz() -> float:
	if not ResponsiveLayout:
		return 64.0
	return ResponsiveLayout.get_tile_size()

static func get_scale() -> float:
	if not ResponsiveLayout:
		return 1.0
	return ResponsiveLayout.scale_factor

static func get_font_size(base: int) -> int:
	if not ResponsiveLayout:
		return base
	return ResponsiveLayout.font_size(base)

static func get_grid_columns() -> int:
	if not ResponsiveLayout:
		return 4
	return ResponsiveLayout.get_building_grid_columns()

var _top_bar_bg: StyleBoxFlat
var _bottom_bar_bg: StyleBoxFlat
var _panel_bg: StyleBoxFlat
var _button_normal: StyleBoxFlat
var _button_pressed: StyleBoxFlat
var _button_disabled: StyleBoxFlat
var _panel_title_style: StyleBoxFlat
var _icon_cache: Dictionary = {}

func _ready() -> void:
	_init_styles()

func _init_styles() -> void:
	_top_bar_bg = StyleBoxFlat.new()
	_top_bar_bg.bg_color = Color(0.08, 0.08, 0.12, 0.88)
	_top_bar_bg.corner_radius_top_left = 0
	_top_bar_bg.corner_radius_top_right = 0
	_top_bar_bg.corner_radius_bottom_left = 6
	_top_bar_bg.corner_radius_bottom_right = 6
	_top_bar_bg.content_margin_left = 8
	_top_bar_bg.content_margin_right = 8
	_top_bar_bg.content_margin_top = 4
	_top_bar_bg.content_margin_bottom = 4

	_bottom_bar_bg = StyleBoxFlat.new()
	_bottom_bar_bg.bg_color = Color(0.08, 0.08, 0.12, 0.88)
	_bottom_bar_bg.corner_radius_top_left = 6
	_bottom_bar_bg.corner_radius_top_right = 6
	_bottom_bar_bg.corner_radius_bottom_left = 0
	_bottom_bar_bg.corner_radius_bottom_right = 0
	_bottom_bar_bg.content_margin_left = 8
	_bottom_bar_bg.content_margin_right = 8
	_bottom_bar_bg.content_margin_top = 4
	_bottom_bar_bg.content_margin_bottom = 4

	_panel_bg = StyleBoxFlat.new()
	_panel_bg.bg_color = Color(0.1, 0.1, 0.16, 0.92)
	_panel_bg.corner_radius_top_left = 8
	_panel_bg.corner_radius_top_right = 8
	_panel_bg.corner_radius_bottom_left = 8
	_panel_bg.corner_radius_bottom_right = 8
	_panel_bg.content_margin_left = 12
	_panel_bg.content_margin_right = 12
	_panel_bg.content_margin_top = 12
	_panel_bg.content_margin_bottom = 12

	_button_normal = StyleBoxFlat.new()
	_button_normal.bg_color = Color(0.18, 0.2, 0.28, 0.9)
	_button_normal.border_color = Color(0.35, 0.4, 0.55, 0.8)
	_button_normal.border_width_left = 1
	_button_normal.border_width_right = 1
	_button_normal.border_width_top = 1
	_button_normal.border_width_bottom = 1
	_button_normal.corner_radius_top_left = 6
	_button_normal.corner_radius_top_right = 6
	_button_normal.corner_radius_bottom_left = 6
	_button_normal.corner_radius_bottom_right = 6
	_button_normal.content_margin_left = 6
	_button_normal.content_margin_right = 6
	_button_normal.content_margin_top = 4
	_button_normal.content_margin_bottom = 4

	_button_pressed = StyleBoxFlat.new()
	_button_pressed.bg_color = Color(0.3, 0.35, 0.5, 0.95)
	_button_pressed.border_color = Color(0.5, 0.6, 0.8, 1.0)
	_button_pressed.border_width_left = 2
	_button_pressed.border_width_right = 2
	_button_pressed.border_width_top = 2
	_button_pressed.border_width_bottom = 2
	_button_pressed.corner_radius_top_left = 6
	_button_pressed.corner_radius_top_right = 6
	_button_pressed.corner_radius_bottom_left = 6
	_button_pressed.corner_radius_bottom_right = 6
	_button_pressed.content_margin_left = 5
	_button_pressed.content_margin_right = 5
	_button_pressed.content_margin_top = 3
	_button_pressed.content_margin_bottom = 3

	_button_disabled = StyleBoxFlat.new()
	_button_disabled.bg_color = Color(0.12, 0.12, 0.18, 0.6)
	_button_disabled.corner_radius_top_left = 6
	_button_disabled.corner_radius_top_right = 6
	_button_disabled.corner_radius_bottom_left = 6
	_button_disabled.corner_radius_bottom_right = 6
	_button_disabled.content_margin_left = 6
	_button_disabled.content_margin_right = 6
	_button_disabled.content_margin_top = 4
	_button_disabled.content_margin_bottom = 4

	_panel_title_style = StyleBoxFlat.new()
	_panel_title_style.bg_color = Color(0.15, 0.12, 0.08, 0.5)
	_panel_title_style.border_color = Color(0.6, 0.5, 0.2, 0.6)
	_panel_title_style.border_width_bottom = 1
	_panel_title_style.corner_radius_top_left = 6
	_panel_title_style.corner_radius_top_right = 6
	_panel_title_style.content_margin_left = 8
	_panel_title_style.content_margin_right = 8
	_panel_title_style.content_margin_top = 6
	_panel_title_style.content_margin_bottom = 6

func get_icon(path: String) -> Texture2D:
	if _icon_cache.has(path):
		return _icon_cache[path]
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path)
		_icon_cache[path] = tex
		return tex
	return null

func style_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _button_normal)
	btn.add_theme_stylebox_override("pressed", _button_pressed)
	btn.add_theme_stylebox_override("hover", _button_pressed)
	btn.add_theme_stylebox_override("disabled", _button_disabled)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	var fs = get_font_size(13)
	btn.add_theme_font_size_override("font_size", fs)
	var s = get_scale()
	var min_h = maxi(36, int(36 * s))
	btn.custom_minimum_size = Vector2(BUTTON_MIN_SIZE * s, min_h)

func style_panel(panel: Panel) -> void:
	panel.add_theme_stylebox_override("panel", _panel_bg)

func make_resource_icon(rtype: int) -> TextureRect:
	var path = ""
	match rtype:
		Globals.ResourceType.WOOD: path = "res://Assets/Textures/Resources/wood.png"
		Globals.ResourceType.MARBLE: path = "res://Assets/Textures/Resources/marble.png"
		Globals.ResourceType.GLASS: path = "res://Assets/Textures/Resources/glass.png"
		Globals.ResourceType.WINE: path = "res://Assets/Textures/Resources/wine.png"
		Globals.ResourceType.GOLD: path = "res://Assets/Textures/Resources/gold.png"
		Globals.ResourceType.FOOD: path = "res://Assets/Textures/Resources/food.png"
		Globals.ResourceType.STONE: path = "res://Assets/Textures/Resources/stone.png"
		Globals.ResourceType.CRYSTAL: path = "res://Assets/Textures/Resources/crystal.png"
		Globals.ResourceType.SULFUR: path = "res://Assets/Textures/Resources/sulfur.png"
		Globals.ResourceType.POPULATION: path = "res://Assets/Textures/UI/population.png"
		Globals.ResourceType.WORKERS: path = "res://Assets/Textures/UI/citizen.png"
		Globals.ResourceType.RESEARCH_POINTS: path = "res://Assets/Textures/Resources/research_time.png"

	var icon = TextureRect.new()
	var tex = get_icon(path)
	if tex:
		icon.texture = tex
	var s = get_scale()
	icon.custom_minimum_size = Vector2(20 * s, 20 * s)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

func make_resource_display(rtype: int, initial_value: float = 0.0) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var icon = make_resource_icon(rtype)
	container.add_child(icon)

	var label = Label.new()
	label.name = "Val_%d" % rtype
	label.text = _format_resource_value(initial_value)
	label.add_theme_color_override("font_color", Globals.get_resource_color(rtype))
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)

	return container

func _format_resource_value(val: float) -> String:
	if val >= 10000:
		return "%dk" % int(val / 1000)
	elif val >= 1000:
		return "%.1fk" % (val / 1000)
	elif val >= 1:
		return "%d" % int(val)
	else:
		return "%.1f" % val

func get_building_icon(building_id: String) -> Texture2D:
	var path = Globals.get_building_sprite(building_id)
	return get_icon(path)

func make_building_icon_button(building_id: String, size: Vector2 = Vector2(64, 64)) -> TextureButton:
	var btn = TextureButton.new()
	var tex = get_building_icon(building_id)
	if tex:
		btn.texture_normal = tex
	btn.custom_minimum_size = size
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	return btn

func style_label(label: Label, font_size: int = 13, color: Color = Color(0.9, 0.9, 0.95)) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
