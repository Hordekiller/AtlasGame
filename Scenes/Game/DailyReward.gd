extends Panel

const DAILY_REWARDS := [
	{"gold": 50, "wood": 100},
	{"gold": 75, "crystal": 25},
	{"gold": 100, "marble": 50},
	{"gold": 150, "wine": 20},
	{"gold": 200, "sulfur": 30},
	{"gold": 250, "research_points": 25},
	{"gold": 500, "ambrosia": 10}
]

@onready var day_label: Label = $VBox/DayLabel
@onready var reward_label: Label = $VBox/RewardLabel
@onready var claim_btn: Button = $VBox/ClaimBtn
@onready var close_btn: TextureButton = $VBox/Header/CloseBtn

var _current_day: int = 0

func _ready() -> void:
	UITheme.style_panel(self)
	UITheme.style_button(claim_btn)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(hide)
	claim_btn.pressed.connect(_on_claim)
	hide()

func check_and_show() -> void:
	var today = GameState.current_day
	var last_claimed = _get_last_claim_day()
	if today > last_claimed:
		_current_day = last_claimed + 1
		if _current_day > 7:
			_current_day = 1
		_show_reward()

func _show_reward() -> void:
	var idx = mini(_current_day - 1, DAILY_REWARDS.size() - 1)
	var reward = DAILY_REWARDS[idx]
	day_label.text = "روز %d از ۷" % _current_day
	var text = ""
	for rtype in reward:
		var name = Globals.RESOURCE_DISPLAY_NAMES.get(int(rtype), str(rtype)) if rtype is int else str(rtype)
		text += "%s: %d\n" % [name, reward[rtype]]
	reward_label.text = text
	claim_btn.disabled = false
	claim_btn.text = "دریافت جایزه"
	show()

func _on_claim() -> void:
	var idx = mini(_current_day - 1, DAILY_REWARDS.size() - 1)
	var reward = DAILY_REWARDS[idx]
	var city_id = GameState.selected_city_id
	if not city_id.is_empty():
		for rtype in reward:
			if rtype == "ambrosia":
				continue
			var rti = Globals.RESOURCE_DISPLAY_NAMES.find_key(rtype)
			if rti != null:
				EconomyManager.change_resource(city_id, int(rti), reward[rtype])
	_set_last_claim_day(GameState.current_day)
	claim_btn.disabled = true
	claim_btn.text = "دریافت شد ✅"
	AudioManager.play_upgrade()

func _get_last_claim_day() -> int:
	var cfg = ConfigFile.new()
	if cfg.load("user://daily_reward.cfg") == OK:
		return cfg.get_value("reward", "last_day", 0)
	return 0

func _set_last_claim_day(day: int) -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("reward", "last_day", day)
	cfg.save("user://daily_reward.cfg")
