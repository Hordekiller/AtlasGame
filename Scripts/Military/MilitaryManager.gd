extends Node

const UNIT_DEFINITIONS = {
	"militia": {
		"name": "شبه‌نظامی",
		"type": Globals.UnitType.MILITIA,
		"row": "front",
		"attack": 3,
		"defense": 1,
		"health": 15,
		"speed": 2,
		"cost": { Globals.ResourceType.WOOD: 5, Globals.ResourceType.GOLD: 2 },
		"upkeep": { Globals.ResourceType.FOOD: 0.3, Globals.ResourceType.GOLD: 0.1 },
		"train_time": 5.0,
		"tier": 1,
		"building": "barracks"
	},
	"swordsman": {
		"name": "شمشیرزن",
		"type": Globals.UnitType.SWORDSMAN,
		"row": "front",
		"attack": 6,
		"defense": 5,
		"health": 30,
		"speed": 2,
		"cost": { Globals.ResourceType.WOOD: 12, Globals.ResourceType.GOLD: 10, Globals.ResourceType.STONE: 5 },
		"upkeep": { Globals.ResourceType.FOOD: 0.7, Globals.ResourceType.GOLD: 0.3 },
		"train_time": 15.0,
		"tier": 2,
		"building": "barracks"
	},
	"archer": {
		"name": "کماندار",
		"type": Globals.UnitType.ARCHER,
		"row": "back",
		"attack": 7,
		"defense": 3,
		"health": 20,
		"speed": 3,
		"cost": { Globals.ResourceType.WOOD: 15, Globals.ResourceType.GOLD: 8 },
		"upkeep": { Globals.ResourceType.FOOD: 0.6, Globals.ResourceType.GOLD: 0.2 },
		"train_time": 12.0,
		"tier": 2,
		"building": "barracks"
	},
	"spearman": {
		"name": "نیزه‌دار",
		"type": Globals.UnitType.SPEARMAN,
		"row": "front",
		"attack": 5,
		"defense": 6,
		"health": 25,
		"speed": 2,
		"cost": { Globals.ResourceType.WOOD: 8, Globals.ResourceType.GOLD: 6 },
		"upkeep": { Globals.ResourceType.FOOD: 0.5, Globals.ResourceType.GOLD: 0.2 },
		"train_time": 8.0,
		"tier": 1,
		"building": "barracks"
	},
	"slinger": {
		"name": "تیرانداز",
		"type": Globals.UnitType.SLINGER,
		"row": "back",
		"attack": 5,
		"defense": 2,
		"health": 20,
		"speed": 3,
		"cost": { Globals.ResourceType.WOOD: 10, Globals.ResourceType.GOLD: 5 },
		"upkeep": { Globals.ResourceType.FOOD: 0.5, Globals.ResourceType.GOLD: 0.2 },
		"train_time": 10.0,
		"tier": 1,
		"building": "barracks"
	},
	"hoplite": {
		"name": "هوپلیت",
		"type": Globals.UnitType.HOPLITE,
		"row": "front",
		"attack": 8,
		"defense": 8,
		"health": 40,
		"speed": 2,
		"cost": { Globals.ResourceType.WOOD: 15, Globals.ResourceType.GOLD: 15, Globals.ResourceType.STONE: 10 },
		"upkeep": { Globals.ResourceType.FOOD: 1.0, Globals.ResourceType.GOLD: 0.5 },
		"train_time": 20.0,
		"tier": 2,
		"building": "barracks"
	},
	"steam_giant": {
		"name": "غول بخاری",
		"type": Globals.UnitType.STEAM_GIANT,
		"row": "front",
		"attack": 20,
		"defense": 15,
		"health": 80,
		"speed": 1,
		"cost": { Globals.ResourceType.WOOD: 40, Globals.ResourceType.GOLD: 60, Globals.ResourceType.SULFUR: 30, Globals.ResourceType.CRYSTAL: 20 },
		"upkeep": { Globals.ResourceType.GOLD: 2.0, Globals.ResourceType.SULFUR: 0.5 },
		"train_time": 60.0,
		"tier": 4,
		"building": "barracks"
	},
	"gyrocopter": {
		"name": "ژیروکوپتر",
		"type": Globals.UnitType.GYROCOPTER,
		"row": "back",
		"attack": 15,
		"defense": 5,
		"health": 30,
		"speed": 8,
		"cost": { Globals.ResourceType.WOOD: 50, Globals.ResourceType.GOLD: 80, Globals.ResourceType.SULFUR: 40, Globals.ResourceType.CRYSTAL: 30 },
		"upkeep": { Globals.ResourceType.GOLD: 3.0, Globals.ResourceType.SULFUR: 0.8 },
		"train_time": 70.0,
		"tier": 5,
		"building": "flying_machine_workshop"
	},
	"balloon_bombardier": {
		"name": "بمب‌افکن بالن",
		"type": Globals.UnitType.BALLOON_BOMBARDIER,
		"row": "artillery",
		"attack": 25,
		"defense": 2,
		"health": 25,
		"speed": 4,
		"cost": { Globals.ResourceType.WOOD: 60, Globals.ResourceType.GOLD: 100, Globals.ResourceType.SULFUR: 50, Globals.ResourceType.CRYSTAL: 40 },
		"upkeep": { Globals.ResourceType.GOLD: 4.0, Globals.ResourceType.SULFUR: 1.0 },
		"train_time": 80.0,
		"tier": 5,
		"building": "flying_machine_workshop"
	},
	"cook": {
		"name": "آشپز",
		"type": Globals.UnitType.COOK,
		"row": "back",
		"attack": 1,
		"defense": 1,
		"health": 15,
		"speed": 3,
		"cost": { Globals.ResourceType.WOOD: 5, Globals.ResourceType.GOLD: 10, Globals.ResourceType.FOOD: 20 },
		"upkeep": { Globals.ResourceType.FOOD: 2.0, Globals.ResourceType.GOLD: 0.5 },
		"train_time": 15.0,
		"tier": 2,
		"building": "barracks",
		"morale_bonus": 5.0
	},
	"doctor": {
		"name": "پزشک",
		"type": Globals.UnitType.DOCTOR,
		"row": "back",
		"attack": 1,
		"defense": 2,
		"health": 20,
		"speed": 3,
		"cost": { Globals.ResourceType.WOOD: 10, Globals.ResourceType.GOLD: 25, Globals.ResourceType.WINE: 10 },
		"upkeep": { Globals.ResourceType.GOLD: 1.0, Globals.ResourceType.WINE: 0.3 },
		"train_time": 25.0,
		"tier": 3,
		"building": "barracks",
		"heal_ratio": 0.15
	},
	"catapult": {
		"name": "منجنیق",
		"type": Globals.UnitType.CATAPULT,
		"row": "artillery",
		"attack": 20,
		"defense": 3,
		"health": 40,
		"speed": 1,
		"cost": { Globals.ResourceType.WOOD: 40, Globals.ResourceType.GOLD: 30, Globals.ResourceType.STONE: 25, Globals.ResourceType.MARBLE: 15 },
		"upkeep": { Globals.ResourceType.GOLD: 1.5, Globals.ResourceType.WOOD: 0.5 },
		"train_time": 40.0,
		"tier": 3,
		"building": "barracks",
		"wall_damage": 3.0
	},
	"mortar": {
		"name": "خمپاره‌انداز",
		"type": Globals.UnitType.MORTAR,
		"row": "artillery",
		"attack": 30,
		"defense": 4,
		"health": 35,
		"speed": 1,
		"cost": { Globals.ResourceType.WOOD: 50, Globals.ResourceType.GOLD: 50, Globals.ResourceType.SULFUR: 30, Globals.ResourceType.STONE: 20 },
		"upkeep": { Globals.ResourceType.GOLD: 2.0, Globals.ResourceType.SULFUR: 0.5 },
		"train_time": 55.0,
		"tier": 4,
		"building": "barracks",
		"wall_damage": 5.0
	},
	"ram": {
		"name": "قوچ کوبنده",
		"type": Globals.UnitType.RAM,
		"row": "front",
		"attack": 15,
		"defense": 10,
		"health": 60,
		"speed": 2,
		"cost": { Globals.ResourceType.WOOD: 35, Globals.ResourceType.GOLD: 25, Globals.ResourceType.STONE: 30 },
		"upkeep": { Globals.ResourceType.GOLD: 1.0, Globals.ResourceType.FOOD: 1.0 },
		"train_time": 35.0,
		"tier": 3,
		"building": "barracks",
		"wall_damage": 4.0
	},
	"sulphur_carabineer": {
		"name": "کارابینیر گوگردی",
		"type": Globals.UnitType.SULPHUR_CARABINEER,
		"row": "back",
		"attack": 18,
		"defense": 6,
		"health": 30,
		"speed": 3,
		"cost": { Globals.ResourceType.WOOD: 30, Globals.ResourceType.GOLD: 40, Globals.ResourceType.SULFUR: 25 },
		"upkeep": { Globals.ResourceType.GOLD: 2.0, Globals.ResourceType.SULFUR: 0.3 },
		"train_time": 45.0,
		"tier": 4,
		"building": "barracks"
	},
	## NAVAL UNITS
	"ship_cargo": {
		"name": "کشتی باری",
		"type": Globals.UnitType.SHIP_CARGO,
		"row": "back",
		"attack": 0,
		"defense": 5,
		"health": 50,
		"speed": 4,
		"cost": { Globals.ResourceType.WOOD: 35, Globals.ResourceType.GOLD: 25 },
		"upkeep": { Globals.ResourceType.GOLD: 0.5 },
		"train_time": 25.0,
		"tier": 2,
		"building": "port",
		"naval": true,
		"cargo_capacity": 1000
	},
	"ship_ballista": {
		"name": "کشتی بالیستا",
		"type": Globals.UnitType.SHIP_BALLISTA,
		"row": "back",
		"attack": 10,
		"defense": 8,
		"health": 60,
		"speed": 4,
		"cost": { Globals.ResourceType.WOOD: 50, Globals.ResourceType.GOLD: 40, Globals.ResourceType.STONE: 20 },
		"upkeep": { Globals.ResourceType.GOLD: 1.0, Globals.ResourceType.WOOD: 0.3 },
		"train_time": 35.0,
		"tier": 3,
		"building": "shipyard",
		"naval": true
	},
	"ship_catapult": {
		"name": "کشتی منجنیق",
		"type": Globals.UnitType.SHIP_CATAPULT,
		"row": "artillery",
		"attack": 18,
		"defense": 6,
		"health": 55,
		"speed": 3,
		"cost": { Globals.ResourceType.WOOD: 60, Globals.ResourceType.GOLD: 60, Globals.ResourceType.STONE: 30, Globals.ResourceType.MARBLE: 15 },
		"upkeep": { Globals.ResourceType.GOLD: 2.0, Globals.ResourceType.STONE: 0.3 },
		"train_time": 45.0,
		"tier": 4,
		"building": "shipyard",
		"naval": true,
		"wall_damage": 3.0
	},
	"ship_mortar": {
		"name": "کشتی خمپاره",
		"type": Globals.UnitType.SHIP_MORTAR,
		"row": "artillery",
		"attack": 28,
		"defense": 5,
		"health": 50,
		"speed": 3,
		"cost": { Globals.ResourceType.WOOD: 70, Globals.ResourceType.GOLD: 80, Globals.ResourceType.SULFUR: 35, Globals.ResourceType.STONE: 25 },
		"upkeep": { Globals.ResourceType.GOLD: 3.0, Globals.ResourceType.SULFUR: 0.5 },
		"train_time": 60.0,
		"tier": 4,
		"building": "shipyard",
		"naval": true,
		"wall_damage": 5.0
	},
	"ship_ram": {
		"name": "کشتی قوچ‌دار",
		"type": Globals.UnitType.SHIP_RAM,
		"row": "front",
		"attack": 22,
		"defense": 12,
		"health": 80,
		"speed": 5,
		"cost": { Globals.ResourceType.WOOD: 55, Globals.ResourceType.GOLD: 50, Globals.ResourceType.STONE: 35, Globals.ResourceType.MARBLE: 20 },
		"upkeep": { Globals.ResourceType.GOLD: 2.0, Globals.ResourceType.FOOD: 0.5 },
		"train_time": 50.0,
		"tier": 4,
		"building": "shipyard",
		"naval": true,
		"ram_damage_bonus": 2.0
	},
	"ship_diving": {
		"name": "کشتی غواص",
		"type": Globals.UnitType.SHIP_DIVING,
		"row": "front",
		"attack": 12,
		"defense": 4,
		"health": 35,
		"speed": 6,
		"cost": { Globals.ResourceType.WOOD: 40, Globals.ResourceType.GOLD: 70, Globals.ResourceType.GLASS: 25, Globals.ResourceType.CRYSTAL: 20 },
		"upkeep": { Globals.ResourceType.GOLD: 2.5, Globals.ResourceType.CRYSTAL: 0.3 },
		"train_time": 55.0,
		"tier": 4,
		"building": "shipyard",
		"naval": true,
		"stealth": true
	},
	"ship_fire": {
		"name": "کشتی آتشین",
		"type": Globals.UnitType.SHIP_FIRE,
		"row": "back",
		"attack": 20,
		"defense": 3,
		"health": 30,
		"speed": 5,
		"cost": { Globals.ResourceType.WOOD: 45, Globals.ResourceType.GOLD: 55, Globals.ResourceType.SULFUR: 30 },
		"upkeep": { Globals.ResourceType.GOLD: 1.5, Globals.ResourceType.SULFUR: 0.5 },
		"train_time": 45.0,
		"tier": 4,
		"building": "shipyard",
		"naval": true,
		"splash_damage": true
	},
	"ship_paddle": {
		"name": "کشتی پارویی",
		"type": Globals.UnitType.SHIP_PADDLE,
		"row": "front",
		"attack": 8,
		"defense": 10,
		"health": 65,
		"speed": 7,
		"cost": { Globals.ResourceType.WOOD: 55, Globals.ResourceType.GOLD: 45, Globals.ResourceType.SULFUR: 20, Globals.ResourceType.CRYSTAL: 15 },
		"upkeep": { Globals.ResourceType.GOLD: 2.0, Globals.ResourceType.SULFUR: 0.3 },
		"train_time": 50.0,
		"tier": 4,
		"building": "shipyard",
		"naval": true
	},
	"ship_balloon_carrier": {
		"name": "ناو بالن‌بر",
		"type": Globals.UnitType.SHIP_BALLOON_CARRIER,
		"row": "back",
		"attack": 5,
		"defense": 20,
		"health": 120,
		"speed": 3,
		"cost": { Globals.ResourceType.WOOD: 120, Globals.ResourceType.GOLD: 200, Globals.ResourceType.MARBLE: 80, Globals.ResourceType.GLASS: 50, Globals.ResourceType.SULFUR: 60, Globals.ResourceType.CRYSTAL: 50 },
		"upkeep": { Globals.ResourceType.GOLD: 5.0, Globals.ResourceType.SULFUR: 1.0, Globals.ResourceType.CRYSTAL: 0.5 },
		"train_time": 120.0,
		"tier": 5,
		"building": "shipyard",
		"naval": true,
		"carrier_capacity": 4
	},
	"ship_rocket": {
		"name": "کشتی موشکی",
		"type": Globals.UnitType.SHIP_ROCKET,
		"row": "artillery",
		"attack": 40,
		"defense": 4,
		"health": 40,
		"speed": 4,
		"cost": { Globals.ResourceType.WOOD: 80, Globals.ResourceType.GOLD: 150, Globals.ResourceType.SULFUR: 60, Globals.ResourceType.CRYSTAL: 40, Globals.ResourceType.GLASS: 30 },
		"upkeep": { Globals.ResourceType.GOLD: 4.0, Globals.ResourceType.SULFUR: 1.0 },
		"train_time": 100.0,
		"tier": 5,
		"building": "shipyard",
		"naval": true,
		"wall_damage": 6.0
	},
	"ship_steam_ram": {
		"name": "کشتی بخاری زره‌پوش",
		"type": Globals.UnitType.SHIP_STEAM_RAM,
		"row": "front",
		"attack": 35,
		"defense": 25,
		"health": 150,
		"speed": 4,
		"cost": { Globals.ResourceType.WOOD: 100, Globals.ResourceType.GOLD: 180, Globals.ResourceType.MARBLE: 60, Globals.ResourceType.SULFUR: 50, Globals.ResourceType.CRYSTAL: 40 },
		"upkeep": { Globals.ResourceType.GOLD: 5.0, Globals.ResourceType.SULFUR: 0.8, Globals.ResourceType.CRYSTAL: 0.5 },
		"train_time": 110.0,
		"tier": 5,
		"building": "shipyard",
		"naval": true,
		"ram_damage_bonus": 3.0
	},
	"ship_tender": {
		"name": "کشتی تدارکاتی",
		"type": Globals.UnitType.SHIP_TENDER,
		"row": "back",
		"attack": 3,
		"defense": 8,
		"health": 70,
		"speed": 4,
		"cost": { Globals.ResourceType.WOOD: 50, Globals.ResourceType.GOLD: 60, Globals.ResourceType.STONE: 25, Globals.ResourceType.MARBLE: 15 },
		"upkeep": { Globals.ResourceType.GOLD: 2.0, Globals.ResourceType.FOOD: 1.0 },
		"train_time": 40.0,
		"tier": 5,
		"building": "shipyard",
		"naval": true,
		"troop_transport": 50
	}
}

