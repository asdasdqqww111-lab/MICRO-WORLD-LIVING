class_name WeatherSystem
extends Node
## Scalable Eldoria weather controller (clear <-> rain) with Low/Medium/High
## particle budgets and automatic indoor hiding.

const RAIN_CHANCE := 0.32
const MIN_DURATION_MINUTES := 120.0
const MAX_DURATION_MINUTES := 420.0

var particles: GPUParticles3D
var day_night: DayNightCycle

func setup(parent: Node3D, cycle: DayNightCycle) -> void:
	day_night = cycle
	particles = GPUParticles3D.new()
	particles.name = "RainParticles"
	particles.amount = _rain_budget()
	particles.lifetime = 1.35
	particles.visibility_aabb = AABB(Vector3(-30, -20, -30), Vector3(60, 40, 60))
	particles.emitting = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(22.0, 1.0, 22.0)
	process.direction = Vector3(-0.08, -1.0, 0.04)
	process.spread = 3.5
	process.initial_velocity_min = 16.0
	process.initial_velocity_max = 22.0
	process.gravity = Vector3(0.0, -9.0, 0.0)
	process.scale_min = 0.6
	process.scale_max = 1.15
	particles.process_material = process
	var drop := BoxMesh.new()
	drop.size = Vector3(0.02, 0.48, 0.02)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.82, 0.95, 0.60)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = mat
	particles.draw_pass_1 = drop
	parent.add_child(particles)
	EventBus.graphics_settings_changed.connect(_on_graphics_changed)
	_apply_state()

func _rain_budget() -> int:
	if SettingsManager == null:
		return 550
	match SettingsManager.graphics_preset:
		SettingsManager.GraphicsPreset.LOW: return 220
		SettingsManager.GraphicsPreset.HIGH: return 750
		_: return 480

func _on_graphics_changed() -> void:
	if particles != null:
		particles.amount = _rain_budget()

var _player_ref: Player

func _process(delta: float) -> void:
	if not GameManager.is_playing or get_tree().paused:
		return
	var world := GameManager.world
	world.weather_remaining -= delta * DayNightCycle.TIME_SCALE / 60.0
	if world.weather_remaining <= 0.0:
		_roll_weather()
	if not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group("player") as Player
	var player := _player_ref
	var raining := world.weather == "rain"
	var outdoors := player == null or player.zone == "village"
	if player != null and particles != null:
		var emit := raining and outdoors
		if particles.emitting != emit:
			particles.emitting = emit
		# The rain volume only has to follow the player while it is raining.
		if emit:
			particles.global_position = player.global_position + Vector3(0.0, 16.0, 0.0)
	if day_night != null:
		day_night.set_weather_darkness(0.52 if raining else 0.0)

func _roll_weather() -> void:
	var world := GameManager.world
	var raining := randf() < RAIN_CHANCE
	var next_weather := "rain" if raining else "clear"
	world.weather = next_weather
	world.weather_remaining = randf_range(MIN_DURATION_MINUTES, MAX_DURATION_MINUTES)
	_apply_state()
	EventBus.weather_changed.emit(next_weather)
	EventBus.notify.emit("Mountain rain begins to fall" if raining else "The clouds part over Eldoria")

func _apply_state() -> void:
	if particles != null:
		particles.emitting = GameManager.world.weather == "rain"

func force_weather(weather: String) -> void:
	GameManager.world.weather = weather
	GameManager.world.weather_remaining = 180.0
	_apply_state()
	EventBus.weather_changed.emit(weather)
