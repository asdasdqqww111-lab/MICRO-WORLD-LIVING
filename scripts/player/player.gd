class_name Player
extends CharacterBody3D
## Third-person Knight Hero controller for Eldoria.
## Preserves 100% of v0.1 public API (health: HealthComponent, stamina, visual,
## camera_rig, input, zone, dead, try_attack, take_hit, teleport, set_zone, etc.)
## while adding Knight.glb rig + dynamic gear sync, Mana/Spellcasting, Heavy Cleave,
## Dodge Roll i-frames, Shield Block mitigation, Quick Potion, and SFX.

signal zone_changed(zone_id: String)

const MODEL_PATH := "res://assets/kaykit_adventurers/Knight.glb"
const FALLBACK_MODEL_PATH := "res://assets/characters/player/Knight.glb"
const MODEL_YAW_OFFSET := PI
const MODEL_SCALE := 0.76

const WALK_SPEED := 4.6
const RUN_SPEED := 7.4
const DODGE_SPEED := 9.4
const ACCELERATION := 16.0
const AIR_ACCELERATION := 6.0
const TURN_SPEED := 13.0
const JUMP_VELOCITY := 7.4
const GRAVITY := 22.0
const CAPSULE_HEIGHT := 1.75
const CAPSULE_RADIUS := 0.34
const EYE_HEIGHT := 1.15

const ATTACK_REACH := 2.4
const HEAVY_REACH := 3.0
const ATTACK_ARC := 125.0
const ATTACK_COST := 12.0
const HEAVY_COST := 22.0
const DODGE_COST := 18.0
const BASE_SPELL_MANA := 16.0
const ATTACK_DURATION := 0.44
const HEAVY_DURATION := 0.72
const SPELL_DURATION := 0.65
const COMBO_WINDOW := 0.95
const STAMINA_REGEN := 18.5
const MANA_REGEN := 6.0
const SPRINT_STAMINA_COST := 12.0
const INVULN_TIME := 0.45

var health: HealthComponent
var stamina: float = 100.0
var mana: float = 60.0
var visual: CharacterVisual
var camera_rig: CameraRig
var input := PlayerInput.new()
var zone: String = "village"
var dead: bool = false
var is_blocking: bool = false
var locked_target: Node3D = null
var state_machine := PlayerStateMachine.new()

var _loaded_class_id: String = ""
var _target_ring: MeshInstance3D
var _ring_spin: float = 0.0
var _attack_timer: float = 0.0
var _spell_timer: float = 0.0
var _dodge_timer: float = 0.0
var _dodge_dir: Vector3 = Vector3.FORWARD
var _attack_index: int = 0
var _combo_reset: float = 0.0
var _invuln: float = 0.0
var _land_timer: float = 0.0
var _footstep_timer: float = 0.0
var _was_on_floor: bool = true
var _nearest: Interactable = null
var _spawn_position := Vector3(0.0, 1.2, 16.0)

func _ready() -> void:
	add_to_group("player")
	add_to_group(Combat.DAMAGEABLE_GROUP)
	CollisionLayers.configure_player_body(self)
	_build_collision()
	_build_visual()
	add_child(ArtDirection.make_contact_ao(0.56, 0.38))
	_build_target_ring()
	_build_camera()
	_build_health()
	stamina = GameManager.max_stamina()
	mana = GameManager.max_mana()
	_emit_vitals()
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.skill_tree_changed.connect(_on_stats_updated)
	EventBus.equipment_changed.connect(_sync_equipment_visuals)
	EventBus.hero_class_changed.connect(_on_hero_class_changed)
	if GameManager.inventory != null and not GameManager.inventory.equipment_changed.is_connected(_sync_equipment_visuals):
		GameManager.inventory.equipment_changed.connect(_sync_equipment_visuals)
	_sync_equipment_visuals()

func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.height = CAPSULE_HEIGHT
	capsule.radius = CAPSULE_RADIUS
	shape.shape = capsule
	shape.position = Vector3(0.0, CAPSULE_HEIGHT * 0.5, 0.0)
	add_child(shape)

