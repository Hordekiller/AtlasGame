extends Node

const SAVE_PATH: String = "user://saves/"
const SAVE_EXTENSION: String = ".dat"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_PATH)

func save_game(slot: int = 0) -> void:
	var data = GameState.to_dict()
	data["version"] = Globals.VERSION
	data["save_time"] = Time.get_unix_time_from_system()

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

func save_exists(slot: int) -> bool:
	var path = SAVE_PATH + "save_%d" % slot + SAVE_EXTENSION
	return FileAccess.file_exists(path)
