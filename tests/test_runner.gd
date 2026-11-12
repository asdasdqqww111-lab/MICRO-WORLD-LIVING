extends Node
## Headless acceptance harness.
##   godot --headless --path . tests/test_runner.tscn
## Exercises the real game scene (world build, combat, quests, save/load) and
## writes a result sheet to docs/reports/headless_test_results.txt.

const SAVE_SLOT := "test_slot"
const MIGRATE_SLOT := "test_migrate"
const CORRUPT_SLOT := "test_corrupt"
const NEWER_SLOT := "test_newer"
const REPORT_PATH := "res://docs/reports/headless_test_results.txt"

var _passes: int = 0
var _failures: Array[String] = []
var _log: PackedStringArray = []
var _draw_calls: int = 0
var _triangles: int = 0
var _nodes: float = 0.0
var _fps: float = 0.0

class MockTouch:
	extends Node
	var move_vector: Vector2 = Vector2.ZERO
	var sprinting: bool = false
	var pressed: Dictionary = {}

	func get_move_vector() -> Vector2:
		return move_vector

	func is_sprinting() -> bool:
		return sprinting

	func consume_pressed(action: String) -> bool:
		if bool(pressed.get(action, false)):
			pressed[action] = false
			return true
		return false

func _ready() -> void:
	await get_tree().process_frame
	await _run_all()

func _collect_multimeshes(node: Node, found: Array) -> void:
	if node is MultiMeshInstance3D:
		found.append(node)
	for child: Node in node.get_children():
		_collect_multimeshes(child, found)

func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		_log.append("PASS  " + label)
	else:
		_failures.append(label)
		_log.append("FAIL  " + label)
	print(("PASS  " if condition else "FAIL  ") + label)

func _section(title: String) -> void:
	_log.append("")
	_log.append("== " + title + " ==")

func _wait_frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame

