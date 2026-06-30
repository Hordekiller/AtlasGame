extends Node

const CONFIG_PATH: String = "user://settings.cfg"
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_UI: String = "UI"

var _volumes: Dictionary = {
	BUS_MASTER: 0.8,
	BUS_MUSIC: 0.7,
	BUS_SFX: 0.6,
	BUS_UI: 0.6
}

var _sfx_cache: Dictionary = {}
var _music_stream: AudioStreamPlayer = null

func _ready() -> void:
	_setup_busses()
	_load_settings()

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

func play_sfx(path: String, volume: float = 1.0) -> void:
	if _volumes[BUS_SFX] <= 0.0:
		return
	var stream: AudioStream = _get_stream(path)
	if not stream:
		return
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.volume_db = linear_to_db(volume)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

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
	play_ui_sfx("res://Assets/Audio/SFX/click.wav")

func play_build() -> void:
	play_ui_sfx("res://Assets/Audio/SFX/build.wav")

func play_upgrade() -> void:
	play_ui_sfx("res://Assets/Audio/SFX/upgrade.wav")

func play_trade() -> void:
	play_ui_sfx("res://Assets/Audio/SFX/trade.wav")

func play_notification() -> void:
	play_ui_sfx("res://Assets/Audio/SFX/notification.wav")

func play_error() -> void:
	play_ui_sfx("res://Assets/Audio/SFX/error.wav")

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
