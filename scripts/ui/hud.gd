class_name HUD
extends Control
## Arabic/EN fantasy RPG HUD, built for the Mobile renderer of Godot 4.3, which
## issues one draw call per glyph and per stylebox. Text is therefore kept to
## the minimum that carries information:
##   - Top-left: level + HP number in one header line, then HP / MP / SP / XP bars.
##   - Top-centre: seven icon-only menu buttons (bag, quests, skills, crafting,
##     map, guild, pause), each a 46 px touch target.
##   - Top-right: minimap, one-line clock + weather, one-line current district.

signal quick_menu_pressed(screen_name: String)

var health_bar: StatBar
var mana_bar: StatBar
var stamina_bar: StatBar
var xp_bar: StatBar
var level_label: Label
var guild_label: Label
var clock_label: Label
var gold_label: Label
var weather_label: Label
var district_label: Label
var hp_text_label: Label
var _district_timer: float = 0.0
var _district_key: String = ""
var _top_left_stack: VBoxContainer
var _top_right_stack: VBoxContainer
var minimap: MinimapControl
var quest_panel: PanelContainer
var quest_box: VBoxContainer
var boss_panel: PanelContainer
var boss_name_label: Label
var boss_hp_bar: ProgressBar
var target_panel: PanelContainer
var target_name_label: Label
var target_hp_bar: ProgressBar
var waypoint_label: Label
var _ribbon_buttons: Dictionary = {}
var interact_panel: PanelContainer
var interact_label: Label
var notifications: VBoxContainer
var damage_flash: ColorRect
var perf_label: Label

var _player: Player
var _perf_timer: float = 0.0
var _perf_log_timer: float = 0.0
var _target_refresh_timer: float = 0.0
var _waypoint_refresh_timer: float = 0.0
var _cached_waypoint: QuestWaypoint3D

func setup(player: Player) -> void:
	_player = player
	if minimap != null:
		minimap.player = player

func _ready() -> void:
	add_to_group("hud_root")
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIFactory.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_vitals()
	_build_top_bar_and_boss()
	_build_top_right()
	_build_quest_tracker()
	_build_prompt()
	_build_notifications()
	_build_damage_flash()
	_build_perf_overlay()
	_connect_signals()
	_cached_waypoint = get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
	refresh_all()

func _glass_box(bg: Color, rim: Color, radius: int = 10, pad: int = 9) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = rim
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad)
	sb.shadow_size = 0
	return sb

func _build_vitals() -> void:
	_top_left_stack = VBoxContainer.new()
	_top_left_stack.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_top_left_stack.position = Vector2(12, 10)
	_top_left_stack.add_theme_constant_override("separation", 6)
	_top_left_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top_left_stack)

	var panel := PanelContainer.new()
	panel.name = "StatsGlassPanel"
	panel.custom_minimum_size = Vector2(214, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _glass_box(
		Color(0.06, 0.09, 0.13, 0.70), Color(0.72, 0.74, 0.68, 0.30), 12, 9))
	_top_left_stack.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)

	# Header: [star] level ........ HP number
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 5)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header)

	header.add_child(RpgIcon.new().setup("star_gold", Vector2(20, 20)))
	level_label = UIFactory.label("2", 15, Color(1.0, 0.90, 0.56))
	header.add_child(level_label)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(gap)
	hp_text_label = UIFactory.label("0/0", 14, Color(1.0, 0.86, 0.84))
	header.add_child(hp_text_label)
	header.add_child(RpgIcon.new().setup("heart_red", Vector2(16, 16)))

	# Hidden backing labels for guild/gold API compatibility
	guild_label = UIFactory.label("", 11, Color(0.55, 0.82, 1.0))
	guild_label.visible = false
	gold_label = UIFactory.label("", 11, UIFactory.GOLD)
	gold_label.visible = false
	box.add_child(guild_label)
	box.add_child(gold_label)

	health_bar = StatBar.new()
	box.add_child(health_bar)
	health_bar.setup("HP", Color(0.90, 0.25, 0.27), "", 13)

	mana_bar = StatBar.new()
	box.add_child(mana_bar)
	mana_bar.setup("MP", Color(0.22, 0.62, 0.98), "", 8)

	stamina_bar = StatBar.new()
	box.add_child(stamina_bar)
	stamina_bar.setup("SP", Color(0.30, 0.82, 0.52), "", 8)

	xp_bar = StatBar.new()
	box.add_child(xp_bar)
	xp_bar.setup("XP", Color(0.96, 0.80, 0.30), "", 4)

