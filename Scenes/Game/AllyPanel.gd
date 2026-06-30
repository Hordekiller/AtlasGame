extends Panel

@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var no_alliance_label: Label = $VBox/NoAllianceLabel

func _ready() -> void:
	UITheme.style_panel(self)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(hide)
	hide()
	get_viewport().size_changed.connect(_update_responsive)

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(400, vp.size.x * 0.8), min(350, vp.size.y * 0.7)))
	custom_minimum_size = sz
	size = sz
