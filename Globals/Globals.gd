extends Node

const GAME_NAME: String = "GameMB"
const VERSION: String = "0.4.0"
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

const ISLAND_RESOURCE_NAMES: Dictionary = {
	IslandResource.WOOD: "چوب",
	IslandResource.MARBLE: "مرمر",
	IslandResource.GLASS: "شیشه",
	IslandResource.WINE: "شراب",
	IslandResource.CRYSTAL: "کریستال",
	IslandResource.SULFUR: "گوگرد",
	IslandResource.NONE: "ندارد"
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
		ResourceType.ACTION_POINTS: "res://Assets/Textures/Resources/research_time.png",
	}
	var path: String = paths.get(rtype, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path)

func get_building_sprite(building_id: String) -> String:
	var sprite_map: Dictionary = {
		"town_hall": "res://Assets/Textures/Buildings/town_hall.png",
		"lumberjack": "res://Assets/Textures/Buildings/lumberjack.png",
		"quarry": "res://Assets/Textures/Buildings/quarry.png",
		"farm": "res://Assets/Textures/Buildings/farm.png",
		"vineyard": "res://Assets/Textures/Buildings/vineyard.png",
		"glassblower": "res://Assets/Textures/Buildings/glassblower.png",
		"marble_quarry": "res://Assets/Textures/Buildings/marble_quarry.png",
		"academy": "res://Assets/Textures/Buildings/academy.png",
		"warehouse": "res://Assets/Textures/Buildings/warehouse.png",
		"barracks": "res://Assets/Textures/Buildings/barracks.png",
		"port": "res://Assets/Textures/Buildings/port.png",
		"temple": "res://Assets/Textures/Buildings/temple.png",
		"workshop": "res://Assets/Textures/Buildings/workshop.png",
		"sawmill": "res://Assets/Textures/Buildings/sawmill.png",
		"wall": "res://Assets/Textures/Buildings/wall.png",
		"tavern": "res://Assets/Textures/Buildings/tavern.png",
		"museum": "res://Assets/Textures/Buildings/museum.png",
		"palace": "res://Assets/Textures/Buildings/palace.png",
		"governor_residence": "res://Assets/Textures/Buildings/governor_residence.png",
		"hideout": "res://Assets/Textures/Buildings/hideout.png",
		"marketplace": "res://Assets/Textures/Buildings/marketplace.png",
		"shipyard": "res://Assets/Textures/Buildings/shipyard.png",
		"carpenter": "res://Assets/Textures/Buildings/carpenter.png",
		"architect": "res://Assets/Textures/Buildings/architect.png",
		"optician": "res://Assets/Textures/Buildings/optician.png",
		"firework_test": "res://Assets/Textures/Buildings/firework_test.png",
		"wine_press_building": "res://Assets/Textures/Buildings/wine_press_building.png",
		"alchemist_tower": "res://Assets/Textures/Buildings/alchemist_tower.png",
		"dump": "res://Assets/Textures/Buildings/dump.png",
		"sea_chart_archive": "res://Assets/Textures/Buildings/sea_chart_archive.png",
		"pirate_fortress": "res://Assets/Textures/Buildings/pirate_fortress.png",
		"steam_workshop": "res://Assets/Textures/Buildings/steam_workshop.png",
		"flying_machine_workshop": "res://Assets/Textures/Buildings/flying_machine_workshop.png",
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