func _build_top_bar_and_boss() -> void:
	# Top-centre menu dock: seven icon-only buttons, 46 px touch targets.
	var dock := PanelContainer.new()
	dock.name = "TopCenterActionDock"
	dock.set_anchors_preset(Control.PRESET_CENTER_TOP)
	dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock.position = Vector2(0, 8)
	dock.add_theme_stylebox_override("panel", _glass_box(
		Color(0.06, 0.09, 0.13, 0.62), Color(0.76, 0.72, 0.56, 0.34), 14, 4))
	add_child(dock)

	var ribbon := HBoxContainer.new()
	ribbon.add_theme_constant_override("separation", 3)
	dock.add_child(ribbon)

	var items := [
		["inventory", "bag", "Bag", "الحقيبة"],
		["journal", "quests", "Quests", "المهام"],
		["skills", "skills", "Skills", "المهارات"],
		["crafting", "life", "Crafting", "الحِرف"],
		["map", "map", "Map", "الخريطة"],
		["guild", "guide", "Guild", "النقابة"],
		["pause", "gear", "Menu", "القائمة"],
	]
	var slot_empty := StyleBoxEmpty.new()
	var slot_hover := RpgIcon.shared_stylebox("btn_dock", 0, Color(1.3, 1.3, 1.2, 0.8))

	for entry: Array in items:
		var scr := String(entry[0])
		# TouchActionButton owns the finger that pressed it, so the menus open
		# even while another finger is holding the movement stick (a stock
		# Button only hears the first finger).
		var btn := TouchActionButton.new()
		btn.name = "TopBtn_" + scr
		btn.text = ""
		btn.focus_mode = Control.FOCUS_NONE
		btn.circular_hit = false
		btn.hit_padding = 2.0
		btn.haptic_ms = 10
		btn.custom_minimum_size = Vector2(46, 46)
		for st: String in ["normal", "focus", "disabled", "pressed", "hover_pressed"]:
			btn.add_theme_stylebox_override(st, slot_empty)
		btn.add_theme_stylebox_override("hover", slot_hover)
		var icon := RpgIcon.new().setup(String(entry[1]), Vector2(32, 32))
		icon.position = Vector2(7, 7)
		btn.add_child(icon)
		btn.activated.connect(func() -> void: quick_menu_pressed.emit(scr))
		ribbon.add_child(btn)
		_ribbon_buttons[scr] = {"btn": btn, "lbl": null, "en": String(entry[2]), "ar": String(entry[3])}

	# Dynamic Boss Health Bar right beneath the dock
	boss_panel = UIFactory.card_panel(Color(0.88, 0.28, 0.34))
	boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_panel.position = Vector2(0, 70)
	boss_panel.custom_minimum_size = Vector2(420, 0)
	boss_panel.visible = false
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(boss_panel)
	var bbox := VBoxContainer.new()
	bbox.add_theme_constant_override("separation", 4)
	boss_panel.add_child(bbox)
	boss_name_label = UIFactory.label("☠ Boss", 17, Color(1.0, 0.62, 0.62))
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bbox.add_child(boss_name_label)
	boss_hp_bar = UIFactory.progress_bar(Color(0.88, 0.22, 0.28), 14)
	bbox.add_child(boss_hp_bar)

	# Target Lock-On Enemy Card
	target_panel = UIFactory.card_panel(UIFactory.GOLD)
	target_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	target_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	target_panel.position = Vector2(0, 70)
	target_panel.custom_minimum_size = Vector2(310, 0)
	target_panel.visible = false
	target_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(target_panel)
	var tbox := VBoxContainer.new()
	tbox.add_theme_constant_override("separation", 3)
	target_panel.add_child(tbox)
	target_name_label = UIFactory.label("◎ Target", 15, UIFactory.GOLD)
	target_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tbox.add_child(target_name_label)
	target_hp_bar = UIFactory.progress_bar(UIFactory.DANGER, 10)
	tbox.add_child(target_hp_bar)

