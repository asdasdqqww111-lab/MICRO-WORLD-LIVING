class_name CameraDragArea
extends Control
## Free screen area: one finger drags to orbit, two fingers pinch to zoom.
##
## Fingers are tracked by touch index, so orbiting keeps working while other
## fingers hold the joystick or the action buttons. Pinch is computed here from
## two tracked fingers because Android does not emit InputEventMagnifyGesture
## unless the optional pan/scale gesture setting is enabled.

signal dragged(relative: Vector2)
signal pinched(factor: float)

const MAX_POINTERS := 2
## Ignore pinch updates while the fingers are closer than this (px): the ratio
## becomes unstable and would make the zoom jump.
const MIN_PINCH_DISTANCE := 24.0
## Zoom step for one mouse-wheel notch (desktop testing).
const WHEEL_ZOOM_FACTOR := 1.12

## touch index -> last known position (control space)
var _pointers: Dictionary = {}
var _pinch_distance: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				release()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			release()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _pointers.size() < MAX_POINTERS:
				_pointers[touch.index] = touch.position
				_pinch_distance = _measure_pinch()
		elif _pointers.has(touch.index):
			_pointers.erase(touch.index)
			_pinch_distance = _measure_pinch()
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if not _pointers.has(drag.index):
			return
		var previous: Vector2 = _pointers[drag.index]
		_pointers[drag.index] = drag.position
		if _pointers.size() == 1:
			dragged.emit(drag.position - previous)
		else:
			_update_pinch()
		accept_event()
	elif event is InputEventMagnifyGesture:
		pinched.emit((event as InputEventMagnifyGesture).factor)
		accept_event()
	elif event is InputEventMouseButton:
		# This control stops pointer events, so the wheel never reaches
		# CameraRig._unhandled_input while the cursor is over it.
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			pinched.emit(WHEEL_ZOOM_FACTOR)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			pinched.emit(1.0 / WHEEL_ZOOM_FACTOR)
	elif event is InputEventMouseMotion and Input.is_action_pressed("camera_drag"):
		dragged.emit((event as InputEventMouseMotion).relative)

## Forgets every tracked finger (menus opening, app losing focus).
func release() -> void:
	_pointers.clear()
	_pinch_distance = 0.0

func pointer_count() -> int:
	return _pointers.size()

func _measure_pinch() -> float:
	if _pointers.size() < 2:
		return 0.0
	var points: Array = _pointers.values()
	var a: Vector2 = points[0]
	var b: Vector2 = points[1]
	return a.distance_to(b)

func _update_pinch() -> void:
	var current := _measure_pinch()
	if current < MIN_PINCH_DISTANCE:
		return
	if _pinch_distance >= MIN_PINCH_DISTANCE:
		# factor > 1 = fingers spreading = zoom in (matches MagnifyGesture).
		pinched.emit(current / _pinch_distance)
	_pinch_distance = current