func get_unit_def(unit_type: String) -> Dictionary:
	return UNIT_DEFINITIONS.get(unit_type, {}).duplicate(true)

func get_units_for_building(building_id: String) -> Array:
	var result = []
	for unit_type in UNIT_DEFINITIONS:
		if UNIT_DEFINITIONS[unit_type].get("building") == building_id:
			result.append(unit_type)
	return result

func train_units(city_id: String, unit_type: String, count: int) -> bool:
	var defn = UNIT_DEFINITIONS.get(unit_type)
	if not defn:
		return false

	var total_cost = {}
	for r in defn.get("cost", {}):
		total_cost[r] = defn["cost"][r] * count

	if not EconomyManager.can_afford(city_id, total_cost):
		return false

	EconomyManager.deduct_costs(city_id, total_cost)

	var city = GameState.current_cities.get(city_id)
	if not city:
		return false

	if not city.has("units"):
		city["units"] = {}

	if not city["units"].has(unit_type):
		city["units"][unit_type] = {"count": 0, "training": 0, "training_progress": 0.0}

	city["units"][unit_type]["training"] += count

	EventBus.unit_trained.emit(city_id, unit_type, count)
	return true

func get_army_strength(city_id: String) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0.0

	var strength = 0.0
	var units = city.get("units", {})
	for unit_type in units:
		var defn = UNIT_DEFINITIONS.get(unit_type)
		if defn:
			var count = units[unit_type].get("count", 0)
			strength += count * (defn.get("attack", 0) + defn.get("defense", 0))
	var wall_def = BuildingManager.get_wall_defense(city_id)
	strength += wall_def * 2.0
	return strength