func _build_top_right() -> void:
	var wrap := VBoxContainer.new()
	wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wrap.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	wrap.position = Vector2(-12, 10)
	wrap.add_theme_constant_override("separation", 6)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)
	_top_right_stack = wrap

	minimap = MinimapControl.new()
	minimap.player = _player
	minimap.size_flags_horizontal = Control.SIZE_SHRINK_END
	wrap.add_child(minimap)

	# One line: "10:13 · صحو". One draw call per glyph, so it stays short.
	var pill := PanelContainer.new()
	pill.name = "DayWeatherPanel"
	pill.size_flags_horizontal = Control.SIZE_SHRINK_END
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_theme_stylebox_override("panel", _glass_box(
		Color(0.06, 0.09, 0.13, 0.70), Color(0.66, 0.68, 0.52, 0.34), 10, 5))
	wrap.add_child(pill)

	var pbox := HBoxContainer.new()
	pbox.add_theme_constant_override("separation", 6)
	pbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(pbox)

	clock_label = UIFactory.label("17:01", 13, Color(0.96, 0.96, 0.92))
	pbox.add_child(clock_label)
	weather_label = UIFactory.label("صحو", 12, Color(0.80, 0.90, 1.0))
	pbox.add_child(weather_label)

	# Current quarter / area. Updated twice a second from CityPlan.
	var city_pill := PanelContainer.new()
	city_pill.name = "RoyalCityDistrictPanel"
	city_pill.size_flags_horizontal = Control.SIZE_SHRINK_END
	city_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	city_pill.add_theme_stylebox_override("panel", _glass_box(
		Color(0.13, 0.10, 0.20, 0.74), Color(0.82, 0.60, 0.94, 0.40), 10, 5))
	wrap.add_child(city_pill)
	district_label = UIFactory.label("", 12, Color(0.92, 0.86, 1.0))
	district_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	city_pill.add_child(district_label)

func _build_quest_tracker() -> void:
	quest_panel = UIFactory.panel(0.82)
	quest_panel.custom_minimum_size = Vector2(236, 0)
	quest_panel.visible = false
	quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_left_stack.add_child(quest_panel)
	quest_box = VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 2)
	quest_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_panel.add_child(quest_box)

func _build_prompt() -> void:
	interact_panel = UIFactory.card_panel(UIFactory.GOLD, Color(0.08, 0.11, 0.16, 0.90))
	interact_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interact_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	interact_panel.position = Vector2(0, -96)
	interact_panel.visible = false
	interact_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(interact_panel)
	interact_label = UIFactory.label("", 18, UIFactory.GOLD)
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_panel.add_child(interact_label)

func _build_notifications() -> void:
	# Notifications flow below the minimap / clock / district stack. A fixed
	# y offset used to draw them on top of the district panel.
	notifications = VBoxContainer.new()
	notifications.name = "Notifications"
	notifications.custom_minimum_size = Vector2(300, 0)
	notifications.size_flags_horizontal = Control.SIZE_SHRINK_END
	notifications.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_right_stack.add_child(notifications)

func _build_damage_flash() -> void:
	damage_flash = ColorRect.new()
	UIFactory.full_rect(damage_flash)
	damage_flash.color = Color(0.8, 0.1, 0.1, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)

func _build_perf_overlay() -> void:
	perf_label = UIFactory.label("", 13, Color(0.6, 1.0, 0.7))
	perf_label.position = Vector2(16, 250)
	perf_label.visible = SettingsManager.show_performance_overlay
	perf_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(perf_label)

