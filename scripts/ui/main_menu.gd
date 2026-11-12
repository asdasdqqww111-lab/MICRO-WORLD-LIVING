class_name MainMenu
extends Control
## Fantasy RPG Title Screen: MICRO WORLD: LIVING — Chronicles of Eldoria
## Supports New Game, Continue, Settings (Graphics, Audio, English/Arabic RTL),
## Save Management, and Credits.

class HorizonBackdrop extends Control:
	func _draw() -> void:
		# Painted twilight-gold & royal-indigo fantasy mountain backdrop
		var h := size.y
		var w := size.x
		for i: int in 24:
			var t0 := float(i) / 24.0
			var t1 := float(i + 1) / 24.0
			var sky_c := Color(0.05, 0.09, 0.18).lerp(Color(0.18, 0.28, 0.44), t0).lerp(Color(0.56, 0.42, 0.28), maxf(0.0, t0 - 0.55) * 1.4)
			draw_rect(Rect2(0.0, t0 * h, w, (t1 - t0) * h + 2.0), sky_c, true)
		# Sun/moon halo
		draw_circle(Vector2(w * 0.72, h * 0.34), h * 0.13, Color(1.0, 0.82, 0.48, 0.18))
		draw_circle(Vector2(w * 0.72, h * 0.34), h * 0.07, Color(1.0, 0.90, 0.65, 0.32))
		# Distant mountain ridge silhouettes
		var ridge1 := PackedVector2Array([
			Vector2(0, h), Vector2(0, h * 0.58), Vector2(w * 0.18, h * 0.42),
			Vector2(w * 0.36, h * 0.55), Vector2(w * 0.56, h * 0.36),
			Vector2(w * 0.78, h * 0.50), Vector2(w, h * 0.40), Vector2(w, h)])
		draw_colored_polygon(ridge1, Color(0.09, 0.13, 0.20, 0.92))
		var ridge2 := PackedVector2Array([
			Vector2(0, h), Vector2(0, h * 0.72), Vector2(w * 0.25, h * 0.62),
			Vector2(w * 0.48, h * 0.70), Vector2(w * 0.70, h * 0.58),
			Vector2(w, h * 0.68), Vector2(w, h)])
		draw_colored_polygon(ridge2, Color(0.05, 0.08, 0.12, 0.98))

var _continue_button: Button
var _new_button: Button
var _settings_button: Button
var _quit_button: Button
var _title_label: Label
var _subtitle_label: Label
var _settings_panel: PanelContainer
var _info_label: Label
var _save_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.is_playing = false
	get_tree().paused = false
	UIFactory.full_rect(self)
	_build()
	EventBus.language_changed.connect(func(_l: String) -> void: _refresh_save_state())
	if AudioManager != null:
		AudioManager.play_music_for_zone("menu")

func _build() -> void:
	var bg := HorizonBackdrop.new()
	UIFactory.full_rect(bg)
	add_child(bg)

	var card := UIFactory.panel(0.92)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.custom_minimum_size = Vector2(490, 0)
	add_child(card)

	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 10)
	card.add_child(center)

	_title_label = UIFactory.label(Localization.tr_key("game_title"), 42, UIFactory.GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_title_label)

	_subtitle_label = UIFactory.label(Localization.tr_key("game_subtitle"), 18, Color(0.72, 0.84, 0.96))
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_subtitle_label)
	center.add_child(UIFactory.hsep())

	_continue_button = UIFactory.button(Localization.tr_key("continue_game"), 52)
	_continue_button.pressed.connect(_on_continue)
	center.add_child(_continue_button)

	_new_button = UIFactory.button(Localization.tr_key("new_game"), 52)
	_new_button.pressed.connect(_on_new_game)
	center.add_child(_new_button)

	_settings_button = UIFactory.button(Localization.tr_key("settings"), 48)
	_settings_button.pressed.connect(_toggle_settings)
	center.add_child(_settings_button)

	_save_button = UIFactory.button("Delete Save Slot", 42)
	_save_button.pressed.connect(_on_delete_save)
	center.add_child(_save_button)

	_quit_button = UIFactory.button(Localization.tr_key("quit"), 42)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	center.add_child(_quit_button)

	_info_label = UIFactory.label("", 14, UIFactory.TEXT_DIM)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_info_label)

	var version := UIFactory.label("Eldoria Edition v1.0  ·  Godot 4.3 Mobile Compatibility  ·  100% Free CC0/OFL Assets", 13, UIFactory.TEXT_DIM)
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.position = Vector2(18, -30)
	add_child(version)

	_build_settings_panel()
	_refresh_save_state()

