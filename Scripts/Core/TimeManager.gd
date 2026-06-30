extends Node

@export var tick_interval: float = 1.0

var _tick_timer: float = 0.0
var _day_timer: float = 0.0
var _paused: bool = false
var _last_autosave_day: int = -3
var _session_last_seen: int = 0
var _offline_processed: bool = false

func _ready() -> void:
	_day_timer = Globals.DAY_DURATION
	_notification(NOTIFICATION_APPLICATION_RESUMED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and not _offline_processed:
		_offline_processed = true
		_process_offline_time()

func _process(delta: float) -> void:
	if _paused:
		return
	var scaled_delta = delta * GameState.time_speed
	_tick_timer += scaled_delta
	_day_timer += scaled_delta
	GameState.game_time += scaled_delta

	if _tick_timer >= Globals.TICK_INTERVAL:
		_tick_timer -= Globals.TICK_INTERVAL
		_tick()

	if _day_timer >= Globals.DAY_DURATION:
		_day_timer -= Globals.DAY_DURATION
		GameState.current_day += 1
		EventBus.day_changed.emit(GameState.current_day)
		_autosave_check()

func _tick() -> void:
	if not is_instance_valid(EconomyManager) or not is_instance_valid(BuildingManager) or not is_instance_valid(ResearchManager):
		return
	EconomyManager.process_tick()
	BuildingManager.process_tick()
	ResearchManager.process_tick()
	MilitaryManager.process_tick()

func catch_up(offline_seconds: float) -> void:
	if offline_seconds <= 0:
		return
	var max_catchup = Globals.DAY_DURATION * 30
	offline_seconds = mini(offline_seconds, max_catchup)
	var ticks = int(offline_seconds / Globals.TICK_INTERVAL)
	for _i in range(ticks):
		_tick()
	GameState.game_time += offline_seconds
	print("Offline catch-up: ", offline_seconds, "s, ", ticks, " ticks")

func set_speed(speed: float) -> void:
	GameState.time_speed = clampf(speed, 0.0, 10.0)
	EventBus.time_speed_changed.emit(GameState.time_speed)

func toggle_pause() -> void:
	_paused = !_paused

func is_paused() -> bool:
	return _paused

func set_paused(paused: bool) -> void:
	_paused = paused

func _autosave_check() -> void:
	var autosave_interval = 3
	if GameState.current_day - _last_autosave_day >= autosave_interval:
		_last_autosave_day = GameState.current_day
		SaveManager.save_game(0)
		print("Autosave: day ", GameState.current_day)

func _process_offline_time() -> void:
	var config = ConfigFile.new()
	if config.load("user://session.cfg") != OK:
		return
	var last_seen: int = config.get_value("session", "last_seen", 0)
	if last_seen <= 0:
		return
	var now = Time.get_unix_time_from_system()
	var elapsed = now - last_seen
	if elapsed < 10:
		return
	catch_up(elapsed)
	EventBus.safe_emit("notification_added", ["پیشرفت آفلاین اعمال شد", "info"])

func record_session_end() -> void:
	var config = ConfigFile.new()
	config.set_value("session", "last_seen", Time.get_unix_time_from_system())
	config.save("user://session.cfg")
