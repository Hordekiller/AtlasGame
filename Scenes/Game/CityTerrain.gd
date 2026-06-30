extends Node2D

const HEX_PATH = "res://Assets/Textures/Buildings/kenney_hex/Previews/"

const GROUND_VARIANTS: Array[String] = [
	"dirt", "stone", "sand", "grass-forest",
]

var _nodes: Array = []
var _city_id: String = ""
var _grid_size: int = 16
var _rng: RandomNumberGenerator
var _tex_cache: Dictionary = {}

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func _tex(name: String) -> Texture2D:
	if _tex_cache.has(name):
		return _tex_cache[name]
	var path = HEX_PATH + name + ".png"
	if ResourceLoader.exists(path):
		var t = ResourceLoader.load(path) as Texture2D
		_tex_cache[name] = t
		return t
	return null

func build(city_id: String, grid_size: int) -> void:
	_city_id = city_id
	_grid_size = grid_size
	_rng.seed = hash(city_id)
	_clear()
	_generate_ground()
	_generate_roads()
	_generate_walls()
	_generate_edge_decor()

func _clear() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()

func _place(name: String, gp: Vector2i, z: int, s: float = 1.0, c: Color = Color(1, 1, 1, 1)) -> Sprite2D:
	var tex = _tex(name)
	if not tex:
		return null
	var ts = ResponsiveLayout.get_tile_size()
	var pos = Vector2(gp.x * ts, gp.y * ts) + Vector2(ts * 0.5, ts * 0.5)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = pos
	spr.centered = true
	spr.z_index = z
	spr.scale = Vector2(s, s)
	spr.modulate = c
	add_child(spr)
	_nodes.append(spr)
	return spr

func _generate_ground() -> void:
	var gs = _grid_size
	for x in range(gs):
		for y in range(gs):
			var gp = Vector2i(x, y)
			_place("grass", gp, -10)

			_rng.seed = hash(_city_id) ^ hash(gp) ^ hash("gv")
			if _rng.randf() > 0.12:
				continue
			var v = GROUND_VARIANTS[_rng.randi() % GROUND_VARIANTS.size()]
			_place(v, gp, -9, 0.7, Color(1, 1, 1, 0.45))

func _generate_roads() -> void:
	var gs = _grid_size
	var cx = gs / 2 - 1
	var cy = gs / 2 - 1

	# Main N-S roads at columns cx, cx+1
	for y in range(gs):
		_place("path-straight", Vector2i(cx, y), -8, 0.85, Color(1, 1, 1, 0.6))
		_place("path-straight", Vector2i(cx + 1, y), -8, 0.85, Color(1, 1, 1, 0.6))

	# Main E-W roads at rows cy, cy+1
	for x in range(gs):
		_place("path-straight", Vector2i(x, cy), -8, 0.85, Color(1, 1, 1, 0.6))
		_place("path-straight", Vector2i(x, cy + 1), -8, 0.85, Color(1, 1, 1, 0.6))

	# Center crossing plaza (4x4 area)
	for ox in range(4):
		for oy in range(4):
			_place("path-square", Vector2i(cx - 1 + ox, cy - 1 + oy), -8, 0.9, Color(1, 1, 1, 0.7))

	# Path intersections at road crossings
	for x in [cx, cx + 1]:
		for y in [cy, cy + 1]:
			_place("path-crossing", Vector2i(x, y), -7)

	# Ring road (inner ring at columns/rows 2-3 and gs-4, gs-3)
	var ring_inner = 2
	var ring_outer = gs - 3
	for x in range(ring_inner, ring_outer + 1):
		_place("path-straight", Vector2i(x, ring_inner), -8, 0.8, Color(1, 1, 1, 0.35))
		_place("path-straight", Vector2i(x, ring_outer), -8, 0.8, Color(1, 1, 1, 0.35))
	for y in range(ring_inner, ring_outer + 1):
		_place("path-straight", Vector2i(ring_inner, y), -8, 0.8, Color(1, 1, 1, 0.35))
		_place("path-straight", Vector2i(ring_outer, y), -8, 0.8, Color(1, 1, 1, 0.35))
	for x in [ring_inner, ring_outer]:
		for y in [ring_inner, ring_outer]:
			_place("path-corner", Vector2i(x, y), -8, 0.85, Color(1, 1, 1, 0.5))

func _generate_walls() -> void:
	var gs = _grid_size
	var cx = gs / 2 - 1
	var cy = gs / 2 - 1

	# Top wall (y = 0)
	for x in range(gs):
		if x in [cx, cx + 1, cx + 2]:
			continue
		_place("building-wall", Vector2i(x, 0), -7, 0.8)

	# Bottom wall (y = gs-1)
	for x in range(gs):
		if x in [cx, cx + 1, cx + 2]:
			continue
		_place("building-wall", Vector2i(x, gs - 1), -7, 0.8)

	# Left wall (x = 0)
	for y in range(gs):
		if y in [cy, cy + 1, cy + 2]:
			continue
		_place("building-wall", Vector2i(0, y), -7, 0.8)

	# Right wall (x = gs-1)
	for y in range(gs):
		if y in [cy, cy + 1, cy + 2]:
			continue
		_place("building-wall", Vector2i(gs - 1, y), -7, 0.8)

	# Corner towers
	for cx2 in [0, gs - 1]:
		for cy2 in [0, gs - 1]:
			_place("building-tower", Vector2i(cx2, cy2), -6, 1.0)

func _generate_edge_decor() -> void:
	var gs = _grid_size
	var cx = gs / 2 - 1
	var cy = gs / 2 - 1

	# Gate markers at road entrances (N, S, E, W)
	var gates = [
		Vector2i(cx + 1, 0), Vector2i(cx + 1, gs - 1),
		Vector2i(0, cy + 1), Vector2i(gs - 1, cy + 1),
	]
	for g in gates:
		_place("building-tower", g, -6, 0.8, Color(1, 1, 1, 0.8))

	# Small flags/torches at gate openings
	var gate_flags = [
		Vector2i(cx, 0), Vector2i(cx + 2, 0),
		Vector2i(cx, gs - 1), Vector2i(cx + 2, gs - 1),
		Vector2i(0, cy), Vector2i(0, cy + 2),
		Vector2i(gs - 1, cy), Vector2i(gs - 1, cy + 2),
	]
	for gf in gate_flags:
		_place("unit-wall-tower", gf, -6, 0.6, Color(1, 1, 1, 0.7))

func update_for_new_building(gp: Vector2i) -> void:
	pass
