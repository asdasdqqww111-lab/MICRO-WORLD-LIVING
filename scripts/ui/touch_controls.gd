class_name TouchControls
extends Control
## Mobile RPG touch controls.
##   - Bottom-left: movement stick with a round sprint toggle beside it.
##   - Bottom-right: the attack button with two thumb arcs centred on it.
##     Inner arc (most used): heavy strike, dodge, jump.
##     Outer arc: potion, spell, block (hold), target lock, interact.
##     Every pair of buttons keeps a >= 44 px clear gap.
##   - Bottom-centre: three working quick slots (health potion, mana elixir,
##     food) and, above them, a tappable prompt that appears whenever something
##     can be used, opened or talked to.
##   Icons only - no text on the buttons - so the whole layer costs ~30 draws.
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
var interact_prompt: TouchActionButton
var _prompt_label: Label
var _quick_slots: Array[TouchActionButton] = []
var _quick_slot_labels: Array[Label] = []
var _quick_slot_items: Array[String] = ["", "", ""]
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
	# The buttons carry icons only; the one text element is the interact
	# prompt, which already arrives localized through the EventBus.
	pass

## Centre of the attack button measured from the bottom-right corner, and the
## two arc radii. Arc angles are measured from "straight left", going up.
const ATTACK_CENTER := Vector2(82.0, 78.0)
const ATTACK_SIZE := 96.0
const INNER_RADIUS := 127.0
const INNER_SIZE := 62.0
const OUTER_RADIUS := 235.0
const OUTER_SIZE := 58.0
## Quick slots: [icon, candidate item ids in priority order].
const QUICK_SLOTS: Array = [
	["potion", ["health_potion"]],
	["potion_blue", ["mana_elixir"]],
	["food", ["venison", "bread"]],
]

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

	# Round sprint toggle beside the stick (lit while sprint is latched on).
	sprint_button = _make_round_button("Btn_sprint", "sprint", "btn_circle", 58.0)
	sprint_button.press_mode = TouchActionButton.PressMode.TOGGLE
	sprint_button.anchor_left = 0.0
	sprint_button.anchor_top = 1.0
	sprint_button.anchor_right = 0.0
	sprint_button.anchor_bottom = 1.0
	sprint_button.activated.connect(func() -> void: _sprint = sprint_button.toggled_on)
	add_child(sprint_button)

	_build_quick_slots()
	_build_interact_prompt()

	# Bottom-right combat cluster: attack plus two arcs centred on it.
	attack_button = _place_arc_button("attack", "swords", "btn_attack", 0.0, 0.0, ATTACK_SIZE)
	attack_button.haptic_ms = 18
	_place_arc_button("attack_heavy", "heavy", "btn_circle", INNER_RADIUS, -6.0, INNER_SIZE)
	_place_arc_button("dodge", "dodge", "btn_circle", INNER_RADIUS, 46.0, INNER_SIZE)
	_place_arc_button("jump", "jump", "btn_circle", INNER_RADIUS, 98.0, INNER_SIZE)
	_place_arc_button("quick_potion", "potion", "btn_circle", OUTER_RADIUS, -6.0, OUTER_SIZE)
	_place_arc_button("cast_spell", "spell", "btn_blue", OUTER_RADIUS, 20.0, OUTER_SIZE)
	block_button = _place_arc_button("block", "shield", "btn_circle", OUTER_RADIUS, 46.0, OUTER_SIZE)
	block_button.press_mode = TouchActionButton.PressMode.HOLD
	block_button.held_changed.connect(func(held: bool) -> void: _blocking = held)
	_place_arc_button("lock_target", "target", "btn_circle", OUTER_RADIUS, 72.0, OUTER_SIZE)
	_place_arc_button("interact", "talk", "btn_green", OUTER_RADIUS, 98.0, OUTER_SIZE)
	action_button("interact").set_dimmed(true)
	_built = true
	_layout_responsive()

