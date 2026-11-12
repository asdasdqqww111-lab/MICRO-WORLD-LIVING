class_name TouchControls
extends Control
## On-screen controls: left joystick, right camera drag, action buttons.
## Also functions as the touch input source for PlayerInput.

signal look_dragged(relative: Vector2)
signal zoom_requested(factor: float)
signal menu_action(action_name: String)

var joystick: VirtualJoystick
var drag_area: CameraDragArea
var sprint_button: Button

var _move: Vector2 = Vector2.ZERO
var _pressed: Dictionary = {}
var _sprint: bool = false

func _ready() -> void:
	add_to_group("touch_controls")
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIFactory.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = SettingsManager.show_touch_controls
	EventBus.graphics_settings_changed.connect(func() -> void:
		visible = SettingsManager.show_touch_controls)

func _build() -> void:
	drag_area = CameraDragArea.new()
	drag_area.name = "CameraDragArea"
	drag_area.anchor_left = 0.34
	drag_area.anchor_top = 0.05
	drag_area.anchor_right = 1.0
	drag_area.anchor_bottom = 0.95
	drag_area.offset_left = 0
	drag_area.offset_top = 0
	drag_area.offset_right = 0
	drag_area.offset_bottom = 0
	drag_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(drag_area)
	drag_area.dragged.connect(func(relative: Vector2) -> void: look_dragged.emit(relative))
	drag_area.pinched.connect(func(factor: float) -> void: zoom_requested.emit(factor))

	joystick = VirtualJoystick.new()
	joystick.name = "Joystick"
	joystick.anchor_left = 0.0
	joystick.anchor_top = 1.0
	joystick.anchor_right = 0.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 24
	joystick.offset_top = -232
	joystick.offset_right = 232
	joystick.offset_bottom = -24
	add_child(joystick)
	joystick.moved.connect(func(vector: Vector2) -> void: _move = vector)

	_place_action_button("attack", "ATK", 26.0, 36.0, 122.0, UIFactory.DANGER)
	_place_action_button("jump", "JUMP", 166.0, 52.0, 98.0, Color(0.35, 0.55, 0.85))
	_place_action_button("interact", "USE", 40.0, 176.0, 96.0, UIFactory.ACCENT)
	_place_action_button("inventory", "BAG", 172.0, 176.0, 74.0, Color(0.55, 0.5, 0.35))
	_place_action_button("journal", "LOG", 260.0, 176.0, 74.0, Color(0.5, 0.45, 0.35))
	_place_action_button("character", "STAT", 348.0, 176.0, 78.0, Color(0.45, 0.4, 0.5))
	_place_action_button("pause", "II", 40.0, 290.0, 66.0, Color(0.3, 0.3, 0.35))
	sprint_button = _place_action_button("sprint", "RUN", 262.0, 52.0, 90.0, Color(0.4, 0.6, 0.4))

func _place_action_button(action: String, text: String, right_margin: float, bottom_margin: float,
		size: float, tint: Color) -> Button:
	var b := UIFactory.icon_button(text, int(size))
	b.name = "Btn_" + action
	b.anchor_left = 1.0
	b.anchor_top = 1.0
	b.anchor_right = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = -(right_margin + size)
	b.offset_top = -(bottom_margin + size)
	b.offset_right = -right_margin
	b.offset_bottom = -bottom_margin
	b.modulate = Color(1, 1, 1, 0.92)
	b.add_theme_color_override("font_color", tint.lerp(Color.WHITE, 0.35))
	if action == "sprint":
		b.button_down.connect(func() -> void:
			_sprint = not _sprint
			b.modulate = Color(1, 1, 1, 1.0) if _sprint else Color(1, 1, 1, 0.7))
	elif ["inventory", "journal", "character", "pause"].has(action):
		b.button_down.connect(func() -> void: menu_action.emit(action))
	else:
		b.button_down.connect(func() -> void: _pressed[action] = true)
	add_child(b)
	return b

func get_move_vector() -> Vector2:
	return _move

func is_sprinting() -> bool:
	return _sprint

func consume_pressed(action: String) -> bool:
	if not visible:
		return false
	if bool(_pressed.get(action, false)):
		_pressed[action] = false
		return true
	return false

func set_controls_visible(value: bool) -> void:
	visible = value

func reset_state() -> void:
	_move = Vector2.ZERO
	_pressed.clear()
	_sprint = false
	if sprint_button != null:
		sprint_button.modulate = Color(1, 1, 1, 0.7)
