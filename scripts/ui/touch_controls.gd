class_name TouchControls
extends Control
## Stylized Mobile RPG Touch Controls matching the Arabic Reference HUD:
##   - Bottom-Left: Transparent Dual-Ring Joystick + Pill-shaped "ركض" (Sprint) Button
##   - Bottom-Right: Large Ornate Bronze/Gold "هجوم" Button (crossed swords),
##     curved arc of 8 bronze/gold RPG buttons (>= 46px clear gap), & 5 Quick-Slot squares.
##
## Input model (multi-touch correct): the joystick, the camera drag area and
## every action button own the index of the finger that pressed them
## (TouchPointer / TouchActionButton). Any combination of fingers therefore
## works at the same time: move + attack, move + block + dodge, move + orbit.
## Stock Buttons cannot do this because the engine emulates the mouse from a
## single finger only.

signal look_dragged(relative: Vector2)
signal zoom_requested(factor: float)
signal menu_action(action_name: String)

## Consumables the quick-potion button can use (mirrors Player.try_quick_potion).
const POTION_IDS: Array[String] = ["health_potion", "mana_elixir", "venison", "bread"]
## Largest share of a screen edge the safe-area inset may claim.
const MAX_SAFE_INSET_RATIO := 0.12

var joystick: MobileVirtualJoystick
var drag_area: CameraDragArea
var sprint_button: TouchActionButton
var block_button: TouchActionButton
var attack_button: TouchActionButton
var _sprint_label: Label
var _attack_label: Label
var _quick_slots: Array[PanelContainer] = []
var _combat_specs: Array[Dictionary] = []
var _action_buttons: Dictionary = {}
var _built := false

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
		visible = SettingsManager.show_touch_controls
		_layout_responsive())
	EventBus.language_changed.connect(func(_l: String) -> void:
		_refresh_labels())
	_connect_context_feedback()

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

	joystick = MobileVirtualJoystick.new()
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
	sprint_button = TouchActionButton.new()
	sprint_button.name = "Btn_sprint"
	sprint_button.text = ""
	sprint_button.focus_mode = Control.FOCUS_NONE
	sprint_button.press_mode = TouchActionButton.PressMode.TOGGLE
	sprint_button.circular_hit = false
	sprint_button.hit_padding = 10.0
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
	for st: String in ["normal", "hover", "focus", "disabled"]:
		sprint_button.add_theme_stylebox_override(st, pill_sb)
	for st: String in ["pressed", "hover_pressed"]:
		sprint_button.add_theme_stylebox_override(st, pill_pr)

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

	sprint_button.activated.connect(func() -> void: _sprint = sprint_button.toggled_on)
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
	block_button.press_mode = TouchActionButton.PressMode.HOLD
	block_button.held_changed.connect(func(held: bool) -> void: _blocking = held)
	_built = true
	_layout_responsive()

func _place_rpg_button(action: String, icon_kind: String, right_margin: float, bottom_margin: float,
		btn_size: float, is_main_attack: bool) -> TouchActionButton:
	var b := TouchActionButton.new()
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
	for st: String in ["normal", "hover", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, sb_n)
	for st: String in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, sb_p)
	b.haptic_ms = 18 if is_main_attack else 12

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

	# TAP buttons queue one action per touch-down; Player consumes the queue on
	# its next physics tick. Block is switched to HOLD by the caller, and HOLD
	# buttons never emit `activated`, so they do not enter the queue.
	b.activated.connect(func() -> void: _pressed[action] = true)
	add_child(b)
	_action_buttons[action] = b
	_combat_specs.append({"button": b, "right": right_margin, "bottom": bottom_margin, "size": btn_size})
	return b

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			if _built:
				_layout_responsive()
		NOTIFICATION_VISIBILITY_CHANGED:
			if _built and not is_visible_in_tree():
				release_all()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			# A finger that is down while the app goes to the background never
			# reports its release, so drop every held input explicitly.
			if _built:
				release_all()

## Display cut-out / rounded-corner insets as (left, top, right, bottom) in
## this control's coordinate space. Zero on desktop and in headless runs.
func _safe_area_insets() -> Vector4:
	if not SettingsManager.is_mobile() or size.x <= 1.0 or size.y <= 1.0:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0:
		return Vector4.ZERO
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	var to_local := Vector2(size.x / window_size.x, size.y / window_size.y)
	var max_x := size.x * MAX_SAFE_INSET_RATIO
	var max_y := size.y * MAX_SAFE_INSET_RATIO
	return Vector4(
		clampf(float(safe.position.x) * to_local.x, 0.0, max_x),
		clampf(float(safe.position.y) * to_local.y, 0.0, max_y),
		clampf((window_size.x - float(safe.end.x)) * to_local.x, 0.0, max_x),
		clampf((window_size.y - float(safe.end.y)) * to_local.y, 0.0, max_y))

