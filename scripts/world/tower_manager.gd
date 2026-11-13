class_name TowerManager
extends Node3D
## Runtime brain of the Celestial Ascent Tower.
##   - Builds the overworld gate (a tall visible spire + portal).
##   - Loads exactly ONE floor at a time into a container node.
##   - Spawns the Floor Master + region mobs via WorldRoot.spawn_creature(),
##     which ALREADY refuses to spawn creatures marked dead in WorldState —
##     so defeated Floor Masters stay defeated across save/load for free.
##   - Tracks progression in WorldState.flags (schema v3-safe, no migration).
##   - Progression rule: floor N+1 unlocks only after floor N's master dies.
##
## Integration: Game.gd instantiates this right after the WorldRoot is added.

const GATE_HEIGHT := 42.0
const FLAG_PREFIX := "tower_master_"
const CURRENT_FLOOR_FLAG := "tower_current_floor"
const FINAL_FLOOR := TowerDB.FLOOR_COUNT

var world: WorldRoot
var tower_root: Node3D
var floor_container: Node3D
var gate_portal: TowerPortal
var current_floor: int = 0
var _floor_uids: Array[String] = []

func _ready() -> void:
	add_to_group("tower_manager")
	tower_root = Node3D.new()
	tower_root.name = "TowerZone"
	add_child(tower_root)
	tower_root.visible = false
	floor_container = Node3D.new()
	floor_container.name = "TowerFloors"
	tower_root.add_child(floor_container)
	EventBus.creature_died.connect(_on_creature_died)
	_build_gate()

# --- Overworld gate -----------------------------------------------------------

func _build_gate() -> void:
	# Visible spire at the edge of the meadow (near Sacred Grove, clear of city bounds).
	var base := TowerDB.TOWER_GATE_OVERWORLD
	var spire := MeshInstance3D.new()
	spire.name = "TowerGateSpire"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.5
	cyl.bottom_radius = 4.2
	cyl.height = GATE_HEIGHT
	spire.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.44, 0.40, 0.62)
	mat.roughness = 0.7
	mat.metallic = 0.15
	spire.material_override = mat
	add_child(spire)
	spire.global_position = base + Vector3(0.0, GATE_HEIGHT * 0.5, 0.0)

	var body := StaticBody3D.new()
	body.name = "TowerGateBody"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	body.global_position = base + Vector3(0.0, GATE_HEIGHT * 0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5.0, GATE_HEIGHT, 5.0)
	shape.shape = box
	body.add_child(shape)

	# Crown glow so the tower reads as a landmark from the city walls.
	var crown := MeshInstance3D.new()
	crown.name = "TowerCrown"
	var crown_cyl := CylinderMesh.new()
	crown_cyl.top_radius = 2.1
	crown_cyl.bottom_radius = 1.9
	crown_cyl.height = 1.2
	crown.mesh = crown_cyl
	var crown_mat := StandardMaterial3D.new()
	crown_mat.albedo_color = Color(1.0, 0.88, 0.42)
	crown_mat.emission_enabled = true
	crown_mat.emission = Color(1.0, 0.85, 0.40)
	crown_mat.emission_energy_multiplier = 0.9
	crown.material_override = crown_mat
	add_child(crown)
	crown.global_position = base + Vector3(0.0, GATE_HEIGHT + 0.6, 0.0)
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var glow := OmniLight3D.new()
	glow.name = "TowerGateGlow"
	glow.light_color = Color(0.85, 0.75, 1.0)
	glow.light_energy = 0.8
	glow.omni_range = 12.0
	glow.shadow_enabled = false
	add_child(glow)
	glow.global_position = base + Vector3(0.0, 4.0, 0.0)

	gate_portal = TowerPortal.new()
	gate_portal.name = "TowerGatePortal"
	gate_portal.setup_portal("enter", 1, self)
	add_child(gate_portal)
	gate_portal.global_position = base + Vector3(0.0, 0.0, 3.4)

	var label := Label3D.new()
	label.name = "TowerGateSign"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.outline_size = 9
	label.modulate = Color(0.95, 0.88, 1.0)
	label.text = "برج الصعود السماوي" if Localization.is_arabic() else "Celestial Ascent Tower"
	label.position = Vector3(0.0, 3.4, 0.0)
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gate_portal.add_child(label)

# --- Save/load bridge ---------------------------------------------------------

