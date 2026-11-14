class_name Creature
extends CharacterBody3D
## Eldoria Wildlife, Monster, Elite & Multi-Phase Dungeon Boss AI.
## Preserves 100% of v0.1 contracts (setup, health: HealthComponent, uid, home,
## aggro, state: String, take_hit, defense_value) while adding passive fleeing
## wildlife, Frost slow, knockback, Elite auras, and Malakor's 2-phase boss fight.

const GRAVITY := 22.0
const MODEL_YAW_OFFSET := PI
const DEATH_FREE_DELAY := 2.8
## Monsters are sized against the 1.3 m heroes (see CharacterVisual.HUMAN_SCALE).
const WORLD_SCALE := 0.74

var data: CreatureData
var uid: String = ""
var home: Vector3 = Vector3.ZERO
var health: HealthComponent
var anim: CharacterVisual
var model_root: Node3D
var aggro: bool = false
var state: String = "idle"

var _attack_cooldown: float = 0.0
var _dead: bool = false
var dead: bool:
	get:
		return _dead
var passive: bool:
	get:
		return data != null and not data.hostile
var _wander_target: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _flee_timer: float = 0.0
var _slow_timer: float = 0.0
var _slow_mult: float = 1.0
var _time: float = 0.0
var _speed_now: float = 0.0
var _distant_accum: float = 0.0
var _boss_hp_sent: float = -1.0
var _boss_phase_sent: int = -1
var _boss_emit_timer: float = 0.0
var _steer_timer: float = 0.0
var _steered_dir: Vector3 = Vector3.ZERO
var _hp_label: Label3D
var _boss_phase: int = 1
var _boss_nova_timer: float = 5.5
var _boss_casting_nova: float = 0.0
var _boss_telegraph: MeshInstance3D
var _player_cache: Player

func _ready() -> void:
	add_to_group("creature")
	add_to_group(Combat.DAMAGEABLE_GROUP)
	collision_layer = CollisionLayers.CREATURE
	collision_mask = CollisionLayers.MASK_CREATURE_SOLID
	if data == null:
		data = CreatureDB.get_creature("skeleton_forest")
	_player_cache = get_tree().get_first_node_in_group("player") as Player
	_build()

func setup(creature_data: CreatureData, creature_uid: String, home_position: Vector3) -> void:
	data = creature_data
	uid = creature_uid
	home = home_position

func _build() -> void:
	var capsule := CapsuleShape3D.new()
	if data.visual_type == "slime":
		capsule.radius = 0.5
		capsule.height = 0.9
	elif data.visual_type == "wolf" or data.visual_type == "stag":
		capsule.radius = 0.42
		capsule.height = 1.25
	else:
		capsule.radius = 0.44
		capsule.height = 1.85
	var size_mult := WORLD_SCALE * (1.25 if data.is_boss else 1.0)
	capsule.radius *= size_mult
	capsule.height = maxf(capsule.height * size_mult, capsule.radius * 2.0 + 0.05)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	shape.shape = capsule
	shape.position = Vector3(0.0, capsule.height * 0.5, 0.0)
	add_child(shape)

	health = HealthComponent.new()
	health.name = "Health"
	health.setup(data.max_health)
	add_child(health)
	health.died.connect(_die)

	if data.model_path.is_empty():
		model_root = ProceduralModels.build(data.visual_type)
		model_root.name = "Visual"
		model_root.rotation.y = MODEL_YAW_OFFSET
		model_root.scale = Vector3.ONE * data.body_scale * WORLD_SCALE
		add_child(model_root)
	else:
		var candidate := CharacterVisual.new()
		candidate.name = "Visual"
		candidate.rotation.y = MODEL_YAW_OFFSET
		add_child(candidate)
		if candidate.setup(data.model_path, data.body_scale * WORLD_SCALE):
			candidate.position.y = data.model_y_offset * WORLD_SCALE
			if data.tint_color != Color.WHITE:
				candidate.tint(data.tint_color)
			if candidate.anim_player != null:
				anim = candidate
				model_root = candidate
				anim.play("idle")
			else:
				model_root = candidate
		else:
			candidate.queue_free()
			model_root = ProceduralModels.build("slime")
			add_child(model_root)

	_build_aura_and_label()
	_apply_lod_recursive(self, 42.0)
	EventBus.language_changed.connect(func(_l: String) -> void: _refresh_hp_label())
	_wander_target = home

