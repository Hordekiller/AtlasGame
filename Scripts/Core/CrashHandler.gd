extends Node

var _last_crash_log: String = ""

func _ready() -> void:
	if FileAccess.file_exists("user://crash_log.txt"):
		var f = FileAccess.open("user://crash_log.txt", FileAccess.READ)
		if f:
			_last_crash_log = f.get_as_text()
			f.close()
			DirAccess.remove_absolute("user://crash_log.txt")

func log_crash(context: String, msg: String) -> void:
	var entry = "[" + Time.get_datetime_string_from_system() + "] " + context + ": " + msg
	var f = FileAccess.open("user://crash_log.txt", FileAccess.WRITE)
	if f:
		f.store_line(entry)
		f.close()
	printerr(entry)

func has_previous_crash() -> bool:
	return not _last_crash_log.is_empty()

func get_last_crash_log() -> String:
	return _last_crash_log