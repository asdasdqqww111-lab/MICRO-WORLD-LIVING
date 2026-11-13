class_name VFXManager
extends Node3D
## Lightweight mobile-friendly 3D Particle VFX ("Juice") controller:
##   - Walking / sprinting boot dust puffs on terrain
##   - Melee & critical-hit glowing spark bursts
##   - Arcane spell cast burst
##   - Rain ground splash mist outdoors

var _player: Player
var _dust_particles: CPUParticles3D
var _rain_splash: CPUParticles3D
var _sun_motes: CPUParticles3D
var _spark_pool: Array[CPUParticles3D] = []
var _spark_idx: int = 0

static var _soft_quad: QuadMesh
static var _slash_arc_mesh: ArrayMesh

static func soft_particle_quad(size: float = 0.22) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	return q

static func _particle_material(tint: Color, additive: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = tint
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = _radial_soft_texture()
	return mat

static var _radial_tex: ImageTexture

static func _radial_soft_texture() -> ImageTexture:
	if _radial_tex != null:
		return _radial_tex
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var dx := (float(x) - 15.5) / 15.5
			var dy := (float(y) - 15.5) / 15.5
			var d := sqrt(dx * dx + dy * dy)
			var a := pow(clampf(1.0 - d, 0.0, 1.0), 2.1)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_radial_tex = ImageTexture.create_from_image(img)
	return _radial_tex

func setup(player: Player) -> void:
	_player = player

func _ready() -> void:
	name = "VFXManager"
	add_to_group("vfx_manager")
	_build_footstep_dust()
	_build_rain_splashes()
	_build_sun_motes()
	_build_spark_pool()
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.player_level_up.connect(func(_lv: int) -> void:
		if _player != null and is_instance_valid(_player):
			spawn_burst(_player.global_position + Vector3(0.0, 1.1, 0.0), Color(1.0, 0.90, 0.35, 1.0)))

static func _get_slash_arc_mesh() -> ArrayMesh:
	if _slash_arc_mesh != null:
		return _slash_arc_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 14
	var r_inner := 0.85
	var r_outer := 1.78
	var span := deg_to_rad(132.0)
	for i in segs:
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var a0 := -span * 0.5 + span * t0
		var a1 := -span * 0.5 + span * t1
		var fade0 := sin(t0 * PI)
		var fade1 := sin(t1 * PI)
		var p0_in := Vector3(sin(a0) * r_inner, 0.0, -cos(a0) * r_inner)
		var p0_out := Vector3(sin(a0) * (r_inner + (r_outer - r_inner) * (0.45 + 0.55 * fade0)), 0.0, -cos(a0) * (r_inner + (r_outer - r_inner) * (0.45 + 0.55 * fade0)))
		var p1_in := Vector3(sin(a1) * r_inner, 0.0, -cos(a1) * r_inner)
		var p1_out := Vector3(sin(a1) * (r_inner + (r_outer - r_inner) * (0.45 + 0.55 * fade1)), 0.0, -cos(a1) * (r_inner + (r_outer - r_inner) * (0.45 + 0.55 * fade1)))
		st.set_color(Color(1.0, 1.0, 1.0, fade0 * 0.15))
		st.add_vertex(p0_in)
		st.set_color(Color(1.0, 1.0, 1.0, fade0 * 0.92))
		st.add_vertex(p0_out)
		st.set_color(Color(1.0, 1.0, 1.0, fade1 * 0.92))
		st.add_vertex(p1_out)

		st.set_color(Color(1.0, 1.0, 1.0, fade0 * 0.15))
		st.add_vertex(p0_in)
		st.set_color(Color(1.0, 1.0, 1.0, fade1 * 0.92))
		st.add_vertex(p1_out)
		st.set_color(Color(1.0, 1.0, 1.0, fade1 * 0.15))
		st.add_vertex(p1_in)
	_slash_arc_mesh = st.commit()
	return _slash_arc_mesh

func spawn_slash_arc(world_pos: Vector3, yaw: float, tilt_deg: float = 0.0, scale_mult: float = 1.0, tint: Color = Color(0.95, 0.90, 0.72, 0.85)) -> void:
	var arc := MeshInstance3D.new()
	arc.mesh = _get_slash_arc_mesh()
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = tint
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	arc.material_override = mat
	add_child(arc)
	arc.global_position = world_pos
	arc.rotation = Vector3(0.0, yaw - 0.32, deg_to_rad(tilt_deg))
	arc.scale = Vector3.ONE * (0.78 * scale_mult)
	var tw := arc.create_tween()
	tw.set_parallel(true)
	tw.tween_property(arc, "rotation:y", yaw + 0.36, 0.20)
	tw.tween_property(arc, "scale", Vector3.ONE * (1.16 * scale_mult), 0.20)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.21)
	tw.chain().tween_callback(arc.queue_free)