func _build_visual() -> void:
	visual = CharacterVisual.new()
	visual.name = "Visual"
	visual.rotation.y = MODEL_YAW_OFFSET
	add_child(visual)
	_loaded_class_id = GameManager.hero_class if GameManager != null else "knight"
	var class_model := HeroClassDB.model_for(_loaded_class_id)
	var chosen := class_model if AssetLibrary.has_model(class_model) else (MODEL_PATH if AssetLibrary.has_model(MODEL_PATH) else FALLBACK_MODEL_PATH)
	if not visual.setup(chosen, MODEL_SCALE):
		push_warning("Player: character model missing")

func _on_hero_class_changed(new_class: String) -> void:
	if new_class == _loaded_class_id and visual != null:
		_sync_equipment_visuals()
		return
	if visual != null:
		remove_child(visual)
		visual.queue_free()
		visual = null
	_build_visual()
	_sync_equipment_visuals()
	_on_stats_updated()

func _build_target_ring() -> void:
	_target_ring = MeshInstance3D.new()
	_target_ring.name = "TargetLockRing"
	_target_ring.top_level = true
	_target_ring.visible = false
	_target_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var torus := TorusMesh.new()
	torus.inner_radius = 0.62
	torus.outer_radius = 0.78
	torus.rings = 18
	torus.ring_segments = 8
	_target_ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.82, 0.28, 0.92)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_target_ring.material_override = mat
	add_child(_target_ring)

func _sync_equipment_visuals() -> void:
	if visual != null and GameManager != null and GameManager.inventory != null:
		visual.sync_player_equipment(GameManager.inventory, GameManager.hero_class)

func _build_camera() -> void:
	camera_rig = CameraRig.new()
	camera_rig.name = "CameraRig"
	camera_rig.height_offset = EYE_HEIGHT
	add_child(camera_rig)

func _build_health() -> void:
	health = HealthComponent.new()
	health.name = "Health"
	health.max_health = GameManager.max_health()
	health.current_health = GameManager.max_health()
	add_child(health)
	health.damaged.connect(_on_health_damaged)
	health.healed.connect(_on_health_healed)
	health.died.connect(_on_health_died)

func _physics_process(delta: float) -> void:
	if dead:
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)
	_spell_timer = maxf(0.0, _spell_timer - delta)
	_dodge_timer = maxf(0.0, _dodge_timer - delta)
	_combo_reset = maxf(0.0, _combo_reset - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_land_timer = maxf(0.0, _land_timer - delta)

	var move := input.move_vector()
	var yaw := camera_rig.yaw
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var direction := (right * move.x + forward * (-move.y))
	if direction.length() > 0.05:
		direction = direction.normalized()
	else:
		direction = Vector3.ZERO

	is_blocking = input.is_blocking() and _dodge_timer <= 0.0 and _attack_timer <= 0.0 and stamina > 4.0
	var sprinting := input.is_sprinting() and not is_blocking and direction != Vector3.ZERO and stamina > 4.0 and _dodge_timer <= 0.0

	if _dodge_timer > 0.0:
		velocity.x = _dodge_dir.x * DODGE_SPEED
		velocity.z = _dodge_dir.z * DODGE_SPEED
	else:
		var speed := (RUN_SPEED if sprinting else WALK_SPEED) * GameManager.move_speed_multiplier()
		if _attack_timer > 0.0:
			speed *= 0.35
		elif is_blocking:
			speed *= 0.50
		var target := direction * speed
		var accel := ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, target.x, accel * delta * 6.0)
		velocity.z = move_toward(velocity.z, target.z, accel * delta * 6.0)

	if sprinting:
		stamina = maxf(0.0, stamina - SPRINT_STAMINA_COST * delta)
		EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif input.jump_pressed() and _dodge_timer <= 0.0:
		velocity.y = JUMP_VELOCITY
		if AudioManager != null:
			AudioManager.play_sfx("jump_land", -4.0, 1.15)

	var face_dir := _dodge_dir if _dodge_timer > 0.0 else direction
	if locked_target != null and is_instance_valid(locked_target) and _dodge_timer <= 0.0 and not sprinting:
		_face_locked_target()
	elif face_dir != Vector3.ZERO and _attack_timer <= 0.0:
		var target_yaw := atan2(-face_dir.x, -face_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(TURN_SPEED * delta, 0.0, 1.0))

	move_and_slide()

	var now_floor := is_on_floor()
	if now_floor and not _was_on_floor:
		_land_timer = 0.16
		if AudioManager != null:
			AudioManager.play_sfx("jump_land", -3.0, 0.92)
	_was_on_floor = now_floor

	var planar := Vector2(velocity.x, velocity.z).length()
	if now_floor and planar > 1.2 and _dodge_timer <= 0.0:
		_footstep_timer -= delta * (1.42 if sprinting else 1.0)
		if _footstep_timer <= 0.0:
			_footstep_timer = 0.40
			var surface := _detect_surface()
			if AudioManager != null:
				AudioManager.play_footstep(surface, sprinting)

	if input.lock_target_pressed():
		toggle_target_lock()
	if input.dodge_pressed():
		try_dodge(direction)
	if input.attack_pressed():
		try_attack()
	if input.heavy_attack_pressed():
		try_heavy_attack()
	if input.spell_pressed():
		try_cast_spell()
	if input.potion_pressed():
		try_quick_potion()
	if input.interact_pressed() and _nearest != null:
		visual.play("interact", true)
		_nearest.interact(self)
	if Input.is_action_just_pressed("camera_recenter") and camera_rig != null:
		camera_rig.recenter_behind(rotation.y)

	_enforce_anti_clip_safety()
	_update_target_lock(delta)
	_update_vitals_regen(delta)
	_update_interactable()
	state_machine.evaluate(delta, dead, _dodge_timer, _attack_timer, _spell_timer, is_blocking, is_on_floor(), sprinting, planar)
	_update_animation(sprinting, planar)

