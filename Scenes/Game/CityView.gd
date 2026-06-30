extends Node2D

const TILE_SIZE: int = 64
const GRID_LINE_COLOR: Color = Color(0.3, 0.3, 0.35, 0.3)
const GRID_SIZE: int = 16

const BUILDING_SCENE = preload("res://Scenes/Building/Building.tscn")

var _camera: Camera2D
var _drag_start: Vector2
var _is_dragging: bool = false

var _hovered_tile: Vector2i = Vector2i(-1, -1)
var _selected_tile: Vector2i = Vector2i(-1, -1)
var _placement_mode: bool = false
var _placement_building_id: String = ""

var _city_id: String = ""
var _building_nodes: Dictionary = {}

func _ready() -> void:
	_camera = $Camera2D
	_city_id = GameState.selected_city_id

	EventBus.building_constructed.connect(_on_building_changed)
	EventBus.building_demolished.connect(_on_building_demolished)
	EventBus.city_selected.connect(_on_city_selected)
	EventBus.building_upgrade_complete.connect(_on_upgrade_complete)
	EventBus.building_construct_complete.connect(_on_construct_complete)
	EventBus.building_upgrade_progress.connect(_on_progress_update)
	EventBus.building_construct_progress.connect(_on_progress_update)

	_update_camera_for_viewport()
	get_viewport().size_changed.connect(_update_camera_for_viewport)
	_setup_water_shader()
	rebuild_all()

func _setup_water_shader() -> void:
	if ResourceLoader.exists("res://Assets/Shaders/water.gdshader"):
		var bg = $Bg
		if bg:
			var mat = ShaderMaterial.new()
			mat.shader = ResourceLoader.load("res://Assets/Shaders/water.gdshader")
			bg.material = mat

func _update_camera_for_viewport() -> void:
	var vp = get_viewport().get_visible_rect()
	var ts = ResponsiveLayout.get_tile_size()
	_camera.position = Vector2(GRID_SIZE * ts * 0.5, GRID_SIZE * ts * 0.5)
	var zoom_x = vp.size.x / (GRID_SIZE * ts * 1.5)
	var zoom_y = vp.size.y / (GRID_SIZE * ts * 1.3)
	var zoom = min(zoom_x, zoom_y)
	_camera.zoom = Vector2(clampf(zoom, 0.4, 1.2), clampf(zoom, 0.4, 1.2))

func _on_city_selected(city_id: String) -> void:
	_city_id = city_id
	_update_camera_for_viewport()
	rebuild_all()

func rebuild_all() -> void:
	_clear_all_nodes()
	_build_all()
	queue_redraw()

func _clear_all_nodes() -> void:
	for key in _building_nodes:
		var n = _building_nodes[key]
		if is_instance_valid(n):
			n.queue_free()
	_building_nodes.clear()

func _build_all() -> void:
	var city = GameState.current_cities.get(_city_id)
	if not city:
		return
	var buildings = city.get("buildings", {})
	var placed: Dictionary = {}
	for pos in buildings:
		var data = buildings[pos]
		var og = data.get("grid_pos", pos)
		var k = Vector2i(og.x, og.y)
		if placed.has(k):
			continue
		placed[k] = true
		_build_single(data)

func _build_single(data: Dictionary) -> void:
	var pos: Vector2i = data.get("grid_pos", Vector2i())
	var bid: String = data.get("id", "unknown")
	var defn = BuildingManager.get_building_def(bid)
	if defn.is_empty():
		return

	var building = BUILDING_SCENE.instantiate()
	building.setup(data, defn, _city_id)
	var ts = ResponsiveLayout.get_tile_size()
	building.position = Vector2(pos.x * ts, pos.y * ts)
	building.clicked.connect(_on_building_clicked_from_scene)
	add_child(building)

	_building_nodes[Vector2i(pos.x, pos.y)] = building

func _on_building_clicked_from_scene(_data: Dictionary, grid_pos: Vector2i) -> void:
	if _placement_mode:
		return
	_selected_tile = grid_pos
	_on_building_clicked_action()

func update_view() -> void:
	rebuild_all()

func _on_building_changed(city_id: String, _bid: String, _pos: Vector2i) -> void:
	if city_id == _city_id:
		rebuild_all()

func _on_building_demolished(city_id: String, _pos: Vector2i) -> void:
	if city_id == _city_id:
		rebuild_all()

func _on_upgrade_complete(city_id: String, grid_pos: Vector2i, _bid: String, _new_level: int) -> void:
	if city_id == _city_id:
		_flash_effect(grid_pos)
		_update_building_node(grid_pos)

func _on_construct_complete(city_id: String, grid_pos: Vector2i, _bid: String) -> void:
	if city_id == _city_id:
		_flash_effect(grid_pos)
		_update_building_node(grid_pos)

func _on_progress_update(city_id: String, grid_pos: Vector2i, _progress: float, _total: float) -> void:
	if city_id != _city_id:
		return
	var key = Vector2i(grid_pos.x, grid_pos.y)
	var b = _building_nodes.get(key)
	if b and is_instance_valid(b) and b.has_method("update_progress"):
		b.update_progress()

func _flash_effect(grid_pos: Vector2i) -> void:
	var key = Vector2i(grid_pos.x, grid_pos.y)
	var b = _building_nodes.get(key)
	if b and is_instance_valid(b) and b.has_method("flash_effect"):
		b.flash_effect()
	else:
		rebuild_all()

