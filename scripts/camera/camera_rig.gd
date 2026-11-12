class_name CameraRig
extends Node3D
## Third person orbit camera: SpringArm3D collision, drag-look, pinch/wheel zoom.

const MIN_PITCH := -60.0
const MAX_PITCH := 55.0

@export var distance: float = 5.4
@export var min_distance: float = 2.0
@export var max_distance: float = 9.0
@export var height_offset: float = 1.45
@export var follow_smoothing: float = 14.0

var yaw: float = 0.0
var pitch: float = -14.0

var spring_arm: SpringArm3D
var camera: Camera3D
var _target_distance: float = 5.4
var _body: CollisionObject3D

func _ready() -> void:
	position = Vector3(0.0, height_offset, 0.0)
	_build()
	_target_distance = distance

func _build() -> void:
	spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	spring_arm.spring_length = distance
	spring_arm.margin = 0.35
	spring_arm.collision_mask = 1
	spring_arm.add_excluded_object(_find_owner_rid())
	add_child(spring_arm)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 70.0
	camera.near = 0.08
	camera.far = SettingsManager.view_distance() * 2.0
	camera.current = true
	spring_arm.add_child(camera)

func _find_owner_rid() -> RID:
	var parent := get_parent()
	if parent is CollisionObject3D:
		_body = parent
		return (parent as CollisionObject3D).get_rid()
	return RID()

func _process(delta: float) -> void:
	var follow := get_parent() as Node3D
	if follow != null:
		if _body == null:
			_body = follow as CollisionObject3D
		# Rig follows position only; yaw/pitch stay user controlled.
		position = Vector3(0.0, height_offset, 0.0)
	rotation.y = yaw
	spring_arm.rotation.x = deg_to_rad(clampf(pitch, MIN_PITCH, MAX_PITCH))
	spring_arm.spring_length = lerpf(spring_arm.spring_length, _target_distance, clampf(delta * follow_smoothing, 0.0, 1.0))

func add_look(relative: Vector2) -> void:
	var sens := 0.16 * SettingsManager.camera_sensitivity
	yaw -= relative.x * sens
	var invert := -1.0 if SettingsManager.invert_camera_y else 1.0
	pitch -= relative.y * sens * invert
	pitch = clampf(pitch, MIN_PITCH, MAX_PITCH)

func add_zoom(amount: float) -> void:
	_target_distance = clampf(_target_distance - amount, min_distance, max_distance)

## Zoom target — what the spring arm is easing towards (test + HUD friendly).
func current_distance() -> float:
	return _target_distance

func set_zoom_factor(factor: float) -> void:
	_target_distance = clampf(_target_distance / factor, min_distance, max_distance)

func reset() -> void:
	yaw = 0.0
	pitch = -14.0
	_target_distance = distance

func flat_forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw)).normalized()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("camera_drag"):
		add_look((event as InputEventMouseMotion).relative)
	elif event is InputEventMouseButton and event.is_pressed():
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			add_zoom(0.45)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			add_zoom(-0.45)
	elif event is InputEventMagnifyGesture:
		set_zoom_factor((event as InputEventMagnifyGesture).factor)
