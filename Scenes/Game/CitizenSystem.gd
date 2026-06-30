extends Node2D

var _city_id: String = ""
var _citizens: Array = []
var _citizen_scene: PackedScene

const MAX_CITIZENS: int = 20
const WANDER_RADIUS: float = 80.0

func _ready() -> void:
	var img = Image.create(8, 12, false, Image.FORMAT_RGBA8)
	for x in range(8):
		for y in range(12):
			var c = Color(0, 0, 0, 0)
			if y < 10:
				var body = (x >= 2 and x < 6)
				var head = (y < 4 and body)
				if body or head:
					var shade = 0.5 + (y * 0.04)
					c = Color(0.9 * shade, 0.75 * shade, 0.6 * shade, 1)
			img.set_pixel(x, y, c)

	var tex = ImageTexture.create_from_image(img)
	var sprite_inst = Sprite2D.new()
	sprite_inst.texture = tex
	sprite_inst.centered = true

	_citizen_scene = PackedScene.new()
	_citizen_scene.pack(sprite_inst)
	sprite_inst.queue_free()

	EventBus.city_selected.connect(_on_city_selected)
	EventBus.resource_changed.connect(_on_resource_changed)

func _on_city_selected(city_id: String) -> void:
	_city_id = city_id
	_refresh_citizens()

func _on_resource_changed(city_id: String, rtype: String, new_amount: float, _delta: float) -> void:
	if city_id != _city_id:
		return
	if int(rtype) == Globals.ResourceType.POPULATION:
		_refresh_citizens()

func _refresh_citizens() -> void:
	_clear_citizens()

	var city = GameState.current_cities.get(_city_id)
	if not city:
		return
	var pop = int(city.get("resources", {}).get(Globals.ResourceType.POPULATION, 0))
	var satisfaction = city.get("satisfaction", 100.0)
	var sat_factor = clampf(satisfaction / 100.0, 0.2, 1.5)
	var count = clampi(int(pop / 3 * sat_factor), 0, MAX_CITIZENS)

	var buildings = city.get("buildings", {})
	var positions: Array = []
	var processed: Array = []
	for pos in buildings:
		var data = buildings[pos]
		if processed.has(data):
			continue
		processed.append(data)
		if data.get("constructed", false) and not data.get("constructing", false):
			var gp = data.get("grid_pos", pos)
			var size = data.get("size", Vector2i(2, 2))
			var cx = gp.x * 64 + size.x * 32
			var cy = gp.y * 64 + size.y * 32
			positions.append(Vector2(cx, cy))

	if positions.is_empty():
		return

	var rng = RandomNumberGenerator.new()
	for i in range(count):
		var base = positions[i % positions.size()]
		var offset = Vector2(rng.randf_range(-WANDER_RADIUS, WANDER_RADIUS), rng.randf_range(-WANDER_RADIUS, WANDER_RADIUS))
		_spawn_citizen(base + offset, satisfaction)

func _spawn_citizen(pos: Vector2, satisfaction: float = 100.0) -> void:
	if not _citizen_scene:
		return
	var c = _citizen_scene.instantiate()
	c.position = pos
	c.z_index = 5
	var sat_scale = clampf(satisfaction / 100.0, 0.6, 1.2)
	c.scale = Vector2(0.8, 0.8) * sat_scale

	if satisfaction >= 80.0:
		c.modulate = Color(0.8, 1.0, 0.8, 1.0)
	elif satisfaction >= 50.0:
		c.modulate = Color(1.0, 1.0, 0.8, 1.0)
	else:
		c.modulate = Color(1.0, 0.7, 0.7, 1.0)

	add_child(c)
	_citizens.append(c)

	var wander_range = 30.0 * sat_scale
	var speed_factor = 1.0 / maxf(sat_scale, 0.1)

	var tween = create_tween().set_loops()
	var target = pos + Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	tween.tween_property(c, "position", target, randf_range(2.0, 4.0) * speed_factor)
	tween.tween_callback(func():
		if is_instance_valid(c):
			target = pos + Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
			var t2 = create_tween().set_loops()
			t2.tween_property(c, "position", target, randf_range(2.0, 4.0) * speed_factor)
	)

func _clear_citizens() -> void:
	for c in _citizens:
		if is_instance_valid(c):
			c.queue_free()
	_citizens.clear()