## A round, icon-only button: one atlas quad for the plate, one for the icon.
func _make_round_button(node_name: String, icon_kind: String, plate_kind: String, btn_size: float) -> TouchActionButton:
	var b := TouchActionButton.new()
	b.name = node_name
	b.text = ""
	b.focus_mode = Control.FOCUS_NONE
	var plate := RpgIcon.shared_stylebox(plate_kind)
	for st: String in ["normal", "hover", "focus", "disabled", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, plate)
	var icon := RpgIcon.new().setup(icon_kind, Vector2(btn_size, btn_size) * 0.56)
	icon.name = "Icon"
	icon.anchor_left = 0.22
	icon.anchor_top = 0.22
	icon.anchor_right = 0.78
	icon.anchor_bottom = 0.78
	icon.offset_left = 0
	icon.offset_top = 0
	icon.offset_right = 0
	icon.offset_bottom = 0
	b.add_child(icon)
	return b

func _place_arc_button(action: String, icon_kind: String, plate_kind: String, arc_radius: float,
		angle_deg: float, btn_size: float) -> TouchActionButton:
	var b := _make_round_button("Btn_" + action, icon_kind, plate_kind, btn_size)
	b.anchor_left = 1.0
	b.anchor_top = 1.0
	b.anchor_right = 1.0
	b.anchor_bottom = 1.0
	var ang := deg_to_rad(angle_deg)
	var center := ATTACK_CENTER + Vector2(cos(ang), sin(ang)) * arc_radius
	var right_margin := roundf(center.x - btn_size * 0.5)
	var bottom_margin := roundf(center.y - btn_size * 0.5)
	b.offset_left = -(right_margin + btn_size)
	b.offset_top = -(bottom_margin + btn_size)
	b.offset_right = -right_margin
	b.offset_bottom = -bottom_margin
	# TAP buttons queue one action per touch-down; Player consumes the queue on
	# its next physics tick. Block is switched to HOLD by the caller, and HOLD
	# buttons never emit `activated`, so they do not enter the queue.
	b.activated.connect(func() -> void: _pressed[action] = true)
	add_child(b)
	_action_buttons[action] = b
	_combat_specs.append({"button": b, "right": right_margin, "bottom": bottom_margin, "size": btn_size})
	return b

## Three working quick slots, bottom-centre: tap to use the item.
func _build_quick_slots() -> void:
	var qs_bar := HBoxContainer.new()
	qs_bar.name = "QuickSlotsBar"
	qs_bar.anchor_left = 0.5
	qs_bar.anchor_top = 1.0
	qs_bar.anchor_right = 0.5
	qs_bar.anchor_bottom = 1.0
	qs_bar.offset_left = -81
	qs_bar.offset_top = -58
	qs_bar.offset_right = 81
	qs_bar.offset_bottom = -10
	qs_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	qs_bar.add_theme_constant_override("separation", 9)
	qs_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(qs_bar)
	var plate := RpgIcon.shared_stylebox("slot_box")
	for qi: int in QUICK_SLOTS.size():
		var slot := TouchActionButton.new()
		slot.name = "QuickSlot_%d" % qi
		slot.text = ""
		slot.focus_mode = Control.FOCUS_NONE
		slot.circular_hit = false
		slot.hit_padding = 4.0
		slot.custom_minimum_size = Vector2(48, 48)
		for st: String in ["normal", "hover", "focus", "disabled", "pressed", "hover_pressed"]:
			slot.add_theme_stylebox_override(st, plate)
		var icon := RpgIcon.new().setup(String(QUICK_SLOTS[qi][0]), Vector2(30, 30))
		icon.position = Vector2(9, 5)
		slot.add_child(icon)
		var count := UIFactory.label("", 12, Color(1.0, 0.98, 0.90))
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count.set_anchors_preset(Control.PRESET_FULL_RECT)
		count.offset_right = -5
		count.offset_bottom = -1
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		slot.add_child(count)
		slot.activated.connect(_use_quick_slot.bind(qi))
		qs_bar.add_child(slot)
		_quick_slots.append(slot)
		_quick_slot_labels.append(count)

func _use_quick_slot(index: int) -> void:
	var item_id := _quick_slot_items[index]
	if item_id.is_empty():
		EventBus.notify.emit(Localization.tr_key("no_potions"))
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("use_consumable"):
		player.call("use_consumable", item_id)

