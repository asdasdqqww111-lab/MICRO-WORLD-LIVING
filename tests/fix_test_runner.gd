extends Node
## Gameplay acceptance for the on-device problem list (docs/FIX_CHECKLIST.md).
##   godot --headless --path . tests/fix_test_runner.tscn
## One section per reported problem; every check drives the real game scene.

const REPORT_PATH := "res://docs/reports/fix_test_results.txt"

var _passes: int = 0
var _failures: Array[String] = []
var _log: PackedStringArray = []
var _finished: bool = false

var game: Game
var player: Player
var world: WorldRoot
var ui: UIRoot

func _ready() -> void:
	_watchdog()
	await get_tree().process_frame
	await _run_all()

func _watchdog() -> void:
	await get_tree().create_timer(160.0).timeout
	if _finished:
		return
	_failures.append("WATCHDOG timeout (a coroutine stopped on a script error)")
	_report()

func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
	else:
		_failures.append(label)
	var line := ("PASS  " if condition else "FAIL  ") + label
	_log.append(line)
	print(line)

func _section(title: String) -> void:
	_log.append("")
	_log.append("== " + title)
	print("== " + title)

func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func _physics(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func _run_all() -> void:
	SaveManager.delete_slot("fix_test") if SaveManager.has_method("delete_slot") else null
	GameManager.start_new_game()
	game = (load("res://scenes/game/game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	await _frames(20)
	player = game.player
	world = game.world
	ui = game.ui
	await _test_p1_characters()
	await _test_p2_interiors()
	_report()

# --- helpers ------------------------------------------------------------------

func _in_bind_pose(v: CharacterVisual) -> bool:
	var sk := v._skeleton
	if sk == null:
		return false
	var b := sk.find_bone("hand.r")
	if b < 0:
		return false
	return sk.get_bone_global_pose(b).origin.distance_to(sk.get_bone_global_rest(b).origin) < 0.01

func _outdoor_npcs() -> Array[VillageNPC]:
	var out: Array[VillageNPC] = []
	for n: Node in get_tree().get_nodes_in_group("npc"):
		var npc := n as VillageNPC
		if npc != null and npc.is_visible_in_tree():
			out.append(npc)
	return out

# --- Problem 1: villagers and character size ---------------------------------------

func _test_p1_characters() -> void:
	_section("Problem 1 - villagers: pose, behaviour, size")
	var capsule := (player.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
	_check(capsule.height <= 1.35 and player.visual.model.scale.x <= 0.60,
		"hero is about 1.3 m tall (capsule %.2f m, model scale %.2f)" % [capsule.height, player.visual.model.scale.x])
	var npcs := _outdoor_npcs()
	_check(npcs.size() >= 16, "%d villagers live in the town" % npcs.size())
	var too_big := 0
	for npc: VillageNPC in npcs:
		if npc.visual.model.scale.x > 0.60:
			too_big += 1
	_check(too_big == 0, "no villager is larger than the hero (%d oversized)" % too_big)

	# Walk up to every villager, including the ones that started far away with
	# their animation switched off: none may be left in the bind pose.
	var bind_posed: PackedStringArray = []
	var not_facing: PackedStringArray = []
	var silent: PackedStringArray = []
	for npc: VillageNPC in npcs:
		player.teleport(npc.global_position + Vector3(1.1, 0.3, 1.1), "village")
		await _frames(24)
		if _in_bind_pose(npc.visual):
			bind_posed.append(npc.npc_id)
		var to_p := player.global_position - npc.global_position
		to_p.y = 0.0
		var facing := Vector3(-sin(npc.rotation.y), 0.0, -cos(npc.rotation.y))
		if facing.dot(to_p.normalized()) < 0.7:
			not_facing.append(npc.npc_id)
		if not npc._bubble.visible or npc._bubble.text.is_empty():
			silent.append(npc.npc_id)
	_check(bind_posed.is_empty(), "no villager stands in the bind pose (arms out): %s" % ", ".join(bind_posed))
	_check(not_facing.is_empty(), "every villager turns to face the hero: %s" % ", ".join(not_facing))
	_check(silent.is_empty(), "every villager greets the hero out loud: %s" % ", ".join(silent))

	# Solid bodies: the hero cannot walk through a villager.
	var smith := world.npc_by_id("blacksmith")
	var body := smith.get_node_or_null("Body") as CollisionObject3D
	_check(body != null and (player.collision_mask & body.collision_layer) != 0,
		"villagers are solid for the hero")
	var from := smith.global_position + Vector3(0.0, 0.3, 2.2)
	player.teleport(from, "village")
	await _physics(3)
	for i in 70:
		player.velocity = Vector3(0.0, player.velocity.y, -4.0)
		player.move_and_slide()
		await get_tree().physics_frame
	var passed_through := player.global_position.z < smith.global_position.z - 0.3 \
		and absf(player.global_position.x - smith.global_position.x) < 0.15
	_check(not passed_through, "walking straight at a villager does not pass through them")

	# Daily life: with the hero away, villagers move about and stay out of buildings.
	player.teleport(Vector3(0.0, 0.6, 14.0), "village")
	var before := {}
	var furthest := {}
	for npc: VillageNPC in npcs:
		before[npc] = npc.global_position
		furthest[npc] = 0.0
	Engine.time_scale = 8.0
	for round in 24:
		await _frames(25)
		for npc: VillageNPC in npcs:
			furthest[npc] = maxf(furthest[npc], npc.global_position.distance_to(before[npc]))
	Engine.time_scale = 1.0
	var movers := 0
	var still: PackedStringArray = []
	var in_buildings: PackedStringArray = []
	for npc: VillageNPC in npcs:
		if float(furthest[npc]) > 0.5:
			movers += 1
		else:
			still.append(npc.npc_id)
		if CityPlan.on_lot(npc.global_position.x, npc.global_position.z, 0.0):
			in_buildings.append(npc.npc_id)
	print("    (stood still: %s)" % ", ".join(still))
	_check(movers >= npcs.size() - 3, "villagers go about their day (%d of %d moved)" % [movers, npcs.size()])
	_check(in_buildings.is_empty(), "no villager is standing inside a building: %s" % ", ".join(in_buildings))

	# Night: ordinary villagers go home, the ones the player needs stay.
	GameManager.world.time_of_day = 23.0 * 3600.0
	Engine.time_scale = 8.0
	await _frames(700)
	Engine.time_scale = 1.0
	var indoors := 0
	for npc: VillageNPC in npcs:
		if npc.is_indoors_asleep():
			indoors += 1
	_check(indoors >= 3, "at night villagers walk home and go indoors (%d did)" % indoors)
	var elder := world.npc_by_id("elder")
	var guard := world.npc_by_id("guard")
	_check(not elder.is_indoors_asleep() and not guard.is_indoors_asleep() and not smith.is_indoors_asleep(),
		"quest givers, guards and shopkeepers stay available at night")
	GameManager.world.time_of_day = 8.0 * 3600.0
	await _frames(45)
	var outside := 0
	for npc: VillageNPC in npcs:
		if not npc.is_indoors_asleep() and npc.visual.visible:
			outside += 1
	_check(outside == npcs.size(), "everybody is back outside in the morning (%d of %d)" % [outside, npcs.size()])

# --- Problem 2: interiors, tower floors, staff and lighting ------------------------

func _test_p2_interiors() -> void:
	_section("Problem 2: interiors and tower floors")
	var env := world.environment

	# --- Cottage: furniture, fire, ceiling, door -------------------------------
	var house_mesh := world.house_root.get_node_or_null("HouseInterior")
	_check(house_mesh != null and house_mesh.is_inside_tree(), "the cottage interior is built (HouseInterior mesh)")
	_check(world.house_root.get_node_or_null("HouseGlow") != null, "the cottage glow batch is built")
	var house_lights := 0
	for n: Node in world.house_root.get_children():
		if n is OmniLight3D:
			house_lights += 1
	_check(house_lights >= 2, "the cottage has its own lights (%d)" % house_lights)
	_check(world.overworld_root.get_node_or_null("HouseDoor") != null,
		"the cottage entrance door exists in the square")

	# --- Guild hall: furniture, quest board, chandeliers, staff -----------------
	var guild_mesh := world.guild_root.get_node_or_null("GuildInterior")
	_check(guild_mesh != null and guild_mesh.is_inside_tree(), "the guild hall interior is built (GuildInterior mesh)")
	var guild_lights := 0
	for n: Node in world.guild_root.get_children():
		if n is OmniLight3D:
			guild_lights += 1
	_check(guild_lights >= 4, "the guild hall is lit by its own lights (%d)" % guild_lights)
	_check(world.guild_root.get_node_or_null("GuildHallQuestBoard") != null, "the guild quest board stands in the hall")
	var staff_facing := 0
	var staff_total := 0
	for n: Node in world.guild_root.get_children():
		var npc := n as VillageNPC
		if npc == null or not npc.always_awake:
			continue
		staff_total += 1
		if (npc.post_facing - Vector3.ZERO).length() > 0.01:
			staff_facing += 1
	_check(staff_total >= 5, "the guild hall has its staff (%d)" % staff_total)
	_check(staff_facing == staff_total, "every guild staff member keeps a post and faces it (%d of %d)" % [staff_facing, staff_total])

	# --- Room ambient follows the zone -----------------------------------------
	player.teleport(world.interior["spawn"] + Vector3(0.0, 0.6, 0.0), "house")
	await _frames(6)
	_check(world.house_root.visible and not world.guild_root.visible, "entering the cottage shows the cottage zone")
	var house_energy := env.ambient_light_energy
	_check(absf(house_energy - float(world.interior["ambient_energy"])) < 0.02,
		"the cottage ambient matches its room tone (%.2f)" % house_energy)

	player.teleport(world.guild_interior["spawn"] + Vector3(0.0, 0.6, 0.0), "guild")
	await _frames(6)
	_check(world.guild_root.visible and not world.house_root.visible, "entering the guild hall shows the guild zone")
	var guild_energy := env.ambient_light_energy
	_check(absf(guild_energy - float(world.guild_interior["ambient_energy"])) < 0.02,
		"the guild hall ambient matches its room tone (%.2f)" % guild_energy)

	player.teleport(Vector3(0.0, 0.6, 14.0), "village")
	await _frames(6)
	_check(not world.house_root.visible and not world.guild_root.visible, "leaving the buildings hides both interiors")
	_check(absf(env.ambient_light_energy - house_energy) > 0.01 or env.ambient_light_color != world.interior["ambient"],
		"the overworld ambient is restored outside")

	# --- Tower floor: ceiling, dressing, fire lights ----------------------------
	var tower := game.tower
	_check(tower != null, "the celestial tower manager exists")
	if tower != null:
		tower.player_entered(player)
		await _frames(10)
		var floor_root := tower.floor_container.get_child(0) if tower.floor_container != null and tower.floor_container.get_child_count() > 0 else null
		_check(floor_root != null and floor_root.name.begins_with("Floor"), "a tower floor is built (%s)" % str(floor_root.name if floor_root else "none"))
		if floor_root != null:
			_check(floor_root.get_node_or_null("FloorCeiling") != null, "the tower floor has a ceiling")
			_check(floor_root.get_node_or_null("FloorDressing") != null, "the tower floor has wall dressing and props")
			_check(floor_root.get_node_or_null("FloorLight") != null, "the tower floor keeps its central light")
			var fire_lights := 0
			for n: Node in floor_root.get_children():
				if n is FlickerLight:
					fire_lights += 1
			_check(fire_lights >= 3, "the tower floor burns with fire lights (%d)" % fire_lights)

# --- report -------------------------------------------------------------------

func _report() -> void:
	if _finished:
		return
	_finished = true
	var lines := PackedStringArray()
	lines.append("MICRO WORLD: LIVING - gameplay acceptance for the reported problem list")
	lines.append("checks passed: %d" % _passes)
	lines.append("checks failed: %d" % _failures.size())
	lines.append_array(_log)
	var f := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
		f.close()
	print("checks passed: %d" % _passes)
	print("checks failed: %d" % _failures.size())
	for failure: String in _failures:
		print("FAILED: " + failure)
	get_tree().quit(1 if not _failures.is_empty() else 0)
