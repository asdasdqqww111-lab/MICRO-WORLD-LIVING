class_name VirtualJoystick
extends Control
## Touch joystick (also usable with the mouse thanks to touch emulation).

signal moved(vector: Vector2)

var radius: float = 92.0
var dead_zone: float = 0.16
var _center: Vector2
var _knob: Vector2
var _pointer_id: int = -1
var _active: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.2, radius * 2.2)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center = size * 0.5
	_knob = _center

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center = size * 0.5
		if not _active:
			_knob = _center

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _pointer_id == -1:
			_pointer_id = touch.index
			_active = true
			_update_from_position(touch.position)
			accept_event()
		elif not touch.pressed and touch.index == _pointer_id:
			_pointer_id = -1
			_active = false
			_knob = _center
			moved.emit(Vector2.ZERO)
			queue_redraw()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _pointer_id:
			_update_from_position(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_active = mb.pressed
			if mb.pressed:
				_update_from_position(mb.position)
			else:
				_knob = _center
				moved.emit(Vector2.ZERO)
				queue_redraw()
			accept_event()

func _update_from_position(position: Vector2) -> void:
	var delta := position - _center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	_knob = _center + delta
	var vector := delta / radius
	if vector.length() < dead_zone:
		vector = Vector2.ZERO
	moved.emit(vector)
	queue_redraw()

func vector() -> Vector2:
	var delta := (_knob - _center) / radius
	return Vector2.ZERO if delta.length() < dead_zone else delta

func _draw() -> void:
	var base_color := Color(1, 1, 1, 0.12)
	var ring_color := Color(1, 1, 1, 0.35)
	draw_circle(_center, radius, base_color)
	draw_arc(_center, radius, 0.0, TAU, 48, ring_color, 3.0, true)
	draw_circle(_knob, radius * 0.38, Color(0.55, 0.78, 0.45, 0.75))
	draw_arc(_knob, radius * 0.38, 0.0, TAU, 32, Color(1, 1, 1, 0.6), 2.0, true)
