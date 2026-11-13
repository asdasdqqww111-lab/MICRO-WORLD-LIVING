class_name TouchControls
extends Control
## Stylized Mobile RPG Touch Controls matching the Arabic Reference HUD:
##   - Bottom-Left: Transparent Dual-Ring Joystick + Pill-shaped "ركض" (Sprint) Button
##   - Bottom-Right: Large Ornate Bronze/Gold "هجوم" Button (crossed swords),
##     curved arc of 8 bronze/gold RPG buttons (>= 46px clear gap), & 5 Quick-Slot squares.

signal look_dragged(relative: Vector2)
signal zoom_requested(factor: float)
signal menu_action(action_name: String)

var joystick: VirtualJoystick
var drag_area: CameraDragArea
var sprint_button: Button
var block_button: Button
var attack_button: Button
var _sprint_label: Label
var _attack_label: Label
var _quick_slots: Array[PanelContainer] = []

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
	_refresh_labels()
	visible = SettingsManager.show_touch_controls
	EventBus.graphics_settings_changed.connect(func() -> void:
		visible = SettingsManager.show_touch_controls)
	EventBus.language_changed.connect(func(_l: String) -> void:
		_refresh_labels())

func _refresh_labels() -> void:
	var ar := Localization.is_arabic()
	if _sprint_label != null:
		_sprint_label.text = "ركض" if ar else "RUN"
	if _attack_label != null:
		_attack_label.text = "هجوم" if ar else "ATK"

func _make_bronze_circle_style(radius: int, bg_col: Color, border_col: Color, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_size = 0
	return sb

func _build() -> void:
	drag_area = CameraDragArea.new()
	drag_area.name = "CameraDragArea"
	drag_area.anchor_left = 0.30
	drag_area.anchor_top = 0.10
	drag_area.anchor_right = 1.0
	drag_area.anchor_bottom = 0.92
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
	joystick.offset_left = 20
	joystick.offset_top = -198
	joystick.offset_right = 198
	joystick.offset_bottom = -20
	add_child(joystick)
	joystick.moved.connect(func(vector: Vector2) -> void: _move = vector)

	# Pill-shaped "ركض" (Sprint) Button with circular running badge on left
	sprint_button = Button.new()
	sprint_button.name = "Btn_sprint"
	sprint_button.text = ""
	sprint_button.focus_mode = Control.FOCUS_NONE
	sprint_button.anchor_left = 0.0
	sprint_button.anchor_top = 1.0
	sprint_button.anchor_right = 0.0
	sprint_button.anchor_bottom = 1.0
	sprint_button.offset_left = 216
	sprint_button.offset_top = -64
	sprint_button.offset_right = 324
	sprint_button.offset_bottom = -24
	var pill_sb := _make_bronze_circle_style(20, Color(0.10, 0.12, 0.12, 0.76), Color(0.68, 0.62, 0.44, 0.72), 1)
	var pill_pr := _make_bronze_circle_style(20, Color(0.24, 0.22, 0.14, 0.88), Color(0.96, 0.82, 0.42, 0.95), 2)
	for st: String in ["normal", "hover", "focus"]:
		sprint_button.add_theme_stylebox_override(st, pill_sb)
	sprint_button.add_theme_stylebox_override("pressed", pill_pr)

	var sp_hbox := HBoxContainer.new()
	sp_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	sp_hbox.offset_left = 4
	sp_hbox.offset_right = -10
	sp_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sp_hbox.add_theme_constant_override("separation", 6)
	sp_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprint_button.add_child(sp_hbox)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(30, 30)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _make_bronze_circle_style(15, Color(0.18, 0.18, 0.16, 0.90), Color(0.76, 0.66, 0.44, 0.82), 1))
	var badge_center := CenterContainer.new()
	badge_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_center.add_child(RpgIcon.new().setup("sprint", Vector2(20, 20)))
	badge.add_child(badge_center)
	sp_hbox.add_child(badge)

	_sprint_label = UIFactory.label("ركض", 14, Color(0.96, 0.95, 0.90))
	_sprint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sprint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_hbox.add_child(_sprint_label)

	sprint_button.button_down.connect(func() -> void:
		_sprint = not _sprint
		sprint_button.modulate = Color(1.0, 0.95, 0.72, 1.0) if _sprint else Color(1, 1, 1, 0.92))
	add_child(sprint_button)

	# 5 Quick-Slot Squares along bottom-right edge (matching reference image!)
	var qs_bar := HBoxContainer.new()
	qs_bar.name = "QuickSlotsBar"
	qs_bar.anchor_left = 1.0
	qs_bar.anchor_top = 1.0
	qs_bar.anchor_right = 1.0
	qs_bar.anchor_bottom = 1.0
	qs_bar.offset_left = -352
	qs_bar.offset_top = -40
	qs_bar.offset_right = -162
	qs_bar.offset_bottom = -8
	qs_bar.add_theme_constant_override("separation", 6)
	qs_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(qs_bar)
	var qs_sb := RpgIcon.shared_stylebox("slot_box")
	for qi in 5:
		var slot := PanelContainer.new()
		slot.name = "QuickSlot_%d" % qi
		slot.custom_minimum_size = Vector2(32, 32)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_theme_stylebox_override("panel", qs_sb)
		qs_bar.add_child(slot)
		_quick_slots.append(slot)

	# Bottom-Right Ornate Bronze/Gold Combat Cluster (9 buttons, >= 46px clear gap!)
	attack_button = _place_rpg_button("attack", "swords", 34.0, 26.0, 92.0, true)
	# Inner Arc
	_place_rpg_button("attack_heavy", "bag", 198.0, 58.0, 58.0, false)
	_place_rpg_button("dodge", "sparkle", 150.0, 158.0, 58.0, false)
	_place_rpg_button("jump", "stone", 48.0, 198.0, 58.0, false)
	# Outer Arc
	_place_rpg_button("cast_spell", "book", 310.0, 72.0, 54.0, false)
	_place_rpg_button("interact", "burst", 269.0, 192.0, 54.0, false)
	_place_rpg_button("lock_target", "hand", 177.0, 278.0, 54.0, false)
	_place_rpg_button("quick_potion", "potion", 418.0, 40.0, 54.0, false)

	block_button = _place_rpg_button("block", "swords", 56.0, 311.0, 54.0, false)
	block_button.button_down.connect(func() -> void: _blocking = true)
	block_button.button_up.connect(func() -> void: _blocking = false)