func _update_building_node(grid_pos: Vector2i) -> void:
	var key = Vector2i(grid_pos.x, grid_pos.y)
	var existing = _building_nodes.get(key)
	if is_instance_valid(existing):
		var data = _get_building_data(key)
		var defn = BuildingManager.get_building_def(data.get("id", ""))
		if not defn.is_empty():
			existing.setup(data, defn, _city_id)

func _get_building_data(grid_pos: Vector2i) -> Dictionary:
	var city = GameState.current_cities.get(_city_id)
	if not city:
		return {}
	return city.get("buildings", {}).get(grid_pos, {})

func _draw() -> void:
	_draw_grid()
	_draw_placement_preview()

func _draw_grid() -> void:
	var city = GameState.current_cities.get(_city_id)
	var gs = city.get("grid_size", GRID_SIZE) if city else GRID_SIZE
	for x in range(gs + 1):
		draw_line(_grid_to_world(Vector2i(x, 0)), _grid_to_world(Vector2i(x, gs)), GRID_LINE_COLOR, 1.0)
	for y in range(gs + 1):
		draw_line(_grid_to_world(Vector2i(0, y)), _grid_to_world(Vector2i(gs, y)), GRID_LINE_COLOR, 1.0)
	var cn = city.get("name", "") if city else ""
	if not cn.is_empty():
		var tp = _grid_to_world(Vector2i(gs / 2, -1))
		draw_string(ThemeDB.fallback_font, tp, cn, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1, 1, 1, 0.7))

func _draw_placement_preview() -> void:
	if _hovered_tile.x < 0:
		return
	var defn = null
	var size = Vector2i(1, 1)
	var color = Color(0, 1, 0, 0.25)

	if _placement_mode:
		defn = BuildingManager.get_building_def(_placement_building_id)
		if defn:
			size = defn.get("size", Vector2i(1, 1))
		var check = BuildingManager.can_place_building(_city_id, _placement_building_id, _hovered_tile)
		color = Color(0, 1, 0, 0.25) if check.success else Color(1, 0, 0, 0.25)

		var wp = _grid_to_world(_hovered_tile)
		var ts = ResponsiveLayout.get_tile_size()
		draw_rect(Rect2(wp, size * ts), color, true)

		var sp = Globals.get_building_sprite(_placement_building_id)
		if ResourceLoader.exists(sp):
			var tex = ResourceLoader.load(sp) as Texture2D
			if tex:
				var ts2 = size.x * ts * 0.5
				var center = wp + size * ts / 2
				var alpha = 0.4 if not check.success else 0.7
				draw_texture_rect(tex, Rect2(center - Vector2(ts2 * 0.5, ts2 * 0.5), Vector2(ts2, ts2)), false, Color(1, 1, 1, alpha))
	else:
		var ts = ResponsiveLayout.get_tile_size()
		draw_rect(Rect2(_grid_to_world(_hovered_tile), Vector2(ts, ts)), Color(1, 1, 1, 0.1), true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				_drag_start = get_global_mouse_position()
				_is_dragging = false
			elif not _is_dragging:
				var tile = _screen_to_grid(get_global_mouse_position())
				if _placement_mode:
					_try_place_building(tile)
				else:
					_selected_tile = tile
					_on_building_clicked_action()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed() and _placement_mode:
			_cancel_placement()
			event.accept()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom = max(0.3, _camera.zoom * 0.9)
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var mp = get_global_mouse_position()
			var delta = mp - _drag_start
			if delta.length() > 15:
				_is_dragging = true
			if _is_dragging:
				_camera.position -= delta / _camera.zoom.x
				_drag_start = mp
		else:
			_hovered_tile = _screen_to_grid(get_global_mouse_position())
			queue_redraw()
	elif event is InputEventPanGesture:
		_camera.position -= event.delta * 100 / _camera.zoom.x
	elif event is InputEventMagnifyGesture:
		var z = _camera.zoom * (1.0 / event.factor)
		_camera.zoom = max(Vector2(0.3, 0.3), min(Vector2(5.0, 5.0), z))

func _screen_to_grid(sp: Vector2) -> Vector2i:
	var local = sp - global_position
	var city = GameState.current_cities.get(_city_id)
	var gs = city.get("grid_size", GRID_SIZE) if city else GRID_SIZE
	var ts = ResponsiveLayout.get_tile_size()
	return Vector2i(
		clamp(int(floor(local.x / ts)), 0, gs - 1),
		clamp(int(floor(local.y / ts)), 0, gs - 1)
	)

func _grid_to_world(g: Vector2i) -> Vector2:
	var ts = ResponsiveLayout.get_tile_size()
	return Vector2(g.x * ts, g.y * ts)

func enter_placement_mode(bid: String) -> void:
	_placement_mode = true
	_placement_building_id = bid

func _try_place_building(tile: Vector2i) -> void:
	if not _placement_mode:
		return
	var r = BuildingManager.can_place_building(_city_id, _placement_building_id, tile)
	if r.success:
		BuildingManager.place_building(_city_id, _placement_building_id, tile)
		UIManager.show_notification("در حال ساخت...", "info")
		_cancel_placement()
	else:
		UIManager.show_notification(r.get("reason", "خطا"), "error")

func _cancel_placement() -> void:
	_placement_mode = false
	_placement_building_id = ""
	queue_redraw()

func _on_building_clicked_action() -> void:
	var city = GameState.current_cities.get(_city_id)
	if not city:
		return
	var b = city.get("buildings", {}).get(_selected_tile)
	if b:
		EventBus.building_selected.emit(_city_id, b.get("grid_pos", _selected_tile))
