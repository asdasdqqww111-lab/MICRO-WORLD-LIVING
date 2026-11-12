class_name Player
extends CharacterBody3D
## Third-person player controller.  All nodes are built in code so the scene
## file stays trivial and the controller can be exercised headless.

signal zone_changed(zone_id: String)

const MODEL_PATH := "res://assets/models/characters/Skeleton_Warrior.glb"
const MODEL_YAW_OFFSET := PI          # KayKit characters face +Z, Godot forward is -Z
const MODEL_SCALE := 1.0

const WALK_SPEED := 4.2
const RUN_SPEED := 7.1
const ACCELERATION := 16.0
const AIR_ACCELERATION := 6.0
const TURN_SPEED := 12.0
const JUMP_VELOCITY := 7.4
const GRAVITY := 22.0
const CAPSULE_HEIGHT := 2.0
const CAPSULE_RADIUS := 0.36
const EYE_HEIGHT := 1.55

const ATTACK_REACH := 2.3
const ATTACK_ARC := 120.0
const ATTACK_COST := 14.0
const ATTACK_DURATION := 0.46
const COMBO_WINDOW := 0.9
const STAMINA_REGEN := 17.0
const SPRINT_STAMINA_COST := 12.0
const INVULN_TIME := 0.45

var health: HealthComponent
var stamina: float = 100.0
var visual: CharacterVisual
var camera_rig: CameraRig
var input := PlayerInput.new()
var zone: String = "village"
var dead: bool = false

var _attack_timer: float = 0.0
var _attack_index: int = 0
var _combo_reset: float = 0.0
var _invuln: float = 0.0
var _nearest: Interactable = null
var _spawn_position := Vector3(0.0, 1.2, 16.0)

func _ready() -> void:
	add_to_group("player")
	add_to_group(Combat.DAMAGEABLE_GROUP)
	collision_layer = 2
	collision_mask = 1
	_build_collision()
	_build_visual()
	_build_camera()
	_build_health()
	stamina = GameManager.max_stamina()
	_emit_vitals()
	EventBus.player_level_up.connect(_on_level_up)

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
	visual.position = Vector3(0.0, 0.0, 0.0)
	visual.rotation.y = MODEL_YAW_OFFSET
	add_child(visual)
	var ok := visual.setup(MODEL_PATH, MODEL_SCALE)
	if not ok:
		push_warning("Player: character model missing, running invisible (logic still works)")

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
	health.died.connect(_on_health_died)

func _physics_process(delta: float) -> void:
	if dead:
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)
	_combo_reset = maxf(0.0, _combo_reset - delta)
	_invuln = maxf(0.0, _invuln - delta)

	var move := input.move_vector()
	var yaw := camera_rig.yaw
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var direction := (right * move.x + forward * (-move.y))
	if direction.length() > 0.05:
		direction = direction.normalized()
	else:
		direction = Vector3.ZERO

	var sprinting := input.is_sprinting() and direction != Vector3.ZERO and stamina > 4.0
	var speed := (RUN_SPEED if sprinting else WALK_SPEED) * GameManager.move_speed_multiplier()
	if _attack_timer > 0.0:
		speed *= 0.35
	var target := direction * speed
	var accel := ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, target.x, accel * delta * 6.0)
	velocity.z = move_toward(velocity.z, target.z, accel * delta * 6.0)

	if sprinting:
		stamina = maxf(0.0, stamina - SPRINT_STAMINA_COST * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif input.jump_pressed():
		velocity.y = JUMP_VELOCITY

	if direction != Vector3.ZERO and _attack_timer <= 0.0:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(TURN_SPEED * delta, 0.0, 1.0))

	move_and_slide()

	if input.attack_pressed():
		try_attack()
	if input.interact_pressed() and _nearest != null:
		_nearest.interact(self)
	_update_stamina(delta)
	_update_interactable()
	_update_animation(sprinting)

func _update_stamina(delta: float) -> void:
	if _attack_timer <= 0.0 and not input.is_sprinting():
		var before := stamina
		stamina = minf(GameManager.max_stamina(), stamina + STAMINA_REGEN * delta)
		if absf(stamina - before) > 0.01 and int(stamina * 2.0) != int(before * 2.0):
			EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())

