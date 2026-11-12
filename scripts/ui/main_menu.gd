class_name MainMenu
extends Control
## Title screen: New Game / Continue / Settings / Quit.

var _continue_button: Button
var _settings_panel: PanelContainer
var _info_label: Label
var _save_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.is_playing = false
	get_tree().paused = false
	UIFactory.full_rect(self)
	_build()

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.08, 0.11, 0.13, 1.0)
	UIFactory.full_rect(background)
	add_child(background)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.custom_minimum_size = Vector2(460, 0)
	center.add_theme_constant_override("separation", 10)
	add_child(center)

	var title := UIFactory.label("MICRO WORLD", 54, UIFactory.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	var subtitle := UIFactory.label("L I V I N G", 26, UIFactory.GOLD)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(subtitle)
	center.add_child(UIFactory.spacer(18))

	var new_game := UIFactory.button("New Game", 58)
	new_game.pressed.connect(_on_new_game)
	center.add_child(new_game)

	_continue_button = UIFactory.button("Continue", 58)
	_continue_button.pressed.connect(_on_continue)
	center.add_child(_continue_button)

	var settings := UIFactory.button("Settings", 58)
	settings.pressed.connect(_toggle_settings)
	center.add_child(settings)

	_save_button = UIFactory.button("Delete save", 46)
	_save_button.pressed.connect(_on_delete_save)
	center.add_child(_save_button)

	var quit := UIFactory.button("Quit", 46)
	quit.pressed.connect(func() -> void: get_tree().quit())
	center.add_child(quit)

	_info_label = UIFactory.label("", 15, UIFactory.TEXT_DIM)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_info_label)

	var version := UIFactory.label("Vertical slice 0.1  ·  Godot 4.3 Compatibility", 14, UIFactory.TEXT_DIM)
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.position = Vector2(18, -34)
	add_child(version)

	_build_settings_panel()
	_refresh_save_state()

func _build_settings_panel() -> void:
	_settings_panel = UIFactory.panel()
	_settings_panel.anchor_left = 0.5
	_settings_panel.anchor_right = 0.5
	_settings_panel.anchor_top = 0.5
	_settings_panel.anchor_bottom = 0.5
	_settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_settings_panel.custom_minimum_size = Vector2(560, 0)
	_settings_panel.visible = false
	add_child(_settings_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_settings_panel.add_child(box)
	box.add_child(UIFactory.label("Settings", 26))

	box.add_child(UIFactory.label("Graphics quality", 18, UIFactory.TEXT_DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var labels := ["Low", "Medium", "High"]
	for i: int in labels.size():
		var button := UIFactory.button(labels[i], 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_pressed = SettingsManager.graphics_preset == i
		button.pressed.connect(func() -> void:
			SettingsManager.graphics_preset = i
			SettingsManager.save_settings()
			SettingsManager.apply_graphics()
			_refresh_save_state())
		row.add_child(button)

	var touch_toggle := UIFactory.button("")
	touch_toggle.pressed.connect(func() -> void:
		SettingsManager.show_touch_controls = not SettingsManager.show_touch_controls
		SettingsManager.save_settings()
		SettingsManager.apply_all()
		_refresh_save_state())
	touch_toggle.name = "TouchToggle"
	box.add_child(touch_toggle)

	var overlay_toggle := UIFactory.button("")
	overlay_toggle.name = "OverlayToggle"
	overlay_toggle.pressed.connect(func() -> void:
		SettingsManager.show_performance_overlay = not SettingsManager.show_performance_overlay
		SettingsManager.save_settings()
		SettingsManager.apply_all()
		_refresh_save_state())
	box.add_child(overlay_toggle)

	box.add_child(UIFactory.label("Camera sensitivity", 18, UIFactory.TEXT_DIM))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.4
	sensitivity.max_value = 2.2
	sensitivity.step = 0.1
	sensitivity.value = SettingsManager.camera_sensitivity
	sensitivity.custom_minimum_size = Vector2(0, 40)
	sensitivity.value_changed.connect(func(value: float) -> void:
		SettingsManager.camera_sensitivity = value
		SettingsManager.save_settings())
	box.add_child(sensitivity)

	var close := UIFactory.button("Back", 50)
	close.pressed.connect(_toggle_settings)
	box.add_child(close)

func _refresh_save_state() -> void:
	var has_save := SaveManager.has_save(SaveManager.DEFAULT_SLOT)
	_continue_button.disabled = not has_save
	_save_button.visible = has_save
	if has_save:
		_info_label.text = "Last save: %s" % _save_timestamp()
	else:
		_info_label.text = "No save yet"
	var touch_toggle := _settings_panel.find_child("TouchToggle", true, false) as Button
	if touch_toggle != null:
		touch_toggle.text = "Touch controls: %s" % ("on" if SettingsManager.show_touch_controls else "off")
	var overlay_toggle := _settings_panel.find_child("OverlayToggle", true, false) as Button
	if overlay_toggle != null:
		overlay_toggle.text = "Performance overlay: %s" % ("on" if SettingsManager.show_performance_overlay else "off")

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
	return "%s  ·  level %d" % [String(data.get("saved_at", "?")), level]

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
