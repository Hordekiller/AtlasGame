extends Node

const DEFENSIVE_BUILDINGS := {
	"watchtower": {
		"name": "برج دیده‌بانی",
		"description": "افزایش دید و شناسایی حملات زودهنگام",
		"category": "military",
		"max_level": 5,
		"stats_per_level": {
			"sight_range_bonus": 20,
			"alert_time_bonus": 0.1
		},
		"cost": {"gold": 500, "wood": 200},
		"upgrade_costs": {"gold": 400, "marble": 100}
	},
	"cannon": {
		"name": "توپ دفاعی",
		"description": "آسیب به واحدهای مهاجم در هر راند نبرد",
		"category": "military",
		"max_level": 10,
		"stats_per_level": {
			"garrison_attack": 15,
			"garrison_defense": 5
		},
		"cost": {"gold": 1000, "sulfur": 200},
		"upgrade_costs": {"gold": 800, "sulfur": 150}
	},
	"harbor_chain": {
		"name": "زنجیر بندر",
		"description": "جلوگیری از ورود کشتی‌های دشمن به بندر",
		"category": "military",
		"max_level": 3,
		"stats_per_level": {
			"block_chance": 0.2,
			"naval_damage": 10
		},
		"cost": {"gold": 2000, "marble": 300},
		"upgrade_costs": {"gold": 1500, "marble": 250}
	},
	"vault": {
		"name": "خزانه",
		"description": "محافظت از منابع در برابر غارت",
		"category": "infrastructure",
		"max_level": 10,
		"stats_per_level": {
			"protection_percent": 5
		},
		"cost": {"gold": 300, "marble": 100},
		"upgrade_costs": {"gold": 500, "marble": 200}
	},
	"wall": {
		"name": "دیوار شهر",
		"description": "افزایش دفاع کلی شهر در برابر حملات",
		"category": "infrastructure",
		"max_level": 20,
		"stats_per_level": {
			"defense_bonus": 0.05
		},
		"cost": {"gold": 200, "stone": 100},
		"upgrade_costs": {"gold": 300, "stone": 200}
	}
}

static func get_building(id: String) -> Dictionary:
	return DEFENSIVE_BUILDINGS.get(id, {})

static func get_all_buildings() -> Dictionary:
	return DEFENSIVE_BUILDINGS.duplicate(true)

static func calculate_defense_bonus(city_level: int, buildings: Dictionary) -> Dictionary:
	var result = {
		"garrison_attack_bonus": 0,
		"garrison_defense_bonus": 0,
		"protection_percent": 0,
		"block_chance": 0.0,
		"naval_damage": 0,
		"sight_range_bonus": 0,
		"alert_time_bonus": 0.0,
		"defense_bonus": 0.0
	}
	for grid_pos in buildings:
		var bd = buildings[grid_pos]
		if not bd.get("constructed", false):
			continue
		var id = bd.get("id", "")
		var defn = DEFENSIVE_BUILDINGS.get(id, {})
		if defn.is_empty():
			continue
		var level = bd.get("level", 1)
		var stats = defn.get("stats_per_level", {})
		for key in stats:
			if result.has(key):
				result[key] += stats[key] * level
	return result
