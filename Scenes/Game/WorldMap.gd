extends Node2D

const ISLAND_SPACING: float = 200.0
const ISLAND_RADIUS: float = 80.0

var _camera: Camera2D
var _ocean_tex: Texture = null
var _island_tex: Texture = null

var _island_bgs: Dictionary = {}
var _city_blue_tex: Texture = null
var _city_red_tex: Texture = null
var _drag_start: Vector2 = Vector2.ZERO
var _dragging: bool = false

var _touch_points: Dictionary = {}
var _last_pinch_distance: float = -1.0

var _island_cols: int = 5

func _ready() -> void:
	_camera = $Camera2D
	EventBus.city_created.connect(_on_city_updated)
	EventBus.game_loaded.connect(update_map)
	_preload_textures()
	get_viewport().size_changed.connect(_update_viewport)

func _update_viewport() -> void:
	var vp = get_viewport().get_visible_rect()
	_island_cols = clampi(int(vp.size.x / 280), 3, 7)
	var s = ResponsiveLayout.scale_factor
	_camera.zoom = Vector2(s, s)
	queue_redraw()

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
				"city_blue": _city_blue_tex = tex
				"city_red": _city_red_tex = tex

	for rt_name in ["wood", "marble", "glass", "wine", "crystal", "sulfur"]:
		var path = "res://Assets/Textures/Resources/island_%s.jpg" % rt_name
		if ResourceLoader.exists(path):
			_island_bgs[rt_name] = ResourceLoader.load(path)

func update_map() -> void:
	queue_redraw()

func _get_visible_rect() -> Rect2:
	var vp = get_viewport().get_visible_rect()
	var cam_pos = _camera.global_position if _camera else Vector2.ZERO
	var zoom = _camera.zoom if _camera else Vector2.ONE
	var view_size = vp.size / zoom
	var margin = ISLAND_RADIUS * 3 * ResponsiveLayout.scale_factor
	return Rect2(cam_pos - view_size / 2 - Vector2(margin, margin), view_size + Vector2(margin * 2, margin * 2))

func _draw() -> void:
	var s = ResponsiveLayout.scale_factor
	var radius = ISLAND_RADIUS * s
	var ocean_step = int(200 * s)
	var visible_rect = _get_visible_rect()

	for x in range(0, int(2000 * s), max(ocean_step, 1)):
		for y in range(0, int(2000 * s), max(ocean_step, 1)):
			if _ocean_tex and Rect2(x, y, ocean_step, ocean_step).intersects(visible_rect):
				var os = 200 * s
				draw_texture_rect(_ocean_tex, Rect2(x, y, os, os), false)

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
				draw_texture_rect(bg, Rect2(pos - Vector2(radius, radius), Vector2(radius * 2, radius * 2)), false)
			elif _island_tex:
				draw_texture_rect(_island_tex, Rect2(pos - Vector2(radius, radius), Vector2(radius * 2, radius * 2)), false)

			var label = island.get("name", "")
			draw_string(ThemeDB.fallback_font, pos + Vector2(-40 * s, -radius - 15 * s), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * s), Color(1, 1, 1, 0.8))

			var res_label = res_name.capitalize()
			draw_string(ThemeDB.fallback_font, pos + Vector2(-30 * s, radius + 5 * s), res_label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * s), Color(0.8, 0.9, 1.0, 0.7))

			for city_id in island.get("player_cities", []):
				var city = GameState.current_cities.get(city_id)
				if city:
					var city_pos = pos + Vector2(0, 20 * s)
					if _city_blue_tex:
						var cs = 16 * s
						draw_texture_rect(_city_blue_tex, Rect2(city_pos - Vector2(cs * 0.5, cs * 0.5), Vector2(cs, cs)), false)
					draw_string(ThemeDB.fallback_font, city_pos + Vector2(12 * s, 4 * s), city.get("name", ""),
						HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * s), Color(1, 1, 1, 0.9))
		else:
			if _island_tex:
				draw_texture_rect(_island_tex, Rect2(pos - Vector2(radius, radius), Vector2(radius * 2, radius * 2)), false, Color(0.3, 0.3, 0.35, 0.6))
			draw_string(ThemeDB.fallback_font, pos + Vector2(-20 * s, -5 * s), "???",
				HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * s), Color(0.5, 0.5, 0.5, 0.7))

		index += 1

	_draw_trade_routes(s)

func _draw_trade_routes(s: float) -> void:
	var route_color = Color(0.2, 0.6, 1.0, 0.5)
	var arrow_color = Color(0.3, 0.7, 1.0, 0.7)
	var player_cities = WorldManager.find_player_cities()

	if player_cities.size() < 2:
		return

	var city_positions = {}
	for cid in player_cities:
		var city = GameState.current_cities.get(cid)
		if not city:
			continue
		var island = GameState.current_islands.get(city.get("island_id", ""))
		if not island:
			continue
		var idx = island.get("index", 0)
		city_positions[cid] = _get_island_position(idx) + Vector2(0, 20 * s)

	for route in GameState.trade_routes.values():
		var from = route.get("from_city", "")
		var to = route.get("to_city", "")
		if not city_positions.has(from) or not city_positions.has(to):
			continue
		if not route.get("active", true):
			continue

		var start_pos = city_positions[from]
		var end_pos = city_positions[to]
		var mid = (start_pos + end_pos) * 0.5
		var offset = Vector2(0, -20 * s)
		var control = mid + offset

		var points = PackedVector2Array()
		points.append(start_pos)
		var steps = 20
		for i in range(steps + 1):
			var t = float(i) / steps
			var q0 = start_pos.lerp(control, t)
			var q1 = control.lerp(end_pos, t)
			var p = q0.lerp(q1, t)
			points.append(p)

		draw_polyline(points, route_color, 2.0 * s, true)

		var dir = (end_pos - start_pos).normalized()
		var perp = Vector2(-dir.y, dir.x)
		var tip = end_pos
		var base = end_pos - dir * (10 * s)
		var spread = perp * (6 * s)
		draw_line(tip, base + spread, arrow_color, 2.0 * s, true)
		draw_line(tip, base - spread, arrow_color, 2.0 * s, true)

func _get_island_position(index: int) -> Vector2:
	var spacing = ISLAND_SPACING * ResponsiveLayout.scale_factor
	var x = (index % _island_cols) * int(spacing * 2.5) + int(spacing * 0.75)
	var y = (index / _island_cols) * int(spacing * 2.5) + int(spacing * 0.75)
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
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
		else:
			_touch_points.erase(event.index)
			_last_pinch_distance = -1.0
	elif event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
		if _touch_points.size() == 1:
			_camera.position -= event.relative / _camera.zoom.x
		elif _touch_points.size() == 2:
			_handle_pinch()

func _handle_pinch() -> void:
	var points = _touch_points.values()
	var dist = points[0].distance_to(points[1])
	if _last_pinch_distance > 0:
		var factor = dist / _last_pinch_distance
		_camera.zoom = max(0.3, min(5.0, _camera.zoom * factor))
	_last_pinch_distance = dist

func _handle_click(screen_pos: Vector2) -> void:
	var world_pos = _camera.get_canvas_transform().affine_inverse() * screen_pos
	var radius = ISLAND_RADIUS * ResponsiveLayout.scale_factor

	var islands = GameState.current_islands
	var index = 0
	for island_id in islands:
		var island = islands[island_id]
		if not island.get("explored", false):
			index += 1
			continue

		var pos = _get_island_position(index)
		if world_pos.distance_to(pos) < radius:
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