func _wait_physics(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame

func _run_all() -> void:
	GameManager.reset_state()
	_test_databases()
	_test_progression()
	_test_inventory()
	_test_combat_math()
	_test_world_state()
	_test_market()
	_test_schedule()
	_test_quest_flow()
	_test_save_file()
	await _test_game_scene()
	_report()

# --- data --------------------------------------------------------------------

func _test_databases() -> void:
	_section("Data resources")
	ItemDB.reload()
	QuestDB.reload()
	SkillDB.reload()
	CreatureDB.reload()
	_check(ItemDB.count() >= 14, "ItemDB loads >= 14 items (got %d)" % ItemDB.count())
	_check(QuestDB.count() == 2, "QuestDB loads 2 quests (got %d)" % QuestDB.count())
	_check(SkillDB.count() == 3, "SkillDB loads 3 skills (got %d)" % SkillDB.count())
	_check(CreatureDB.count() == 4, "CreatureDB loads 4 creatures (got %d)" % CreatureDB.count())
	var valid := true
	for item: ItemData in ItemDB.all_items():
		if item.id.is_empty() or item.display_name.is_empty() or item.max_stack < 1:
			valid = false
		if not ["none", "weapon", "armor", "helmet"].has(item.equip_slot):
			valid = false
	_check(valid, "every item resource has id/name/stack and a valid equip slot")
	_check(ItemDB.has("rusty_sword") and ItemDB.has("health_potion") and ItemDB.has("ancient_relic"),
		"core items exist (rusty_sword, health_potion, ancient_relic)")
	for creature: CreatureData in CreatureDB.all_creatures():
		if not creature.model_path.is_empty():
			_check(AssetLibrary.has_model(creature.model_path),
				"model exists for creature '%s'" % creature.id)
	_check(QuestDB.get_quest("skeleton_menace") != null, "quest 'skeleton_menace' present")
	_check(QuestDB.get_quest("skeleton_menace").objectives.size() == 1, "quest has 1 objective")

# --- progression -------------------------------------------------------------

func _test_progression() -> void:
	_section("Progression")
	var p := Progression.new()
	_check(p.xp_to_next() == 60, "level 1 needs 60 xp (got %d)" % p.xp_to_next())
	var gained := p.add_xp(60)
	_check(gained == 1 and p.level == 2, "60 xp levels up to 2")
	_check(p.xp == 0, "leftover xp is carried correctly (got %d)" % p.xp)
	p.add_xp(100000)
	_check(p.level == Progression.MAX_LEVEL, "xp is capped at max level %d (got %d)"
		% [Progression.MAX_LEVEL, p.level])
	var stats := CharacterStats.new()
	stats.recalc_for_level(5)
	_check(stats.max_health > CharacterStats.BASE_HEALTH, "level 5 raises max health")

# --- inventory ---------------------------------------------------------------

func _test_inventory() -> void:
	_section("Inventory")
	var inv := Inventory.new()
	_check(inv.add_item("bone", 40) == 0, "adding 40 bones fits")
	_check(inv.count_item("bone") == 40, "bone count is 40 (got %d)" % inv.count_item("bone"))
	_check(inv.used_slots() == 2, "40 bones use 2 stacks of 30 (got %d)" % inv.used_slots())
	_check(inv.remove_item("bone", 39), "removing 39 bones works")
	_check(inv.count_item("bone") == 1, "one bone left")
	_check(inv.add_item("does_not_exist", 1) == 1, "unknown items are rejected")

	inv.clear()
	inv.add_item("rusty_sword", 1)
	_check(inv.equip("rusty_sword"), "equip rusty_sword")
	_check(inv.equipped("weapon") == "rusty_sword", "weapon slot holds the sword")
	_check(inv.count_item("rusty_sword") == 0, "equipped item leaves the bags")
	inv.add_item("iron_sword", 1)
	_check(inv.equip("iron_sword"), "equip iron_sword over rusty_sword")
	_check(inv.count_item("rusty_sword") == 1, "old weapon returns to the bags")
	_check(inv.total_attack_bonus() > 0.0, "attack bonus is applied from gear")
	_check(inv.unequip("weapon"), "unequip weapon")

	var full := Inventory.new()
	for _i: int in Inventory.SLOT_COUNT:
		full.add_item("iron_ore", 30)
	_check(full.is_full(), "20 full stacks fill the inventory")
	_check(full.add_item("bone", 1) == 1, "no room means leftover")

	var round_trip := Inventory.new()
	round_trip.add_item("health_potion", 3)
	round_trip.add_item("leather_armor", 1)
	round_trip.equip("leather_armor")
	var copy := Inventory.new()
	copy.from_dict(round_trip.to_dict())
	_check(copy.count_item("health_potion") == 3, "inventory serialises consumables")
	_check(copy.equipped("armor") == "leather_armor", "inventory serialises equipment")

# --- combat ------------------------------------------------------------------

func _test_combat_math() -> void:
	_section("Combat maths")
	seed(1234)
	var low_defense := GameManager.compute_damage(30.0, 0.0, false)
	var high_defense := GameManager.compute_damage(30.0, 200.0, false)
	_check(float(low_defense.get("amount", 0.0)) > 1.0, "damage scales with attack")
	_check(float(high_defense.get("amount", 0.0)) == 1.0, "damage never drops below 1")
	_check(not bool(low_defense.get("crit", true)), "crit can be disabled")

# --- world state -------------------------------------------------------------

func _test_world_state() -> void:
	_section("World clock + persistence flags")
	var state := WorldState.new()
	state.time_of_day = 23.0 * 3600.0
	var new_day := state.advance(2.0 * 3600.0)
	_check(new_day and state.day == 2, "clock rolls over into day 2")
	_check(state.hour() == 1, "hour is 01:00 after rollover (got %d)" % state.hour())
	_check(state.is_night(), "01:00 counts as night")
	state.mark_dead("forest_skeleton_0")
	_check(state.is_dead("forest_skeleton_0"), "dead creatures are tracked")
	var copy := WorldState.new()
	copy.from_dict(state.to_dict())
	_check(copy.is_dead("forest_skeleton_0") and copy.day == 2, "world state round-trips")

# --- market ------------------------------------------------------------------

func _test_market() -> void:
	_section("Market")
	var price_day_1 := Market.price("health_potion", 1)
	var price_day_1_again := Market.price("health_potion", 1)
	_check(price_day_1 > 0, "potion has a price")
	_check(price_day_1 == price_day_1_again, "same day = same price")
	_check(Market.sell_price("bone", 1) < Market.price("bone", 1) + 1, "sell price is below buy price")
	var distinct: Dictionary = {}
	for day: int in range(1, 15):
		distinct[Market.price("health_potion", day)] = true
	_check(distinct.size() > 1, "prices change across days (%d distinct)" % distinct.size())
	_check(Market.stock_for(2).size() > 0, "blacksmith has stock")

func _test_schedule() -> void:
	_section("NPC schedule")
	_check(VillageNPC.activity_for_hour(8) == "work", "08:00 is work time")
	_check(VillageNPC.activity_for_hour(6) == "work", "06:00 starts work")
	_check(VillageNPC.activity_for_hour(18) == "rest", "18:00 is rest")
	_check(VillageNPC.activity_for_hour(21) == "rest", "21:00 is rest")
	_check(VillageNPC.activity_for_hour(22) == "sleep", "22:00 is sleep")
	_check(VillageNPC.activity_for_hour(3) == "sleep", "03:00 is sleep")

# --- quests ------------------------------------------------------------------

func _test_quest_flow() -> void:
	_section("Quest flow")
	GameManager.start_new_game()
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_NOT_STARTED,
		"quest starts unstarted")
	_check(GameManager.start_quest("skeleton_menace"), "quest can be started")
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_ACTIVE, "quest is active")
	for _i: int in 3:
		GameManager.quest_log.record_event("kill", "skeleton_forest", 1)
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_READY,
		"3 kills make the quest ready to hand in")
	var xp_before := GameManager.progression.xp
	var level_before := GameManager.progression.level
	var gold_before := GameManager.gold
	var potions_before := GameManager.inventory.count_item("health_potion")
	_check(GameManager.turn_in_quest("skeleton_menace"), "quest turns in")
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_COMPLETED,
		"quest is completed")
	_check(GameManager.progression.xp != xp_before or GameManager.progression.level > level_before,
		"reward xp is applied")
	_check(GameManager.gold == gold_before + 20, "reward gold is applied (+20)")
	_check(GameManager.inventory.count_item("health_potion") == potions_before + 2,
		"reward items are applied (+2 potions)")
	_check(not GameManager.turn_in_quest("skeleton_menace"), "a quest cannot be turned in twice")

