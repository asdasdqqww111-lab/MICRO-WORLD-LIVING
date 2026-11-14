class_name TouchActionButton
extends Button
## Multi-touch aware action button for the on-screen combat cluster.
##
## A stock Button only reacts to mouse events, and the engine emulates the
## mouse from one finger at a time, so stock buttons cannot be pressed while
## another finger already holds the joystick. This control owns the index of
## the finger that pressed it instead, which makes "move + attack",
## "move + block" and "block + dodge" reliable on a touchscreen.
##
## It still extends Button so theme overrides, focus rules and existing callers
## (`button_down` / `button_up`, `as Button` casts, offset based layout) keep
## working. All BaseButton mouse handling is bypassed on purpose: visual states
## are driven here through `modulate` and `scale`.
##
## Visual states, in priority order: disabled > pressed (or toggled on) >
## highlighted > dimmed > normal.

## TAP fires `activated` on touch-down. HOLD reports `held_changed` while the
## finger stays down. TOGGLE flips `toggled_on` on every touch-down.
enum PressMode { TAP, HOLD, TOGGLE }

signal activated()
signal held_changed(held: bool)

const TINT_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const TINT_PRESSED := Color(1.24, 1.18, 1.04, 1.0)
const TINT_HIGHLIGHT := Color(1.18, 1.08, 0.74, 1.0)
const TINT_DIMMED := Color(0.72, 0.72, 0.76, 0.70)
const TINT_DISABLED := Color(0.55, 0.55, 0.58, 0.42)
const PRESS_SCALE := 0.93

var press_mode: PressMode = PressMode.TAP
## Circular hit test (round combat buttons) instead of the rectangle.
var circular_hit: bool = true
## Extra touch slop around the visible shape, in control-space pixels.
var hit_padding: float = 8.0
## Vibration length on touch-down; 0 disables haptics for this button.
var haptic_ms: int = 12
var toggled_on: bool = false

var _pointer: int = TouchPointer.NONE
var _held: bool = false
var _highlighted: bool = false
var _dimmed: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_pivot()
	_refresh_visual()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_update_pivot()
		NOTIFICATION_VISIBILITY_CHANGED:
			# A menu opening must never leave a hidden button "held".
			if not is_visible_in_tree():
				force_release()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			force_release()

func _update_pivot() -> void:
	pivot_offset = size * 0.5

## Enlarged, shape-aware touch target (thumb friendly, >= 48dp effective).
func _has_point(point: Vector2) -> bool:
	if circular_hit:
		var radius := maxf(size.x, size.y) * 0.5 + hit_padding
		return point.distance_to(size * 0.5) <= radius
	return Rect2(Vector2.ZERO, size).grow(hit_padding).has_point(point)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _pointer == TouchPointer.NONE and not disabled:
				_begin_press(touch.index)
		elif touch.index == _pointer:
			_end_press()
		accept_event()
	elif event is InputEventScreenDrag:
		if (event as InputEventScreenDrag).index == _pointer:
			accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if TouchPointer.is_real_mouse_button(mb):
			if mb.pressed:
				if _pointer == TouchPointer.NONE and not disabled:
					_begin_press(TouchPointer.MOUSE)
			elif _pointer == TouchPointer.MOUSE:
				_end_press()
		# Always swallow the click so BaseButton never double-handles it.
		accept_event()

func _begin_press(pointer: int) -> void:
	_pointer = pointer
	_held = true
	if press_mode == PressMode.TOGGLE:
		toggled_on = not toggled_on
	_refresh_visual()
	_play_haptic()
	button_down.emit()
	held_changed.emit(true)
	if press_mode != PressMode.HOLD:
		activated.emit()

func _end_press() -> void:
	if _pointer == TouchPointer.NONE:
		return
	_pointer = TouchPointer.NONE
	_held = false
	_refresh_visual()
	button_up.emit()
	held_changed.emit(false)

## Drops any active press without firing a new action (focus loss, menus).
func force_release() -> void:
	_end_press()

func is_held() -> bool:
	return _held

func active_pointer() -> int:
	return _pointer

## TOGGLE mode: set the latched state from code (e.g. reset when a menu opens).
func set_toggled(value: bool) -> void:
	if toggled_on == value:
		return
	toggled_on = value
	_refresh_visual()

## Contextual emphasis, e.g. Interact while something is in reach.
func set_highlighted(value: bool) -> void:
	if _highlighted == value:
		return
	_highlighted = value
	_refresh_visual()

func is_highlighted() -> bool:
	return _highlighted

## Soft "cannot afford this right now" hint. The button stays pressable so the
## gameplay layer keeps the final say (and can explain the refusal).
func set_dimmed(value: bool) -> void:
	if _dimmed == value:
		return
	_dimmed = value
	_refresh_visual()

func is_dimmed() -> bool:
	return _dimmed

## Hard enable/disable. A disabled button ignores presses entirely.
func set_enabled(value: bool) -> void:
	if disabled == (not value):
		return
	disabled = not value
	if disabled:
		force_release()
	_refresh_visual()

func _refresh_visual() -> void:
	var tint := TINT_NORMAL
	if disabled:
		tint = TINT_DISABLED
	elif _held or (press_mode == PressMode.TOGGLE and toggled_on):
		tint = TINT_PRESSED
	elif _highlighted:
		tint = TINT_HIGHLIGHT
	elif _dimmed:
		tint = TINT_DIMMED
	modulate = tint
	scale = Vector2.ONE * (PRESS_SCALE if _held else 1.0)

func _play_haptic() -> void:
	if haptic_ms <= 0 or not SettingsManager.haptics_enabled:
		return
	if SettingsManager.is_mobile():
		Input.vibrate_handheld(haptic_ms)
