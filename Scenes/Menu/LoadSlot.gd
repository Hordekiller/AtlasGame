extends Panel

var slot_index: int = 0
var on_selected: Callable = Callable()
var on_deleted: Callable = Callable()

@onready var slot_label: Label = $VBox/SlotLabel
@onready var info_label: Label = $VBox/InfoLabel
@onready var load_btn: Button = $VBox/LoadBtn
@onready var delete_btn: Button = $VBox/DeleteBtn

func _ready() -> void:
	UITheme.style_panel(self)
	UITheme.style_button(load_btn)
	UITheme.style_button(delete_btn)
	load_btn.pressed.connect(_on_load)
	delete_btn.pressed.connect(_on_delete)
	get_viewport().size_changed.connect(_update_responsive)
	_update_responsive()

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	custom_minimum_size = Vector2(min(300, vp.size.x * 0.6), 0)
	size = custom_minimum_size

func setup(slot: int) -> void:
	slot_index = slot
	var info = SaveManager.get_save_info(slot)
	slot_label.text = "ذخیره %d" % (slot + 1)

	if info.is_empty() or not info.get("exists", false):
		info_label.text = "خالی"
		load_btn.disabled = true
		load_btn.text = "خالی"
		delete_btn.disabled = true
		return

	var day = info.get("day", 1)
	var time_str = ""
	var save_time = info.get("save_time", 0)
	if save_time > 0:
		var dt = Time.get_datetime_dict_from_unix_time(int(save_time))
		time_str = "%04d/%02d/%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]

	info_label.text = "روز %d\n%s" % [day, time_str]
	load_btn.disabled = false
	load_btn.text = "بارگذاری"
	delete_btn.disabled = false

func _on_load() -> void:
	if on_selected.is_null():
		return
	on_selected.call(slot_index)

func _on_delete() -> void:
	if on_deleted.is_null():
		return
	on_deleted.call(slot_index)