func _apply_lod_recursive(node: Node, max_dist: float) -> void:
	if node is GeometryInstance3D:
		var gi := node as GeometryInstance3D
		if gi.visibility_range_end <= 0.0:
			gi.visibility_range_end = max_dist
			gi.visibility_range_end_margin = 3.0
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c: Node in node.get_children():
		_apply_lod_recursive(c, max_dist)

func _build_aura_and_label() -> void:
	_hp_label = Label3D.new()
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.font_size = 28 if data.is_boss else 22
	_hp_label.outline_size = 7
	_hp_label.modulate = Color(1.0, 0.52, 0.52) if data.is_boss else (Color(0.65, 0.88, 1.0) if data.is_elite else Color(0.95, 0.90, 0.84))
	_hp_label.position = Vector3(0.0, (2.55 if data.is_boss else 2.05) * WORLD_SCALE + 0.15, 0.0)
	_hp_label.visible = data.is_boss or data.is_elite
	add_child(_hp_label)
	_refresh_hp_label()

	if data.is_boss or data.is_elite:
		var glow := OmniLight3D.new()
		glow.light_color = Color(0.96, 0.28, 0.36) if data.is_boss else Color(0.45, 0.76, 1.0)
		glow.light_energy = 1.25 if data.is_boss else 0.7
		glow.omni_range = 6.0 if data.is_boss else 3.6
		glow.shadow_enabled = false
		glow.position = Vector3(0.0, 1.2, 0.0)
		add_child(glow)

	if data.is_boss:
		_boss_telegraph = MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 4.3
		cyl.bottom_radius = 4.3
		cyl.height = 0.05
		_boss_telegraph.mesh = cyl
		_boss_telegraph.position = Vector3(0.0, 0.06, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.22, 0.28, 0.45)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_boss_telegraph.material_override = mat
		_boss_telegraph.visible = false
		add_child(_boss_telegraph)

func apply_slow(mult: float, duration: float) -> void:
	_slow_mult = clampf(mult, 0.35, 1.0)
	_slow_timer = maxf(_slow_timer, duration)

