extends Panel

@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var no_alliance_label: Label = $VBox/NoAllianceLabel
@onready var alliance_list: VBoxContainer = $VBox/AllianceList
@onready var requests_list: VBoxContainer = $VBox/RequestsList

var _current_aid: String = ""

func _ready() -> void:
	UITheme.style_panel(self)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(hide)
	hide()
	get_viewport().size_changed.connect(_update_responsive)
	EventBus.game_loaded.connect(refresh)

func refresh() -> void:
	var player_id = "player"
	_current_aid = AllySystem.get_player_alliance(player_id)
	no_alliance_label.visible = _current_aid.is_empty()
	if alliance_list:
		alliance_list.visible = not _current_aid.is_empty()
		if not _current_aid.is_empty():
			var alliance = AllySystem.get_alliance(_current_aid)
			for child in alliance_list.get_children():
				child.queue_free()
			var members = alliance.get("members", [])
			for m in members:
				var label = Label.new()
				label.text = "👤 " + m
				alliance_list.add_child(label)
	if requests_list:
		var reqs = AllySystem.get_pending_requests()
		for child in requests_list.get_children():
			child.queue_free()
		for req in reqs:
			var label = Label.new()
			label.text = "درخواست از: " + req.get("from", "")
			requests_list.add_child(label)

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(400, vp.size.x * 0.8), min(350, vp.size.y * 0.7)))
	custom_minimum_size = sz
	size = sz
