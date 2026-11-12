class_name DayNightCycle
extends Node
## Drives the world clock and sun/sky. 1 real second = 1 in-game minute.

const TIME_SCALE := 60.0
const SUNRISE_HOUR := 6.0
const SUNSET_HOUR := 19.5

var sun: DirectionalLight3D
var environment: Environment
var sky_material: ProceduralSkyMaterial

var _last_minute: int = -1
var _weather_darkness: float = 0.0
var _time_scale_multiplier: float = 1.0

func setup(sun_light: DirectionalLight3D, env: Environment) -> void:
	sun = sun_light
	environment = env
	if env != null and env.sky != null:
		sky_material = env.sky.sky_material as ProceduralSkyMaterial
	apply_now()

func set_time_scale_multiplier(value: float) -> void:
	_time_scale_multiplier = maxf(0.0, value)

func _process(delta: float) -> void:
	if not GameManager.is_playing or get_tree().paused:
		return
	var day_before := GameManager.world.day
	var new_day := GameManager.world.advance(delta * TIME_SCALE * _time_scale_multiplier)
	if new_day:
		EventBus.day_started.emit(GameManager.world.day)
	apply_now()
	var minute := GameManager.world.minute()
	if minute != _last_minute:
		_last_minute = minute
		EventBus.time_changed.emit(GameManager.world.hour(), minute, GameManager.world.day)

func apply_now() -> void:
	if sun == null:
		return
	var hour := GameManager.world.hour_float()
	var elevation := sin((hour / 24.0 - 0.25) * TAU) * 90.0
	sun.rotation_degrees = Vector3(-elevation, -35.0, 0.0)
	var daylight := clampf(sin((hour / 24.0 - 0.25) * TAU) * 1.6 + 0.15, 0.0, 1.0)
	var night_factor := 1.0 - clampf(daylight * 2.2, 0.0, 1.0)
	var weather_factor := 1.0 - _weather_darkness * 0.55
	sun.light_energy = lerpf(0.12, 1.35, daylight) * weather_factor
	sun.light_color = Color(1.0, 0.95, 0.85).lerp(Color(0.72, 0.82, 1.0), night_factor)
	if environment != null:
		environment.ambient_light_energy = lerpf(0.22, 0.85, daylight) * weather_factor
		environment.ambient_light_color = Color(0.24, 0.3, 0.42).lerp(Color(0.75, 0.72, 0.62), daylight)
		environment.fog_light_color = Color(0.16, 0.19, 0.26).lerp(Color(0.68, 0.75, 0.8), daylight)
		if sky_material != null:
			var top_day := Color(0.32, 0.55, 0.86)
			var top_night := Color(0.03, 0.05, 0.12)
			var horizon_day := Color(0.72, 0.82, 0.92)
			var horizon_night := Color(0.08, 0.11, 0.2)
			var rain_grey := Color(0.5, 0.53, 0.56)
			var top := top_day.lerp(top_night, night_factor)
			var horizon := horizon_day.lerp(horizon_night, night_factor)
			if _weather_darkness > 0.0:
				top = top.lerp(rain_grey, _weather_darkness * 0.7)
				horizon = horizon.lerp(rain_grey, _weather_darkness * 0.7)
			sky_material.sky_top_color = top
			sky_material.sky_horizon_color = horizon
			sky_material.ground_bottom_color = horizon.darkened(0.35)

func set_weather_darkness(value: float) -> void:
	_weather_darkness = clampf(value, 0.0, 1.0)
	apply_now()

func is_daytime() -> bool:
	var h := GameManager.world.hour_float()
	return h >= SUNRISE_HOUR and h < SUNSET_HOUR
