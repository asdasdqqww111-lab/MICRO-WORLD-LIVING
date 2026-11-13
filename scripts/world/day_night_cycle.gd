class_name DayNightCycle
extends Node
## Synchronized Eldoria atmosphere controller:
##   - Drives world clock (1 real sec = 1 in-game minute)
##   - Emits time_changed, hour_changed, and day_started
##   - Blends sun/moon elevation, golden-hour warmth, sky colors, fog & clouds
##   - Automatically switches village lanterns on at dusk and off at dawn

const TIME_SCALE := 60.0
const SUNRISE_HOUR := 6.0
const SUNSET_HOUR := 19.5

var sun: DirectionalLight3D
var moon: DirectionalLight3D
var clouds: CloudLayer
var environment: Environment
var sky_material: ProceduralSkyMaterial
var sky_shader_material: ShaderMaterial
var panorama_sky_material: PanoramaSkyMaterial

var _last_minute: int = -1
var _last_hour: int = -1
var _weather_darkness: float = 0.0
var _time_scale_multiplier: float = 1.0
var _lanterns_lit: bool = false

func setup(sun_light: DirectionalLight3D, env: Environment, moon_light: DirectionalLight3D = null, cloud_layer: CloudLayer = null) -> void:
	sun = sun_light
	moon = moon_light
	clouds = cloud_layer
	environment = env
	if env != null and env.sky != null:
		sky_material = env.sky.sky_material as ProceduralSkyMaterial
		sky_shader_material = env.sky.sky_material as ShaderMaterial
		panorama_sky_material = env.sky.sky_material as PanoramaSkyMaterial
	apply_now()

func set_time_scale_multiplier(value: float) -> void:
	_time_scale_multiplier = maxf(0.0, value)

func _process(delta: float) -> void:
	if not GameManager.is_playing or get_tree().paused:
		return
	var new_day := GameManager.world.advance(delta * TIME_SCALE * _time_scale_multiplier)
	if new_day:
		EventBus.day_started.emit(GameManager.world.day)
		if get_tree() != null:
			for node: Node in get_tree().get_nodes_in_group("resource_node"):
				if node.has_method("refresh_state"):
					node.call("refresh_state")
	apply_now()
	var h := GameManager.world.hour()
	var minute := GameManager.world.minute()
	if h != _last_hour:
		_last_hour = h
		EventBus.hour_changed.emit(h)
	if minute != _last_minute:
		_last_minute = minute
		EventBus.time_changed.emit(h, minute, GameManager.world.day)

