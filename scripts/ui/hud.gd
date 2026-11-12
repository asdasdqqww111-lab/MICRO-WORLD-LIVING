class_name HUD
extends Control
## Always-on HUD: vitals, clock, gold, quest tracker, prompts, notifications,
## damage flash and the optional performance overlay.

var health_bar: StatBar
var stamina_bar: StatBar
var xp_bar: StatBar
var level_label: Label
var clock_label: Label
var gold_label: Label
var weather_label: Label
var quest_panel: PanelContainer
var quest_box: VBoxContainer
var interact_label: Label
var notifications: VBoxContainer
var damage_flash: ColorRect
var perf_label: Label

var _player: Player
var _perf_timer: float = 0.0
var _perf_log_timer: float = 0.0

func setup(player: Player) -> void:
	_player = player

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIFactory.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_vitals()
	_build_top_right()
	_build_quest_tracker()
	_build_prompt()
	_build_notifications()
	_build_damage_flash()
	_build_perf_overlay()
	_connect_signals()
	refresh_all()

func _build_vitals() -> void:
	var panel := UIFactory.panel()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(320, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	level_label = UIFactory.label("Level 1", 19)
	box.add_child(level_label)
	xp_bar = StatBar.new()
	box.add_child(xp_bar)
	xp_bar.setup("XP", UIFactory.GOLD)
	health_bar = StatBar.new()
	box.add_child(health_bar)
	health_bar.setup("HP", UIFactory.DANGER)
	stamina_bar = StatBar.new()
	box.add_child(stamina_bar)
	stamina_bar.setup("SP", Color(0.35, 0.7, 0.95))

func _build_top_right() -> void:
	var panel := UIFactory.panel()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-236, 16)
	panel.custom_minimum_size = Vector2(220, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	clock_label = UIFactory.label("Day 1  ·  08:00", 19)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(clock_label)
	weather_label = UIFactory.label("Clear", 15, UIFactory.TEXT_DIM)
	weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(weather_label)
	gold_label = UIFactory.label("Gold: 0", 17, UIFactory.GOLD)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(gold_label)

func _build_quest_tracker() -> void:
	quest_panel = UIFactory.panel()
	quest_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	quest_panel.position = Vector2(-190, 16)
	quest_panel.custom_minimum_size = Vector2(380, 0)
	add_child(quest_panel)
	quest_box = VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 2)
	quest_panel.add_child(quest_box)

func _build_prompt() -> void:
	interact_label = UIFactory.label("", 20, UIFactory.TEXT)
	interact_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interact_label.position = Vector2(-160, -150)
	interact_label.custom_minimum_size = Vector2(320, 0)
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	interact_label.add_theme_constant_override("outline_size", 6)
	add_child(interact_label)

func _build_notifications() -> void:
	notifications = VBoxContainer.new()
	notifications.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	notifications.position = Vector2(-330, -120)
	notifications.custom_minimum_size = Vector2(300, 0)
	notifications.alignment = BoxContainer.ALIGNMENT_END
	add_child(notifications)