func _build_sun_motes() -> void:
	_sun_motes = CPUParticles3D.new()
	_sun_motes.name = "AmbientSunMotes"
	_sun_motes.amount = 22
	_sun_motes.lifetime = 3.6
	_sun_motes.emitting = true
	_sun_motes.local_coords = false
	_sun_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var q := soft_particle_quad(0.09)
	q.material = _particle_material(Color(1.0, 0.94, 0.74, 0.48), true)
	_sun_motes.mesh = q
	_sun_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_sun_motes.emission_box_extents = Vector3(11.0, 3.2, 11.0)
	_sun_motes.direction = Vector3(0.3, 0.4, 0.2)
	_sun_motes.spread = 180.0
	_sun_motes.gravity = Vector3(0.0, 0.08, 0.0)
	_sun_motes.initial_velocity_min = 0.08
	_sun_motes.initial_velocity_max = 0.26
	add_child(_sun_motes)

func _build_footstep_dust() -> void:
	_dust_particles = CPUParticles3D.new()
	_dust_particles.name = "FootstepDust"
	_dust_particles.amount = 18
	_dust_particles.lifetime = 0.55
	_dust_particles.emitting = false
	_dust_particles.local_coords = false
	_dust_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var q := soft_particle_quad(0.28)
	q.material = _particle_material(Color(0.76, 0.70, 0.58, 0.42), false)
	_dust_particles.mesh = q
	_dust_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_dust_particles.emission_sphere_radius = 0.22
	_dust_particles.direction = Vector3(0.0, 1.0, 0.0)
	_dust_particles.spread = 42.0
	_dust_particles.gravity = Vector3(0.0, 0.8, 0.0)
	_dust_particles.initial_velocity_min = 0.35
	_dust_particles.initial_velocity_max = 0.85
	_dust_particles.scale_amount_min = 0.65
	_dust_particles.scale_amount_max = 1.35
	add_child(_dust_particles)

func _build_rain_splashes() -> void:
	_rain_splash = CPUParticles3D.new()
	_rain_splash.name = "RainSplashes"
	_rain_splash.amount = 28
	_rain_splash.lifetime = 0.32
	_rain_splash.emitting = false
	_rain_splash.local_coords = false
	_rain_splash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var q := soft_particle_quad(0.16)
	q.material = _particle_material(Color(0.78, 0.88, 1.0, 0.50), true)
	_rain_splash.mesh = q
	_rain_splash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain_splash.emission_box_extents = Vector3(9.0, 0.05, 9.0)
	_rain_splash.direction = Vector3(0.0, 1.0, 0.0)
	_rain_splash.spread = 25.0
	_rain_splash.gravity = Vector3(0.0, -4.5, 0.0)
	_rain_splash.initial_velocity_min = 0.8
	_rain_splash.initial_velocity_max = 1.6
	add_child(_rain_splash)

func _build_spark_pool() -> void:
	for i in 5:
		var sp := CPUParticles3D.new()
		sp.name = "HitSpark_%d" % i
		sp.one_shot = true
		sp.explosiveness = 0.92
		sp.amount = 14
		sp.lifetime = 0.36
		sp.emitting = false
		sp.local_coords = false
		sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var q := soft_particle_quad(0.18)
		q.material = _particle_material(Color(1.0, 0.82, 0.36, 0.92), true)
		sp.mesh = q
		sp.direction = Vector3(0.0, 1.0, 0.0)
		sp.spread = 135.0
		sp.gravity = Vector3(0.0, -8.5, 0.0)
		sp.initial_velocity_min = 2.6
		sp.initial_velocity_max = 5.4
		sp.scale_amount_min = 0.55
		sp.scale_amount_max = 1.25
		add_child(sp)
		_spark_pool.append(sp)

func spawn_burst(world_pos: Vector3, tint: Color = Color(1.0, 0.82, 0.36, 0.95)) -> void:
	if _spark_pool.is_empty():
		return
	var sp := _spark_pool[_spark_idx % _spark_pool.size()]
	_spark_idx += 1
	sp.global_position = world_pos
	if sp.mesh != null and sp.mesh.material is StandardMaterial3D:
		(sp.mesh.material as StandardMaterial3D).albedo_color = tint
	sp.restart()
	sp.emitting = true

func _on_damage_dealt(target: Node, _amount: float, is_crit: bool) -> void:
	if target is Node3D:
		var pos := (target as Node3D).global_position + Vector3(0.0, 1.0, 0.0)
		var col := Color(1.0, 0.46, 0.20, 1.0) if is_crit else Color(1.0, 0.84, 0.38, 0.92)
		spawn_burst(pos, col)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		if _dust_particles != null:
			_dust_particles.emitting = false
		if _rain_splash != null:
			_rain_splash.emitting = false
		return
	var hvel := Vector2(_player.velocity.x, _player.velocity.z).length()
	if _dust_particles != null:
		_dust_particles.global_position = _player.global_position + Vector3(0.0, 0.08, 0.0)
		_dust_particles.emitting = _player.is_on_floor() and hvel > 2.2
	if _rain_splash != null and GameManager != null:
		_rain_splash.global_position = _player.global_position + Vector3(0.0, 0.08, 0.0)
		_rain_splash.emitting = (GameManager.world.weather == "rain" and _player.zone == "village")
	if _sun_motes != null and GameManager != null:
		_sun_motes.global_position = _player.global_position + Vector3(0.0, 1.8, 0.0)
		_sun_motes.emitting = (GameManager.world.weather != "rain" and _player.zone == "village")
