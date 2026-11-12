class_name WeatherSystem
extends Node
## Minimal weather: clear <-> rain, persisted in WorldState.

const RAIN_CHANCE := 0.35
const MIN_DURATION_MINUTES := 120.0
const MAX_DURATION_MINUTES := 420.0
const RAIN_AMOUNT := 700

var particles: GPUParticles3D
var day_night: DayNightCycle

func setup(parent: Node3D, cycle: DayNightCycle) -> void:
	day_night = cycle
	particles = GPUParticles3D.new()
	particles.name = "RainParticles"
	particles.amount = RAIN_AMOUNT
	particles.lifetime = 1.4
	particles.visibility_aabb = AABB(Vector3(-30, -20, -30), Vector3(60, 40, 60))
	particles.emitting = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(24.0, 1.0, 24.0)
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 4.0
	process.initial_velocity_min = 16.0
	process.initial_velocity_max = 22.0
	process.gravity = Vector3(0.0, -9.0, 0.0)
	process.scale_min = 0.6
	process.scale_max = 1.2
	particles.process_material = process
	var drop := BoxMesh.new()
	drop.size = Vector3(0.02, 0.5, 0.02)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.82, 0.95, 0.65)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = mat
	particles.draw_pass_1 = drop
	parent.add_child(particles)
	_apply_state(false)

func _process(delta: float) -> void:
	if not GameManager.is_playing or get_tree().paused:
		return
	var world := GameManager.world
	world.weather_remaining -= delta * DayNightCycle.TIME_SCALE / 60.0
	if world.weather_remaining <= 0.0:
		_roll_weather()
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and particles != null:
		particles.global_position = player.global_position + Vector3(0.0, 16.0, 0.0)
	if day_night != null:
		day_night.set_weather_darkness(0.55 if world.weather == "rain" else 0.0)

func _roll_weather() -> void:
	var world := GameManager.world
	var raining := randf() < RAIN_CHANCE
	var next_weather := "rain" if raining else "clear"
	world.weather = next_weather
	world.weather_remaining = randf_range(MIN_DURATION_MINUTES, MAX_DURATION_MINUTES)
	_apply_state(true)
	EventBus.weather_changed.emit(next_weather)
	EventBus.notify.emit("It starts to rain" if raining else "The sky clears")

func _apply_state(announce: bool) -> void:
	if particles != null:
		particles.emitting = GameManager.world.weather == "rain"
	if announce:
		pass

func force_weather(weather: String) -> void:
	GameManager.world.weather = weather
	GameManager.world.weather_remaining = 180.0
	_apply_state(false)
	EventBus.weather_changed.emit(weather)
