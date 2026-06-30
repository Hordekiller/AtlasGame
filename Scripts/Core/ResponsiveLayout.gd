extends Node

enum ScreenSizeClass {
	XL, L, M, S, XS
}

const DESIGN_WIDTH: float = 1920.0
const DESIGN_HEIGHT: float = 1080.0
const MIN_TOUCH_TARGET: float = 88.0

var current_size_class: int = ScreenSizeClass.L
var scale_factor: float = 1.0
var safe_area: Rect2 = Rect2(0, 0, 1920, 1080)
var safe_margin_left: int = 0
var safe_margin_right: int = 0
var safe_margin_top: int = 0
var safe_margin_bottom: int = 0
var top_bar_height: float = 56.0
var bottom_bar_height: float = 88.0
var tile_size: float = 64.0

func _ready() -> void:
	get_viewport().size_changed.connect(_on_size_changed)
	if Engine.has_singleton("SafeAreaManager"):
		SafeAreaManager.safe_area_changed.connect(_on_safe_area_changed)
	_calculate()

func _on_safe_area_changed(rect: Rect2i) -> void:
	if Engine.has_singleton("SafeAreaManager"):
		safe_margin_left = SafeAreaManager.get_margin_left()
		safe_margin_right = SafeAreaManager.get_margin_right()
		safe_margin_top = SafeAreaManager.get_margin_top()
		safe_margin_bottom = SafeAreaManager.get_margin_bottom()
	_calculate()

func _calculate() -> void:
	var vp = get_viewport().get_visible_rect()
	safe_area = _get_safe_area()

	var width = vp.size.x - safe_margin_left - safe_margin_right
	var height = vp.size.y - safe_margin_top - safe_margin_bottom

	scale_factor = min(width / DESIGN_WIDTH, height / DESIGN_HEIGHT)
	scale_factor = clampf(scale_factor, 0.55, 1.2)

	if width >= 1920 and height >= 1080:
		current_size_class = ScreenSizeClass.XL
	elif width >= 1600:
		current_size_class = ScreenSizeClass.L
	elif width >= 1280:
		current_size_class = ScreenSizeClass.M
	elif width >= 960:
		current_size_class = ScreenSizeClass.S
	else:
		current_size_class = ScreenSizeClass.XS

	top_bar_height = max(44.0, 56.0 * scale_factor)
	bottom_bar_height = max(64.0, 88.0 * scale_factor)
	tile_size = clampf(64.0 * min(1.0, scale_factor * 1.2), 40.0, 72.0)

func _get_safe_area() -> Rect2:
	if Engine.has_singleton("SafeAreaManager") and SafeAreaManager.safe_area != Rect2i():
		var sa = SafeAreaManager.safe_area
		return Rect2(sa.position, sa.size)
	return get_viewport().get_visible_rect()

func _on_size_changed() -> void:
	_calculate()

func get_scaled_value(base: float) -> float:
	return max(base * scale_factor, base * 0.6)

func get_top_bar_h() -> float:
	return top_bar_height

func get_bottom_bar_h() -> float:
	return bottom_bar_height

func get_tile_size() -> float:
	return tile_size

func get_panel_width_percent(percent: float) -> float:
	var vp = get_viewport().get_visible_rect()
	return vp.size.x * percent / 100.0

func get_panel_height_percent(percent: float) -> float:
	var vp = get_viewport().get_visible_rect()
	return vp.size.y * percent / 100.0

func font_size(base: int) -> int:
	return maxi(10, int(base * scale_factor))

func is_small_screen() -> bool:
	return current_size_class >= ScreenSizeClass.S

func get_building_grid_columns() -> int:
	match current_size_class:
		ScreenSizeClass.XL: return 4
		ScreenSizeClass.L: return 4
		ScreenSizeClass.M: return 3
		ScreenSizeClass.S: return 2
		ScreenSizeClass.XS: return 2
	return 3

func clamp_modal_size(size: Vector2) -> Vector2:
	var vp = get_viewport().get_visible_rect()
	var max_w = vp.size.x * 0.92
	var max_h = vp.size.y * 0.85
	return Vector2(min(size.x, max_w), min(size.y, max_h))
