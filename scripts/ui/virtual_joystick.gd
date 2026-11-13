class_name VirtualJoystick
extends Control
## Transparent Dual-Ring Mobile RPG Joystick with 4 directional chevrons.

signal moved(vector: Vector2)

var radius: float = 78.0
var dead_zone: float = 0.15
var _center: Vector2
var _knob: Vector2
var _pointer_id: int = -1
var _active: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.25, radius * 2.25)
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
	# Subtle translucent outer ring + faint inner glass disc
	draw_circle(_center, radius, Color(0.86, 0.90, 0.88, 0.12))
	draw_arc(_center, radius, 0.0, TAU, 56, Color(0.92, 0.94, 0.92, 0.34), 2.0, true)
	draw_arc(_center, radius - 5.0, 0.0, TAU, 48, Color(0.92, 0.94, 0.92, 0.12), 1.0, true)

	# Four subtle cardinal chevrons around outer ring
	var chev_col := Color(0.94, 0.95, 0.92, 0.38)
	var cr := radius - 11.0
	for dir: Vector2 in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
		var tip := _center + dir * (cr + 4.0)
		var perp := Vector2(-dir.y, dir.x) * 4.5
		draw_colored_polygon(PackedVector2Array([tip, _center + dir * (cr - 2.0) + perp, _center + dir * (cr - 2.0) - perp]), chev_col)

	# Frosted translucent inner thumb knob
	var knob_r := radius * 0.36
	draw_circle(_knob, knob_r, Color(0.84, 0.87, 0.86, 0.48))
	draw_arc(_knob, knob_r, 0.0, TAU, 36, Color(0.98, 0.99, 0.98, 0.72), 2.2, true)
