extends Node3D
## Real GLES3 Screenshot Probe — captures ALL 12 required verification views
## from Section 25 of the Eldoria Master Upgrade Plan:
##   01_main_menu.png
##   02_village_square.png
##   03_guild_exterior.png
##   04_guild_interior.png
##   05_forest_exploration.png
##   06_river_lake_bridge.png
##   07_mountains_sunset.png
##   08_gameplay_combat_hud.png
##   09_inventory_equipment.png
##   10_skill_tree.png
##   11_quest_guild_board.png
##   12_sunken_crypt_dungeon.png

const OUT_DIR := "res://docs/screenshots"
const LOG_PATH := "res://docs/reports/screenshot_probe_log.txt"

const WORLD_SHOTS := [
	{"name": "00_reference_stylized_hud", "zone": "village", "time": 17.017,
		"pos": Vector3(0.35, 0.2, 11.4), "yaw": 2.0, "pitch": -5.0, "dist": 4.0, "hud": true},
	{"name": "02_village_square", "zone": "village", "time": 17.017,
		"pos": Vector3(0.35, 0.2, 11.4), "yaw": 2.0, "pitch": -5.0, "dist": 4.0, "hud": false},
	{"name": "03_guild_exterior", "zone": "village", "time": 16.5,
		"pos": Vector3(1.5, 0.6, -8.5), "yaw": 0.0, "pitch": -8.0, "dist": 9.5, "hud": false},
	{"name": "04_guild_interior", "zone": "guild", "time": 11.0,
		"pos": Vector3(500.0, 0.6, 206.5), "yaw": 0.0, "pitch": -10.0, "dist": 8.2, "hud": false},
	{"name": "05_forest_exploration", "zone": "village", "time": 10.0,
		"pos": Vector3(-52.0, 1.5, -12.0), "yaw": 125.0, "pitch": -14.0, "dist": 10.5, "hud": false},
	{"name": "06_river_lake_bridge", "zone": "village", "time": 14.5,
		"pos": Vector3(41.0, 1.2, 1.2), "yaw": -115.0, "pitch": -16.0, "dist": 10.5, "hud": false},
	{"name": "07_mountains_sunset", "zone": "village", "time": 17.7,
		"pos": Vector3(-2.0, 1.2, 46.0), "yaw": 0.0, "pitch": -12.0, "dist": 16.0, "hud": false},
	{"name": "12_sunken_crypt_dungeon", "zone": "dungeon", "time": 12.0,
		"pos": Vector3(-496.0, 0.6, 28.5), "yaw": 180.0, "pitch": -9.0, "dist": 6.8, "hud": false},
]

var _game: Node
var _player: Player
var _world: WorldRoot
var _ui: UIRoot
var _log: PackedStringArray = []
var _finished := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_watchdog()
	_run()

func _watchdog() -> void:
	await get_tree().create_timer(380.0).timeout
	if _finished:
		return
	_log.append("WATCHDOG: still running after 180s - aborting")
	_flush_log()
	get_tree().quit(2)

func _flush_log() -> void:
	var file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_log) + "\n")
		file.close()

func _note(text: String) -> void:
	_log.append(text)
	print("[shot] " + text)
	_flush_log()

func _run() -> void:
	_note("start: renderer=%s adapter=%s" % [
		ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		RenderingServer.get_video_adapter_name()])
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	# 1. Main Menu First
	var menu: Node = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu)
	await _frames(8)
	await _save("01_main_menu")
	menu.queue_free()
	await _frames(4)

	# 2. Boot Real Eldoria Game Scene
	GameManager.start_new_game()
	_game = load("res://scenes/game/game.tscn").instantiate()
	add_child(_game)
	await _frames(14)

	_player = get_tree().get_first_node_in_group("player") as Player
	_world = get_tree().get_first_node_in_group("world_root") as WorldRoot
	_ui = _game.get("ui") as UIRoot
	if _player == null or _world == null or _ui == null:
		_note("ERROR: missing game nodes")
		get_tree().quit(1)
		return

	# Capture scenic & dungeon views
	for shot: Dictionary in WORLD_SHOTS:
		await _capture_world_shot(shot)

	# 8. Active Combat + Full HUD + Touch Controls
	GameManager.world.time_of_day = 10.2 * 3600.0
	if _world.day_night != null:
		_world.day_night.sync_from_state()
	_player.teleport(Vector3(0.6, 0.6, 9.4), "village")
	var combat_mob := _world.spawn_creature("forest_goblin", "shot_goblin", Vector3(-0.8, 0.6, 6.0))
	var combat_skel := _world.spawn_creature("skeleton_forest", "shot_skel", Vector3(1.6, 0.6, 6.4))
	if combat_mob != null:
		combat_mob.take_hit(14.0, _player, true)
	GameManager.start_quest("main_guild_call")
	GameManager.register_in_guild()
	GameManager.guild.add_reputation(45)
	_ui.visible = true
	_ui.close_current_screen()
	_ui.touch.set_controls_visible(true)
	_ui.hud.refresh_all()
	_set_cam(8.0, -14.0, 8.2)
	await _frames(6)
	await _save("08_gameplay_combat_hud")
	if combat_mob != null and is_instance_valid(combat_mob):
		combat_mob.queue_free()
	if combat_skel != null and is_instance_valid(combat_skel):
		combat_skel.queue_free()

	# 14. Top-down plan of the walled town (free orthographic camera).
	await _capture_city_overview()

	# Populate rich RPG state for UI inspection screenshots
	GameManager.gain_gold(340)
	GameManager.gain_item("steel_greatsword", 1)
	GameManager.gain_item("knight_plate", 1)
	GameManager.gain_item("guild_aegis", 1)
	GameManager.gain_item("guild_ring", 1)
	GameManager.gain_item("eldoria_mythic_blade", 1)
	GameManager.gain_item("mana_elixir", 4)
	GameManager.gain_item("herb_moonpetal", 6)
	GameManager.inventory.equip("steel_greatsword")
	GameManager.inventory.equip("knight_plate")
	GameManager.inventory.equip("guild_aegis")
	GameManager.inventory.equip("guild_ring")
	GameManager.progression.add_xp(360)
	GameManager.skills.add_points(6)
	GameManager.skills.upgrade("mighty_blow")
	GameManager.skills.upgrade("heavy_cleave")
	GameManager.skills.upgrade("iron_skin")
	GameManager.skills.upgrade("fire_bolt")
	GameManager.skills.upgrade("swift_feet")

	# 9. Inventory & 5-Slot Equipment Screen
	_ui.open_screen("inventory")
	_ui.inventory.selected_index = 0
	_ui.inventory.refresh()
	await _frames(6)
	await _save("09_inventory_equipment")

	# 10. Interactive 24-Node Skill Tree Screen
	_ui.open_screen("skills")
	await _frames(6)
	await _save("10_skill_tree")

	# 11. Adventurers Guild & Contracts Board Screen
	GameManager.start_quest("contract_forest_cull")
	_ui.open_screen("guild")
	await _frames(6)
	await _save("11_quest_guild_board")

	# 13. Illustrated Royal Cartography World Map Screen
	_ui.open_screen("map")
	await _frames(6)
	await _save("13_world_map_cartography")

	_ui.close_current_screen()
	_note("all 14 screenshots captured successfully")
	_finished = true
	get_tree().quit(0)

