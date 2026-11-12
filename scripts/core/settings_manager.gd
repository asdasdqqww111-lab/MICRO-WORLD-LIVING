extends Node
## Persists user options and applies render/audio/localization presets (autoload: SettingsManager).

const SETTINGS_PATH := "user://settings.cfg"

enum GraphicsPreset { LOW, MEDIUM, HIGH }

var graphics_preset: int = GraphicsPreset.MEDIUM
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.65
var camera_sensitivity: float = 1.0
var invert_camera_y: bool = false
var show_performance_overlay: bool = false
var developer_mode: bool = false
var show_touch_controls: bool = true
var touch_scale: float = 1.0
var autosave_enabled: bool = true
var language: String = "en"

func _ready() -> void:
	InputSetup.ensure_actions()
	load_settings()
	apply_all()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		graphics_preset = GraphicsPreset.LOW if is_mobile() else GraphicsPreset.MEDIUM
		save_settings()
		return
	graphics_preset = clampi(int(cfg.get_value("video", "graphics_preset", GraphicsPreset.MEDIUM)), 0, 2)
	master_volume = float(cfg.get_value("audio", "master", 1.0))
	sfx_volume = float(cfg.get_value("audio", "sfx", 1.0))
	music_volume = float(cfg.get_value("audio", "music", 0.65))
	camera_sensitivity = clampf(float(cfg.get_value("input", "camera_sensitivity", 1.0)), 0.25, 2.5)
	invert_camera_y = bool(cfg.get_value("input", "invert_camera_y", false))
	developer_mode = bool(cfg.get_value("debug", "developer_mode", false))
	show_performance_overlay = bool(cfg.get_value("debug", "show_performance", false)) and developer_mode
	show_touch_controls = bool(cfg.get_value("input", "show_touch_controls", true))
	touch_scale = clampf(float(cfg.get_value("input", "touch_scale", 1.0)), 0.8, 1.3)
	autosave_enabled = bool(cfg.get_value("game", "autosave", true))
	language = String(cfg.get_value("game", "language", "en"))
	if language != "en" and language != "ar":
		language = "en"

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "graphics_preset", graphics_preset)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("input", "camera_sensitivity", camera_sensitivity)
	cfg.set_value("input", "invert_camera_y", invert_camera_y)
	cfg.set_value("debug", "developer_mode", developer_mode)
	cfg.set_value("debug", "show_performance", show_performance_overlay)
	cfg.set_value("input", "show_touch_controls", show_touch_controls)
	cfg.set_value("input", "touch_scale", touch_scale)
	cfg.set_value("game", "autosave", autosave_enabled)
	cfg.set_value("game", "language", language)
	cfg.save(SETTINGS_PATH)

func set_language(lang: String) -> void:
	var normalized := "ar" if lang == "ar" else "en"
	if language == normalized:
		return
	language = normalized
	save_settings()
	EventBus.language_changed.emit(language)

func apply_all() -> void:
	apply_audio()
	apply_graphics()

func apply_audio() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("SFX", sfx_volume)
	_set_bus_volume("Music", music_volume)

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var db := -80.0 if linear <= 0.001 else linear_to_db(clampf(linear, 0.0, 1.6))
	AudioServer.set_bus_volume_db(idx, db)

## Applies real Android/GLES3 rendering costs across Low / Medium / High presets.
func apply_graphics() -> void:
	var viewport := get_viewport()
	if viewport != null:
		match graphics_preset:
			GraphicsPreset.LOW:
				viewport.msaa_3d = Viewport.MSAA_DISABLED
				viewport.scaling_3d_scale = 0.75
			GraphicsPreset.MEDIUM:
				viewport.msaa_3d = Viewport.MSAA_2X
				viewport.scaling_3d_scale = 0.92 if is_mobile() else 1.0
			_:
				viewport.msaa_3d = Viewport.MSAA_4X
				viewport.scaling_3d_scale = 1.0
	EventBus.graphics_settings_changed.emit()

func shadow_quality() -> int:
	match graphics_preset:
		GraphicsPreset.LOW:
			return RenderingServer.SHADOW_QUALITY_HARD
		GraphicsPreset.MEDIUM:
			return RenderingServer.SHADOW_QUALITY_SOFT_LOW
		_:
			return RenderingServer.SHADOW_QUALITY_SOFT_HIGH

func view_distance() -> float:
	match graphics_preset:
		GraphicsPreset.LOW:
			return 95.0
		GraphicsPreset.MEDIUM:
			return 145.0
		_:
			return 210.0

func vegetation_density_multiplier() -> float:
	match graphics_preset:
		GraphicsPreset.LOW:
			return 0.65
		GraphicsPreset.MEDIUM:
			return 0.85
		_:
			return 1.0

func is_desktop() -> bool:
	return OS.has_feature("pc")

func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android")
