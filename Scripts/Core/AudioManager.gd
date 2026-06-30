extends Node

const CONFIG_PATH: String = "user://settings.cfg"
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_UI: String = "UI"

const SFX: Dictionary = {
	"build": "res://Assets/Audio/SFX/build.wav",
	"upgrade": "res://Assets/Audio/SFX/upgrade.wav",
	"train": "res://Assets/Audio/SFX/train.wav",
	"research": "res://Assets/Audio/SFX/research.wav",
	"battle_start": "res://Assets/Audio/SFX/battle_start.wav",
	"battle_hit": "res://Assets/Audio/SFX/battle_hit.wav",
	"battle_end": "res://Assets/Audio/SFX/battle_end.wav",
	"click": "res://Assets/Audio/SFX/click.wav",
	"error": "res://Assets/Audio/SFX/error.wav",
	"notification": "res://Assets/Audio/SFX/notification.wav",
	"colonize": "res://Assets/Audio/SFX/colonize.wav",
	"trade": "res://Assets/Audio/SFX/trade.wav",
	"spy": "res://Assets/Audio/SFX/spy.wav",
	"level_up": "res://Assets/Audio/SFX/level_up.wav",
	"victory": "res://Assets/Audio/SFX/victory.wav",
	"defeat": "res://Assets/Audio/SFX/defeat.wav"
}

const SFX_PRIORITY: Dictionary = {
	"battle_start": 3, "battle_hit": 3, "battle_end": 3,
	"colonize": 3, "spy": 3, "victory": 3, "defeat": 3,
	"build": 2, "upgrade": 2, "train": 2, "research": 2, "trade": 2, "level_up": 2,
	"click": 1, "error": 1, "notification": 1
}

var sfx_bus: String = BUS_SFX

var _volumes: Dictionary = {
	BUS_MASTER: 0.8,
	BUS_MUSIC: 0.7,
	BUS_SFX: 0.6,
	BUS_UI: 0.6
}

var _sfx_cache: Dictionary = {}
var _music_stream: AudioStreamPlayer = null
var _active_sfx: Dictionary = {}

func _ready() -> void:
	_setup_busses()
	_load_settings()
	preload_sfx()

func _setup_busses() -> void:
	for bus_name in [BUS_MASTER, BUS_MUSIC, BUS_SFX, BUS_UI]:
		var idx = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			AudioServer.add_bus()
			idx = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, bus_name)
			if bus_name != BUS_MASTER:
				AudioServer.set_bus_send(idx, BUS_MASTER)

func _load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		for bus_name in _volumes:
			var v = cfg.get_value("audio", bus_name, _volumes[bus_name])
			_volumes[bus_name] = clampf(v, 0.0, 1.0)
			_set_bus_volume(bus_name, _volumes[bus_name])

func _save_settings() -> void:
	var cfg = ConfigFile.new()
	for bus_name in _volumes:
		cfg.set_value("audio", bus_name, _volumes[bus_name])
	cfg.save(CONFIG_PATH)

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		var db = linear_to_db(maxf(linear, 0.001))
		AudioServer.set_bus_volume_db(idx, db)
		AudioServer.set_bus_mute(idx, linear <= 0.0)

func set_volume(bus_name: String, linear: float) -> void:
	_volumes[bus_name] = clampf(linear, 0.0, 1.0)
	_set_bus_volume(bus_name, _volumes[bus_name])
	_save_settings()

func get_volume(bus_name: String) -> float:
	return _volumes.get(bus_name, 0.8)

func preload_sfx() -> void:
	for name in SFX:
		var path: String = SFX[name]
		if ResourceLoader.exists(path):
			_sfx_cache[name] = ResourceLoader.load(path)

func play_sfx(name: String, volume_override: float = 1.0) -> void:
	if not SFX.has(name):
		push_warning("Unknown SFX: ", name)
		return
	if _volumes[sfx_bus] <= 0.0:
		return
	var new_priority: int = SFX_PRIORITY.get(name, 0)
	if _active_sfx.has(name):
		var active = _active_sfx[name]
		if active["priority"] >= new_priority and is_instance_valid(active["player"]):
			return
	var path: String = SFX[name]
	var stream: AudioStream = _get_stream(path)
	if not stream:
		stream = _sfx_cache.get(name)
		if not stream:
			return
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = sfx_bus
	player.volume_db = linear_to_db(volume_override)
	add_child(player)
	_active_sfx[name] = {"priority": new_priority, "player": player}
	player.finished.connect(_on_sfx_finished.bind(name, player))
	player.play()

func _on_sfx_finished(name: String, player: AudioStreamPlayer2D) -> void:
	if _active_sfx.get(name, {}).get("player") == player:
		_active_sfx.erase(name)
	player.queue_free()

func play_ui_sfx(path: String) -> void:
	if _volumes[BUS_UI] <= 0.0:
		return
	var stream: AudioStream = _get_stream(path)
	if not stream:
		return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS_UI
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_music(path: String, fade_time: float = 0.5) -> void:
	if _music_stream and is_instance_valid(_music_stream):
		var tween = create_tween()
		tween.tween_property(_music_stream, "volume_db", -80.0, fade_time)
		tween.tween_callback(_music_stream.queue_free)

	var stream: AudioStream = _get_stream(path)
	if not stream:
		return
	_music_stream = AudioStreamPlayer.new()
	_music_stream.stream = stream
	_music_stream.bus = BUS_MUSIC
	_music_stream.volume_db = -80.0
	add_child(_music_stream)
	_music_stream.play()
	var tween = create_tween()
	tween.tween_property(_music_stream, "volume_db", 0.0, fade_time)

func stop_music(fade_time: float = 0.5) -> void:
	if _music_stream and is_instance_valid(_music_stream):
		var tween = create_tween()
		tween.tween_property(_music_stream, "volume_db", -80.0, fade_time)
		tween.tween_callback(_music_stream.queue_free)
		_music_stream = null

func _get_stream(path: String) -> AudioStream:
	if _sfx_cache.has(path):
		return _sfx_cache[path]
	if ResourceLoader.exists(path):
		var stream = ResourceLoader.load(path)
		_sfx_cache[path] = stream
		return stream
	return null

func play_button_click() -> void:
	play_sfx("click")

func play_build() -> void:
	play_sfx("build")

func play_upgrade() -> void:
	play_sfx("upgrade")

func play_trade() -> void:
	play_sfx("trade")

func play_notification() -> void:
	play_sfx("notification")

func play_error() -> void:
	play_sfx("error")

func play_main_theme() -> void:
	play_music("res://Assets/Audio/Music/start_of_civilisation.wav")

func play_ambient_ocean() -> void:
	var paths = [
		"res://Assets/Audio/Ambient/wave_01.flac",
		"res://Assets/Audio/Ambient/wave_02.flac",
		"res://Assets/Audio/Ambient/wave_03.flac",
		"res://Assets/Audio/Ambient/wave_04.flac"
	]
	var idx = randi() % paths.size()
	if _volumes[BUS_MUSIC] > 0.0:
		var stream = _get_stream(paths[idx])
		if stream:
			var player = AudioStreamPlayer2D.new()
			player.stream = stream
			player.bus = BUS_MUSIC
			player.volume_db = linear_to_db(0.15)
			add_child(player)
			player.finished.connect(player.queue_free)
			player.play()
