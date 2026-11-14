class_name TouchPointer
extends RefCounted
## Shared pointer-identity rules for every on-screen touch control.
##
## Why this exists: the engine emulates a mouse from exactly ONE finger at a
## time (`input_devices/pointing/emulate_mouse_from_touch`). Controls that only
## listen to mouse events therefore go dead as soon as another finger is already
## down - e.g. no attacking while the thumb holds the joystick. Every touch
## control in this project instead tracks the index of the finger that pressed
## it (InputEventScreenTouch / InputEventScreenDrag are routed per finger by
## the Viewport) and uses these helpers to decide whether a mouse event is a
## real pointer or only the emulated echo of a touch that was already handled.

## No finger currently owns the control.
const NONE := -1
## A real (non-emulated) mouse button owns the control.
const MOUSE := -2

## True when the engine converts mouse clicks into touch events at runtime.
## In that mode the emulated touch is the single source of truth and raw mouse
## buttons must be ignored, otherwise every desktop click would count twice.
static func mouse_emulates_touch() -> bool:
	# Read through Object.get() so a missing property can never break parsing.
	var runtime: Variant = Input.get("emulate_touch_from_mouse")
	if typeof(runtime) == TYPE_BOOL:
		return bool(runtime)
	var wanted := bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false))
	return wanted and not DisplayServer.is_touchscreen_available()

## True when `event` is a genuine mouse button that should act as a pointer:
## not the emulated echo of a finger, and not already mirrored as a touch.
static func is_real_mouse_button(event: InputEventMouseButton) -> bool:
	if event == null or event.button_index != MOUSE_BUTTON_LEFT:
		return false
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return false
	return not mouse_emulates_touch()

## Maps a raw stick deflection (0..1 of the ring radius) to an output vector
## with a rescaled radial dead zone, so movement starts smoothly at zero right
## past the dead zone instead of jumping to `dead_zone` magnitude.
static func apply_radial_dead_zone(raw: Vector2, dead_zone: float) -> Vector2:
	var magnitude := raw.length()
	var dz := clampf(dead_zone, 0.0, 0.9)
	if magnitude <= dz or magnitude <= 0.0001:
		return Vector2.ZERO
	var scaled := clampf((magnitude - dz) / (1.0 - dz), 0.0, 1.0)
	return raw / magnitude * scaled
