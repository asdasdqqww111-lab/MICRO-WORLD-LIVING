class_name HUD
extends Control
## Clean Fantasy RPG Gameplay HUD:
##   - Top-Left: Hero Level, Guild Rank Badge, Gold, HP / MP / SP / XP bars
##   - Top-Center: Quick Menu Ribbon + Dynamic Boss Health & Phase Bar
##   - Top-Right: Live Minimap + Day/Time/Weather Pill
##   - Active Quest Tracker (compact, collapsible) + Floating Combat Numbers
##   - Zero debug overlay in normal gameplay (developer-only toggle via F3)

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
var _top_left_stack: VBoxContainer
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
	refresh_all()

func _build_vitals() -> void:
	_top_left_stack = VBoxContainer.new()
	_top_left_stack.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_top_left_stack.position = Vector2(14, 12)
	_top_left_stack.add_theme_constant_override("separation", 8)
	_top_left_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top_left_stack)

	var panel := UIFactory.card_panel(Color(0.86, 0.78, 0.52, 0.38), UIFactory.BG_GLASS_HUD)
	panel.custom_minimum_size = Vector2(248, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_left_stack.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)
	level_label = UIFactory.label("Lv 1", 18, UIFactory.GOLD)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(level_label)
	guild_label = UIFactory.label("Guild —", 14, Color(0.55, 0.82, 1.0))
	header.add_child(guild_label)
	gold_label = UIFactory.label("35g", 16, UIFactory.GOLD)
	header.add_child(gold_label)

	health_bar = StatBar.new()
	box.add_child(health_bar)
	health_bar.setup("HP", UIFactory.DANGER)

	mana_bar = StatBar.new()
	box.add_child(mana_bar)
	mana_bar.setup("MP", UIFactory.MANA_BLUE)

	stamina_bar = StatBar.new()
	box.add_child(stamina_bar)
	stamina_bar.setup("SP", UIFactory.STAMINA_TEAL)

	xp_bar = StatBar.new()
	box.add_child(xp_bar)
	xp_bar.setup("XP", UIFactory.GOLD)

func _build_top_bar_and_boss() -> void:
	# Compact Top-Center Quick Menu Ribbon (Bag, Skills, Guild, Quests, Map, Pause)
	var ribbon := HBoxContainer.new()
	ribbon.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ribbon.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ribbon.position = Vector2(0, 12)
	ribbon.add_theme_constant_override("separation", 6)
	add_child(ribbon)

	var items := [
		["inventory", "BAG", "حقيبة"],
		["skills", "SKILLS", "مهارات"],
		["guild", "GUILD", "نقابة"],
		["journal", "QUESTS", "مهام"],
		["map", "MAP", "خريطة"],
		["character", "HERO", "البطل"],
		["pause", "II", "II"],
	]
	for pair: Array in items:
		var scr := String(pair[0])
		var lbl_en := String(pair[1])
		var lbl_ar := String(pair[2])
		var lbl := lbl_ar if Localization.is_arabic() else lbl_en
		var btn := UIFactory.glass_pill_button(lbl, 56 if lbl_en != "II" else 34, 28)
		btn.pressed.connect(func() -> void: quick_menu_pressed.emit(scr))
		ribbon.add_child(btn)
		_ribbon_buttons[scr] = {"btn": btn, "en": lbl_en, "ar": lbl_ar}

	var lang_pill := UIFactory.glass_pill_button("EN/ع", 44, 28)
	lang_pill.pressed.connect(func() -> void:
		SettingsManager.language = "en" if Localization.is_arabic() else "ar"
		SettingsManager.save_settings()
		SettingsManager.apply_all()
		refresh_all())
	ribbon.add_child(lang_pill)

	# Dynamic Boss Health Bar right beneath the ribbon
	boss_panel = UIFactory.card_panel(Color(0.88, 0.28, 0.34))
	boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_panel.position = Vector2(0, 58)
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

	# Target Lock-On Enemy Card (shown when locked onto a non-boss hostile)
	target_panel = UIFactory.card_panel(UIFactory.GOLD)
	target_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	target_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	target_panel.position = Vector2(0, 58)
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
	wrap.position = Vector2(-14, 12)
	wrap.add_theme_constant_override("separation", 6)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)

	minimap = MinimapControl.new()
	minimap.player = _player
	minimap.size_flags_horizontal = Control.SIZE_SHRINK_END
	wrap.add_child(minimap)

	var pill := UIFactory.panel(0.92)
	pill.custom_minimum_size = Vector2(158, 0)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(pill)
	var pbox := VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 2)
	pill.add_child(pbox)
	clock_label = UIFactory.label("Day 1 · 08:30", 15, UIFactory.TEXT)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pbox.add_child(clock_label)
	weather_label = UIFactory.label("Clear", 13, UIFactory.TEXT_DIM)
	weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pbox.add_child(weather_label)

