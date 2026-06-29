extends Node

@export var tick_interval: float = 1.0

var _tick_timer: float = 0.0
var _day_timer: float = 0.0
var _paused: bool = false

func _ready() -> void:
	_day_timer = Globals.DAY_DURATION

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

func _tick() -> void:
	EconomyManager.process_tick()
	BuildingManager.process_tick()
	ResearchManager.process_tick()

func set_speed(speed: float) -> void:
	GameState.time_speed = clampf(speed, 0.0, 10.0)
	EventBus.time_speed_changed.emit(GameState.time_speed)

func toggle_pause() -> void:
	_paused = !_paused

func is_paused() -> bool:
	return _paused

func set_paused(paused: bool) -> void:
	_paused = paused