func _physics_process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	if _dead:
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	var player := _find_player()
	var distance := INF
	if player != null and player.is_visible_in_tree():
		distance = global_position.distance_to(player.global_position)
		# Animation LOD: nothing is drawn or animated beyond ~46 m.
		if anim != null:
			anim.set_lod_active(distance < 46.0 or data.is_boss)
		if distance > 40.0 and not data.is_boss and not aggro:
			_distant_accum += delta
			if _distant_accum < 0.30:
				return
			delta = _distant_accum
			_distant_accum = 0.0

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_flee_timer = maxf(0.0, _flee_timer - delta)
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_mult = 1.0

	if data.hostile and player != null and not player.dead and distance <= data.aggro_radius:
		if not aggro:
			if anim != null:
				anim.play("taunt", true)
			EventBus.creature_aggro.emit(self)
		aggro = true
	if aggro and (player == null or player.dead or distance > data.aggro_radius * 2.4
			or global_position.distance_to(home) > data.leash_radius):
		aggro = false
		if data.is_boss:
			_boss_hp_sent = -1.0
			EventBus.boss_health_changed.emit(data.display_name, health.current_health, health.max_health, _boss_phase, false)

	if data.is_boss and aggro and player != null:
		_tick_boss_phase(delta, player, distance)

	var planar_speed := 0.0
	if _flee_timer > 0.0 and player != null:
		state = "flee"
		var away := global_position - player.global_position
		away.y = 0.0
		if away.length_squared() < 0.01:
			away = Vector3.FORWARD
		planar_speed = _move_towards(global_position + away.normalized() * 6.0, data.move_speed * 1.35 * _slow_mult)
	elif aggro and player != null:
		if distance <= data.attack_range:
			state = "attack"
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if _boss_casting_nova <= 0.0:
				_try_attack(player)
		else:
			state = "chase"
			var spd := data.move_speed * (1.22 if _boss_phase == 2 else 1.0) * _slow_mult
			planar_speed = _move_towards(player.global_position, spd)
	else:
		state = "idle"
		planar_speed = _wander(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_speed_now = planar_speed
	_animate()

func _tick_boss_phase(delta: float, player: Player, distance: float) -> void:
	var cname := Localization.creature_name(data)
	# Only tell the HUD when the bar would actually change (this used to fire
	# sixty times a second for the whole fight).
	var hp_now := health.current_health
	_boss_emit_timer += delta
	if not is_equal_approx(hp_now, _boss_hp_sent) or _boss_phase != _boss_phase_sent or _boss_emit_timer >= 0.5:
		_boss_emit_timer = 0.0
		_boss_hp_sent = hp_now
		_boss_phase_sent = _boss_phase
		EventBus.boss_health_changed.emit(cname, hp_now, health.max_health, _boss_phase, true)
	if _boss_phase == 1 and health.ratio() <= 0.55:
		_boss_phase = 2
		EventBus.notify.emit(("%s يدخل المرحلة الثانية — غضب السرداب القرمزي!" % cname) if Localization.is_arabic() else ("%s enters Phase II — Crimson Dread!" % cname))
		if AudioManager != null:
			AudioManager.play_sfx("magic_cast", 0.0, 0.75)

	if _boss_casting_nova > 0.0:
		_boss_casting_nova -= delta
		if _boss_telegraph != null:
			_boss_telegraph.visible = true
			var p := 0.92 + sin(_time * 18.0) * 0.08
			_boss_telegraph.scale = Vector3(p, 1.0, p)
		if _boss_casting_nova <= 0.0:
			if _boss_telegraph != null:
				_boss_telegraph.visible = false
			if distance <= 4.3:
				var info := GameManager.compute_damage(data.damage * 1.45, player.defense_value(), false)
				player.take_hit(float(info.get("amount", 0.0)), self, true)
			if AudioManager != null:
				AudioManager.play_sfx("sword_heavy", -1.0, 0.82)
		return

	_boss_nova_timer -= delta
	if _boss_nova_timer <= 0.0 and distance <= 6.2:
		_boss_nova_timer = 5.2 if _boss_phase == 2 else 7.5
		_boss_casting_nova = 1.05
		if anim != null:
			anim.play("cast", true)

func _find_player() -> Player:
	if _player_cache != null and is_instance_valid(_player_cache):
		return _player_cache
	_player_cache = get_tree().get_first_node_in_group("player") as Player
	return _player_cache

func _move_towards(target: Vector3, speed: float) -> float:
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.05:
		return 0.0
	var desired := to_target.normalized()
	var dir := _steer_direction(desired)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.18)
	return speed

func _steer_direction(desired: Vector3) -> Vector3:
	_steer_timer -= get_physics_process_delta_time()
	if _steer_timer > 0.0 and _steered_dir != Vector3.ZERO and _steered_dir.dot(desired) > 0.25:
		return _steered_dir
	_steer_timer = 0.12
	var w3d := get_world_3d()
	if w3d == null or w3d.direct_space_state == null:
		_steered_dir = desired
		return desired
	var origin := global_position + Vector3(0.0, 0.65, 0.0)
	var look := 1.65
	var q0 := PhysicsRayQueryParameters3D.create(origin, origin + desired * look, 1)
	if w3d.direct_space_state.intersect_ray(q0).is_empty():
		_steered_dir = desired
		return desired
	for ang: float in [0.65, -0.65, 1.25, -1.25]:
		var alt := desired.rotated(Vector3.UP, ang)
		var qa := PhysicsRayQueryParameters3D.create(origin, origin + alt * look, 1)
		if w3d.direct_space_state.intersect_ray(qa).is_empty():
			_steered_dir = alt
			return alt
	_steered_dir = desired
	return desired

func _wander(delta: float) -> float:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(4.0, 9.0)
		var angle := randf() * TAU
		_wander_target = home + Vector3(cos(angle), 0.0, sin(angle)) * randf_range(1.5, 5.5)
	var to_target := _wander_target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.6:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		return 0.0
	var dir := _steer_direction(to_target.normalized())
	var speed := data.move_speed * 0.32 * _slow_mult
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.10)
	return speed