func _connect_signals() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_mana_changed.connect(_on_mana_changed)
	EventBus.player_stamina_changed.connect(_on_stamina_changed)
	EventBus.player_xp_changed.connect(_on_xp_changed)
	EventBus.player_gold_changed.connect(_on_gold_changed)
	EventBus.guild_updated.connect(_refresh_guild_badge)
	EventBus.interact_prompt_changed.connect(_on_prompt_changed)
	EventBus.notify.connect(show_notification)
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.quest_updated.connect(_on_quest_updated)
	EventBus.quest_started.connect(_on_quest_updated)
	EventBus.quest_completed.connect(_on_quest_updated)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.boss_health_changed.connect(_on_boss_health)
	EventBus.target_locked_changed.connect(func(_t: Node) -> void: _refresh_target_card())
	EventBus.hero_class_changed.connect(func(_c: String) -> void: refresh_all())
	EventBus.graphics_settings_changed.connect(_on_settings_changed)
	EventBus.language_changed.connect(func(_l: String) -> void: refresh_all())

func refresh_all() -> void:
	var ar := Localization.is_arabic()
	for scr: String in _ribbon_buttons.keys():
		var info: Dictionary = _ribbon_buttons[scr]
		var lbl_node := info.get("lbl") as Label
		if lbl_node != null:
			lbl_node.text = String(info["ar"] if ar else info["en"])
	_district_key = ""
	_refresh_district()
	_on_xp_changed(GameManager.progression.level, GameManager.progression.xp,
		GameManager.progression.xp_to_next())
	_on_gold_changed(GameManager.gold)
	_refresh_guild_badge()
	_on_time_changed(GameManager.world.hour(), GameManager.world.minute(), GameManager.world.day)
	_on_weather_changed(GameManager.world.weather)
	if _player != null and _player.health != null:
		_on_health_changed(_player.health.current_health, _player.health.max_health)
		_on_mana_changed(_player.mana, GameManager.max_mana())
		_on_stamina_changed(_player.stamina, GameManager.max_stamina())
	_refresh_quest_tracker()
	_refresh_target_card()

func _refresh_guild_badge() -> void:
	if guild_label != null:
		var rk := GameManager.guild.current_rank()
		guild_label.text = ("رتبة " + rk) if Localization.is_arabic() else ("Rank " + rk)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.set_values(current, maximum)
	if hp_text_label != null:
		hp_text_label.text = health_bar.value_text()

const DISTRICT_NAMES := {
	"plaza": ["Royal Plaza", "الساحة الملكية"],
	"citadel": ["Citadel", "القلعة"],
	"residential": ["Old Quarter", "الحي القديم"],
	"chapel": ["Chapel Quarter", "حي المعبد"],
	"craft": ["Crafters' Row", "حي الحرفيين"],
	"market": ["Market Quarter", "حي السوق"],
	"south": ["South Ward", "الحي الجنوبي"],
	"west_woods": ["West Woods", "الغابة الغربية"],
	"south_meadow": ["South Meadow", "المرج الجنوبي"],
	"riverside": ["Riverside", "ضفة النهر"],
	"highlands": ["Highlands", "المرتفعات"],
	"house": ["Your Cottage", "منزلك"],
	"guild": ["Guild Hall", "قاعة النقابة"],
	"dungeon": ["Sunken Crypt", "السرداب"],
	"tower": ["The Tower", "البرج"],
}

## Names the quarter (or wilderness side) the player is standing in.
func _refresh_district() -> void:
	if district_label == null:
		return
	var key := "plaza"
	if _player != null:
		var zone := String(_player.zone)
		if zone == "village":
			var pos := _player.global_position
			key = CityPlan.district_at(pos.x, pos.z)
			if key == "outside":
				if absf(pos.x) >= absf(pos.z):
					key = "riverside" if pos.x > 0.0 else "west_woods"
				else:
					key = "south_meadow" if pos.z > 0.0 else "highlands"
		elif DISTRICT_NAMES.has(zone):
			key = zone
		else:
			key = "tower"
	if key == _district_key:
		return
	_district_key = key
	var names: Array = DISTRICT_NAMES[key]
	district_label.text = String(names[1] if Localization.is_arabic() else names[0])

func _on_mana_changed(current: float, maximum: float) -> void:
	mana_bar.set_values(current, maximum)

func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.set_values(current, maximum)

