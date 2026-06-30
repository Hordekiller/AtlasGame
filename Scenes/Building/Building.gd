extends Node2D

var building_data: Dictionary = {}
var building_def: Dictionary = {}
var city_id: String = ""
var grid_pos: Vector2i

var _building_sprite: Sprite2D
var _highlight: Sprite2D
var _badge: Sprite2D
var _level_label: Label
var _worker_label: Label
var _progress_bg: ColorRect
var _progress_fill: ColorRect
var _progress_label: Label
var _ground: Sprite2D

var _tween: Tween
var _flash_rect: ColorRect
var _local_construct_left: float = -1.0
var _local_upgrade_left: float = -1.0

signal clicked(data: Dictionary, pos: Vector2i)

func setup(data: Dictionary, def: Dictionary, cid: String) -> void:
	building_data = data
	building_def = def
	city_id = cid
	grid_pos = data.get("grid_pos", Vector2i())
	_build_all()

func _tile_size() -> int:
	return ResponsiveLayout.get_tile_size()

func _build_all() -> void:
	_clear_children()

	var pos: Vector2i = grid_pos
	var ts = _tile_size()
	var size: Vector2i = building_data.get("size", Vector2i(2, 2))
	var level: int = building_data.get("level", 1)
	var bid: String = building_data.get("id", "unknown")
	var wc = _grid_to_world(pos) + Vector2(size * ts / 2.0)

	_ground = Sprite2D.new()
	_ground.texture = _get_ground_tex()
	_ground.position = wc
	_ground.centered = true
	_ground.scale = Vector2(size.x, size.y)
	_ground.z_index = 0
	add_child(_ground)

	var constructing = building_data.get("constructing", false)
	var upgrading = building_data.get("upgrading", false)
	var constructed = building_data.get("constructed", true)

	if constructing:
		_show_constructing(wc, size, bid)
	elif upgrading:
		_show_upgrading(wc, size, bid)
	else:
		_show_normal(wc, size, bid, level)

	var rect = RectangleShape2D.new()
	rect.size = Vector2(size * ts) - Vector2(4, 4)
	var area = Area2D.new()
	area.z_index = 2
	var col = CollisionShape2D.new()
	col.shape = rect
	area.add_child(col)
	area.position = wc
	area.input_event.connect(_on_clicked)
	add_child(area)

func _process(delta: float) -> void:
	if _local_construct_left > 0:
		_local_construct_left -= delta
		_update_progress_local("construct_time_total", "construct_time_left", _local_construct_left, Color(0.2, 0.7, 1.0))
	elif _local_upgrade_left > 0:
		_local_upgrade_left -= delta
		_update_progress_local("upgrade_time_total", "upgrade_time_left", _local_upgrade_left, Color(1.0, 0.7, 0.1))

func _update_progress_local(total_key: String, left_key: String, local_left: float, color: Color) -> void:
	var total = building_data.get(total_key, 1.0)
	var progress = 1.0 - (local_left / max(total, 0.01))
	if _progress_fill:
		_progress_fill.color = color
		_progress_fill.size.x = (_progress_bg.size.x if _progress_bg else 100) * clamp(progress, 0.0, 1.0)
	if _progress_label:
		var secs = int(max(0, local_left))
		if secs >= 60:
			_progress_label.text = "%d:%02d" % [secs / 60, secs % 60]
		else:
			_progress_label.text = "%ds" % secs

func _show_constructing(wc: Vector2, size: Vector2i, _bid: String) -> void:
	var cp = "res://Assets/Textures/Buildings/construct.png"
	if ResourceLoader.exists(cp):
		var scaffold = Sprite2D.new()
		scaffold.texture = ResourceLoader.load(cp)
		scaffold.position = wc
		scaffold.centered = true
		scaffold.scale = Vector2(max(1.0, size.x * 0.5), max(1.0, size.y * 0.5))
		scaffold.z_index = 1
		if ResourceLoader.exists("res://Assets/Shaders/building_glow.gdshader"):
			var mat = ShaderMaterial.new()
			mat.shader = ResourceLoader.load("res://Assets/Shaders/building_glow.gdshader")
			scaffold.material = mat
		add_child(scaffold)

	var total = building_data.get("construct_time_total", 1.0)
	_local_construct_left = building_data.get("construct_time_left", total)
	var progress = 1.0
	if total > 0:
		progress = 1.0 - (_local_construct_left / total)
	_make_progress_bar(wc, size, progress, Color(0.2, 0.7, 1.0))

func _show_upgrading(wc: Vector2, size: Vector2i, bid: String) -> void:
	var sp = Globals.get_building_sprite(bid)
	if ResourceLoader.exists(sp):
		var spr = Sprite2D.new()
		spr.texture = ResourceLoader.load(sp)
		spr.position = wc
		spr.centered = true
		spr.scale = Vector2(max(1.0, size.x * 0.5), max(1.0, size.y * 0.5))
		spr.z_index = 1
		spr.modulate = Color(1, 1, 1, 0.6)
		add_child(spr)

	var total = building_data.get("upgrade_time_total", 1.0)
	_local_upgrade_left = building_data.get("upgrade_time_left", total)
	var progress = 0.0
	if total > 0:
		progress = 1.0 - (_local_upgrade_left / total)
	_make_progress_bar(wc, size, progress, Color(1.0, 0.7, 0.1))