# --- save files --------------------------------------------------------------

func _test_save_file() -> void:
	_section("Save files")
	GameManager.start_new_game()
	GameManager.gain_gold(77)
	GameManager.start_quest("sunken_cellar")
	GameManager.quest_log.record_event("visit", "dungeon", 1)
	_check(SaveManager.save_game(SAVE_SLOT), "save writes to disk")
	_check(SaveManager.has_save(SAVE_SLOT), "save file exists")
	var path := SaveManager.path_for(SAVE_SLOT)
	var file := FileAccess.open(path, FileAccess.READ)
	var raw := file.get_as_text()
	file.close()
	_check(raw.contains("\"schema_version\": 3"), "save file carries schema_version 3")
	GameManager.gold = 0
	GameManager.quest_log.entries.clear()
	_check(SaveManager.load_game(SAVE_SLOT), "save loads")
	_check(GameManager.gold == GameManager.STARTING_GOLD + 77, "gold restored (%d)" % GameManager.gold)
	_check(GameManager.quest_log.state_of("sunken_cellar") == QuestLog.STATE_ACTIVE,
		"quest state restored")
	SaveManager.consume_pending()

	# v1 migration: no skills / no world payload.
	var legacy := {
		"schema_version": 1,
		"game": {"gold": 12, "level": 3, "xp": 5, "inventory": {"slots": [], "equipment": {}}},
	}
	var legacy_file := FileAccess.open(SaveManager.path_for(MIGRATE_SLOT), FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy))
	legacy_file.close()
	_check(SaveManager.load_game(MIGRATE_SLOT), "v1 save migrates and loads")
	_check(GameManager.gold == 12, "migrated save keeps gold")
	_check(GameManager.progression.level == 3, "migrated save keeps level")
	SaveManager.consume_pending()

	var corrupt := FileAccess.open(SaveManager.path_for(CORRUPT_SLOT), FileAccess.WRITE)
	corrupt.store_string("{ this is not json")
	corrupt.close()
	_check(not SaveManager.load_game(CORRUPT_SLOT), "corrupt save is refused")
	_check(SaveManager.last_save_error.contains("JSON"), "corrupt save reports a reason")

	var newer := FileAccess.open(SaveManager.path_for(NEWER_SLOT), FileAccess.WRITE)
	newer.store_string(JSON.stringify({"schema_version": 99, "game": {"gold": 1}}))
	newer.close()
	_check(not SaveManager.load_game(NEWER_SLOT), "newer schema version is refused")

	for slot: String in [SAVE_SLOT, MIGRATE_SLOT, CORRUPT_SLOT, NEWER_SLOT]:
		SaveManager.delete_save(slot)