func _enforce_anti_clip_safety() -> void:
	if zone == "village":
		global_position.x = clampf(global_position.x, -114.5, 114.5)
		global_position.z = clampf(global_position.z, -114.5, 114.5)
		var wr := get_tree().get_first_node_in_group("world_root") as WorldRoot
		if wr != null and wr.terrain != null:
			var min_y := wr.terrain.height_at(global_position.x, global_position.z) - 0.85
			if global_position.y < min_y:
				global_position.y = min_y + 0.90
				velocity.y = maxf(0.0, velocity.y)
		# Check outdoor landmark visit triggers for Exploration & Story Quests
		var p2 := Vector2(global_position.x, global_position.z)
		if p2.distance_to(Vector2(66.0, -18.0)) < 11.5:
			GameManager.report_visit("ruins")
		elif p2.distance_to(Vector2(-62.0, -24.0)) < 11.5:
			GameManager.report_visit("monster_camp")
		elif p2.distance_to(Vector2(-56.0, 44.0)) < 11.5:
			GameManager.report_visit("sacred_grove")
		elif p2.distance_to(Vector2(-14.0, -60.0)) < 11.5:
			GameManager.report_visit("cave")
	else:
		if global_position.y < -3.5:
			global_position.y = 0.25
			velocity.y = 0.0

func toggle_target_lock() -> Node3D:
	var candidates: Array[Node3D] = []
	for n: Node in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c == null or not c.is_visible_in_tree() or c.health == null or c.health.is_dead():
			continue
		if c.data != null and not c.data.hostile and not c.aggro:
			continue
		if global_position.distance_to(c.global_position) <= 18.5:
			candidates.append(c)
	if candidates.is_empty():
		clear_target_lock()
		return null
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	if locked_target != null and is_instance_valid(locked_target):
		var idx := candidates.find(locked_target)
		if idx >= 0 and idx + 1 < candidates.size():
			locked_target = candidates[idx + 1]
		else:
			clear_target_lock()
			return null
	else:
		locked_target = candidates[0]
	if AudioManager != null:
		AudioManager.play_sfx("ui_click", -3.0, 1.2)
	EventBus.target_locked_changed.emit(locked_target)
	return locked_target

func clear_target_lock() -> void:
	if locked_target != null:
		locked_target = null
		EventBus.target_locked_changed.emit(null)
	if _target_ring != null:
		_target_ring.visible = false

