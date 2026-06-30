extends Node

const SAVE_PATH: String = "user://saves/"
const SAVE_EXTENSION: String = ".dat"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_PATH)

func save_game(slot: int = 0) -> void:
	var data = GameState.to_dict()
	data["version"] = Globals.VERSION
	data["save_time"] = Time.get_unix_time_from_system()
	data["economy"] = EconomyManager.get_save_data()
	data["research"] = ResearchManager.get_save_data()
	data["military"] = MilitaryManager.get_save_data()
	data["army_travel"] = ArmyTravel.get_save_data()
	data["game_state"] = GameStateManager.get_save_data()
	data["quest"] = QuestSystem.get_save_data()
	data["event"] = EventSystem.get_save_data()
	data["spy"] = SpySystem.get_save_data()
	data["marketplace"] = MarketplaceManager.get_save_data()
	data["protection"] = BeginnerProtection.get_save_data()
	data["notifications"] = NotificationManager.get_save_data()
	var game = get_parent().get_node_or_null("Game")
	if game and game.has_node("TutorialManager"):
		data["tutorial"] = game.get_node("TutorialManager").save_state()

	var path = SAVE_PATH + "save_%d" % slot + SAVE_EXTENSION
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		EventBus.game_saved.emit()
		print("Game saved to slot ", slot)
	else:
		push_error("Failed to save game to: ", path)

func load_game(slot: int = 0) -> bool:
	var path = SAVE_PATH + "save_%d" % slot + SAVE_EXTENSION
	if not FileAccess.file_exists(path):
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		GameState.from_dict(data)

		EconomyManager.load_save_data(data.get("economy", {}))
		ResearchManager.load_save_data(data.get("research", {}))
		MilitaryManager.load_save_data(data.get("military", {}))
		ArmyTravel.load_save_data(data.get("army_travel", {}))
		GameStateManager.load_save_data(data.get("game_state", {}))
		QuestSystem.load_save_data(data.get("quest", {}))
		EventSystem.load_save_data(data.get("event", {}))
		SpySystem.load_save_data(data.get("spy", {}))
		MarketplaceManager.load_save_data(data.get("marketplace", {}))
		BeginnerProtection.load_save_data(data.get("protection", {}))
		NotificationManager.load_save_data(data.get("notifications", {}))

		if data.has("tutorial"):
			var game = get_parent().get_node_or_null("Game")
			if game and game.has_node("TutorialManager"):
				game.get_node("TutorialManager").load_state(data["tutorial"])
		EventBus.game_loaded.emit()
		print("Game loaded from slot ", slot)
		return true
	return false

func get_save_info(slot: int) -> Dictionary:
	var path = SAVE_PATH + "save_%d" % slot + SAVE_EXTENSION
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		return {
			"exists": true,
			"version": data.get("version", "unknown"),
			"save_time": data.get("save_time", 0),
			"day": data.get("current_day", 1)
		}
	return {}

func get_save_slots() -> Array:
	var slots = []
	for i in range(5):
		var info = get_save_info(i)
		info["slot"] = i
		slots.append(info)
	return slots

func delete_save(slot: int) -> void:
	var path = SAVE_PATH + "save_%d" % slot + SAVE_EXTENSION
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func load_tutorial_state() -> Dictionary:
	var path = SAVE_PATH + "save_0.dat"
	if not FileAccess.file_exists(path):
		return {"completed": false}
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		return data.get("tutorial", {"completed": false})
	return {"completed": false}

func save_exists(slot: int) -> bool:
	var path = SAVE_PATH + "save_%d" % slot + SAVE_EXTENSION
	return FileAccess.file_exists(path)