func _layout_responsive() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var insets := _safe_area_insets()
	var fit := clampf(minf(size.x / 900.0, size.y / 600.0), 0.78, 1.0)
	fit *= clampf(SettingsManager.touch_scale, 0.85, 1.18)
	for spec: Dictionary in _combat_specs:
		var b := spec["button"] as Button
		var s := float(spec["size"]) * fit
		var r := float(spec["right"]) * fit + maxf(10.0, size.x * 0.014) + insets.z
		var bot := float(spec["bottom"]) * fit + maxf(10.0, size.y * 0.014) + insets.w
		b.offset_left = -(r + s)
		b.offset_top = -(bot + s)
		b.offset_right = -r
		b.offset_bottom = -bot
	if joystick != null:
		var joy_size := clampf(minf(size.x * 0.24, size.y * 0.30), 172.0, 218.0)
		var joy_bottom := maxf(16.0, size.y * 0.035) + insets.w
		joystick.offset_left = maxf(12.0, size.x * 0.025) + insets.x
		joystick.offset_top = -(joy_size + joy_bottom)
		joystick.offset_right = joystick.offset_left + joy_size
		joystick.offset_bottom = -joy_bottom
		if sprint_button != null:
			# Keep the sprint pill clear of the stick on every screen size.
			var pill_w := 108.0
			var pill_h := 40.0
			sprint_button.offset_left = joystick.offset_right + 10.0
			sprint_button.offset_right = sprint_button.offset_left + pill_w
			sprint_button.offset_bottom = -(joy_bottom + 4.0)
			sprint_button.offset_top = sprint_button.offset_bottom - pill_h

# --- Contextual feedback -------------------------------------------------------

func _connect_context_feedback() -> void:
	EventBus.interact_prompt_changed.connect(_on_interact_prompt_changed)
	EventBus.target_locked_changed.connect(_on_target_locked_changed)
	EventBus.player_stamina_changed.connect(_on_stamina_changed)
	EventBus.player_mana_changed.connect(_on_mana_changed)
	EventBus.inventory_changed.connect(_refresh_potion_state)
	_refresh_potion_state()

## The button registered for `action`, or null (e.g. "attack", "block").
func action_button(action: String) -> TouchActionButton:
	return _action_buttons.get(action) as TouchActionButton

func _on_interact_prompt_changed(text: String) -> void:
	var b := action_button("interact")
	if b != null:
		b.set_highlighted(not text.is_empty())

func _on_target_locked_changed(target: Node) -> void:
	var b := action_button("lock_target")
	if b != null:
		b.set_highlighted(target != null)

func _on_stamina_changed(current: float, _maximum: float) -> void:
	_set_dimmed("attack", current < Player.ATTACK_COST)
	_set_dimmed("attack_heavy", current < Player.HEAVY_COST)
	var dodge_cost := Player.DODGE_COST
	if GameManager.skills != null:
		dodge_cost *= GameManager.skills.dodge_cost_multiplier()
	_set_dimmed("dodge", current < dodge_cost)

func _on_mana_changed(current: float, _maximum: float) -> void:
	var spell_cost := Player.BASE_SPELL_MANA
	if GameManager.skills != null:
		spell_cost *= GameManager.skills.mana_cost_multiplier()
	_set_dimmed("cast_spell", current < spell_cost)

func _refresh_potion_state() -> void:
	var has_any := false
	if GameManager.inventory != null:
		for item_id: String in POTION_IDS:
			if GameManager.inventory.count_item(item_id) > 0:
				has_any = true
				break
	_set_dimmed("quick_potion", not has_any)

func _set_dimmed(action: String, value: bool) -> void:
	var b := action_button(action)
	if b != null:
		b.set_dimmed(value)

# --- Input API consumed by PlayerInput ----------------------------------------

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

## Releases every finger-owned control without touching latched state such as
## the sprint toggle. Used when the controls are hidden or the app loses focus.
func release_all() -> void:
	if joystick != null:
		joystick.release()
	if drag_area != null:
		drag_area.release()
	for action: String in _action_buttons:
		(_action_buttons[action] as TouchActionButton).force_release()
	if sprint_button != null:
		sprint_button.force_release()
	_move = Vector2.ZERO
	_blocking = false
	_pressed.clear()

func reset_state() -> void:
	release_all()
	_sprint = false
	if sprint_button != null:
		sprint_button.set_toggled(false)