func _show_normal(wc: Vector2, size: Vector2i, bid: String, level: int) -> void:
	var sp = Globals.get_building_sprite(bid)
	if ResourceLoader.exists(sp):
		_building_sprite = Sprite2D.new()
		_building_sprite.texture = ResourceLoader.load(sp)
		_building_sprite.position = wc
		_building_sprite.centered = true
		_building_sprite.scale = Vector2(max(1.0, size.x * 0.5), max(1.0, size.y * 0.5))
		_building_sprite.z_index = 1
		_building_sprite.modulate = Color(1, 1, 1, 0.9)
		add_child(_building_sprite)
	else:
		var cat = building_def.get("category", -1)
		var cat_color = _get_category_color(cat)
		var placeholder = ColorRect.new()
		var ts = _tile_size()
		placeholder.size = Vector2(size * ts) - Vector2(8, 8)
		placeholder.position = wc - placeholder.size / 2
		placeholder.color = Color(cat_color.r, cat_color.g, cat_color.b, 0.5)
		placeholder.z_index = 1
		add_child(placeholder)
		var border = ColorRect.new()
		border.size = placeholder.size + Vector2(4, 4)
		border.position = wc - border.size / 2
		border.color = Color(cat_color.r * 0.6, cat_color.g * 0.6, cat_color.b * 0.6, 0.8)
		border.z_index = 0
		add_child(border)
		var name_label = Label.new()
		name_label.text = building_def.get("name", bid)
		name_label.position = wc - Vector2(placeholder.size.x / 2 - 4, 6)
		name_label.z_index = 2
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		add_child(name_label)

	_highlight = Sprite2D.new()
	_highlight.position = wc + Vector2(0, -8)
	_highlight.centered = true
	_highlight.texture = _get_highlight_tex()
	var cat = building_def.get("category", -1)
	_highlight.modulate = _get_category_color(cat)
	_highlight.self_modulate = Color(1, 1, 1, 0.12)
	_highlight.scale = Vector2(size.x * 0.6, 0.3)
	_highlight.z_index = 0
	add_child(_highlight)

	_badge = Sprite2D.new()
	_badge.texture = _get_badge_tex()
	_badge.position = wc + Vector2(-size.x * _tile_size() / 2 + 14, -size.y * _tile_size() / 2 + 14)
	_badge.centered = true
	_badge.scale = Vector2.ONE * 0.8
	_badge.z_index = 3
	add_child(_badge)

	_level_label = Label.new()
	_level_label.text = str(level)
	_level_label.position = wc + Vector2(-size.x * _tile_size() / 2 + 9, -size.y * _tile_size() / 2 + 6)
	_level_label.z_index = 4
	_level_label.add_theme_font_size_override("font_size", 11)
	_level_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	_level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_level_label.add_theme_constant_override("shadow_outline_size", 1)
	add_child(_level_label)

	_worker_label = Label.new()
	var assigned = building_data.get("workers_assigned", 0)
	var needed = BuildingManager.get_workers_needed(bid, level)
	_worker_label.text = "🧑 %d/%d" % [assigned, needed]
	_worker_label.position = wc + Vector2(-size.x * _tile_size() / 2 + 9, -size.y * _tile_size() / 2 + 22)
	_worker_label.z_index = 4
	_worker_label.add_theme_font_size_override("font_size", 8)
	_worker_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	add_child(_worker_label)

func update_workers() -> void:
	if not _worker_label:
		return
	var level = building_data.get("level", 1)
	var assigned = building_data.get("workers_assigned", 0)
	var needed = BuildingManager.get_workers_needed(building_data.get("id", ""), level)
	_worker_label.text = "🧑 %d/%d" % [assigned, needed]

func update_progress() -> void:
	var constructing = building_data.get("constructing", false)
	var upgrading = building_data.get("upgrading", false)
	if not (constructing or upgrading):
		_local_construct_left = -1.0
		_local_upgrade_left = -1.0
		if _progress_bg:
			_progress_bg.queue_free()
			_progress_fill.queue_free()
			_progress_label.queue_free()
		return

	var progress = 0.0
	var total = 1.0
	var color = Color(0.2, 0.7, 1.0)
	if constructing:
		total = building_data.get("construct_time_total", 1.0)
		_local_construct_left = building_data.get("construct_time_left", total)
		progress = 1.0 - (_local_construct_left / max(total, 0.01))
	elif upgrading:
		total = building_data.get("upgrade_time_total", 1.0)
		_local_upgrade_left = building_data.get("upgrade_time_left", total)
		progress = 1.0 - (_local_upgrade_left / max(total, 0.01))
		color = Color(1.0, 0.7, 0.1)

	if _progress_fill:
		_progress_fill.color = color
		_progress_fill.size.x = (_progress_bg.size.x if _progress_bg else 100) * clamp(progress, 0.0, 1.0)
	if _progress_label:
		_progress_label.text = "%d%%" % (progress * 100)