func _build_damage_flash() -> void:
	damage_flash = ColorRect.new()
	damage_flash.color = Color(0.8, 0.1, 0.1, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIFactory.full_rect(damage_flash)
	add_child(damage_flash)

func _build_perf_overlay() -> void:
	perf_label = UIFactory.label("", 14, Color(0.6, 1.0, 0.7))
	perf_label.position = Vector2(16, 180)
	perf_label.visible = SettingsManager.show_performance_overlay
	add_child(perf_label)

func _connect_signals() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_stamina_changed.connect(_on_stamina_changed)
	EventBus.player_xp_changed.connect(_on_xp_changed)
	EventBus.player_gold_changed.connect(_on_gold_changed)
	EventBus.interact_prompt_changed.connect(_on_prompt_changed)
	EventBus.notify.connect(show_notification)
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.quest_updated.connect(_on_quest_updated)
	EventBus.quest_started.connect(_on_quest_updated)
	EventBus.quest_completed.connect(_on_quest_updated)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.graphics_settings_changed.connect(_on_settings_changed)

func refresh_all() -> void:
	_on_xp_changed(GameManager.progression.level, GameManager.progression.xp,
		GameManager.progression.xp_to_next())
	_on_gold_changed(GameManager.gold)
	_on_time_changed(GameManager.world.hour(), GameManager.world.minute(), GameManager.world.day)
	_on_weather_changed(GameManager.world.weather)
	if _player != null and _player.health != null:
		_on_health_changed(_player.health.current_health, _player.health.max_health)
		_on_stamina_changed(_player.stamina, GameManager.max_stamina())
	_refresh_quest_tracker()

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.set_values(current, maximum)

func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.set_values(current, maximum)

func _on_xp_changed(level: int, xp: int, xp_to_next: int) -> void:
	level_label.text = "Level %d" % level
	xp_bar.set_values(xp, xp_to_next)
	xp_bar.visible = level < Progression.MAX_LEVEL

func _on_gold_changed(gold: int) -> void:
	gold_label.text = "Gold: %d" % gold

func _on_prompt_changed(text: String) -> void:
	interact_label.text = text

func _on_time_changed(hour: int, minute: int, day: int) -> void:
	clock_label.text = "Day %d  ·  %02d:%02d" % [day, hour, minute]

func _on_weather_changed(weather: String) -> void:
	weather_label.text = "Raining" if weather == "rain" else "Clear skies"

func _on_damage_dealt(target: Node, _amount: float, _is_crit: bool) -> void:
	if target != null and target.is_in_group("player"):
		var tween := create_tween()
		damage_flash.color = Color(0.75, 0.08, 0.08, 0.35)
		tween.tween_property(damage_flash, "color:a", 0.0, 0.45)

func _on_quest_updated(_quest_id: String) -> void:
	_refresh_quest_tracker()

func _refresh_quest_tracker() -> void:
	for child: Node in quest_box.get_children():
		child.queue_free()
	var tracked := GameManager.quest_log.tracked_quests()
	if tracked.is_empty():
		quest_panel.visible = false
		return
	quest_panel.visible = true
	for quest_id: String in tracked:
		var quest := QuestDB.get_quest(quest_id)
		if quest == null:
			continue
		quest_box.add_child(UIFactory.label(quest.title, 18, UIFactory.GOLD))
		for i: int in quest.objectives.size():
			var objective: Dictionary = quest.objectives[i]
			var progress := GameManager.quest_log.objective_progress(quest_id, i)
			var required := int(objective.get("required", 1))
			var done := progress >= required
			var text := "%s  %d/%d" % [String(objective.get("label", "Objective")), progress, required]
			if done:
				text = "✔ " + text
			quest_box.add_child(UIFactory.label("   " + text, 15,
				UIFactory.ACCENT if done else UIFactory.TEXT_DIM))
		if GameManager.quest_log.can_turn_in(quest_id):
			quest_box.add_child(UIFactory.label("   Return to %s"
				% _npc_display_name(quest.turn_in_npc), 15, UIFactory.ACCENT))

func _npc_display_name(npc_id: String) -> String:
	match npc_id:
		"farmer":
			return "Mira the Farmer"
		"guard":
			return "Osk the Guard"
		"blacksmith":
			return "Grim the Smith"
		_:
			return npc_id.capitalize()

func show_notification(text: String) -> void:
	var label := UIFactory.label(text, 17, UIFactory.TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	notifications.add_child(label)
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)
	while notifications.get_child_count() > 5:
		notifications.get_child(0).queue_free()
		break

func _on_settings_changed() -> void:
	if perf_label != null:
		perf_label.visible = SettingsManager.show_performance_overlay

func _process(delta: float) -> void:
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
	perf_label.text = "FPS %d\nDraw calls %d\nTriangles %d\nNodes %d\nMemory %.0f MB" % [
		fps, int(draw_calls), int(triangles / 3.0), int(objects),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
	]
	_perf_log_timer += delta
	if _perf_log_timer >= 5.0:
		_perf_log_timer = 0.0
		_write_perf_line(fps, int(draw_calls), int(triangles / 3.0))

## Device-side measurement artefact: one line per 5s while the overlay is on.
## Pull it from the phone with: adb pull /data/data/<package>/files/perf_log.txt
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