func _flag_key(floor_num: int) -> String:
	return FLAG_PREFIX + str(floor_num)

func is_master_defeated(floor_num: int) -> bool:
	return bool(GameManager.world.get_flag(_flag_key(floor_num), false))

func highest_unlocked_floor() -> int:
	# Floor 1 always open; floor N+1 open when master of N is defeated.
	var unlocked := 1
	for f in range(1, FINAL_FLOOR):
		if is_master_defeated(f):
			unlocked = f + 1
		else:
			break
	return unlocked

func floors_cleared() -> int:
	var cleared := 0
	for f in range(1, FINAL_FLOOR + 1):
		if is_master_defeated(f):
			cleared += 1
	return cleared

# --- Floor lifecycle -----------------------------------------------------------

func player_entered(player: Node) -> void:
	var target := 1
	var saved := int(GameManager.world.get_flag(CURRENT_FLOOR_FLAG, 1))
	if saved >= 1 and saved <= FINAL_FLOOR:
		# Return to the highest floor the player earned access to, capped by save.
		target = mini(saved, highest_unlocked_floor())
	_load_floor(target, player)
	var ar := Localization.is_arabic()
	EventBus.notify.emit("دخلت برج الصعود السماوي — الطابق %d" % target if ar else "You enter the Celestial Ascent Tower — Floor %d" % target)
	if AudioManager != null:
		AudioManager.play_music_for_zone("tower")

func ascend(player: Node) -> void:
	if current_floor <= 0 or current_floor >= FINAL_FLOOR:
		return
	if not is_master_defeated(current_floor):
		return
	_load_floor(current_floor + 1, player)
	var ar := Localization.is_arabic()
	EventBus.notify.emit("صعدت إلى الطابق %d" % current_floor if ar else "You ascend to Floor %d" % current_floor)

func player_exited(player: Node) -> void:
	GameManager.world.set_flag(CURRENT_FLOOR_FLAG, current_floor)
	_clear_floor()
	current_floor = 0
	tower_root.visible = false
	if player != null and player.has_method("teleport"):
		player.call("teleport", TowerDB.TOWER_GATE_OVERWORLD + Vector3(0.0, 0.6, 6.5), "village")
	if AudioManager != null:
		AudioManager.play_music_for_zone("village")
	var ar := Localization.is_arabic()
	EventBus.notify.emit("عدت إلى رحاب إلدوريا" if ar else "You return to Eldoria")

func _load_floor(floor_num: int, player: Node) -> void:
	_clear_floor()
	current_floor = floor_num
	GameManager.world.set_flag(CURRENT_FLOOR_FLAG, floor_num)
	var anchors := TowerFloorBuilder.build_floor(floor_container, floor_num)
	tower_root.visible = true
	var region_key: String = anchors["region"]

	# --- Portals: exit always, up only if not final --------------------------
	var exit_portal := TowerPortal.new()
	exit_portal.name = "TowerExitPortal"
	exit_portal.setup_portal("exit", floor_num, self)
	floor_container.add_child(exit_portal)
	exit_portal.global_position = anchors["origin"] + Vector3(0.0, 0.0, TowerDB.FLOOR_HALF - 1.4)

	var is_final := floor_num >= FINAL_FLOOR
	if not is_final:
		var up_portal := TowerPortal.new()
		up_portal.name = "TowerUpPortal"
		up_portal.setup_portal("up", floor_num, self, false)
		floor_container.add_child(up_portal)
		up_portal.global_position = anchors["origin"] + Vector3(0.0, 0.0, -TowerDB.FLOOR_HALF + 1.6)

	# --- Region mobs ----------------------------------------------------------
	var mob := TowerDB.mob_stats(floor_num)
	var mob_data := CreatureDB.get_creature(mob["id"])
	if mob_data != null:
		for i in int(mob["count"]):
			var angle := TAU * float(i) / maxf(1.0, float(mob["count"])) + 0.35
			var radius := 7.5
			var pos: Vector3 = anchors["origin"] + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
			var uid := _uid_for(floor_num, "mob", i)
			_spawn_scaled(mob_data, uid, pos, float(mob["hp"]), float(mob["damage"]))

	# --- Floor Master (unique name, boss scaling, unique uid) ------------------
	var master := _make_master_data(floor_num)
	var master_uid := _uid_for(floor_num, "master", 0)
	var master_spawn: Vector3 = anchors["master_anchor"]
	# spawn_creature refuses to spawn dead uids — persistence is automatic.
	world.spawn_creature_data(master["data"], master_uid, master_spawn, floor_container)
	_floor_uids.append(master_uid)

	# --- Move player to the floor spawn --------------------------------------
	if player != null and player.has_method("teleport"):
		player.call("teleport", anchors["spawn"], "tower")

	EventBus.zone_entered.emit("tower")
	EventBus.boss_health_changed.emit(
		Localization.creature_name(master["data"]), 0.0, 1.0, 1, false)

