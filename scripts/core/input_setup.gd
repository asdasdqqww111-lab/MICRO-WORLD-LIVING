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
	"heavy_attack": [KEY_R],
	"attack_heavy": [KEY_R],
	"cast_spell": [KEY_Z, KEY_1],
	"quick_potion": [KEY_X, KEY_2],
	"block": [KEY_B],
	"interact": [KEY_E],
	"dodge": [KEY_Q],
	"lock_target": [KEY_T],
	"recenter_camera": [KEY_V],
	"camera_recenter": [KEY_V],
	"toggle_inventory": [KEY_I, KEY_TAB],
	"toggle_journal": [KEY_J],
	"toggle_character": [KEY_C],
	"toggle_skills": [KEY_K],
	"toggle_guild": [KEY_G],
	"toggle_crafting": [KEY_H],
	"toggle_map": [KEY_M],
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
			InputMap.add_action(action_name)
		var keys: Array = ACTIONS[action_name]
		for keycode: int in keys:
			if not _action_has_key(action_name, keycode):
				var ev := InputEventKey.new()
				ev.physical_keycode = keycode as Key
				InputMap.action_add_event(action_name, ev)

	if not InputMap.has_action("camera_drag"):
		InputMap.add_action("camera_drag")
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("camera_drag", mb)

static func _action_has_key(action_name: String, keycode: int) -> bool:
	for ev: InputEvent in InputMap.action_get_events(action_name):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == keycode:
			return true
	return false