func _capture_world_shot(shot: Dictionary) -> void:
	var zone := String(shot.get("zone", "village"))
	var tod := float(shot.get("time", 10.0)) * 3600.0
	GameManager.world.time_of_day = tod
	if _world.day_night != null:
		_world.day_night.sync_from_state()
	var pos: Vector3 = shot["pos"]
	if zone == "village" and _world != null and _world.terrain != null:
		pos.y = _world.terrain.height_at(pos.x, pos.z) + 0.15
	_player.teleport(pos, zone)
	_player.rotation.y = deg_to_rad(float(shot["yaw"]))
	_set_cam(float(shot["yaw"]), float(shot["pitch"]), float(shot["dist"]))
	if _ui != null:
		var show_hud := bool(shot["hud"])
		_ui.visible = show_hud
		if show_hud:
			SettingsManager.language = "ar"
			_ui.close_current_screen()
			_ui.touch.set_controls_visible(true)
			_ui.hud.refresh_all()
	await _frames(6)
	await _save(String(shot["name"]))
	if _ui != null:
		_ui.visible = true

## North is up, east is right: the same orientation as the world map, so the
## two can be compared directly.
func _capture_city_overview() -> void:
	GameManager.world.time_of_day = 12.5 * 3600.0
	if _world.day_night != null:
		_world.day_night.sync_from_state()
	_player.teleport(Vector3(0.0, 0.6, 14.0), "village")
	var cam := Camera3D.new()
	cam.name = "CityOverviewCamera"
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 86.0
	cam.near = 1.0
	cam.far = 220.0
	_world.add_child(cam)
	cam.global_position = Vector3(0.0, 64.0, 0.0)
	cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var previous := get_viewport().get_camera_3d()
	cam.make_current()
	var env: Environment = _world.environment
	var fog_was := env.fog_enabled if env != null else false
	if env != null:
		env.fog_enabled = false
	if _ui != null:
		_ui.visible = false
	# Distance culling is tuned for the third-person camera; from 64 m up it
	# would hide every house, so lift it for this one capture.
	var ranges: Array = []
	var stack: Array[Node] = [_world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		var gi := node as GeometryInstance3D
		if gi != null and gi.visibility_range_end > 0.0:
			ranges.append([gi, gi.visibility_range_end])
			gi.visibility_range_end = 0.0
	await _frames(6)
	await _save("14_city_overview")
	for entry: Array in ranges:
		if is_instance_valid(entry[0]):
			(entry[0] as GeometryInstance3D).visibility_range_end = float(entry[1])
	if env != null:
		env.fog_enabled = fog_was
	if previous != null and is_instance_valid(previous):
		previous.make_current()
	cam.queue_free()
	if _ui != null:
		_ui.visible = true
	await _frames(2)

func _set_cam(yaw_deg: float, pitch_deg: float, dist: float) -> void:
	var rig := _player.camera_rig
	if rig == null:
		return
	rig.snap_to_parent()
	rig.yaw = deg_to_rad(yaw_deg)
	rig.pitch = pitch_deg
	rig._target_distance = dist
	if rig.spring_arm != null:
		rig.spring_arm.spring_length = dist

func _save(shot_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var texture := get_viewport().get_texture()
	if texture == null:
		_note("ERROR: no viewport texture for " + shot_name)
		return
	var image := texture.get_image()
	if image == null:
		_note("ERROR: no image for " + shot_name)
		return
	var path := "%s/%s.png" % [OUT_DIR, shot_name]
	var err := image.save_png(path)
	_note("%s -> %s (%s)" % [shot_name, path, "ok" if err == OK else "err %d" % err])

func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
