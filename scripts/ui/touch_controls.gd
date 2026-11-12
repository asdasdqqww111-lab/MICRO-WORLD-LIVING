class_name TouchControls
extends Control
## Mobile-first fantasy action RPG touch controls:
##   - Left thumb: Smooth Virtual Joystick + Sprint toggle
##   - Right thumb: Camera drag & pinch-to-zoom + ergonomic arc of combat buttons
##     (ATK, HVY, MAG, DODGE, BLK, POT, USE, JMP) — all >=54px touch targets!

signal look_dragged(relative: Vector2)
signal zoom_requested(factor: float)
signal menu_action(action_name: String)

var joystick: VirtualJoystick
var drag_area: CameraDragArea
var sprint_button: Button
var block_button: Button

var _move: Vector2 = Vector2.ZERO
var _pressed: Dictionary = {}
var _sprint: bool = false
var _blocking: bool = false

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
	drag_area.anchor_left = 0.32
	drag_area.anchor_top = 0.08
	drag_area.anchor_right = 1.0
	drag_area.anchor_bottom = 0.94
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
	joystick.offset_top = -224
	joystick.offset_right = 224
	joystick.offset_bottom = -24
	add_child(joystick)
	joystick.moved.connect(func(vector: Vector2) -> void: _move = vector)

	# Left-side Sprint toggle just above joystick
	sprint_button = UIFactory.icon_button("RUN", 58)
	sprint_button.name = "Btn_sprint"
	sprint_button.anchor_left = 0.0
	sprint_button.anchor_top = 1.0
	sprint_button.anchor_right = 0.0
	sprint_button.anchor_bottom = 1.0
	sprint_button.offset_left = 236
	sprint_button.offset_top = -90
	sprint_button.offset_right = 294
	sprint_button.offset_bottom = -32
	sprint_button.modulate = Color(1, 1, 1, 0.78)
	sprint_button.button_down.connect(func() -> void:
		_sprint = not _sprint
		sprint_button.modulate = Color(1.0, 0.95, 0.65, 1.0) if _sprint else Color(1, 1, 1, 0.78))
	add_child(sprint_button)

	# Ergonomic Right-Hand Action Cluster (no overlap, clear silhouettes)
	_place_action_button("attack", "⚔ ATK", 24.0, 26.0, 108.0, UIFactory.DANGER)
	_place_action_button("attack_heavy", "🪓 HVY", 144.0, 24.0, 74.0, Color(0.96, 0.58, 0.24))
	_place_action_button("cast_spell", "✦ MAG", 228.0, 24.0, 72.0, UIFactory.MANA_BLUE)
	_place_action_button("dodge", "💨 DGE", 144.0, 108.0, 72.0, UIFactory.STAMINA_TEAL)
	_place_action_button("jump", "⬆ JMP", 26.0, 146.0, 74.0, Color(0.55, 0.78, 1.0))
	_place_action_button("interact", "✦ USE", 110.0, 190.0, 72.0, UIFactory.GOLD)
	_place_action_button("quick_potion", "⚗ POT", 228.0, 106.0, 64.0, UIFactory.ACCENT)

	# Hold-to-Block Shield Button
	block_button = _place_action_button("block", "🛡 BLK", 26.0, 230.0, 68.0, Color(0.72, 0.78, 0.92))
	block_button.button_down.connect(func() -> void: _blocking = true)
	block_button.button_up.connect(func() -> void: _blocking = false)

func _place_action_button(action: String, text: String, right_margin: float, bottom_margin: float,
		btn_size: float, tint: Color) -> Button:
	var b := UIFactory.icon_button(text, int(btn_size))
	b.name = "Btn_" + action
	b.anchor_left = 1.0
	b.anchor_top = 1.0
	b.anchor_right = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = -(right_margin + btn_size)
	b.offset_top = -(bottom_margin + btn_size)
	b.offset_right = -right_margin
	b.offset_bottom = -bottom_margin
	b.modulate = Color(1, 1, 1, 0.90)
	b.add_theme_font_size_override("font_size", 15 if btn_size < 95.0 else 18)
	b.add_theme_color_override("font_color", tint.lerp(Color.WHITE, 0.30))
	if action != "block":
		b.button_down.connect(func() -> void: _pressed[action] = true)
	add_child(b)
	return b

func get_move_vector() -> Vector2:
	return _move

func is_sprinting() -> bool:
	return _sprint

func is_blocking() -> bool:
	return _blocking

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
	_blocking = false
	if sprint_button != null:
		sprint_button.modulate = Color(1, 1, 1, 0.78)