func _face_locked_target() -> void:
	if locked_target == null or not is_instance_valid(locked_target):
		return
	var to_t := locked_target.global_position - global_position
	to_t.y = 0.0
	if to_t.length_squared() > 0.04:
		rotation.y = atan2(-to_t.x, -to_t.z)

func _update_target_lock(delta: float) -> void:
	if locked_target == null:
		if _target_ring != null:
			_target_ring.visible = false
		return
	var valid := is_instance_valid(locked_target) and locked_target.is_inside_tree() and locked_target.is_visible_in_tree()
	if valid and locked_target is Creature:
		var c := locked_target as Creature
		if c.health == null or c.health.is_dead():
			valid = false
	if valid and global_position.distance_to(locked_target.global_position) > 22.0:
		valid = false
	if not valid:
		clear_target_lock()
		# Auto-acquire next nearby aggroed foe if one is right in front of us
		for n: Node in get_tree().get_nodes_in_group("creature"):
			var c2 := n as Creature
			if c2 != null and c2.aggro and c2.health != null and not c2.health.is_dead() and global_position.distance_to(c2.global_position) <= 12.0:
				locked_target = c2
				EventBus.target_locked_changed.emit(locked_target)
				break
		if locked_target == null:
			return
	_ring_spin += delta * 2.4
	if _target_ring != null:
		_target_ring.visible = true
		_target_ring.global_position = locked_target.global_position + Vector3(0.0, 0.08, 0.0)
		_target_ring.rotation = Vector3(0.0, _ring_spin, 0.0)
	if camera_rig != null and not Input.is_action_pressed("camera_drag"):
		camera_rig.soft_track_target(locked_target.global_position, delta)

func _update_vitals_regen(delta: float) -> void:
	var regen_mult := GameManager.skills.potion_multiplier()
	if _attack_timer <= 0.0 and _dodge_timer <= 0.0 and not input.is_sprinting() and not is_blocking:
		var before_s := stamina
		stamina = minf(GameManager.max_stamina(), stamina + STAMINA_REGEN * regen_mult * delta)
		if absf(stamina - before_s) > 0.05:
			EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())
	var before_m := mana
	mana = minf(GameManager.max_mana(), mana + MANA_REGEN * delta)
	if absf(mana - before_m) > 0.05:
		EventBus.player_mana_changed.emit(mana, GameManager.max_mana())

func _detect_surface() -> String:
	if zone == "house":
		return "wood"
	if zone == "guild" or zone == "dungeon":
		return "stone"
	var wr := get_tree().get_first_node_in_group("world_root") as WorldRoot
	if wr != null and wr.terrain != null:
		var gx := global_position.x
		var gz := global_position.z
		if AudioManager != null:
			AudioManager.update_biome_ambience(zone, wr.terrain.biome_at(gx, gz))
		if wr.terrain.is_water_at(gx, gz):
			return "water"
		if wr.terrain.is_road_at(gx, gz) or Vector2(gx, gz).length() <= Terrain.VILLAGE_RADIUS:
			return "stone"
	return "grass"

func _update_animation(sprinting: bool, planar: float) -> void:
	if _dodge_timer > 0.0:
		return
	if _attack_timer > 0.0 or _spell_timer > 0.25:
		return
	if is_blocking:
		visual.play("block")
		return
	if not is_on_floor():
		visual.play("jump" if velocity.y > 0.5 else "fall")
		return
	if _land_timer > 0.0 and planar < 0.8:
		visual.play("land")
		return
	if sprinting and planar > 4.5:
		visual.play("sprint")
	elif locked_target != null and is_instance_valid(locked_target) and planar > 0.45:
		var vel_xz := Vector3(velocity.x, 0.0, velocity.z).normalized()
		var fwd := (-global_transform.basis.z).normalized()
		var right := global_transform.basis.x.normalized()
		var f_dot := fwd.dot(vel_xz)
		var r_dot := right.dot(vel_xz)
		if absf(r_dot) > 0.55:
			visual.play("strafe_right" if r_dot > 0.0 else "strafe_left")
		elif f_dot < -0.35:
			visual.play("walk_back")
		else:
			visual.play("run" if planar > 5.0 else "walk")
	elif planar > 5.4:
		visual.play("run")
	elif planar > 0.35:
		visual.play("walk")
	else:
		visual.play("idle_combat" if (locked_target != null and is_instance_valid(locked_target)) else "idle")

