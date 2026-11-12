class_name CameraDragArea
extends Control
## Right-hand side of the screen: drag to orbit, pinch to zoom.

signal dragged(relative: Vector2)
signal pinched(factor: float)

var _pointer_id: int = -1
var _last: Vector2 = Vector2.ZERO
var _pinch_distance: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _pointer_id == -1:
			_pointer_id = touch.index
			_last = touch.position
		elif not touch.pressed and touch.index == _pointer_id:
			_pointer_id = -1
			_pinch_distance = 0.0
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _pointer_id:
			dragged.emit(drag.position - _last)
			_last = drag.position
	elif event is InputEventMagnifyGesture:
		pinched.emit((event as InputEventMagnifyGesture).factor)
	elif event is InputEventMouseMotion and Input.is_action_pressed("camera_drag"):
		dragged.emit((event as InputEventMouseMotion).relative)
