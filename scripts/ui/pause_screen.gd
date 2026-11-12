class_name PauseScreen
extends MenuScreen
## Pause menu + settings (graphics preset, overlay, touch controls).

signal request_main_menu()

func _ready() -> void:
	configure("Paused")
	super._ready()
	closed.connect(func() -> void: get_tree().paused = false)

func refresh() -> void:
	clear_content()
	var resume := UIFactory.button("Resume")
	resume.pressed.connect(close)
	content.add_child(resume)

	var save_button := UIFactory.button("Save game")
	save_button.pressed.connect(func() -> void:
		if SaveManager.save_game(SaveManager.DEFAULT_SLOT):
			EventBus.notify.emit("Game saved")
		else:
			EventBus.notify.emit("Save failed: %s" % SaveManager.last_save_error))
	content.add_child(save_button)

	var load_button := UIFactory.button("Load last save")
	load_button.disabled = not SaveManager.has_save(SaveManager.DEFAULT_SLOT)
	load_button.pressed.connect(func() -> void:
		if SaveManager.load_game(SaveManager.DEFAULT_SLOT):
			SceneManager.change_scene(SceneManager.GAME)
		else:
			EventBus.notify.emit("Load failed: %s" % SaveManager.last_save_error))
	content.add_child(load_button)

	content.add_child(UIFactory.hsep())
	content.add_child(UIFactory.label("Graphics", 19, UIFactory.ACCENT))
	var graphics_row := HBoxContainer.new()
	graphics_row.add_theme_constant_override("separation", 8)
	content.add_child(graphics_row)
	var labels := ["Low", "Medium", "High"]
	for i: int in labels.size():
		var button := UIFactory.button(labels[i], 46)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_pressed = SettingsManager.graphics_preset == i
		button.pressed.connect(func() -> void:
			SettingsManager.graphics_preset = i
			SettingsManager.save_settings()
			SettingsManager.apply_graphics())
		graphics_row.add_child(button)

	var overlay := UIFactory.button("Performance overlay: %s"
		% ("on" if SettingsManager.show_performance_overlay else "off"))
	overlay.pressed.connect(func() -> void:
		SettingsManager.show_performance_overlay = not SettingsManager.show_performance_overlay
		SettingsManager.save_settings()
		SettingsManager.apply_all())
	content.add_child(overlay)

	var touch_toggle := UIFactory.button("Touch controls: %s"
		% ("on" if SettingsManager.show_touch_controls else "off"))
	touch_toggle.pressed.connect(func() -> void:
		SettingsManager.show_touch_controls = not SettingsManager.show_touch_controls
		SettingsManager.save_settings()
		SettingsManager.apply_all())
	content.add_child(touch_toggle)

	content.add_child(UIFactory.hsep())
	var main_menu := UIFactory.button("Save and quit to menu")
	main_menu.pressed.connect(func() -> void:
		SaveManager.save_game(SaveManager.DEFAULT_SLOT)
		request_main_menu.emit())
	content.add_child(main_menu)
