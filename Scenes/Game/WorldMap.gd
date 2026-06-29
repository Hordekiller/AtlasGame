extends Node2D

const ISLAND_SPACING: float = 200.0
const ISLAND_RADIUS: float = 80.0

var _camera: Camera2D
var _ocean_tex: Texture = null
var _island_tex: Texture = null
var _island_active_tex: Texture = null
var _island_bgs: Dictionary = {}
var _city_blue_tex: Texture = null
var _city_red_tex: Texture = null
var _drag_start: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: float = 1.0

func _ready() -> void:
	_camera = $Camera2D
	EventBus.city_created.connect(_on_city_updated)
	EventBus.game_loaded.connect(update_map)
	_preload_textures()

func _preload_textures() -> void:
	var paths = {
		"ocean": "res://Assets/Textures/World/ocean.png",
		"island": "res://Assets/Textures/World/island.png",
		"island_active": "res://Assets/Textures/World/island_active.png",
		"city_blue": "res://Assets/Textures/Environment/city_blue.png",
		"city_red": "res://Assets/Textures/Environment/city_red.png"
	}
	for key in paths:
		var p = paths[key]
		if ResourceLoader.exists(p):
			var tex = ResourceLoader.load(p)
			match key:
				"ocean": _ocean_tex = tex
				"island": _island_tex = tex
				"island_active": _island_active_tex = tex
				"city_blue": _city_blue_tex = tex
				"city_red": _city_red_tex = tex

	for rt_name in ["wood", "marble", "glass", "wine", "sulfur"]:
		var path = "res://Assets/Textures/Resources/island_%s.jpg" % rt_name
		if ResourceLoader.exists(path):
			_island_bgs[rt_name] = ResourceLoader.load(path)

func update_map() -> void:
	queue_redraw()

func _draw() -> void:
	for x in range(0, 2000, 200):
		for y in range(0, 2000, 200):
			if _ocean_tex:
				draw_texture_rect(_ocean_tex, Rect2(x, y, 200, 200), false)

	var islands = GameState.current_islands
	var index = 0

	for island_id in islands:
		var island = islands[island_id]
		var pos = _get_island_position(index)

		if island.get("explored", false):
			var resource = island.get("primary_resource", -1)
			var res_name = _resource_to_name(resource)
			var bg = _island_bgs.get(res_name) if _island_bgs.has(res_name) else _island_tex
			if bg:
				draw_texture_rect(bg, Rect2(pos - Vector2(ISLAND_RADIUS, ISLAND_RADIUS), Vector2(ISLAND_RADIUS * 2, ISLAND_RADIUS * 2)), false)
			elif _island_tex:
				draw_texture_rect(_island_tex, Rect2(pos - Vector2(ISLAND_RADIUS, ISLAND_RADIUS), Vector2(ISLAND_RADIUS * 2, ISLAND_RADIUS * 2)), false)

			var label = island.get("name", "")
			draw_string(ThemeDB.fallback_font, pos + Vector2(-40, -ISLAND_RADIUS - 15), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.8))

			var res_label = res_name.capitalize()
			draw_string(ThemeDB.fallback_font, pos + Vector2(-30, ISLAND_RADIUS + 5), res_label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.9, 1.0, 0.7))

			for city_id in island.get("player_cities", []):
				var city = GameState.current_cities.get(city_id)
				if city:
					var city_pos = pos + Vector2(0, 20)
					if _city_blue_tex:
						draw_texture_rect(_city_blue_tex, Rect2(city_pos - Vector2(8, 8), Vector2(16, 16)), false)
					draw_string(ThemeDB.fallback_font, city_pos + Vector2(12, 4), city.get("name", ""),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.9))
		else:
			if _island_tex:
				draw_texture_rect(_island_tex, Rect2(pos - Vector2(ISLAND_RADIUS, ISLAND_RADIUS), Vector2(ISLAND_RADIUS * 2, ISLAND_RADIUS * 2)), false, Color(0.3, 0.3, 0.35, 0.6))
			draw_string(ThemeDB.fallback_font, pos + Vector2(-20, -5), "???",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.5, 0.7))

		index += 1

func _get_island_position(index: int) -> Vector2:
	var cols = 5
	var x = (index % cols) * int(ISLAND_SPACING * 2.5) + 150
	var y = (index / cols) * int(ISLAND_SPACING * 2.5) + 150
	return Vector2(x, y)

func _resource_to_name(resource_type: int) -> String:
	match resource_type:
		Globals.IslandResource.WOOD: return "wood"
		Globals.IslandResource.MARBLE: return "marble"
		Globals.IslandResource.GLASS: return "glass"
		Globals.IslandResource.WINE: return "wine"
		Globals.IslandResource.CRYSTAL: return "crystal"
		Globals.IslandResource.SULFUR: return "sulfur"
		_: return ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				_drag_start = event.position
				_dragging = false
			elif not _dragging:
				_handle_click(event.position)
				_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom = max(0.3, _camera.zoom * 0.9)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if _drag_start != Vector2.ZERO:
			var delta = event.position - _drag_start
			if delta.length() > 20:
				_dragging = true
			if _dragging:
				_camera.position -= delta / _camera.zoom.x
			_drag_start = event.position
	elif event is InputEventPanGesture:
		_camera.position -= event.delta * 100 / _camera.zoom.x
	elif event is InputEventMagnifyGesture:
		_camera.zoom = max(0.3, min(5.0, _camera.zoom * (1.0 / event.factor)))
		if _camera.zoom.x == 0:
			_camera.zoom = Vector2(1, 1)

func _handle_click(screen_pos: Vector2) -> void:
	var world_pos = _camera.get_canvas_transform().affine_inverse() * screen_pos

	var islands = GameState.current_islands
	var index = 0
	for island_id in islands:
		var island = islands[island_id]
		if not island.get("explored", false):
			index += 1
			continue

		var pos = _get_island_position(index)
		if world_pos.distance_to(pos) < ISLAND_RADIUS:
			var player_cities = island.get("player_cities", [])
			if not player_cities.is_empty():
				GameState.selected_city_id = player_cities[0]
				EventBus.city_selected.emit(player_cities[0])
				var game = get_parent()
				if game and game.has_method("switch_to_city_view"):
					game.switch_to_city_view()
			else:
				_show_colonize_dialog(island_id)
			return
		index += 1

func _show_colonize_dialog(island_id: String) -> void:
	var source_cities = []
	for cid in WorldManager.find_player_cities():
		var city = GameState.current_cities.get(cid, {})
		if city.get("island_id") != island_id:
			source_cities.append(cid)

	if source_cities.is_empty():
		EventBus.notification_added.emit("شهری با بندر برای اعزام کشتی ندارید!", "warning")
		return

	var dialog = get_parent().get_node("ColonizeDialog") if get_parent().has_node("ColonizeDialog") else null
	if dialog and dialog.has_method("show_for_island"):
		dialog.show_for_island(island_id, source_cities)

func _on_city_updated(city_id: String, _name: String, _island_id: String) -> void:
	update_map()