func _update_interactable() -> void:
	var best: Interactable = null
	var best_distance := INF
	for node: Node in get_tree().get_nodes_in_group("interactable"):
		var inter := node as Interactable
		if inter == null or not inter.enabled or not inter.is_inside_tree() or not inter.is_visible_in_tree():
			continue
		var distance := global_position.distance_to(inter.global_position)
		if distance <= inter.interaction_radius and distance < best_distance:
			if not inter.can_interact(self):
				continue
			best = inter
			best_distance = distance
	if best != _nearest:
		_nearest = best
		EventBus.interact_prompt_changed.emit("" if best == null else best.prompt_for(self))

func current_interactable() -> Interactable:
	return _nearest

func try_dodge(move_dir: Vector3 = Vector3.ZERO) -> bool:
	if dead or _dodge_timer > 0.0:
		return false
	var cost := DODGE_COST * GameManager.skills.dodge_cost_multiplier()
	if stamina < cost:
		return false
	stamina = maxf(0.0, stamina - cost)
	EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())
	_dodge_timer = 0.34
	_invuln = 0.45 + GameManager.skills.bonus_total(SkillData.Effect.DODGE_BONUS) * 0.18
	var fwd := (-global_transform.basis.z).normalized()
	var right := global_transform.basis.x.normalized()
	_dodge_dir = move_dir.normalized() if move_dir.length_squared() > 0.01 else fwd
	var dodge_anim := "dodge"
	if locked_target != null and is_instance_valid(locked_target):
		if right.dot(_dodge_dir) > 0.55:
			dodge_anim = "dodge_right"
		elif right.dot(_dodge_dir) < -0.55:
			dodge_anim = "dodge_left"
		elif fwd.dot(_dodge_dir) < -0.35:
			dodge_anim = "dodge_back"
	visual.play(dodge_anim, true)
	if AudioManager != null:
		AudioManager.play_sfx("dodge_roll")
	return true

func try_attack() -> bool:
	if dead or _attack_timer > 0.0 or stamina < ATTACK_COST:
		return false
	_face_locked_target()
	_attack_index = (_attack_index + 1) % 3 if _combo_reset > 0.0 else 0
	_combo_reset = COMBO_WINDOW
	_attack_timer = ATTACK_DURATION * (1.16 if _attack_index == 2 else 1.0)
	stamina = maxf(0.0, stamina - ATTACK_COST)
	EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())
	var cls := GameManager.hero_class if GameManager != null else "knight"
	var anim_state := "attack_1"
	if _attack_index == 2:
		anim_state = "attack_3"
	elif cls == "ranger":
		anim_state = "attack_dual_1" if _attack_index == 0 else "attack_dual_2"
	elif cls == "barbarian":
		anim_state = "attack_2h_1" if _attack_index == 0 else "attack_2h_2"
	else:
		anim_state = "attack_1" if _attack_index == 0 else "attack_2"
	visual.play(anim_state, true)
	if AudioManager != null:
		if _attack_index == 2:
			AudioManager.play_sfx("sword_finisher", -1.0, 0.05)
		elif cls == "ranger":
			AudioManager.play_sfx("sword_swing_1", -2.0, 0.08)
		else:
			AudioManager.play_sfx("sword_swing", -2.0, 0.08)

	var vfx_mgr := get_tree().get_first_node_in_group("vfx_manager") as VFXManager
	if vfx_mgr != null:
		var tilt := -22.0 if _attack_index == 0 else (18.0 if _attack_index == 1 else 68.0)
		var arc_col := Color(1.0, 0.62, 0.24, 0.92) if _attack_index == 2 else Color(0.92, 0.94, 1.0, 0.78)
		vfx_mgr.spawn_slash_arc(global_position + Vector3(0.0, 1.05, 0.0), rotation.y, tilt, 1.25 if _attack_index == 2 else 1.0, arc_col)

	var multiplier := 1.0 if _attack_index == 0 else (1.24 if _attack_index == 1 else (1.58 + GameManager.skills.combo_finisher_bonus()))
	var reach := ATTACK_REACH * (1.18 if _attack_index == 2 else 1.0)
	var targets := Combat.melee_targets(self, reach, ATTACK_ARC, [get_rid()])
	for target: Node in targets:
		var defense := float(target.call("defense_value")) if target.has_method("defense_value") else 0.0
		var info := GameManager.compute_damage(GameManager.attack_power() * multiplier, defense, true)
		var dealt := float(info.get("amount", 0.0))
		Combat.apply_hit(target, dealt, self, bool(info.get("crit", false)))
		var leech := GameManager.skills.lifesteal_ratio()
		if leech > 0.0 and dealt > 0.0:
			heal(dealt * leech)
	if not targets.is_empty() and AudioManager != null:
		AudioManager.play_sfx("sword_hit")
	return true

