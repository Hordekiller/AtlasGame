extends Node2D

const DECOR_PATH = "res://Assets/Textures/Decorations/"

const DECOR_TREES: Array[String] = [
	"decor_tree_1", "decor_tree_2", "decor_tree_3", "decor_tree_4",
	"decor_palm_1", "decor_palm_2", "decor_palm_3",
]
const DECOR_ROCKS: Array[String] = [
	"decor_rock_1", "decor_rock_2", "decor_rock_3", "decor_rock_4",
]
const DECOR_GRASS: Array[String] = [
	"decor_grass_1", "decor_grass_2",
]
const DECOR_FLAGS: Array[String] = [
	"decor_flag_blue", "decor_flag_red", "decor_flag_pirate",
]
const DECOR_CULTURE: Array[String] = [
	"decor_statue", "decor_column", "decor_fountain", "decor_banner",
]
const DECOR_PROPS: Array[String] = [
	"decor_barrel", "decor_crate", "decor_lantern", "decor_pillar",
	"decor_weapon_rack",
]
const DECOR_HEDGE: Array[String] = [
	"decor_hedge", "decor_hedge_large",
]

var _decor_nodes: Array = []
var _city_id: String = ""
var _grid_size: int = 16
var _rng: RandomNumberGenerator

var _decor_textures: Dictionary = {}

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_preload_textures()

func _preload_textures() -> void:
	var names = DECOR_TREES + DECOR_ROCKS + DECOR_GRASS + DECOR_FLAGS + DECOR_CULTURE + DECOR_PROPS + DECOR_HEDGE
	for name in names:
		var path = DECOR_PATH + name + ".png"
		if ResourceLoader.exists(path):
			_decor_textures[name] = ResourceLoader.load(path)

func build(city_id: String, grid_size: int) -> void:
	_city_id = city_id
	_grid_size = grid_size
	_clear()
	_place_decorations()

func _clear() -> void:
	for n in _decor_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_decor_nodes.clear()

func _place_decorations() -> void:
	var city = GameState.current_cities.get(_city_id)
	if not city:
		return
	var buildings = city.get("buildings", {})
	var occupied: Dictionary = {}
	for pos in buildings:
		var data = buildings[pos]
		var og = data.get("grid_pos", pos)
		var size = data.get("size", Vector2i(1, 1))
		var bid = data.get("id", "")
		for x in range(size.x):
			for y in range(size.y):
				occupied[Vector2i(og.x + x, og.y + y)] = bid

	var ts = ResponsiveLayout.get_tile_size()
	for grid_x in range(_grid_size):
		for grid_y in range(_grid_size):
			var gp = Vector2i(grid_x, grid_y)
			if occupied.has(gp):
				var bid = occupied[gp]
				_place_building_specific_decor(gp, bid, ts)
				continue

			_place_random_decor(gp, ts, grid_x, grid_y)

func _place_building_specific_decor(gp: Vector2i, bid: String, ts: int) -> void:
	var wp = Vector2(gp.x * ts, gp.y * ts) + Vector2(ts / 2, ts / 2)

	match bid:
		"barracks", "watchtower", "cannon", "pirate_fortress":
			_spawn_decor("decor_flag_red", wp + Vector2(-ts * 0.3, -ts * 0.1))
			_spawn_decor("decor_weapon_rack", wp + Vector2(ts * 0.35, 0))
		"port", "shipyard", "harbor_chain":
			_spawn_decor("decor_flag_blue", wp + Vector2(ts * 0.3, -ts * 0.1))
			_spawn_decor("decor_palm_1", wp + Vector2(-ts * 0.35, 0))
			_spawn_decor("decor_barrel", wp + Vector2(0, ts * 0.2))
		"temple", "academy", "museum", "palace", "governor_residence":
			_spawn_decor("decor_statue", wp + Vector2(0, -ts * 0.3))
			_spawn_decor("decor_pillar", wp + Vector2(-ts * 0.35, -ts * 0.1))
			_spawn_decor("decor_pillar", wp + Vector2(ts * 0.35, -ts * 0.1))
		"town_hall":
			_spawn_decor("decor_fountain", wp + Vector2(0, -ts * 0.2))
			_spawn_decor("decor_lantern", wp + Vector2(-ts * 0.35, -ts * 0.1))
			_spawn_decor("decor_lantern", wp + Vector2(ts * 0.35, -ts * 0.1))
		"marketplace":
			_spawn_decor("decor_banner", wp + Vector2(0, -ts * 0.25))
			_spawn_decor("decor_crate", wp + Vector2(-ts * 0.3, ts * 0.15))
		"warehouse", "vault":
			_spawn_decor("decor_crate", wp + Vector2(-ts * 0.3, 0))
			_spawn_decor("decor_barrel", wp + Vector2(ts * 0.3, 0))
		"tavern":
			_spawn_decor("decor_barrel", wp + Vector2(-ts * 0.3, 0))
			_spawn_decor("decor_lantern", wp + Vector2(ts * 0.3, -ts * 0.15))

func _place_random_decor(gp: Vector2i, ts: int, grid_x: int, grid_y: int) -> void:
	_rng.seed = hash(_city_id) ^ hash(gp)

	var rand_val = _rng.randf()
	if rand_val > 0.35:
		return

	var wp = Vector2(gp.x * ts, gp.y * ts) + Vector2(ts / 2, ts / 2)
	var is_edge = grid_x == 0 or grid_y == 0 or grid_x == _grid_size - 1 or grid_y == _grid_size - 1

	if rand_val < 0.08:
		var tree = DECOR_TREES[_rng.randi() % DECOR_TREES.size()]
		_spawn_decor(tree, wp + Vector2(0, -ts * 0.15))
	elif rand_val < 0.14:
		var rock = DECOR_ROCKS[_rng.randi() % DECOR_ROCKS.size()]
		_spawn_decor(rock, wp)
	elif rand_val < 0.20:
		var grass = DECOR_GRASS[_rng.randi() % DECOR_GRASS.size()]
		_spawn_decor(grass, wp)
	elif rand_val < 0.27 and is_edge:
		var hedge = DECOR_HEDGE[_rng.randi() % DECOR_HEDGE.size()]
		_spawn_decor(hedge, wp)
	elif rand_val < 0.32:
		var prop = DECOR_PROPS[_rng.randi() % DECOR_PROPS.size()]
		_spawn_decor(prop, wp + Vector2(0, ts * 0.1))

func _spawn_decor(name: String, pos: Vector2) -> void:
	var tex = _decor_textures.get(name)
	if not tex:
		return
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = pos
	spr.centered = true
	spr.z_index = -1
	var tw = tex.get_width()
	var th = tex.get_height()
	var s = ResponsiveLayout.scale_factor
	spr.scale = Vector2(s, s)
	add_child(spr)
	_decor_nodes.append(spr)