## The tappable prompt ("Talk to ...", "Enter ..."): tapping it interacts.
func _build_interact_prompt() -> void:
	interact_prompt = TouchActionButton.new()
	interact_prompt.name = "InteractPrompt"
	interact_prompt.text = ""
	interact_prompt.focus_mode = Control.FOCUS_NONE
	interact_prompt.circular_hit = false
	interact_prompt.hit_padding = 8.0
	interact_prompt.haptic_ms = 14
	interact_prompt.anchor_left = 0.5
	interact_prompt.anchor_top = 1.0
	interact_prompt.anchor_right = 0.5
	interact_prompt.anchor_bottom = 1.0
	interact_prompt.offset_left = -170
	interact_prompt.offset_right = 170
	interact_prompt.offset_top = -124
	interact_prompt.offset_bottom = -72
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.20, 0.13, 0.90)
	sb.border_color = Color(0.66, 1.0, 0.72, 0.92)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(26)
	sb.shadow_size = 0
	for st: String in ["normal", "hover", "focus", "disabled", "pressed", "hover_pressed"]:
		interact_prompt.add_theme_stylebox_override(st, sb)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -16
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interact_prompt.add_child(row)
	var icon_wrap := CenterContainer.new()
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_wrap.add_child(RpgIcon.new().setup("talk", Vector2(30, 30)))
	row.add_child(icon_wrap)
	_prompt_label = UIFactory.label("", 16, Color(0.94, 1.0, 0.92))
	_prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.clip_text = true
	_prompt_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_prompt_label)
	interact_prompt.activated.connect(func() -> void: _pressed["interact"] = true)
	interact_prompt.visible = false
	add_child(interact_prompt)

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
	# Bottom-centre strip rides above the gesture bar / rounded corners.
	var qs_bar := get_node_or_null("QuickSlotsBar") as Control
	if qs_bar != null:
		qs_bar.offset_bottom = -(10.0 + insets.w)
		qs_bar.offset_top = qs_bar.offset_bottom - 48.0
	if interact_prompt != null:
		interact_prompt.offset_bottom = -(72.0 + insets.w)
		interact_prompt.offset_top = interact_prompt.offset_bottom - 52.0
	if joystick != null:
		var joy_size := clampf(minf(size.x * 0.24, size.y * 0.30), 172.0, 218.0)
		var joy_bottom := maxf(16.0, size.y * 0.035) + insets.w
		joystick.offset_left = maxf(12.0, size.x * 0.025) + insets.x
		joystick.offset_top = -(joy_size + joy_bottom)
		joystick.offset_right = joystick.offset_left + joy_size
		joystick.offset_bottom = -joy_bottom
		if sprint_button != null:
			# Keep the sprint toggle clear of the stick on every screen size.
			var sprint_size := 58.0 * fit
			sprint_button.offset_left = joystick.offset_right + 14.0
			sprint_button.offset_right = sprint_button.offset_left + sprint_size
			sprint_button.offset_bottom = -(joy_bottom + 6.0)
			sprint_button.offset_top = sprint_button.offset_bottom - sprint_size

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
	var has_prompt := not text.is_empty()
	var b := action_button("interact")
	if b != null:
		b.set_highlighted(has_prompt)
		b.set_dimmed(not has_prompt)
	if interact_prompt != null:
		if has_prompt:
			_prompt_label.text = text
		interact_prompt.visible = has_prompt

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
	# Quick slots show the first owned item of their group and its count.
	for qi: int in _quick_slots.size():
		var found := ""
		var owned := 0
		if GameManager.inventory != null:
			for item_id: String in QUICK_SLOTS[qi][1]:
				var n := int(GameManager.inventory.count_item(item_id))
				if n > 0:
					found = item_id
					owned = n
					break
		_quick_slot_items[qi] = found
		_quick_slot_labels[qi].text = str(owned) if owned > 0 else ""
		_quick_slots[qi].set_dimmed(owned <= 0)

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
	if interact_prompt != null:
		interact_prompt.force_release()
	for slot: TouchActionButton in _quick_slots:
		slot.force_release()
	_move = Vector2.ZERO
	_blocking = false
	_pressed.clear()

func reset_state() -> void:
	release_all()
	_sprint = false
	if sprint_button != null:
		sprint_button.set_toggled(false)