func try_heavy_attack() -> bool:
	if dead or _attack_timer > 0.0 or stamina < HEAVY_COST:
		return false
	_face_locked_target()
	_attack_timer = HEAVY_DURATION
	_combo_reset = 0.0
	stamina = maxf(0.0, stamina - HEAVY_COST)
	EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())
	visual.play("attack_heavy", true)
	if AudioManager != null:
		AudioManager.play_sfx("sword_heavy")
	var vfx_mgr := get_tree().get_first_node_in_group("vfx_manager") as VFXManager
	if vfx_mgr != null:
		vfx_mgr.spawn_slash_arc(global_position + Vector3(0.0, 1.0, 0.0), rotation.y, 6.0, 1.55, Color(1.0, 0.52, 0.18, 0.95))
	var mult := GameManager.skills.heavy_damage_multiplier()
	var targets := Combat.melee_targets(self, HEAVY_REACH, 250.0, [get_rid()])
	for target: Node in targets:
		var defense := float(target.call("defense_value")) if target.has_method("defense_value") else 0.0
		var info := GameManager.compute_damage(GameManager.attack_power() * mult, defense, true)
		var dealt := float(info.get("amount", 0.0))
		Combat.apply_hit(target, dealt, self, bool(info.get("crit", false)))
		var leech := GameManager.skills.lifesteal_ratio()
		if leech > 0.0 and dealt > 0.0:
			heal(dealt * leech)
	if not targets.is_empty() and AudioManager != null:
		AudioManager.play_sfx("sword_hit")
	return true

func try_cast_spell() -> bool:
	if dead or _spell_timer > 0.0:
		return false
	var cost := BASE_SPELL_MANA * GameManager.skills.mana_cost_multiplier()
	if mana < cost:
		EventBus.notify.emit(Localization.tr_key("not_enough_mana"))
		return false
	mana = maxf(0.0, mana - cost)
	EventBus.player_mana_changed.emit(mana, GameManager.max_mana())
	_spell_timer = SPELL_DURATION
	visual.play("cast", true)
	var elem := GameManager.skills.active_spell_element()
	if AudioManager != null:
		match elem:
			"ice": AudioManager.play_sfx("spell_ice")
			"lightning": AudioManager.play_sfx("spell_lightning")
			_: AudioManager.play_sfx("spell_fire")

	var col := Color(0.45, 0.72, 1.0)
	match elem:
		"fire": col = Color(1.0, 0.46, 0.16)
		"ice": col = Color(0.48, 0.88, 1.0)
		"lightning": col = Color(0.96, 0.88, 0.30)

	_face_locked_target()
	var fwd := (-global_transform.basis.z).normalized()
	var origin := global_position + Vector3(0.0, 1.15, 0.0) + fwd * 0.7
	var best_t: Node3D = locked_target if (locked_target != null and is_instance_valid(locked_target)) else null
	var best_d := 13.5
	if best_t == null:
		for n: Node in get_tree().get_nodes_in_group(Combat.DAMAGEABLE_GROUP):
			if n == self or not (n is Node3D) or not (n as Node3D).is_visible_in_tree():
				continue
			var t := n as Node3D
			var dv := (t.global_position + Vector3.UP * 0.9) - origin
			if dv.length() < best_d and fwd.dot(dv.normalized()) > 0.32:
				best_d = dv.length()
				best_t = t
	var hit_pos := (best_t.global_position + Vector3.UP * 0.9) if best_t != null else (origin + fwd * 10.0)
	_spawn_spell_orb(origin, hit_pos, col)
	var blast_r := 2.8 + GameManager.skills.bonus_total(SkillData.Effect.ELEMENTAL_MASTERY) * 2.5
	var sp := GameManager.spell_power() * 1.45
	for n: Node in get_tree().get_nodes_in_group(Combat.DAMAGEABLE_GROUP):
		if n == self or not (n is Node3D) or not (n as Node3D).is_visible_in_tree():
			continue
		var t := n as Node3D
		if t.global_position.distance_to(Vector3(hit_pos.x, t.global_position.y, hit_pos.z)) <= blast_r:
			var info := GameManager.compute_damage(sp, 1.0, true)
			Combat.apply_hit(t, float(info["amount"]), self, bool(info["crit"]))
			if elem == "ice" and t.has_method("apply_slow"):
				t.call("apply_slow", 0.55, 2.8)
	return true