func _build_quest_tracker() -> void:
	quest_panel = UIFactory.panel(0.86)
	quest_panel.custom_minimum_size = Vector2(276, 0)
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
	notifications = VBoxContainer.new()
	notifications.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	notifications.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	notifications.position = Vector2(-18, 212)
	notifications.custom_minimum_size = Vector2(300, 0)
	notifications.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notifications)

func _build_damage_flash() -> void:
	damage_flash = ColorRect.new()
	UIFactory.full_rect(damage_flash)
	damage_flash.color = Color(0.8, 0.1, 0.1, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)

func _build_perf_overlay() -> void:
	perf_label = UIFactory.label("", 13, Color(0.6, 1.0, 0.7))
	perf_label.position = Vector2(16, 320)
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
		var btn := info["btn"] as Button
		if btn != null:
			btn.text = String(info["ar"] if ar else info["en"])
	if health_bar != null:
		health_bar.set_title("صحة" if ar else "HP")
	if mana_bar != null:
		mana_bar.set_title("مانا" if ar else "MP")
	if stamina_bar != null:
		stamina_bar.set_title("نشاط" if ar else "SP")
	if xp_bar != null:
		xp_bar.set_title("خبرة" if ar else "XP")
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
		if Localization.is_arabic():
			guild_label.text = ("رتبة " + rk) if GameManager.guild.registered else "غير مسجّل"
		else:
			guild_label.text = ("Rank " + rk) if GameManager.guild.registered else "Unreg."

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.set_values(current, maximum)

func _on_mana_changed(current: float, maximum: float) -> void:
	mana_bar.set_values(current, maximum)

func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.set_values(current, maximum)

func _on_xp_changed(level: int, xp: int, xp_to_next: int) -> void:
	var cdef := HeroClassDB.get_class_def(GameManager.hero_class)
	var glyph := String(cdef.get("glyph", "⚔"))
	level_label.text = "%s %s %d" % [glyph, Localization.tr_key("level"), level]
	xp_bar.set_values(xp, xp_to_next)
	xp_bar.visible = level < Progression.MAX_LEVEL

func _on_gold_changed(gold: int) -> void:
	gold_label.text = ("%d ذهب" if Localization.is_arabic() else "%dg") % gold

func _on_prompt_changed(text: String) -> void:
	interact_label.text = ("✦  " + text) if not text.is_empty() else ""
	interact_panel.visible = not text.is_empty()

func _on_time_changed(hour: int, minute: int, day: int) -> void:
	clock_label.text = "%s %d · %02d:%02d" % [Localization.tr_key("day"), day, hour, minute]

func _on_weather_changed(weather: String) -> void:
	weather_label.text = Localization.tr_key("weather_rain" if weather == "rain" else "weather_clear")

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
		quest_box.add_child(UIFactory.label(Localization.quest_title(quest), 15, UIFactory.GOLD))
		for i: int in quest.objectives.size():
			var objective: Dictionary = quest.objectives[i]
			var progress := GameManager.quest_log.objective_progress(quest_id, i)
			var required := int(objective.get("required", 1))
			var done := progress >= required
			var olabel := Localization.quest_obj_label(quest, i, String(objective.get("label", "Objective")))
			var text := "%s  %d/%d" % [olabel, progress, required]
			if done:
				text = "✔ " + text
			quest_box.add_child(UIFactory.label("  " + text, 13,
				UIFactory.ACCENT if done else UIFactory.TEXT_DIM))
			var pbar := UIFactory.progress_bar(UIFactory.ACCENT if done else UIFactory.GOLD, 5)
			pbar.max_value = maxf(1.0, float(required))
			pbar.value = clampf(float(progress), 0.0, float(required))
			quest_box.add_child(pbar)
		if GameManager.quest_log.can_turn_in(quest_id):
			quest_box.add_child(UIFactory.label("  ★ جاهزة للتسليم!" if ar else "  ★ Ready to turn in!", 13, UIFactory.ACCENT))
	waypoint_label = UIFactory.label("", 13, Color(1.0, 0.88, 0.36))
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
	if _player != null and _player.locked_target != null:
		_refresh_target_card()
	elif target_panel != null and target_panel.visible:
		target_panel.visible = false
	if waypoint_label != null and is_instance_valid(waypoint_label) and _player != null and get_tree() != null:
		var wp := get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
		if wp != null and wp.has_waypoint:
			var dist := int(round(_player.global_position.distance_to(wp.target_position)))
			waypoint_label.visible = true
			waypoint_label.text = ("  ◆ المسافة للهدف: %d م" % dist) if Localization.is_arabic() else ("  ◆ Objective Distance: %dm" % dist)
		else:
			waypoint_label.visible = false
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