func _build_settings_panel() -> void:
	_settings_panel = UIFactory.panel()
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_settings_panel.custom_minimum_size = Vector2(560, 0)
	_settings_panel.visible = false
	add_child(_settings_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_settings_panel.add_child(box)
	box.add_child(UIFactory.label("✦  Settings", 24, UIFactory.GOLD))

	box.add_child(UIFactory.label("Language / اللغة", 16, UIFactory.TEXT_DIM))
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 8)
	box.add_child(lang_row)
	for pair: Array in [["en", "English"], ["ar", "العربية (RTL)"]]:
		var code := String(pair[0])
		var lb := UIFactory.button(String(pair[1]), 44)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.pressed.connect(func() -> void:
			SettingsManager.language = code
			SettingsManager.save_settings()
			SettingsManager.apply_all()
			_refresh_save_state())
		lang_row.add_child(lb)

	box.add_child(UIFactory.label("Graphics Quality", 16, UIFactory.TEXT_DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var labels := ["Low", "Medium", "High"]
	for i: int in labels.size():
		var button := UIFactory.button(labels[i], 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			SettingsManager.graphics_preset = i
			SettingsManager.save_settings()
			SettingsManager.apply_graphics()
			_refresh_save_state())
		row.add_child(button)

	var touch_toggle := UIFactory.button("", 42)
	touch_toggle.name = "TouchToggle"
	touch_toggle.pressed.connect(func() -> void:
		SettingsManager.show_touch_controls = not SettingsManager.show_touch_controls
		SettingsManager.save_settings()
		SettingsManager.apply_all()
		_refresh_save_state())
	box.add_child(touch_toggle)

	box.add_child(UIFactory.label("Camera Sensitivity", 16, UIFactory.TEXT_DIM))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.4
	sensitivity.max_value = 2.2
	sensitivity.step = 0.1
	sensitivity.value = SettingsManager.camera_sensitivity
	sensitivity.custom_minimum_size = Vector2(0, 34)
	sensitivity.value_changed.connect(func(value: float) -> void:
		SettingsManager.camera_sensitivity = value
		SettingsManager.save_settings())
	box.add_child(sensitivity)

	var close := UIFactory.button(Localization.tr_key("close"), 46)
	close.pressed.connect(_toggle_settings)
	box.add_child(close)

func _refresh_save_state() -> void:
	Localization.apply_rtl(self)
	_title_label.text = Localization.tr_key("game_title")
	_subtitle_label.text = Localization.tr_key("game_subtitle")
	_continue_button.text = Localization.tr_key("continue_game")
	_new_button.text = Localization.tr_key("new_game")
	_settings_button.text = Localization.tr_key("settings")
	_quit_button.text = Localization.tr_key("quit")

	var has_save := SaveManager.has_save(SaveManager.DEFAULT_SLOT)
	_continue_button.disabled = not has_save
	_save_button.visible = has_save
	_info_label.text = ("Saved Adventure: %s" % _save_timestamp()) if has_save else "Offline Adventure Ready — Start a New Game"
	var touch_toggle := _settings_panel.find_child("TouchToggle", true, false) as Button
	if touch_toggle != null:
		touch_toggle.text = "Touch Controls: %s" % ("ON" if SettingsManager.show_touch_controls else "OFF")

func _save_timestamp() -> String:
	var path := SaveManager.path_for(SaveManager.DEFAULT_SLOT)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "unknown"
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return "unknown"
	var data: Dictionary = parsed
	var meta: Dictionary = data.get("meta", {})
	var level := int((data.get("game", {}) as Dictionary).get("level", 1))
	var gr := String(meta.get("guild_rank", "—"))
	return "%s · Lv %d · Guild %s" % [String(data.get("saved_at", "?")), level, gr]

func _toggle_settings() -> void:
	_settings_panel.visible = not _settings_panel.visible
	_refresh_save_state()

func _on_new_game() -> void:
	await SceneManager.new_game()

func _on_continue() -> void:
	if not SaveManager.load_game(SaveManager.DEFAULT_SLOT):
		EventBus.notify.emit("Save could not be loaded")
		return
	await SceneManager.change_scene(SceneManager.GAME)

func _on_delete_save() -> void:
	SaveManager.delete_save(SaveManager.DEFAULT_SLOT)
	SaveManager.delete_save(SaveManager.AUTOSAVE_SLOT)
	_refresh_save_state()
