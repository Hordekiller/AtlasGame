extends Node

const GAME_NAME: String = "GameMB"
const VERSION: String = "0.2.0"
const TICK_INTERVAL: float = 1.0
const DAY_DURATION: float = 60.0

enum ResourceType {
	WOOD,
	MARBLE,
	GLASS,
	WINE,
	GOLD,
	FOOD,
	STONE,
	CRYSTAL,
	SULFUR,
	POPULATION,
	WORKERS,
	RESEARCH_POINTS,
	SATISFACTION,
	ACTION_POINTS
}

enum BuildingCategory {
	RESOURCE,
	PRODUCTION,
	STORAGE,
	MILITARY,
	RESEARCH,
	CULTURE,
	INFRASTRUCTURE,
	SPECIAL,
	REDUCTION
}

enum IslandResource {
	WOOD,
	MARBLE,
	GLASS,
	WINE,
	CRYSTAL,
	SULFUR,
	NONE
}

enum UnitType {
	MILITIA,
	SWORDSMAN,
	HOPLITE,
	ARCHER,
	STEAM_GIANT,
	GYROCOPTER,
	COOK,
	DOCTOR,
	CATAPULT,
	MORTAR,
	RAM,
	SPEARMAN,
	SLINGER,
	SULPHUR_CARABINEER,
	BALLOON_BOMBARDIER,
	SHIP_CARGO,
	SHIP_BALLISTA,
	SHIP_CATAPULT,
	SHIP_MORTAR,
	SHIP_RAM,
	SHIP_DIVING,
	SHIP_FIRE,
	SHIP_PADDLE,
	SHIP_BALLOON_CARRIER,
	SHIP_ROCKET,
	SHIP_STEAM_RAM,
	SHIP_TENDER
}

enum TechCategory {
	ECONOMY,
	MILITARY,
	SCIENCE,
	NAVIGATION,
	CULTURE
}

enum CitySize {
	SMALL = 12,
	MEDIUM = 16,
	LARGE = 20
}

const RESOURCE_DISPLAY_NAMES: Dictionary = {
	ResourceType.WOOD: "چوب",
	ResourceType.MARBLE: "مرمر",
	ResourceType.GLASS: "شیشه",
	ResourceType.WINE: "شراب",
	ResourceType.GOLD: "طلا",
	ResourceType.FOOD: "غذا",
	ResourceType.STONE: "سنگ",
	ResourceType.CRYSTAL: "کریستال",
	ResourceType.SULFUR: "گوگرد",
	ResourceType.POPULATION: "جمعیت",
	ResourceType.WORKERS: "کارگر",
	ResourceType.RESEARCH_POINTS: "امتیاز پژوهش",
	ResourceType.SATISFACTION: "رضایت",
	ResourceType.ACTION_POINTS: "AP"
}

const HAPPINESS_BASE_SATISFACTION: float = 50.0
const HAPPINESS_TAVERN_SAT_PER_LEVEL: float = 5.0
const HAPPINESS_MUSEUM_SAT_PER_LEVEL: float = 3.0
const HAPPINESS_TEMPLE_SAT_PER_LEVEL: float = 4.0
const HAPPINESS_WINE_SAT_PER_UNIT: float = 2.0
const HAPPINESS_CROWDED_PENALTY_PER_POP: float = -0.1
const HAPPINESS_CORRUPTION_SAT_PENALTY: float = -2.0
const HAPPINESS_POP_GROWTH_MIN_SAT: float = 30.0
const HAPPINESS_POP_GROWTH_MAX_SAT: float = 100.0
const HAPPINESS_POP_GROWTH_MIN_RATE: float = -0.5
const HAPPINESS_POP_GROWTH_MAX_RATE: float = 0.8
const HAPPINESS_CORRUPTION_PER_COLONY: float = 10.0
const HAPPINESS_GOV_RES_CORRUPTION_REDUCTION_PER_LEVEL: float = 5.0
const HAPPINESS_MAX_COLONIES_PER_PALACE_LEVEL: int = 1