func _update_animation(sprinting: bool) -> void:
	if _attack_timer > 0.0:
		return
	if not is_on_floor():
		visual.play("jump" if velocity.y > 0.5 else "fall")
		return
	var planar := Vector2(velocity.x, velocity.z).length()
	if planar > 6.2:
		visual.play("run")
	elif planar > 0.35:
		visual.play("walk")
	else:
		visual.play("idle")
	if sprinting and not visual.has_state("run"):
		visual.play("walk")

func _update_interactable() -> void:
	var best: Interactable = null
	var best_distance := INF
	for node: Node in get_tree().get_nodes_in_group("interactable"):
		var inter := node as Interactable
		if inter == null or not inter.enabled or not inter.is_inside_tree():
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

func try_attack() -> bool:
	if dead or _attack_timer > 0.0 or stamina < ATTACK_COST:
		return false
	_attack_index = (_attack_index + 1) % 2 if _combo_reset > 0.0 else 0
	_combo_reset = COMBO_WINDOW
	_attack_timer = ATTACK_DURATION
	stamina = maxf(0.0, stamina - ATTACK_COST)
	EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())
	visual.play("attack_1" if _attack_index == 0 else "attack_2", true)
	var multiplier := 1.0 if _attack_index == 0 else 1.3
	var targets := Combat.melee_targets(self, ATTACK_REACH, ATTACK_ARC, [get_rid()])
	for target: Node in targets:
		var defense := 0.0
		if target.has_method("defense_value"):
			defense = float(target.call("defense_value"))
		var info := GameManager.compute_damage(GameManager.attack_power() * multiplier, defense, true)
		Combat.apply_hit(target, float(info.get("amount", 0.0)), self, bool(info.get("crit", false)))
	return true

func take_hit(amount: float, _source: Node, is_crit: bool = false) -> void:
	if dead or _invuln > 0.0:
		return
	_invuln = INVULN_TIME
	health.take_damage(amount)
	EventBus.damage_dealt.emit(self, amount, is_crit)
	if not health.is_dead():
		visual.play("hit", true)

func defense_value() -> float:
	return GameManager.defense_power()

func _on_health_damaged(_amount: float, current: float, maximum: float) -> void:
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
	EventBus.notify.emit("You died. Returning to the village...")
	GameManager.gain_gold(-int(GameManager.gold * 0.1))
	await get_tree().create_timer(2.6).timeout
	respawn()

func respawn() -> void:
	dead = false
	health.revive(0.65)
	global_position = _spawn_position
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
	if not new_zone.is_empty():
		set_zone(new_zone)

func set_zone(zone_id: String) -> void:
	if zone == zone_id:
		return
	zone = zone_id
	zone_changed.emit(zone_id)
	GameManager.pending_zone = zone_id
	GameManager.report_visit(zone_id)

func heal(amount: float) -> void:
	health.heal(amount)

func use_consumable(item_id: String) -> bool:
	var data := ItemDB.get_item(item_id)
	if data == null or not data.is_consumable():
		return false
	if data.heal_amount > 0.0 and health.current_health >= health.max_health:
		EventBus.notify.emit("Already at full health")
		return false
	if not GameManager.inventory.remove_item(item_id, 1):
		return false
	heal(data.heal_amount)
	EventBus.notify.emit("Used %s" % data.display_name)
	return true

func _on_level_up(_level: int) -> void:
	health.set_max_health(GameManager.max_health(), false)
	health.heal(health.max_health * 0.4)
	_emit_vitals()

func _emit_vitals() -> void:
	EventBus.player_health_changed.emit(health.current_health, health.max_health)
	EventBus.player_stamina_changed.emit(stamina, GameManager.max_stamina())

func to_save_dict() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"rotation_y": rotation.y,
		"health": health.current_health if health != null else GameManager.max_health(),
		"stamina": stamina,
		"zone": zone,
	}

func apply_save_state(data: Dictionary) -> void:
	var p: Array = data.get("position", [])
	if p.size() == 3:
		global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	rotation.y = float(data.get("rotation_y", 0.0))
	zone = String(data.get("zone", zone))
	GameManager.pending_zone = zone
	if health != null:
		health.setup(GameManager.max_health(), float(data.get("health", GameManager.max_health())))
	stamina = float(data.get("stamina", GameManager.max_stamina()))
	_emit_vitals()
