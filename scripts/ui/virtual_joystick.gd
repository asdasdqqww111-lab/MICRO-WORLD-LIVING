class_name MobileVirtualJoystick
extends Control
## Transparent Dual-Ring Mobile RPG Joystick with 4 directional chevrons.
##
## Input model: the stick is owned by the index of the finger that pressed it
## (see TouchPointer), so it keeps tracking while other fingers use the action
## buttons or orbit the camera. Output uses a rescaled radial dead zone.

signal moved(vector: Vector2)

var radius: float = 78.0
var dead_zone: float = 0.15
## Extra touch slop around the control rectangle, in control-space pixels.
var hit_padding: float = 24.0

var _center: Vector2
var _knob: Vector2
var _pointer_id: int = TouchPointer.NONE
var _active: bool = false
var _output: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.25, radius * 2.25)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center = size * 0.5
	_knob = _center

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_center = size * 0.5
			if not _active:
				_knob = _center
			queue_redraw()
		NOTIFICATION_VISIBILITY_CHANGED:
			# Never keep walking after a menu hides the controls.
			if not is_visible_in_tree():
				release()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			release()

func _has_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).grow(hit_padding).has_point(point)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _pointer_id == TouchPointer.NONE:
				_grab(touch.index, touch.position)
		elif touch.index == _pointer_id:
			release()
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _pointer_id:
			_update_from_position(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if TouchPointer.is_real_mouse_button(mb):
			if mb.pressed:
				if _pointer_id == TouchPointer.NONE:
					_grab(TouchPointer.MOUSE, mb.position)
			elif _pointer_id == TouchPointer.MOUSE:
				release()
		accept_event()
	elif event is InputEventMouseMotion:
		if _pointer_id == TouchPointer.MOUSE:
			_update_from_position((event as InputEventMouseMotion).position)
			accept_event()

func _grab(pointer: int, local_pos: Vector2) -> void:
	_pointer_id = pointer
	_active = true
	_update_from_position(local_pos)

## Centres the stick and reports a zero vector. Safe to call at any time.
func release() -> void:
	var was_active := _active or _output != Vector2.ZERO
	_pointer_id = TouchPointer.NONE
	_active = false
	_knob = _center
	_output = Vector2.ZERO
	if was_active:
		moved.emit(Vector2.ZERO)
		queue_redraw()

func _update_from_position(local_pos: Vector2) -> void:
	var delta := local_pos - _center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	_knob = _center + delta
	_output = TouchPointer.apply_radial_dead_zone(delta / radius, dead_zone)
	moved.emit(_output)
	queue_redraw()

## Current stick output, length 0..1, dead zone already applied.
func vector() -> Vector2:
	return _output

func is_active() -> bool:
	return _active

func active_pointer() -> int:
	return _pointer_id

func _draw() -> void:
	# Two draw calls (base + knob) from the shared icon atlas instead of nine
	# separate circle / arc / polygon commands.
	var tex := RpgIcon.atlas()
	var base_alpha := 1.0 if _active else 0.72
	draw_texture_rect_region(tex, Rect2(_center - Vector2(radius, radius), Vector2(radius, radius) * 2.0),
		RpgIcon.region("joy_base"), Color(1, 1, 1, base_alpha))
	var knob_r := radius * 0.40
	draw_texture_rect_region(tex, Rect2(_knob - Vector2(knob_r, knob_r), Vector2(knob_r, knob_r) * 2.0),
		RpgIcon.region("joy_knob"), Color(1, 1, 1, 1.0 if _active else 0.80))