func _on_xp_changed(level: int, xp: int, xp_to_next: int) -> void:
	level_label.text = str(level)
	xp_bar.set_values(xp, xp_to_next)
	xp_bar.visible = level < Progression.MAX_LEVEL

func _on_gold_changed(gold: int) -> void:
	gold_label.text = ("%d ذهب" if Localization.is_arabic() else "%dg") % gold

func _on_prompt_changed(text: String) -> void:
	interact_label.text = ("✦  " + text) if not text.is_empty() else ""
	# With touch controls on, the tappable prompt in TouchControls shows it.
	interact_panel.visible = not text.is_empty() and not SettingsManager.show_touch_controls

func _on_time_changed(hour: int, minute: int, _day: int) -> void:
	clock_label.text = "%02d:%02d" % [hour, minute]

func _on_weather_changed(weather: String) -> void:
	if Localization.is_arabic():
		weather_label.text = "ممطر" if weather == "rain" else "صحو"
	else:
		weather_label.text = "Rain" if weather == "rain" else "Clear"

func _on_boss_health(boss_name: String, current: float, maximum: float, phase: int, vis: bool) -> void:
	if boss_panel == null:
		return
	boss_panel.visible = vis and current > 0.0
	if boss_panel.visible:
		var p_txt := ("  [المرحلة الثانية]" if Localization.is_arabic() else "  [PHASE II]") if phase >= 2 else ""
		boss_name_label.text = "☠ %s%s" % [boss_name, p_txt]
		boss_hp_bar.max_value = maxf(1.0, maximum)
		boss_hp_bar.value = clampf(current, 0.0, maximum)

func _on_damage_dealt(target: Node, amount: float, is_crit: bool) -> void:
	if target != null and target.is_in_group("player"):
		var tween := create_tween()
		damage_flash.color = Color(0.75, 0.08, 0.08, 0.30)
		tween.tween_property(damage_flash, "color:a", 0.0, 0.40)
	elif target is Node3D and get_viewport() != null:
		var cam := get_viewport().get_camera_3d()
		var wpos := (target as Node3D).global_position + Vector3(0.0, 1.6, 0.0)
		if cam != null and not cam.is_position_behind(wpos):
			var spos := cam.unproject_position(wpos)
			var fl := UIFactory.label(("%d!" if is_crit else "%d") % int(round(amount)),
				22 if is_crit else 17, UIFactory.GOLD if is_crit else Color(1.0, 0.88, 0.82))
			fl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			fl.add_theme_constant_override("outline_size", 5)
			fl.position = spos + Vector2(randf_range(-16.0, 16.0), -12.0)
			fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(fl)
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(fl, "position:y", fl.position.y - 38.0, 0.65)
			tw.tween_property(fl, "modulate:a", 0.0, 0.65)
			tw.chain().tween_callback(fl.queue_free)

func _on_quest_updated(_quest_id: String) -> void:
	_refresh_quest_tracker()

func _refresh_quest_tracker() -> void:
	for child: Node in quest_box.get_children():
		child.queue_free()
	waypoint_label = null
	var tracked := GameManager.quest_log.tracked_quests()
	if tracked.is_empty():
		quest_panel.visible = false
		return
	quest_panel.visible = true
	var ar := Localization.is_arabic()
	var shown := 0
	for quest_id: String in tracked:
		if shown >= 2:
			break
		var quest := QuestDB.get_quest(quest_id)
		if quest == null:
			continue
		shown += 1
		quest_box.add_child(UIFactory.label(Localization.quest_title(quest), 14, UIFactory.GOLD))
		for i: int in quest.objectives.size():
			var objective: Dictionary = quest.objectives[i]
			var progress := GameManager.quest_log.objective_progress(quest_id, i)
			var required := int(objective.get("required", 1))
			var done := progress >= required
			var olabel := Localization.quest_obj_label(quest, i, String(objective.get("label", "Objective")))
			var text := "%s  %d/%d" % [olabel, progress, required]
			if done:
				text = "✔ " + text
			quest_box.add_child(UIFactory.label("  " + text, 12,
				UIFactory.ACCENT if done else UIFactory.TEXT_DIM))
			var pbar := UIFactory.progress_bar(UIFactory.ACCENT if done else UIFactory.GOLD, 5)
			pbar.max_value = maxf(1.0, float(required))
			pbar.value = clampf(float(progress), 0.0, float(required))
			quest_box.add_child(pbar)
		if GameManager.quest_log.can_turn_in(quest_id):
			quest_box.add_child(UIFactory.label("  ★ جاهزة للتسليم!" if ar else "  ★ Ready to turn in!", 12, UIFactory.ACCENT))
	waypoint_label = UIFactory.label("", 12, Color(1.0, 0.88, 0.36))
	quest_box.add_child(waypoint_label)