func _spawn_spell_orb(from_pos: Vector3, to_pos: Vector3, col: Color) -> void:
	if get_parent() == null:
		return
	var orb := MeshInstance3D.new()
	var smesh := SphereMesh.new()
	smesh.radius = 0.24
	smesh.height = 0.48
	orb.mesh = smesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb.material_override = mat
	orb.global_position = from_pos
	get_parent().add_child(orb)
	var tw := orb.create_tween()
	tw.tween_property(orb, "global_position", to_pos, 0.15)
	tw.tween_property(orb, "scale", Vector3.ONE * 2.3, 0.10)
	tw.tween_callback(orb.queue_free)

func take_hit(amount: float, source: Node, is_crit: bool = false) -> void:
	if dead or _invuln > 0.0:
		return
	var incoming := amount
	if is_blocking and stamina >= 6.0:
		incoming *= (1.0 - GameManager.skills.block_mitigation())
		stamina = maxf(0.0, stamina - 7.0)
		EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())
		visual.play("block_hit", true)
		if AudioManager != null:
			AudioManager.play_sfx("shield_block")
	_invuln = INVULN_TIME
	health.take_damage(incoming)
	if source is Node3D:
		var push := global_position - (source as Node3D).global_position
		push.y = 0.0
		if push.length_squared() > 0.01:
			velocity += push.normalized() * (2.0 if is_blocking else 4.0)
	if AudioManager != null and not is_blocking:
		AudioManager.play_sfx("player_hurt")
	EventBus.damage_dealt.emit(self, incoming, is_crit)
	if not health.is_dead() and not is_blocking:
		visual.play("hit", true)

func defense_value() -> float:
	return GameManager.defense_power()

func _on_health_damaged(_amount: float, current: float, maximum: float) -> void:
	EventBus.player_health_changed.emit(current, maximum)

func _on_health_healed(_amount: float, current: float, maximum: float) -> void:
	EventBus.player_health_changed.emit(current, maximum)

func _on_health_died() -> void:
	_die()

func _die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector3.ZERO
	visual.play_once("death")
	EventBus.player_died.emit()
	EventBus.notify.emit(Localization.tr_key("player_fell"))
	GameManager.gain_gold(-int(GameManager.gold * 0.1))
	await get_tree().create_timer(2.4).timeout
	respawn()

func respawn() -> void:
	dead = false
	health.revive(0.75)
	mana = GameManager.max_mana() * 0.75
	global_position = _spawn_position
	set_zone("village")
	velocity = Vector3.ZERO
	visual.resume_tree()
	visual.play("idle", true)
	_invuln = 1.5
	_emit_vitals()

func set_spawn_position(value: Vector3) -> void:
	_spawn_position = value

func teleport(target: Vector3, new_zone: String = "") -> void:
	global_position = target
	velocity = Vector3.ZERO
	if camera_rig != null:
		camera_rig.snap_to_parent()
	if not new_zone.is_empty():
		set_zone(new_zone)

func set_zone(zone_id: String) -> void:
	var changed_zone := (zone != zone_id)
	zone = zone_id
	GameManager.pending_zone = zone_id
	if changed_zone:
		zone_changed.emit(zone_id)
		EventBus.zone_entered.emit(zone_id)
		GameManager.report_visit(zone_id)