func _place_rpg_button(action: String, icon_kind: String, right_margin: float, bottom_margin: float,
		btn_size: float, is_main_attack: bool) -> Button:
	var b := Button.new()
	b.name = "Btn_" + action
	b.text = ""
	b.focus_mode = Control.FOCUS_NONE
	b.anchor_left = 1.0
	b.anchor_top = 1.0
	b.anchor_right = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = -(right_margin + btn_size)
	b.offset_top = -(bottom_margin + btn_size)
	b.offset_right = -right_margin
	b.offset_bottom = -bottom_margin

	var tex_key := "btn_attack" if is_main_attack else "btn_circle"
	var sb_n := RpgIcon.shared_stylebox(tex_key)
	var sb_p := RpgIcon.shared_stylebox(tex_key, 0, Color(1.22, 1.18, 1.05, 1.0))
	for st: String in ["normal", "hover", "focus"]:
		b.add_theme_stylebox_override(st, sb_n)
	b.add_theme_stylebox_override("pressed", sb_p)

	if is_main_attack:
		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 0)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic_wrap := CenterContainer.new()
		ic_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic_wrap.add_child(RpgIcon.new().setup(icon_kind, Vector2(42, 42)))
		vbox.add_child(ic_wrap)
		_attack_label = UIFactory.label("هجوم", 14, Color(0.98, 0.95, 0.86))
		_attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(_attack_label)
		b.add_child(vbox)
	else:
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(RpgIcon.new().setup(icon_kind, Vector2(btn_size * 0.54, btn_size * 0.54)))
		b.add_child(center)

	b.button_down.connect(func() -> void:
		b.modulate = Color(1.20, 1.16, 1.04, 1.0)
		if action != "block":
			_pressed[action] = true)
	b.button_up.connect(func() -> void:
		b.modulate = Color(1, 1, 1, 1.0))
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
		sprint_button.modulate = Color(1, 1, 1, 0.92)
