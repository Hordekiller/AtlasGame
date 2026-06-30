extends Node

signal game_won(reason: String)
signal game_lost(reason: String)
signal city_expanded(city_id: String, island_id: String)
signal npc_faction_defeated(faction_id: String)

var tutorial_completed: bool = false
var win_conditions: Dictionary = {
	"islands_controlled": 5,
	"npc_factions_defeated": 3,
	"max_city_level": 20
}
var lose_conditions: Dictionary = {
	"population_zero_days": 5,
	"treasury_negative_days": 3
}
var _population_zero_days: int = 0
var _treasury_negative_days: int = 0

func _ready() -> void:
	EventBus.city_created.connect(_on_city_created)
	EventBus.npc_faction_defeated.connect(_on_npc_defeated)

func check_win_conditions() -> void:
	var islands_controlled = 0
	var max_city_level = 0
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		if city.get("player", "") != "NPC":
			var island_id = city.get("island_id", "")
			if island_id.length() > 0:
				var island = GameState.current_islands.get(island_id, {})
				if island.get("player_cities", []).size() > 0:
					islands_controlled += 1
			for pos in city.get("buildings", {}):
				var b = city["buildings"][pos]
				if b.get("id") == "town_hall" and b.get("constructed", false):
					max_city_level = max(max_city_level, b.get("level", 1))

	var npc_defeated = GameState.npc_factions_defeated

	if islands_controlled >= win_conditions["islands_controlled"]:
		game_won.emit("شما بر ۵ جزیره مسلط شده‌اید!")
	elif max_city_level >= win_conditions["max_city_level"]:
		game_won.emit("شهر شما به سطح ۲۰ رسیده است!")
	elif npc_defeated >= win_conditions["npc_factions_defeated"]:
		game_won.emit("شما ۳ جناح دشمن را شکست داده‌اید!")

func check_lose_conditions() -> void:
	var total_population = 0
	var total_gold = 0
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		if city.get("player", "") != "NPC":
			total_population += int(city.get("resources", {}).get(Globals.ResourceType.POPULATION, 0))
			total_gold += city.get("resources", {}).get(Globals.ResourceType.GOLD, 0)

	if total_population <= 0:
		_population_zero_days += 1
	else:
		_population_zero_days = 0
	if total_gold < 0:
		_treasury_negative_days += 1
	else:
		_treasury_negative_days = 0

	if _population_zero_days >= lose_conditions["population_zero_days"]:
		game_lost.emit("جمعیت همه شهرها به صفر رسیده است!")
	elif _treasury_negative_days >= lose_conditions["treasury_negative_days"]:
		game_lost.emit("خزانه برای ۳ روز منفی بوده است!")

	var all_destroyed = true
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		if city.get("player", "") != "NPC":
			all_destroyed = false
			break
	if all_destroyed:
		game_lost.emit("تمام شهرهای شما نابود شده‌اند!")

func _on_city_created(city_id: String, _name: String, island_id: String) -> void:
	city_expanded.emit(city_id, island_id)
	check_win_conditions()

func _on_npc_defeated(faction_id: String) -> void:
	GameState.npc_factions_defeated += 1
	npc_faction_defeated.emit(faction_id)
	check_win_conditions()

func get_save_data() -> Dictionary:
	return {
		"tutorial_completed": tutorial_completed,
		"population_zero_days": _population_zero_days,
		"treasury_negative_days": _treasury_negative_days,
		"npc_factions_defeated": GameState.npc_factions_defeated
	}

func load_save_data(data: Dictionary) -> void:
	tutorial_completed = data.get("tutorial_completed", false)
	_population_zero_days = data.get("population_zero_days", 0)
	_treasury_negative_days = data.get("treasury_negative_days", 0)
	GameState.npc_factions_defeated = data.get("npc_factions_defeated", 0)