func heal(amount: float) -> void:
	health.heal(amount)

func restore_mana(amount: float) -> void:
	if amount <= 0.0:
		return
	mana = minf(GameManager.max_mana(), mana + amount)
	EventBus.player_mana_changed.emit(mana, GameManager.max_mana())

func sleep_until_morning() -> void:
	var ws := GameManager.world
	var now_h := ws.hour_float()
	var ahead := (7.0 - now_h) if now_h < 7.0 else (24.0 - now_h + 7.0)
	ws.advance(ahead * 3600.0)
	health.setup(GameManager.max_health(), GameManager.max_health())
	stamina = GameManager.max_stamina()
	mana = GameManager.max_mana()
	_emit_vitals()
	EventBus.notify.emit(Localization.tr_key("rested_morning") % ws.day)

func try_quick_potion() -> bool:
	var inv := GameManager.inventory
	if health.current_health < health.max_health * 0.85 and inv.count_item("health_potion") > 0:
		return use_consumable("health_potion")
	if mana < GameManager.max_mana() * 0.80 and inv.count_item("mana_elixir") > 0:
		return use_consumable("mana_elixir")
	for cid: String in ["health_potion", "venison", "bread", "mana_elixir"]:
		if inv.count_item(cid) > 0:
			return use_consumable(cid)
	EventBus.notify.emit(Localization.tr_key("no_potions"))
	return false

func use_consumable(item_id: String) -> bool:
	var data := ItemDB.get_item(item_id)
	if data == null or not data.is_consumable():
		return false
	if data.heal_amount > 0.0 and data.mana_amount <= 0.0 and health.current_health >= health.max_health:
		EventBus.notify.emit(Localization.tr_key("full_health"))
		return false
	if not GameManager.inventory.remove_item(item_id, 1):
		return false
	var mult := GameManager.skills.potion_multiplier()
	if data.heal_amount > 0.0:
		heal(data.heal_amount * mult)
	if data.mana_amount > 0.0:
		restore_mana(data.mana_amount * mult)
	if data.stamina_amount > 0.0:
		stamina = minf(GameManager.max_stamina(), stamina + data.stamina_amount * mult)
		EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())
	visual.play("use_item", true)
	if AudioManager != null:
		AudioManager.play_sfx("potion_drink")
	EventBus.notify.emit("%s: %s" % [Localization.tr_key("used_item"), Localization.item_name(data)])
	return true

func _on_level_up(_level: int) -> void:
	health.set_max_health(GameManager.max_health(), false)
	health.heal(health.max_health * 0.5)
	mana = GameManager.max_mana()
	if visual != null and not dead:
		visual.play("cheer", true)
	if AudioManager != null:
		AudioManager.play_sfx("level_up")
	_emit_vitals()

func _on_stats_updated() -> void:
	health.set_max_health(GameManager.max_health(), false)
	stamina = minf(stamina, GameManager.max_stamina())
	mana = minf(mana, GameManager.max_mana())
	_emit_vitals()

func _emit_vitals() -> void:
	EventBus.player_health_changed.emit(health.current_health, health.max_health)
	EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())
	EventBus.player_mana_changed.emit(mana, GameManager.max_mana())

func to_save_dict() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"rotation_y": rotation.y,
		"health": health.current_health if health != null else GameManager.max_health(),
		"stamina": stamina,
		"mana": mana,
		"zone": zone,
	}

func apply_save_state(data: Dictionary) -> void:
	var p: Array = data.get("position", [])
	if p.size() == 3:
		global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	rotation.y = float(data.get("rotation_y", 0.0))
	set_zone(String(data.get("zone", zone)))
	if health != null:
		health.setup(GameManager.max_health(), float(data.get("health", GameManager.max_health())))
	stamina = clampf(float(data.get("stamina", GameManager.max_stamina())), 0.0, GameManager.max_stamina())
	mana = clampf(float(data.get("mana", GameManager.max_mana())), 0.0, GameManager.max_mana())
	if camera_rig != null:
		camera_rig.snap_to_parent()
	_on_hero_class_changed(GameManager.hero_class)
	_sync_equipment_visuals()
	_emit_vitals()