# --- full scene --------------------------------------------------------------

func _test_game_scene() -> void:
	_section("Game scene (world + player + UI)")
	GameManager.start_new_game()
	var packed := load("res://scenes/game/game.tscn") as PackedScene
	_check(packed != null, "game.tscn loads")
	if packed == null:
		return
	var game := packed.instantiate()
	add_child(game)
	await _wait_physics(40)

	var world: WorldRoot = game.get("world")
	var player: Player = game.get("player")
	var ui: UIRoot = game.get("ui")
	_check(world != null, "world root created")
	_check(player != null, "player created")
	_check(ui != null, "ui root created")
	_check(ui.hud != null and ui.touch != null, "HUD and touch controls built")
	_check(world.landmarks.size() > 0, "village landmarks built")
	_check(world.npc_by_id("farmer") != null, "farmer NPC exists")
	_check(world.npc_by_id("guard") != null, "guard NPC exists")
	_check(world.npc_by_id("blacksmith") != null, "blacksmith NPC exists")
	_check(world.creature_count() >= 6, "creatures spawned (%d)" % world.creature_count())

	# Instancing pipeline: every MultiMeshInstance3D must carry a real mesh,
	# otherwise the "cheap" forest would silently render nothing.
	var multimeshes: Array = []
	_collect_multimeshes(world, multimeshes)
	var bad_mm := 0
	for mm: MultiMeshInstance3D in multimeshes:
		if mm.multimesh == null or mm.multimesh.mesh == null or mm.multimesh.instance_count == 0:
			bad_mm += 1
	_check(multimeshes.size() >= 5 and bad_mm == 0,
		"multimesh instancing is real (%d batches, %d broken)" % [multimeshes.size(), bad_mm])
	_check(player.visual.model != null, "player character model instantiated")
	_check(player.visual.available_states.has("idle") and player.visual.available_states.has("run"),
		"animation states resolved from the KayKit clips")
	await _wait_physics(60)
	_check(player.is_on_floor(), "player lands on the ground")
	_check(player.global_position.y > -1.0 and player.global_position.y < 3.0,
		"player stands at ground height (y=%.2f)" % player.global_position.y)

	var mock := MockTouch.new()
	add_child(mock)
	player.input.bind_touch_controls(mock)
	var start := player.global_position
	mock.move_vector = Vector2(0.0, -1.0)
	await _wait_physics(45)
	var moved := player.global_position.distance_to(start)
	_check(moved > 0.5, "joystick input moves the player (%.2fm)" % moved)
	mock.move_vector = Vector2.ZERO
	await _wait_physics(10)

	# Camera orbit + zoom.
	var yaw_before := player.camera_rig.yaw
	player.camera_rig.add_look(Vector2(80.0, 0.0))
	_check(absf(player.camera_rig.yaw - yaw_before) > 0.1, "camera yaw responds to drag")
	var zoom_before := player.camera_rig.current_distance()
	player.camera_rig.add_zoom(1.5)
	_check(absf(player.camera_rig.current_distance() - zoom_before) > 0.5,
		"camera zoom changes distance")

	# Attack a skeleton.
	var skeleton: Creature = null
	for creature: Node in world._creatures.values():
		if creature is Creature and (creature as Creature).data.id == "skeleton_forest":
			skeleton = creature as Creature
			break
	_check(skeleton != null, "a forest skeleton exists")
	if skeleton != null:
		player.global_position = skeleton.global_position + Vector3(0.0, 0.0, 1.4)
		player.rotation.y = 0.0
		await _wait_physics(3)
		var hp_before := skeleton.health.current_health
		var attacked := player.try_attack()
		await _wait_physics(3)
		_check(attacked, "player can swing with stamina")
		_check(skeleton.health.current_health < hp_before,
			"skeleton takes damage (%.1f -> %.1f)" % [hp_before, skeleton.health.current_health])
		_check(skeleton.aggro, "skeleton aggroes when hit")

	# Quest: kill three skeletons then hand in to the farmer.
	GameManager.start_quest("skeleton_menace")
	for creature: Node in world._creatures.values():
		if creature is Creature and (creature as Creature).data.id == "skeleton_forest":
			(creature as Creature).take_hit(9999.0, player, false)
	await _wait_physics(10)
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_READY,
		"killing 3 skeletons completes the objective")
	var farmer := world.npc_by_id("farmer")
	var payload: Dictionary = farmer.dialog_payload()
	_check(payload.get("actions", []).size() > 0, "farmer offers dialog actions")
	var turn_in_action := {"type": "quest_turnin", "quest_id": "skeleton_menace"}
	var result: String = farmer.execute_action(turn_in_action)
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_COMPLETED,
		"farmer accepts the quest turn-in")
	_check(result.contains("Reward"), "turn-in reports the reward")

	# Loot drop from a kill is collectable. (The full-stack test above left the bag
	# saturated, so empty it first — otherwise the pickup is correctly rejected.)
	GameManager.inventory.clear()
	var before_bones := GameManager.inventory.count_item("bone")
	# Use the returned node: earlier kills already dropped loot, so scanning
	# get_children() could grab a different (1-bone) drop.
	var drop: LootDrop = world.spawn_loot_drop([{"id": "bone", "count": 2}],
		player.global_position + Vector3(0.5, 0.0, 0.0))
	await _wait_frames(2)
	_check(drop != null and is_instance_valid(drop), "loot drop spawned")
	if drop != null:
		drop.interact(player)
		await _wait_frames(2)
		_check(GameManager.inventory.count_item("bone") == before_bones + 2,
			"loot is collected into the inventory (got %d)" % GameManager.inventory.count_item("bone"))

	# Zone travel (house door).
	var door: ZoneDoor = null
	for child: Node in world.get_children():
		if child is ZoneDoor and child.name == "HouseDoor":
			door = child as ZoneDoor
			break
	_check(door != null, "house door exists")
	if door != null:
		door.interact(player)
		await _wait_physics(3)
		_check(player.zone == "house", "door moves the player into the house zone")
		_check(player.global_position.distance_to(Vector3(500.0, 0.6, 2.2)) < 3.0,
			"player is inside the house")

	_draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_triangles = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	_fps = Engine.get_frames_per_second()

	# Persist, tear down, reload.
	_check(SaveManager.save_game(SAVE_SLOT), "scene state saves")
	var dead_before := GameManager.world.dead_creatures.size()
	_check(dead_before >= 3, "dead creatures recorded (%d)" % dead_before)
	var position_before := player.global_position
	var creatures_before := world.creature_count()
	_check(creatures_before >= 6, "creature count measured before teardown (%d)" % creatures_before)
	game.queue_free()
	await _wait_frames(3)
	GameManager.reset_state()
	_check(SaveManager.load_game(SAVE_SLOT), "scene state reloads")
	var game2 := packed.instantiate()
	add_child(game2)
	await _wait_physics(30)
	var world2: WorldRoot = game2.get("world")
	var player2: Player = game2.get("player")
	_check(world2.creature_count() < creatures_before,
		"dead creatures stay dead after reload (%d alive vs %d before)"
		% [world2.creature_count(), creatures_before])
	_check(player2.global_position.distance_to(position_before) < 4.0,
		"player position restored (%.1fm off)" % player2.global_position.distance_to(position_before))
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_COMPLETED,
		"quest completion survives reload")
	_check(GameManager.inventory.count_item("bone") >= 2, "inventory survives reload")
	game2.queue_free()
	await _wait_frames(2)

	# 10-round save/load cycle (Phase 7 acceptance criterion).
	var rounds_ok := true
	var rounds_detail := ""
	for round_index in 10:
		GameManager.gain_item("wood", 1)
		var expected := GameManager.inventory.count_item("wood")
		var gold_expected := GameManager.gold
		if not SaveManager.save_game(SAVE_SLOT):
			rounds_ok = false
			rounds_detail = "save failed on round %d" % round_index
			break
		GameManager.reset_state()
		if not SaveManager.load_game(SAVE_SLOT):
			rounds_ok = false
			rounds_detail = "load failed on round %d" % round_index
			break
		var loaded: Dictionary = SaveManager.consume_pending()
		GameManager.apply_dict(loaded.get("game", {}) as Dictionary)
		var got := GameManager.inventory.count_item("wood")
		if got != expected or GameManager.gold != gold_expected:
			rounds_ok = false
			rounds_detail = "round %d: wood %d != %d" % [round_index, got, expected]
			break
	_check(rounds_ok, "save/load survives 10 rounds%s" % ("" if rounds_ok else " (%s)" % rounds_detail))

	SaveManager.delete_save(SAVE_SLOT)

