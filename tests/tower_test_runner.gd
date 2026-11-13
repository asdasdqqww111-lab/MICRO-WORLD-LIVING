extends Node
## Automated acceptance suite for the Celestial Ascent Tower (100 floors).
## Mirrors tests/test_runner.gd conventions: self-contained scene, PASS/FAIL
## lines, final "checks passed: N / checks failed: M", exit code 1 on failure.

const RESULTS_PATH := "docs/reports/tower_test_results.txt"
var _lines: Array[String] = []
var _passed := 0
var _failed := 0

func _ready() -> void:
	await _run()
	_write_results()
	print("\n=== TOWER SUITE: %d passed, %d failed ===" % [_passed, _failed])
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(1 if _failed > 0 else 0)

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_passed += 1
		_lines.append("PASS  %s" % name)
		print("PASS  %s" % name)
	else:
		_failed += 1
		var suffix := ("  |  " + detail) if not detail.is_empty() else ""
		_lines.append("FAIL  %s%s" % [name, suffix])
		push_error("FAIL  %s%s" % [name, suffix])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/reports")
	var started := Time.get_ticks_msec()
	_lines.append("MICRO WORLD: LIVING — Celestial Ascent Tower acceptance suite")
	_lines.append("run at: %s" % Time.get_datetime_string_from_system(true))
	_lines.append("")

	# ===== 1. TowerDB integrity =====
	_lines.append("== TowerDB integrity ==")
	var report: Dictionary = TowerDB.validate()
	_check("TowerDB.validate() reports no errors", bool(report["valid"]),
		", ".join((report["errors"] as Array[String]).slice(0, 6)))
	_check("TowerDB defines exactly 100 floors", TowerDB.FLOOR_COUNT == 100)
	_check("TowerDB defines 10 regions", TowerDB.REGIONS.size() == 10)
	var region_ok := true
	for f in range(1, 101):
		var rk := TowerDB.region_for_floor(f)
		if not TowerDB.REGIONS.has(rk):
			region_ok = false
			break
		var r: Dictionary = TowerDB.REGIONS[rk]
		if String(r.get("en", "")).is_empty() or String(r.get("ar", "")).is_empty():
			region_ok = false
			break
	_check("All 100 floors map to bilingual regions", region_ok)
	_check("Floor 1 is ancient_ruins", TowerDB.region_for_floor(1) == "ancient_ruins")
	_check("Floor 11 is crystal_caverns", TowerDB.region_for_floor(11) == "crystal_caverns")
	_check("Floor 100 is divine_battlefield", TowerDB.region_for_floor(100) == "divine_battlefield")
	_check("Floor Master EN #100 is the final boss",
		TowerDB.master_name(100) == "Celestial Sovereign Astraeus, the Eternal Crown")
	_check("Floor Master AR #100 is the final boss (Arabic)",
		TowerDB.master_name_ar(100) == "أسترايوس سيادة السماوات، التاج الأبدي")
	var en_set := {}
	var ar_set := {}
	for f in range(1, 101):
		en_set[TowerDB.master_name(f)] = true
		ar_set[TowerDB.master_name_ar(f)] = true
	_check("100 unique EN Floor Master names", en_set.size() == 100, "got %d" % en_set.size())
	_check("100 unique AR Floor Master names", ar_set.size() == 100, "got %d" % ar_set.size())
	_check("Floor Master #1 EN is Gravelord Vash", TowerDB.master_name(1) == "Gravelord Vash")

	# ===== 2. Stat scaling =====
	_lines.append("")
	_lines.append("== Stat scaling ==")
	var s1: Dictionary = TowerDB.master_stats(1)
	var s50: Dictionary = TowerDB.master_stats(50)
	var s100: Dictionary = TowerDB.master_stats(100)
	_check("Master HP scales up across the tower", float(s100["hp"]) > float(s50["hp"]) and float(s50["hp"]) > float(s1["hp"]))
	_check("Master damage scales up across the tower", float(s100["damage"]) > float(s50["damage"]))
	_check("Master XP reward scales up", int(s100["xp"]) > int(s1["xp"]))
	_check("Final master HP is 8x+ the first master", float(s100["hp"]) >= float(s1["hp"]) * 8.0)
	_check("master_stats deterministic for floor 37",
		TowerDB.master_stats(37)["hp"] == TowerDB.master_stats(37)["hp"])
	var mob1: Dictionary = TowerDB.mob_stats(1)
	_check("Floor 1 mob stats well-formed", int(mob1["count"]) >= 3 and float(mob1["hp"]) > 0.0)
	_check("Mob count within mobile budget (<= 5)", int(TowerDB.mob_stats(64)["count"]) <= 5)

	# ===== 3. Geometry =====
	_lines.append("")
	_lines.append("== Geometry ==")
	var o1 := TowerDB.floor_origin(1)
	var o2 := TowerDB.floor_origin(2)
	_check("Floor origins stack on FLOOR_STRIDE", absf((o2.y - o1.y) - TowerDB.FLOOR_STRIDE) < 0.001)
	_check("Floor origins share TOWER_ORIGIN x/z",
		o1.x == TowerDB.TOWER_ORIGIN.x and o1.z == TowerDB.TOWER_ORIGIN.z)
	_check("Floor spawn sits 1.2m above the origin", absf(TowerDB.floor_spawn(7).y - TowerDB.floor_origin(7).y - 1.2) < 0.001)
	_check("Overworld gate is outside city radius (>58m)",
		Vector2(TowerDB.TOWER_GATE_OVERWORLD.x, TowerDB.TOWER_GATE_OVERWORLD.z).length() > 58.0)
	_check("Tower interiors sit far outside the map (>400m)",
		Vector2(TowerDB.TOWER_ORIGIN.x, TowerDB.TOWER_ORIGIN.z).length() > 400.0)
	_check("Floor 100 origin is 594m above ground", absf(TowerDB.floor_origin(100).y - 594.0) < 0.001)

	# ===== 4. Floor builder =====
	_lines.append("")
	_lines.append("== Floor builder (real nodes) ==")
	GameManager.reset_state()
	var root := Node3D.new()
	root.name = "TestTowerRoot"
	add_child(root)
	var anchors: Dictionary = TowerFloorBuilder.build_floor(root, 23)
	_check("Floor23 anchors returned", not anchors.is_empty())
	var froot: Node = anchors["root"]
	_check("Floor23 root is a real node in tree", froot.is_inside_tree())
	_check("Floor23 has a walkable platform collider", froot.has_node("FloorPlatform"))
	_check("Floor23 has all 4 walls", froot.has_node("Wall0") and froot.has_node("Wall3"))
	_check("Floor23 has all 4 pillars", froot.has_node("Pillar3"))
	_check("Floor23 has a boss arena ring", froot.has_node("BossArenaRing"))
	_check("Floor23 has a floor light", froot.has_node("FloorLight"))
	_check("Floor23 belongs to magical_forest region", TowerDB.region_for_floor(23) == "magical_forest")
	for child in root.get_children():
		child.queue_free()
	await get_tree().process_frame
	_check("Floor nodes freed after queue_free", root.get_child_count() <= 1)
	root.queue_free()

	# ===== 5. TowerManager runtime =====
	_lines.append("")
	_lines.append("== TowerManager runtime ==")
	var world := WorldRoot.new()
	world.name = "World"
	add_child(world)
	var tm := TowerManager.new()
	tm.name = "TestTower"
	tm.world = world
	add_child(tm)
	await get_tree().process_frame

	_check("Manager built the overworld gate portal", tm.gate_portal != null and tm.gate_portal.is_inside_tree())
	_check("Manager gate is an Interactable", tm.gate_portal is Interactable)
	_check("Floor 1 unlocked from the start", tm.highest_unlocked_floor() == 1)
	_check("No floors cleared initially", tm.floors_cleared() == 0)
	_check("Floor 1 master not defeated initially", not tm.is_master_defeated(1))

	var fp := FakeTowerPlayer.new()
	fp.name = "FakePlayer"
	add_child(fp)

	tm.player_entered(fp)
	_check("Entering the tower loads floor 1", tm.active_floor() == 1)
	_check("Tower zone container became visible", tm.tower_root.visible)
	_check("Floor 1 has an exit portal", tm.floor_container.get_node_or_null("TowerExitPortal") != null)
	_check("Floor 1 has an ascent portal", tm.floor_container.get_node_or_null("TowerUpPortal") != null)
	_check("Floor 1 spawned creatures (mobs + master)", world.creature_count() > 0)
	_check("Player teleported into the tower zone", fp.zone == "tower")
	_check("Current floor persisted in world flags",
		int(GameManager.world.get_flag("tower_current_floor", 0)) == 1)

	tm.ascend(fp)
	_check("Cannot ascend before Floor Master defeat", tm.active_floor() == 1)

	EventBus.creature_died.emit("tower_master_1", "tower_f1_master_0", Vector3.ZERO)
	_check("Floor 1 master defeat recorded", tm.is_master_defeated(1))
	_check("Floor 2 becomes reachable", tm.highest_unlocked_floor() == 2)
	_check("floors_cleared counts 1", tm.floors_cleared() == 1)

	tm.ascend(fp)
	_check("Ascending after defeat loads floor 2", tm.active_floor() == 2)
	_check("Only ONE floor container child loaded at a time", tm.floor_container.get_child_count() >= 1
		and tm.floor_container.get_child_count() <= 2)

	tm._load_floor(100, fp)
	_check("Floor 100 loads", tm.active_floor() == 100)
	_check("Floor 100 has NO ascent portal (final)", tm.floor_container.get_node_or_null("TowerUpPortal") == null)
	_check("Floor 100 still has an exit portal", tm.floor_container.get_node_or_null("TowerExitPortal") != null)

	EventBus.creature_died.emit("tower_master_100", "tower_f100_master_0", Vector3.ZERO)
	_check("Tower completion flag set on final master defeat",
		bool(GameManager.world.get_flag("tower_completed", false)))
	_check("floors_cleared counts both defeated masters", tm.floors_cleared() == 2)

	# ===== 6. Persistence =====
	_lines.append("")
	_lines.append("== Persistence ==")
	var wd: Dictionary = GameManager.world.to_dict()
	var restored := WorldState.new()
	restored.from_dict(wd)
	_check("Master defeat flags survive WorldState round-trip",
		restored.get_flag("tower_master_1", false) == true
		and restored.get_flag("tower_master_100", false) == true)
	_check("Current floor flag survives round-trip",
		int(restored.get_flag("tower_current_floor", 0)) == 100)
	_check("Completion flag survives round-trip",
		bool(restored.get_flag("tower_completed", false)))

	tm.player_exited(fp)
	_check("Exiting hides the tower interior", not tm.tower_root.visible)
	_check("Exit returns the player to the overworld zone", fp.zone == "village")

	tm.queue_free()
	world.queue_free()
	fp.queue_free()
	await get_tree().process_frame

	_lines.append("")
	_lines.append("elapsed: %d ms" % (Time.get_ticks_msec() - started))
	_lines.append("checks passed: %d" % _passed)
	_lines.append("checks failed: %d" % _failed)

func _write_results() -> void:
	var file := FileAccess.open("res://%s" % RESULTS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_lines) + "\n")
		file.close()

## Minimal stand-in for Player: records teleports like the real controller.
class FakeTowerPlayer:
	extends CharacterBody3D
	var zone := "village"
	func teleport(pos: Vector3, zone_id: String) -> void:
		global_position = pos
		zone = zone_id
