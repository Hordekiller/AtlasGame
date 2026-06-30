extends Node

const TOUCH_TARGET_MIN := 88
const SWIPE_THRESHOLD := 30
const DEBOUNCE_MS := 200

var _last_touch_time: Dictionary = {}

func is_valid_touch_target(control: Control) -> bool:
	return control.size.x >= TOUCH_TARGET_MIN and control.size.y >= TOUCH_TARGET_MIN

func is_debounced(button_id: String) -> bool:
	var now = Time.get_ticks_msec()
	if _last_touch_time.has(button_id) and now - _last_touch_time[button_id] < DEBOUNCE_MS:
		return false
	_last_touch_time[button_id] = now
	return true

func get_swipe_direction(start: Vector2, end: Vector2) -> String:
	var diff = end - start
	if abs(diff.x) > abs(diff.y):
		return "left" if diff.x < -SWIPE_THRESHOLD else "right"
	return "up" if diff.y < -SWIPE_THRESHOLD else "down"

func is_double_tap(event: InputEvent, last_tap_time: float) -> bool:
	var now = Time.get_ticks_msec()
	return (now - last_tap_time) < 400