# --- report ------------------------------------------------------------------

func _report() -> void:
	var info := Engine.get_version_info()
	var lines: PackedStringArray = []
	lines.append("MICRO WORLD: LIVING — headless test results")
	lines.append("engine: %s %s" % [info.get("string", "?"), info.get("status", "")])
	lines.append("rendering method: %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	lines.append("run at: %s" % Time.get_datetime_string_from_system(true))
	lines.append("checks passed: %d" % _passes)
	lines.append("checks failed: %d" % _failures.size())
	lines.append("")
	lines.append("renderer metrics (headless dummy driver — device run required for the real numbers):")
	lines.append("  fps: %.1f" % _fps)
	lines.append("  draw calls: %d" % _draw_calls)
	lines.append("  triangles: %d" % _triangles)
	lines.append("  nodes: %d" % int(_nodes))
	lines.append("")
	lines.append("checks:")
	for line: String in _log:
		lines.append(line)
	if not _failures.is_empty():
		lines.append("")
		lines.append("FAILURES:")
		for failure: String in _failures:
			lines.append("  - " + failure)
	var text := "\n".join(lines) + "\n"
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()
	print("")
	print("=== %d passed, %d failed ===" % [_passes, _failures.size()])
	for failure: String in _failures:
		print("FAILED: " + failure)
	get_tree().quit(0 if _failures.is_empty() else 1)