func _refresh_target_card() -> void:
	if target_panel == null:
		return
	if _player == null or _player.locked_target == null or not is_instance_valid(_player.locked_target):
		target_panel.visible = false
		return
	var cr := _player.locked_target as Creature
	if cr == null or cr.health == null or cr.health.is_dead() or (cr.data != null and cr.data.is_boss and boss_panel != null and boss_panel.visible):
		target_panel.visible = false
		return
	target_panel.visible = true
	var cname := Localization.creature_name(cr.data) if cr.data != null else "Target"
	target_name_label.text = "◎ %s  (%d/%d)" % [cname, int(ceil(cr.health.current_health)), int(ceil(cr.health.max_health))]
	target_hp_bar.max_value = maxf(1.0, cr.health.max_health)
	target_hp_bar.value = clampf(cr.health.current_health, 0.0, cr.health.max_health)

func show_notification(text: String) -> void:
	var label := UIFactory.label(text, 15, UIFactory.TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.88))
	label.add_theme_constant_override("outline_size", 5)
	notifications.add_child(label)
	var tween := create_tween()
	tween.tween_interval(2.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)
	while notifications.get_child_count() > 4:
		notifications.get_child(0).queue_free()
		break

func _on_settings_changed() -> void:
	if perf_label != null:
		perf_label.visible = SettingsManager.show_performance_overlay

func _process(delta: float) -> void:
	_target_refresh_timer += delta
	_waypoint_refresh_timer += delta
	if _target_refresh_timer >= 0.12:
		_target_refresh_timer = 0.0
		if _player != null and _player.locked_target != null:
			_refresh_target_card()
		elif target_panel != null and target_panel.visible:
			target_panel.visible = false
	if _waypoint_refresh_timer >= 0.20 and waypoint_label != null and is_instance_valid(waypoint_label) and _player != null:
		_waypoint_refresh_timer = 0.0
		if not is_instance_valid(_cached_waypoint):
			_cached_waypoint = get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
		var wp := _cached_waypoint
		if wp != null and wp.has_waypoint:
			var dist := int(round(_player.global_position.distance_to(wp.target_position)))
			waypoint_label.visible = true
			waypoint_label.text = ("  ◆ المسافة للهدف: %d م" % dist) if Localization.is_arabic() else ("  ◆ Objective Distance: %dm" % dist)
		else:
			waypoint_label.visible = false
	_district_timer += delta
	if _district_timer >= 0.5:
		_district_timer = 0.0
		_refresh_district()
	if perf_label == null or not perf_label.visible:
		return
	_perf_timer += delta
	if _perf_timer < 0.25:
		return
	_perf_timer = 0.0
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var triangles := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var objects := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var fps := Engine.get_frames_per_second()
	perf_label.text = "DEV DIAGNOSTICS (F3)\nFPS %d | Draws %d | Tris %d | Nodes %d | RAM %.0f MB" % [
		fps, int(draw_calls), int(triangles / 3.0), int(objects),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
	]
	_perf_log_timer += delta
	if _perf_log_timer >= 5.0:
		_perf_log_timer = 0.0
		_write_perf_line(fps, int(draw_calls), int(triangles / 3.0))

func _write_perf_line(fps: float, draw_calls: int, triangles: int) -> void:
	var file := FileAccess.open("user://perf_log.txt", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("user://perf_log.txt", FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line("%s fps=%.1f draw_calls=%d triangles=%d zone=%s" % [
		Time.get_time_string_from_system(), fps, draw_calls, triangles,
		GameManager.pending_zone,
	])
	file.close()
