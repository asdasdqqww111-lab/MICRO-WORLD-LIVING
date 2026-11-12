class_name Creature
extends CharacterBody3D
## Hostile creature: idle/wander -> chase -> attack -> hit -> death.
## Navigation is intentionally steering based (no baked navmesh) so the slice
## stays cheap on a Snapdragon 6xx.

const GRAVITY := 22.0
const MODEL_YAW_OFFSET := PI
const DEATH_FREE_DELAY := 4.0

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
var _wander_target: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _time: float = 0.0
var _speed_now: float = 0.0

func _ready() -> void:
	add_to_group("creature")
	add_to_group(Combat.DAMAGEABLE_GROUP)
	collision_layer = 4
	collision_mask = 1
	if data == null:
		data = CreatureDB.get_creature("skeleton_forest")
	_build()

func setup(creature_data: CreatureData, creature_uid: String, home_position: Vector3) -> void:
	data = creature_data
	uid = creature_uid
	home = home_position

func _build() -> void:
	var capsule := CapsuleShape3D.new()
	var is_procedural := data.model_path.is_empty()
	if data.visual_type == "slime":
		capsule.radius = 0.5
		capsule.height = 0.9
	elif data.visual_type == "wolf":
		capsule.radius = 0.38
		capsule.height = 1.1
	else:
		capsule.radius = 0.42
		capsule.height = 1.9
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

	if is_procedural:
		model_root = ProceduralModels.build(data.visual_type)
		model_root.name = "Visual"
		model_root.rotation.y = MODEL_YAW_OFFSET
		add_child(model_root)
	else:
		anim = CharacterVisual.new()
		anim.name = "Visual"
		anim.rotation.y = MODEL_YAW_OFFSET
		add_child(anim)
		if anim.setup(data.model_path, data.body_scale):
			model_root = anim
			anim.play("idle")
		else:
			model_root = ProceduralModels.build("slime")
			add_child(model_root)

	_wander_target = home

func _physics_process(delta: float) -> void:
	_time += delta
	if _dead:
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var player := _find_player()
	var distance := INF
	if player != null:
		distance = global_position.distance_to(player.global_position)

	if player != null and not player.dead and distance <= data.aggro_radius:
		if not aggro:
			EventBus.creature_aggro.emit(self)
		aggro = true
	if aggro and (player == null or player.dead or distance > data.aggro_radius * 2.4
			or global_position.distance_to(home) > data.leash_radius):
		aggro = false

	var planar_speed := 0.0
	if aggro and player != null:
		if distance <= data.attack_range:
			state = "attack"
			_try_attack(player)
		else:
			state = "chase"
			planar_speed = _move_towards(player.global_position, data.move_speed)
	else:
		state = "idle"
		planar_speed = _wander(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_speed_now = planar_speed
	_animate(delta)

func _find_player() -> Player:
	var node := get_tree().get_first_node_in_group("player")
	return node as Player

func _move_towards(target: Vector3, speed: float) -> float:
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.05:
		return 0.0
	var dir := to_target.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.16)
	return speed

func _wander(delta: float) -> float:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(4.0, 9.0)
		var angle := randf() * TAU
		_wander_target = home + Vector3(cos(angle), 0.0, sin(angle)) * randf_range(1.0, 5.0)
	var to_target := _wander_target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.6:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		return 0.0
	var dir := to_target.normalized()
	var speed := data.move_speed * 0.28
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.08)
	return speed

func _try_attack(player: Player) -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = data.attack_cooldown
	if anim != null:
		anim.play("attack_1", true)
	var info := GameManager.compute_damage(data.damage, player.defense_value(), false)
	player.take_hit(float(info.get("amount", 0.0)), self, false)

func _animate(delta: float) -> void:
	if model_root == null:
		return
	if anim != null:
		if state == "attack":
			anim.play("attack_1")
		elif _speed_now > 0.1:
			anim.play("run" if _speed_now > data.move_speed * 0.7 else "walk")
		else:
			anim.play("idle")
	else:
		ProceduralModels.animate(model_root, data.visual_type, _time, _speed_now)

func take_hit(amount: float, _source: Node, is_crit: bool = false) -> void:
	if _dead:
		return
	health.take_damage(amount)
	EventBus.damage_dealt.emit(self, amount, is_crit)
	aggro = true
	if model_root != null:
		var tween := create_tween()
		model_root.scale = Vector3(1.06, 0.94, 1.06)
		tween.tween_property(model_root, "scale", Vector3.ONE, 0.15)
	if anim != null and not health.is_dead():
		anim.play("hit", true)

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
	if anim != null:
		anim.play_once("death")
	else:
		var tween := create_tween()
		tween.tween_property(model_root, "scale", Vector3(1.3, 0.08, 1.3), 0.5)
	GameManager.world.mark_dead(uid)
	GameManager.gain_xp(data.xp_reward)
	GameManager.gain_gold(data.gold_reward)
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
	if world == null or not world.has_method("spawn_loot_drop"):
		# No world (unit tests): grant directly so progression still works.
		for drop: Dictionary in drops:
			GameManager.gain_item(String(drop.get("id", "")), int(drop.get("count", 1)))
		return
	world.call("spawn_loot_drop", drops, global_position + Vector3(0.0, 0.2, 0.0))
