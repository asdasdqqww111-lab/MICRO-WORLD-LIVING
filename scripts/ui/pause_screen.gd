class_name PauseScreen
extends MenuScreen
## Pause & Settings Menu: Resume, Save/Load, Language (English / العربية RTL),
## Graphics Preset (Low/Med/High), Audio Sliders, Touch Controls & Quit to Menu.

signal request_main_menu()

func _ready() -> void:
	configure("Paused & Settings", "paused")
	super._ready()
	closed.connect(func() -> void: get_tree().paused = false)

func refresh() -> void:
	clear_content()
	var top_btns := HBoxContainer.new()
	top_btns.add_theme_constant_override("separation", 10)
	content.add_child(top_btns)

	var resume := UIFactory.button(Localization.tr_key("resume"), 46)
	resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume.pressed.connect(close)
	top_btns.add_child(resume)

	var save_button := UIFactory.button(Localization.tr_key("save_game"), 46)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(func() -> void:
		if SaveManager.save_game(SaveManager.DEFAULT_SLOT):
			EventBus.notify.emit("Game saved")
			refresh()
		else:
			EventBus.notify.emit("Save failed: %s" % SaveManager.last_save_error))
	top_btns.add_child(save_button)

	var load_button := UIFactory.button(Localization.tr_key("load_game"), 46)
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.disabled = not SaveManager.has_save(SaveManager.DEFAULT_SLOT)
	load_button.pressed.connect(func() -> void:
		if SaveManager.load_game(SaveManager.DEFAULT_SLOT):
			close()
			SceneManager.change_scene(SceneManager.GAME)
		else:
			EventBus.notify.emit("Load failed: %s" % SaveManager.last_save_error))
	top_btns.add_child(load_button)

	content.add_child(UIFactory.hsep())

	# Language Selector (English / العربية RTL)
	content.add_child(UIFactory.label(Localization.tr_key("language"), 18, UIFactory.GOLD))
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 8)
	content.add_child(lang_row)
	for pair: Array in [["en", "English"], ["ar", "العربية (Arabic RTL)"]]:
		var code := String(pair[0])
		var b := UIFactory.button(String(pair[1]), 42)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.button_pressed = (SettingsManager.language == code)
		b.pressed.connect(func() -> void:
			SettingsManager.language = code
			SettingsManager.save_settings()
			SettingsManager.apply_all()
			refresh())
		lang_row.add_child(b)

	# Graphics Quality Tier
	content.add_child(UIFactory.label(Localization.tr_key("graphics"), 18, UIFactory.ACCENT))
	var graphics_row := HBoxContainer.new()
	graphics_row.add_theme_constant_override("separation", 8)
	content.add_child(graphics_row)
	var labels := [Localization.tr_key("low"), Localization.tr_key("medium"), Localization.tr_key("high")]
	for i: int in labels.size():
		var button := UIFactory.button(labels[i], 42)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_pressed = (SettingsManager.graphics_preset == i)
		button.pressed.connect(func() -> void:
			SettingsManager.graphics_preset = i
			SettingsManager.save_settings()
			SettingsManager.apply_graphics()
			refresh())
		graphics_row.add_child(button)

	# Audio Volume Sliders
	_add_volume_slider(Localization.tr_key("master_vol"), SettingsManager.master_volume, func(v: float) -> void:
		SettingsManager.master_volume = v
		SettingsManager.save_settings()
		SettingsManager.apply_all())
	_add_volume_slider(Localization.tr_key("music_vol"), SettingsManager.music_volume, func(v: float) -> void:
		SettingsManager.music_volume = v
		SettingsManager.save_settings()
		SettingsManager.apply_all())
	_add_volume_slider(Localization.tr_key("sfx_vol"), SettingsManager.sfx_volume, func(v: float) -> void:
		SettingsManager.sfx_volume = v
		SettingsManager.save_settings()
		SettingsManager.apply_all())

	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 10)
	content.add_child(toggles)

	var ar := Localization.is_arabic()
	var on_txt := "مفعّل" if ar else "ON"
	var off_txt := "مغلق" if ar else "OFF"
	var touch_toggle := UIFactory.button("%s: %s" % [Localization.tr_key("touch_controls"), on_txt if SettingsManager.show_touch_controls else off_txt], 42)
	touch_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	touch_toggle.pressed.connect(func() -> void:
		SettingsManager.show_touch_controls = not SettingsManager.show_touch_controls
		SettingsManager.save_settings()
		SettingsManager.apply_all()
		refresh())
	toggles.add_child(touch_toggle)

	var overlay := UIFactory.button(("%s: %s" % ["تشخيص الأداء (F3)" if ar else "Dev Diagnostics (F3)", on_txt if SettingsManager.show_performance_overlay else off_txt]), 42)
	overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay.pressed.connect(func() -> void:
		SettingsManager.show_performance_overlay = not SettingsManager.show_performance_overlay
		SettingsManager.save_settings()
		SettingsManager.apply_all()
		refresh())
	toggles.add_child(overlay)

	content.add_child(UIFactory.hsep())
	var main_menu := UIFactory.button(Localization.tr_key("quit_menu"), 46)
	main_menu.pressed.connect(func() -> void:
		SaveManager.save_game(SaveManager.DEFAULT_SLOT)
		request_main_menu.emit())
	content.add_child(main_menu)

func _add_volume_slider(lbl_text: String, initial: float, cb: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := UIFactory.label(lbl_text, 15, UIFactory.TEXT_DIM)
	lbl.custom_minimum_size = Vector2(170, 0)
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 32)
	slider.value_changed.connect(cb)
	row.add_child(slider)
	content.add_child(row)