func _make_master_data(floor_num: int) -> Dictionary:
	var stats := TowerDB.master_stats(floor_num)
	var base := CreatureDB.get_creature(TowerDB.master_archetype(floor_num))
	var data: CreatureData
	if base != null:
		data = base.duplicate(true)
	else:
		data = CreatureData.new()
	var is_ar := Localization.is_arabic()
	data.id = "tower_master_%d" % floor_num
	data.display_name = TowerDB.master_name_ar(floor_num) if is_ar else TowerDB.master_name(floor_num)
	data.max_health = float(stats["hp"])
	data.damage = float(stats["damage"])
	data.defense = float(stats["defense"])
	data.xp_reward = int(stats["xp"])
	data.gold_reward = int(stats["gold"])
	data.is_boss = true
	data.is_elite = floor_num % 10 == 0
	data.hostile = true
	data.aggro_radius = 16.0
	data.leash_radius = 30.0
	data.attack_range = 2.2
	data.attack_cooldown = 1.3
	data.body_scale = 1.28 if floor_num < 90 else 1.45
	var region: Dictionary = TowerDB.REGIONS.get(TowerDB.region_for_floor(floor_num), {})
	data.tint_color = region.get("accent", Color.WHITE)
	return {"data": data, "stats": stats}

func _spawn_scaled(base: CreatureData, uid: String, pos: Vector3, hp: float, dmg: float) -> void:
	var data: CreatureData = base.duplicate(true)
	data.max_health = hp
	data.damage = dmg
	data.is_boss = false
	data.is_elite = false
	world.spawn_creature_data(data, uid, pos, floor_container)
	_floor_uids.append(uid)

func _clear_floor() -> void:
	# Free the previous floor: nodes are owned by floor_container, so one call
	# disposes geometry + creatures spawned on that floor.
	for uid in _floor_uids:
		if world != null:
			world._creatures.erase(uid)
	_floor_uids.clear()
	for child in floor_container.get_children():
		child.free()

func _uid_for(floor_num: int, role: String, idx: int) -> String:
	# Parseable by _on_creature_died: "tower_7_master_0".
	return "tower_%d_%s_%d" % [floor_num, role, idx]

# --- Master defeat ---------------------------------------------------------------

func _on_creature_died(creature_id: String, uid: String, _position: Vector3) -> void:
	if not uid.begins_with("tower_"):
		return
	var parts := uid.split("_")
	if parts.size() != 4 or parts[2] != "master":
		return
	var floor_num := parts[1].to_int()
	if floor_num <= 0 or floor_num > FINAL_FLOOR:
		return
	GameManager.world.set_flag(_flag_key(floor_num), true)
	var ar := Localization.is_arabic()
	if floor_num >= FINAL_FLOOR:
		EventBus.notify.emit("هزمت أسترايوس، التاج الأبدي! اكتملت ملحمة البرج!" if ar else "Astraeus, the Eternal Crown has fallen! The tower's saga is complete!")
		GameManager.world.set_flag("tower_completed", true)
	else:
		EventBus.notify.emit("سيد الطابق %d سقط — بوابة الصعود انفتحت!" % floor_num if ar else "Floor %d Master fallen — the ascent gate opens!" % floor_num)
	if AudioManager != null:
		AudioManager.play_sfx("quest_complete", 0.0)

# --- Restore after load -----------------------------------------------------------

func restore_after_load(player: Node) -> void:
	# Called by Game._apply_state when the saved zone was "tower".
	var saved := int(GameManager.world.get_flag(CURRENT_FLOOR_FLAG, 1))
	var target := clampi(saved, 1, FINAL_FLOOR)
	var pending := GameManager.pending_zone
	if pending == "tower" and current_floor == 0:
		_load_floor(target, player)

func active_floor() -> int:
	return current_floor