func get_navy_strength(city_id: String) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0.0
	var strength = 0.0
	var units = city.get("units", {})
	for unit_type in units:
		var defn = UNIT_DEFINITIONS.get(unit_type)
		if defn and defn.get("naval", false):
			var count = units[unit_type].get("count", 0)
			strength += count * (defn.get("attack", 0) + defn.get("defense", 0))
	return strength

func get_unit_upkeep(city_id: String) -> Dictionary:
	var total = {}
	var city = GameState.current_cities.get(city_id)
	if not city:
		return total
	var units = city.get("units", {})
	for unit_type in units:
		var defn = UNIT_DEFINITIONS.get(unit_type)
		if not defn:
			continue
		var count = units[unit_type].get("count", 0)
		for r in defn.get("upkeep", {}):
			total[r] = total.get(r, 0.0) + defn["upkeep"][r] * count
	return total

func is_unit_unlocked(city_id: String, unit_type: String) -> bool:
	var defn = UNIT_DEFINITIONS.get(unit_type, {})
	if defn.is_empty():
		return false
	if defn.get("tier", 1) <= 1:
		return true
	var city = GameState.current_cities.get(city_id, {})
	var unlocked = city.get("unlocked_units", [])
	return unit_type in unlocked

func get_save_data() -> Dictionary:
	var data = {}
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		var city_units = city.get("units", {})
		data[cid] = {}
		for ut in city_units:
			data[cid][ut] = city_units[ut].duplicate(true)
	return data

func load_save_data(data: Dictionary) -> void:
	for cid in data:
		var city = GameState.current_cities.get(cid)
		if city:
			city["units"] = data[cid]

func has_navy(city_id: String) -> bool:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return false
	var units = city.get("units", {})
	for unit_type in units:
		var defn = UNIT_DEFINITIONS.get(unit_type)
		if defn and defn.get("naval", false) and units[unit_type].get("count", 0) > 0:
			return true
	return false
