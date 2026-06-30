extends Panel

var DAILY_REWARDS := [
	{Globals.ResourceType.GOLD: 100},
	{Globals.ResourceType.WOOD: 150},
	{Globals.ResourceType.RESEARCH_POINTS: 50},
	{Globals.ResourceType.STONE: 100},
	{Globals.ResourceType.WINE: 20},
	{Globals.ResourceType.CRYSTAL: 15},
	{"commander_shard": {"commander_id": "tactician", "count": 5}}
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
	get_viewport().size_changed.connect(_update_responsive)
	_update_responsive()

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(360, vp.size.x * 0.8), min(300, vp.size.y * 0.7))) if Engine.has_singleton("ResponsiveLayout") else Vector2(360, 300)
	custom_minimum_size = sz
	size = sz

func check_and_show() -> void:
	var today = GameState.current_day
	var state = _get_reward_state()
	if today > state.get("last_claim_day", 0):
		_current_day = state.get("claim_count", 0) + 1
		if _current_day > 7:
			_current_day = 1
		_show_reward()

func _show_reward() -> void:
	var idx = mini(_current_day - 1, DAILY_REWARDS.size() - 1)
	var reward = DAILY_REWARDS[idx]
	day_label.text = "روز %d از ۷" % _current_day
	var text = ""
	for rtype in reward:
		if rtype == "commander_shard":
			var shard_info = reward[rtype]
			var cid = shard_info.get("commander_id", "")
			var config = CommanderConfig.get_commander(cid)
			text += "تکه فرمانده: %s x%d\n" % [config.get("name", cid), shard_info.get("count", 0)]
		elif rtype is int:
			var name = Globals.RESOURCE_DISPLAY_NAMES.get(rtype, str(rtype))
			text += "%s: %d\n" % [name, reward[rtype]]
	reward_label.text = text
	claim_btn.disabled = false
	claim_btn.text = "دریافت جایزه"
	show()

func _on_claim() -> void:
	var idx = mini(_current_day - 1, DAILY_REWARDS.size() - 1)
	var reward = DAILY_REWARDS[idx]
	var city_id = GameState.selected_city_id
	for rtype in reward:
		if rtype == "commander_shard":
			var shard_info = reward[rtype]
			CommanderSystem.collect_shards(shard_info.get("commander_id", ""), shard_info.get("count", 0))
		elif rtype is int:
			if not city_id.is_empty():
				EconomyManager.change_resource(city_id, rtype, reward[rtype])
	var state = _get_reward_state()
	state["last_claim_day"] = GameState.current_day
	state["claim_count"] = state.get("claim_count", 0) + 1
	if state["claim_count"] <= 7:
		state["streak"] = state.get("streak", 0) + 1
	_save_reward_state(state)
	claim_btn.disabled = true
	claim_btn.text = "دریافت شد ✅"
	AudioManager.play_upgrade()
	EventBus.notification_added.emit("جایزه روز %d دریافت شد!" % _current_day, "success")

func _get_reward_state() -> Dictionary:
	return GameState.daily_reward_state

func _save_reward_state(state: Dictionary) -> void:
	GameState.daily_reward_state = state