func get_resource_icon(rtype: int) -> Resource:
	var paths: Dictionary = {
		ResourceType.WOOD: "res://Assets/Textures/Resources/wood.png",
		ResourceType.MARBLE: "res://Assets/Textures/Resources/marble.png",
		ResourceType.GLASS: "res://Assets/Textures/Resources/glass.png",
		ResourceType.WINE: "res://Assets/Textures/Resources/wine.png",
		ResourceType.GOLD: "res://Assets/Textures/Resources/gold.png",
		ResourceType.SULFUR: "res://Assets/Textures/Resources/sulfur.png",
		ResourceType.CRYSTAL: "res://Assets/Textures/Resources/crystal.png",
		ResourceType.FOOD: "res://Assets/Textures/Resources/food.png",
		ResourceType.STONE: "res://Assets/Textures/Resources/stone.png",
		ResourceType.POPULATION: "res://Assets/Textures/UI/population.png",
		ResourceType.WORKERS: "res://Assets/Textures/UI/citizen.png",
		ResourceType.RESEARCH_POINTS: "res://Assets/Textures/Resources/research_time.png",
		ResourceType.SATISFACTION: "res://Assets/Textures/UI/happy.png",
	}
	var path: String = paths.get(rtype, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path)

func get_building_sprite(building_id: String) -> String:
	var sprite_map: Dictionary = {
		"town_hall": "res://Assets/Textures/Buildings/1.png",
		"lumberjack": "res://Assets/Textures/Buildings/2.png",
		"quarry": "res://Assets/Textures/Buildings/14.png",
		"farm": "res://Assets/Textures/Buildings/7.png",
		"vineyard": "res://Assets/Textures/Buildings/5.png",
		"glassblower": "res://Assets/Textures/Buildings/6.png",
		"marble_quarry": "res://Assets/Textures/Buildings/3.png",
		"academy": "res://Assets/Textures/Buildings/10.png",
		"warehouse": "res://Assets/Textures/Buildings/8.png",
		"barracks": "res://Assets/Textures/Buildings/11.png",
		"port": "res://Assets/Textures/Buildings/13.png",
		"temple": "res://Assets/Textures/Buildings/16.png",
		"workshop_crystal": "res://Assets/Textures/Buildings/17.png",
		"sawmill": "res://Assets/Textures/Buildings/19.png",
		"wall": "res://Assets/Textures/Buildings/9.png",
		"tavern": "res://Assets/Textures/Buildings/12.png",
		"museum": "res://Assets/Textures/Buildings/15.png",
		"palace": "res://Assets/Textures/Buildings/18.png",
		"governor_residence": "res://Assets/Textures/Buildings/4.png",
		"hideout": "res://Assets/Textures/Buildings/construct.png",
		"marketplace": "res://Assets/Textures/Buildings/1.png",
		"shipyard": "res://Assets/Textures/Buildings/13.png",
		"carpenter": "res://Assets/Textures/Buildings/14.png",
		"architect": "res://Assets/Textures/Buildings/2.png",
		"optician": "res://Assets/Textures/Buildings/6.png",
		"firework_test": "res://Assets/Textures/Buildings/17.png",
		"wine_press_building": "res://Assets/Textures/Buildings/5.png",
	}
	return sprite_map.get(building_id, "res://Assets/Textures/Buildings/construct.png")

func get_resource_name(rtype: int) -> String:
	return RESOURCE_DISPLAY_NAMES.get(rtype, "ناشناخته")

func get_resource_color(type: ResourceType) -> Color:
	match type:
		ResourceType.WOOD: return Color(0.42, 0.31, 0.13)
		ResourceType.MARBLE: return Color(0.8, 0.8, 0.85)
		ResourceType.GLASS: return Color(0.6, 0.85, 0.9)
		ResourceType.WINE: return Color(0.6, 0.1, 0.2)
		ResourceType.GOLD: return Color(1.0, 0.84, 0.0)
		ResourceType.FOOD: return Color(0.6, 0.4, 0.1)
		ResourceType.STONE: return Color(0.5, 0.5, 0.5)
		ResourceType.CRYSTAL: return Color(0.4, 0.6, 1.0)
		ResourceType.SULFUR: return Color(0.8, 0.7, 0.1)
		ResourceType.POPULATION: return Color(0.3, 0.8, 0.3)
		ResourceType.WORKERS: return Color(0.9, 0.6, 0.2)
		ResourceType.SATISFACTION: return Color(1.0, 0.5, 0.8)
		ResourceType.ACTION_POINTS: return Color(0.5, 0.8, 1.0)
		_: return Color.WHITE

const MARKETPLACE_RATIOS: Dictionary = {
	ResourceType.WOOD: 1.0,
	ResourceType.MARBLE: 2.5,
	ResourceType.GLASS: 3.0,
	ResourceType.WINE: 2.0,
	ResourceType.CRYSTAL: 3.5,
	ResourceType.SULFUR: 2.8,
}