func flash_effect() -> void:
	var ts = _tile_size()
	var size = building_data.get("size", Vector2i(2, 2))
	var wc = position + Vector2(size.x * ts / 2.0, size.y * ts / 2.0)

	_flash_rect = ColorRect.new()
	_flash_rect.size = Vector2(size.x * ts, size.y * ts)
	_flash_rect.position = Vector2(0, 0)
	_flash_rect.color = Color(1, 1, 0.8, 0.6)
	_flash_rect.z_index = 10
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)

	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(_flash_rect, "color", Color(1, 1, 0.8, 0.0), 0.4)
	_tween.tween_property(_flash_rect, "scale", Vector2(1.3, 1.3), 0.4)
	_tween.tween_callback(_cleanup_flash).set_delay(0.5)

func _cleanup_flash() -> void:
	if _flash_rect and is_instance_valid(_flash_rect):
		_flash_rect.queue_free()

func _make_progress_bar(wc: Vector2, size: Vector2i, progress: float, color: Color) -> void:
	var ts = _tile_size()
	var bar_w = size.x * ts - 16
	var bar_h = 6
	var bar_pos = wc + Vector2(-bar_w / 2.0, -size.y * ts / 2.0 - 10)

	_progress_bg = ColorRect.new()
	_progress_bg.size = Vector2(bar_w, bar_h)
	_progress_bg.position = bar_pos
	_progress_bg.color = Color(0.1, 0.1, 0.15, 0.8)
	_progress_bg.z_index = 5
	add_child(_progress_bg)

	if progress > 0.01:
		_progress_fill = ColorRect.new()
		_progress_fill.size = Vector2(bar_w * clamp(progress, 0.0, 1.0), bar_h)
		_progress_fill.position = bar_pos
		_progress_fill.color = color
		_progress_fill.z_index = 6
		add_child(_progress_fill)

	_progress_label = Label.new()
	_progress_label.text = "%d%%" % (progress * 100)
	_progress_label.position = bar_pos + Vector2(bar_w + 4, -2)
	_progress_label.z_index = 6
	_progress_label.add_theme_font_size_override("font_size", 9)
	_progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	add_child(_progress_label)

func _on_clicked(_viewport: Node, event: InputEvent, _si: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_button_click()
		clicked.emit(building_data, grid_pos)

func _clear_children() -> void:
	for c in get_children():
		if is_instance_valid(c):
			c.queue_free()

func _grid_to_world(g: Vector2i) -> Vector2:
	var ts = _tile_size()
	return Vector2(g.x * ts, g.y * ts)

var _ground_tex: Texture = null
var _badge_tex: Texture = null
var _highlight_tex: Texture = null

func _get_ground_tex() -> Texture:
	if not _ground_tex:
		var p = "res://Assets/Textures/Buildings/ground.png"
		_ground_tex = ResourceLoader.load(p) if ResourceLoader.exists(p) else PlaceholderTexture2D.new()
	return _ground_tex

func _get_highlight_tex() -> Texture:
	if not _highlight_tex:
		var img = Image.create(32, 16, false, Image.FORMAT_RGBA8)
		for x in range(32):
			for y in range(16):
				var d = abs(x - 15.5) / 15.5
				var a = max(0.0, 1.0 - d * 2.0) * (1.0 - y / 16.0)
				img.set_pixel(x, y, Color(1, 1, 1, a * 0.5))
		_highlight_tex = ImageTexture.create_from_image(img)
	return _highlight_tex

func _get_badge_tex() -> Texture:
	if not _badge_tex:
		var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
		for x in range(24):
			for y in range(24):
				var dx = x - 12
				var dy = y - 12
				var dist = sqrt(dx * dx + dy * dy)
				if dist < 10:
					img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 0.85))
				elif dist < 11:
					img.set_pixel(x, y, Color(0.7, 0.6, 0.3, 0.9))
		_badge_tex = ImageTexture.create_from_image(img)
	return _badge_tex

func _get_category_color(cat: int) -> Color:
	match cat:
		Globals.BuildingCategory.RESOURCE: return Color(0.3, 0.8, 0.3)
		Globals.BuildingCategory.PRODUCTION: return Color(0.8, 0.5, 0.2)
		Globals.BuildingCategory.STORAGE: return Color(0.6, 0.6, 0.3)
		Globals.BuildingCategory.MILITARY: return Color(0.85, 0.2, 0.2)
		Globals.BuildingCategory.RESEARCH: return Color(0.3, 0.4, 0.9)
		Globals.BuildingCategory.CULTURE: return Color(0.7, 0.3, 0.7)
		Globals.BuildingCategory.INFRASTRUCTURE: return Color(0.4, 0.6, 0.8)
		_: return Color(0.5, 0.5, 0.5)