func apply_now() -> void:
	if sun == null:
		return
	var hour := GameManager.world.hour_float()
	# Calibrated so late afternoon (17:01) hits X=-35, Y=-45 warm golden sun (Color(1.0, 0.95, 0.85))
	var elevation := sin((hour / 24.0 - 0.278) * TAU) * 62.0
	var azimuth := -45.0 + cos((hour - 17.0) / 24.0 * TAU) * 14.0 - 14.0
	sun.rotation_degrees = Vector3(-clampf(elevation, 8.0, 68.0), azimuth, 0.0)

	var daylight := clampf(sin((hour / 24.0 - 0.25) * TAU) * 1.65 + 0.34, 0.0, 1.0)
	var late_dusk := clampf((hour - 18.2) / 1.4, 0.0, 1.0) if hour >= 18.2 else 0.0
	var night_factor := 1.0 - clampf(daylight * 2.3, 0.0, 1.0)
	var weather_factor := 1.0 - _weather_darkness * 0.45

	sun.light_energy = lerpf(0.08, 1.26, daylight) * weather_factor
	var afternoon_col := Color(1.0, 0.95, 0.85)
	var dusk_col := Color(1.0, 0.72, 0.48)
	var night_col := Color(0.58, 0.68, 0.95)
	sun.light_color = afternoon_col.lerp(dusk_col, late_dusk * 0.65).lerp(night_col, night_factor)

	if moon != null:
		moon.rotation_degrees = Vector3(-42.0, 145.0, 0.0)
		moon.light_energy = night_factor * 0.32 * weather_factor

	if environment != null:
		# Keep a readable minimum at night so shadowed geometry never crushes to black.
		environment.ambient_light_energy = lerpf(0.42, 0.66, daylight) * lerpf(1.0, weather_factor, 0.55)
		environment.ambient_light_color = Color(0.24, 0.32, 0.48).lerp(Color(0.74, 0.80, 0.88), daylight)
		var fog_day := Color(0.6, 0.75, 0.9).lerp(Color(0.84, 0.70, 0.60), late_dusk * 0.50)
		var fog_night := Color(0.10, 0.14, 0.22)
		environment.fog_light_color = fog_night.lerp(fog_day, daylight)
		var top_day := Color(0.14, 0.36, 0.74)
		var top_night := Color(0.03, 0.05, 0.12)
		var horizon_day := Color(0.60, 0.76, 0.89).lerp(Color(0.95, 0.64, 0.42), late_dusk * 0.68)
		var horizon_night := Color(0.08, 0.11, 0.20)
		var rain_grey := Color(0.44, 0.48, 0.54)
		var top := top_day.lerp(top_night, night_factor)
		var horizon := horizon_day.lerp(horizon_night, night_factor)
		if _weather_darkness > 0.0:
			top = top.lerp(rain_grey, _weather_darkness * 0.68)
			horizon = horizon.lerp(rain_grey, _weather_darkness * 0.68)
		if panorama_sky_material != null:
			panorama_sky_material.energy_multiplier = lerpf(0.16, 0.96, daylight) * (1.0 - late_dusk * 0.14) * weather_factor
		elif sky_shader_material != null:
			sky_shader_material.set_shader_parameter("sky_top", Vector3(top.r, top.g, top.b))
			sky_shader_material.set_shader_parameter("sky_horizon", Vector3(horizon.r, horizon.g, horizon.b))
			sky_shader_material.set_shader_parameter("night_factor", night_factor)
			sky_shader_material.set_shader_parameter("rain_factor", _weather_darkness)
			sky_shader_material.set_shader_parameter("sky_time", float(Time.get_ticks_msec()) * 0.001)
			var cb := Color(0.99, 0.98, 0.96).lerp(Color(1.0, 0.74, 0.52), late_dusk * 0.65)
			sky_shader_material.set_shader_parameter("cloud_bright", Vector3(cb.r, cb.g, cb.b))
		elif sky_material != null:
			sky_material.sky_top_color = top
			sky_material.sky_horizon_color = horizon
			sky_material.ground_horizon_color = horizon.darkened(0.28)
			sky_material.ground_bottom_color = horizon.darkened(0.52)

	if clouds != null:
		var cloud_col := Color(1.0, 0.98, 0.95).lerp(Color(1.0, 0.76, 0.58), late_dusk * 0.6).lerp(Color(0.22, 0.26, 0.38), night_factor)
		if _weather_darkness > 0.0:
			cloud_col = cloud_col.lerp(Color(0.55, 0.58, 0.62), _weather_darkness * 0.7)
		clouds.set_sky_tint(cloud_col)

	var want_lanterns := night_factor > 0.35 or _weather_darkness > 0.4
	if want_lanterns != _lanterns_lit and get_tree() != null:
		_lanterns_lit = want_lanterns
		for lnode: Node in get_tree().get_nodes_in_group("village_lantern"):
			if lnode is Light3D:
				(lnode as Light3D).visible = want_lanterns

func set_weather_darkness(value: float) -> void:
	_weather_darkness = clampf(value, 0.0, 1.0)
	apply_now()

func sync_from_state() -> void:
	apply_now()

func is_daytime() -> bool:
	var h := GameManager.world.hour_float()
	return h >= SUNRISE_HOUR and h < SUNSET_HOUR
