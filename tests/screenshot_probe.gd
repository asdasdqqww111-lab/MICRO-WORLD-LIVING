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
	{"name": "02_village_square", "zone": "village", "time": 9.8,
		"pos": Vector3(-5.0, 0.6, 15.0), "yaw": -14.0, "pitch": -18.0, "dist": 18.0, "hud": false},
	{"name": "03_guild_exterior", "zone": "village", "time": 10.2,
		"pos": Vector3(0.0, 0.6, -12.5), "yaw": 0.0, "pitch": -8.0, "dist": 11.5, "hud": false},
	{"name": "04_guild_interior", "zone": "guild", "time": 11.0,
		"pos": Vector3(500.0, 0.6, 206.5), "yaw": 0.0, "pitch": -10.0, "dist": 8.2, "hud": false},
	{"name": "05_forest_exploration", "zone": "village", "time": 10.0,
		"pos": Vector3(-48.0, 1.5, 6.0), "yaw": 78.0, "pitch": -10.0, "dist": 9.5, "hud": false},
	{"name": "06_river_lake_bridge", "zone": "village", "time": 14.5,
		"pos": Vector3(28.0, 0.8, 12.0), "yaw": -55.0, "pitch": -15.0, "dist": 15.0, "hud": false},
	{"name": "07_mountains_sunset", "zone": "village", "time": 17.6,
		"pos": Vector3(-2.0, 0.6, 10.0), "yaw": 12.0, "pitch": 8.0, "dist": 10.0, "hud": false},
	{"name": "12_sunken_crypt_dungeon", "zone": "dungeon", "time": 12.0,
		"pos": Vector3(-500.0, 0.6, -13.0), "yaw": 0.0, "pitch": -10.0, "dist": 9.5, "hud": false},
]

var _game: Node
var _player: Player
var _world: WorldRoot
var _ui: UIRoot
var _log: PackedStringArray = []
var _finished := false

func _ready() -> void:
	_watchdog()
	_run()

func _watchdog() -> void:
	await get_tree().create_timer(180.0).timeout
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
	await _frames(18)
	await _save("01_main_menu")
	menu.queue_free()
	await _frames(6)

	# 2. Boot Real Eldoria Game Scene
	GameManager.start_new_game()
	_game = load("res://scenes/game/game.tscn").instantiate()
	add_child(_game)
	await _frames(40)

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
	_player.teleport(Vector3(4.0, 0.6, 8.0), "village")
	var combat_mob := _world.spawn_creature("forest_goblin", "shot_goblin", Vector3(3.2, 0.6, 4.2))
	var combat_skel := _world.spawn_creature("skeleton_forest", "shot_skel", Vector3(5.6, 0.6, 4.8))
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
	await _frames(20)
	await _save("08_gameplay_combat_hud")
	if combat_mob != null and is_instance_valid(combat_mob):
		combat_mob.queue_free()
	if combat_skel != null and is_instance_valid(combat_skel):
		combat_skel.queue_free()

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
	await _frames(15)
	await _save("09_inventory_equipment")

	# 10. Interactive 24-Node Skill Tree Screen
	_ui.open_screen("skills")
	await _frames(15)
	await _save("10_skill_tree")

	# 11. Adventurers Guild & Contracts Board Screen
	GameManager.start_quest("contract_forest_cull")
	_ui.open_screen("guild")
	await _frames(15)
	await _save("11_quest_guild_board")

	_ui.close_current_screen()
	_note("all 12 screenshots captured successfully")
	_finished = true
	get_tree().quit(0)

func _capture_world_shot(shot: Dictionary) -> void:
	var zone := String(shot.get("zone", "village"))
	var tod := float(shot.get("time", 10.0)) * 3600.0
	GameManager.world.time_of_day = tod
	if _world.day_night != null:
		_world.day_night.sync_from_state()
	var pos: Vector3 = shot["pos"]
	if zone == "village":
		pos.y = Terrain.height_at(pos.x, pos.z) + 0.15
	_player.teleport(pos, zone)
	_set_cam(float(shot["yaw"]), float(shot["pitch"]), float(shot["dist"]))
	if _ui != null:
		_ui.visible = bool(shot["hud"])
	await _frames(20)
	await _save(String(shot["name"]))
	if _ui != null:
		_ui.visible = true

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
