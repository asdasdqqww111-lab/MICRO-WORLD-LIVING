class_name InputSetup
extends RefCounted
## Builds the InputMap at runtime so the project has a single typed source of
## truth for every action (keyboard + mouse; touch is handled by TouchControls).

const ACTIONS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"sprint": [KEY_SHIFT],
	"jump": [KEY_SPACE],
	"attack": [KEY_F],
	"interact": [KEY_E],
	"dodge": [KEY_Q],
	"toggle_inventory": [KEY_I, KEY_TAB],
	"toggle_journal": [KEY_J],
	"toggle_character": [KEY_C],
	"toggle_skills": [KEY_K],
	"pause": [KEY_ESCAPE],
	"quick_save": [KEY_F5],
	"quick_load": [KEY_F9],
	"toggle_performance": [KEY_F3],
	"camera_zoom_in": [KEY_EQUAL, KEY_KP_ADD],
	"camera_zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT],
}

static func ensure_actions() -> void:
	for action_name: String in ACTIONS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.2)
		for key: int in ACTIONS[action_name]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action_name, ev)
	# Mouse buttons for camera / attack.
	if InputMap.has_action("attack"):
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mb)
	for action_name: String in ["camera_zoom_in", "camera_zoom_out"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
	if not InputMap.has_action("camera_drag"):
		InputMap.add_action("camera_drag")
	var rmb := InputEventMouseButton.new()
	rmb.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("camera_drag", rmb)