func _try_attack(player: Player) -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = data.attack_cooldown * (0.78 if _boss_phase == 2 else 1.0)
	if anim != null:
		var clips := ["attack_1", "attack_2", "attack_3", "attack_heavy"]
		anim.play(clips[randi() % clips.size()], true)
	var vfx := get_tree().get_first_node_in_group("vfx_manager")
	if vfx != null and vfx.has_method("spawn_slash_arc") and (data.is_boss or data.id.begins_with("skeleton")):
		vfx.call("spawn_slash_arc", global_position + Vector3(0.0, 1.05, 0.0), rotation.y + PI,
			-18.0, 1.65 if data.is_boss else 1.25, Color(1.0, 0.28, 0.24, 0.85))
	if AudioManager != null:
		AudioManager.play_sfx("monster_attack", -3.0, randf_range(0.9, 1.1))
	var dmg := data.damage * (1.18 if _boss_phase == 2 else 1.0)
	var info := GameManager.compute_damage(dmg, player.defense_value(), false)
	player.take_hit(float(info.get("amount", 0.0)), self, false)

func _animate() -> void:
	if model_root == null:
		return
	if anim != null:
		if _boss_casting_nova > 0.0:
			return
		if state == "attack":
			anim.play("attack_1")
		elif _speed_now > 0.1:
			anim.play("run" if _speed_now > data.move_speed * 0.7 else "walk")
		else:
			anim.play("idle")
	else:
		ProceduralModels.animate(model_root, data.visual_type, _time, _speed_now, data.model_y_offset * WORLD_SCALE)

func take_hit(amount: float, source: Node, is_crit: bool = false) -> void:
	if _dead:
		return
	health.take_damage(amount)
	if _hp_label != null:
		_hp_label.visible = true
		_refresh_hp_label()
	EventBus.damage_dealt.emit(self, amount, is_crit)
	if source is Node3D and not data.is_boss:
		var push := global_position - (source as Node3D).global_position
		push.y = 0.0
		if push.length_squared() > 0.01:
			velocity += push.normalized() * 3.8
	if data.flee_when_hurt and not data.hostile:
		_flee_timer = 4.2
	else:
		aggro = true
	if anim != null and not health.is_dead():
		anim.play("hit", true)

func _refresh_hp_label() -> void:
	if _hp_label == null or health == null or data == null:
		return
	var pfx := "☠ " if data.is_boss else ("★ " if data.is_elite else "")
	_hp_label.text = "%s%s  %d/%d" % [pfx, Localization.creature_name(data), int(ceil(health.current_health)), int(ceil(health.max_health))]

func defense_value() -> float:
	return data.defense

func _die() -> void:
	if _dead:
		return
	_dead = true
	state = "dead"
	collision_layer = 0
	collision_mask = 0
	aggro = false
	if _hp_label != null:
		_hp_label.visible = false
	if _boss_telegraph != null:
		_boss_telegraph.visible = false
	if data.is_boss:
		EventBus.boss_health_changed.emit(data.display_name, 0.0, health.max_health, _boss_phase, false)
	if AudioManager != null:
		AudioManager.play_sfx("monster_die")
	if anim != null:
		anim.play_once("death")
	elif model_root != null:
		var tween := create_tween()
		tween.tween_property(model_root, "scale", Vector3(1.2, 0.08, 1.2), 0.45)
	GameManager.world.mark_dead(uid)
	GameManager.gain_xp(data.xp_reward)
	var gold_amt := int(round(float(data.gold_reward) * GameManager.skills.loot_gold_multiplier()))
	GameManager.gain_gold(gold_amt)
	var drops := data.roll_loot(_loot_rng())
	_spawn_loot(drops)
	EventBus.creature_died.emit(data.id, uid, global_position)
	await get_tree().create_timer(DEATH_FREE_DELAY).timeout
	queue_free()

func _loot_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(uid) + GameManager.world.day * 977
	rng.randomize()
	return rng

func _spawn_loot(drops: Array) -> void:
	if drops.is_empty():
		return
	var world := get_tree().get_first_node_in_group("world_root")
	if world == null or not world.has_method("spawn_loot_drop") or data.is_boss:
		for drop: Dictionary in drops:
			GameManager.gain_item(String(drop.get("id", "")), int(drop.get("count", 1)))
		return
	world.call("spawn_loot_drop", drops, global_position + Vector3(0.0, 0.2, 0.0))
