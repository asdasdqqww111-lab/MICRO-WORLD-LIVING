extends Node3D
## Renders the real game to PNGs so the visuals can be reviewed with evidence.
## Requires a real rasteriser (CI runs it under xvfb + Mesa GLES3):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     tests/screenshot_probe.tscn
## Output: res://docs/screenshots/*.png (committed by CI).

const OUT_DIR := "res://docs/screenshots"

# name, player position, camera yaw (deg), camera pitch (deg), distance, hud
const SHOTS := [
	{"name": "01_village_overview", "pos": Vector3(-8.0, 0.0, 16.0), "yaw": 18.0, "pitch": -20.0, "dist": 24.0, "hud": false},
	{"name": "02_village_street", "pos": Vector3(2.0, 0.0, 7.0), "yaw": 165.0, "pitch": -8.0, "dist": 7.0, "hud": false},
	{"name": "03_mountains", "pos": Vector3(0.0, 0.0, 12.0), "yaw": 0.0, "pitch": 4.0, "dist": 10.0, "hud": false},
	{"name": "04_sky_clouds", "pos": Vector3(-4.0, 0.0, 18.0), "yaw": 40.0, "pitch": 26.0, "dist": 8.0, "hud": false},
	{"name": "05_forest_floor", "pos": Vector3(-46.0, 0.0, 4.0), "yaw": 95.0, "pitch": -10.0, "dist": 9.0, "hud": false},
	{"name": "06_house_interior", "pos": Vector3(500.0, 0.0, 2.0), "yaw": 0.0, "pitch": -8.0, "dist": 7.0, "hud": false},
	{"name": "07_dungeon", "pos": Vector3(-500.0, 0.0, 4.0), "yaw": 0.0, "pitch": -6.0, "dist": 8.0, "hud": false},
	{"name": "08_gameplay_hud", "pos": Vector3(-2.0, 0.0, 10.0), "yaw": 25.0, "pitch": -14.0, "dist": 11.0, "hud": true},
]

const LOG_PATH := "res://docs/reports/screenshot_probe_log.txt"

var _game: Node
var _player: Player
var _ui: Node
var _log: PackedStringArray = []
var _finished := false

func _ready() -> void:
	_watchdog()
	_run()

## Hard safety net: never leave CI hanging if a coroutine dies on a script error.
func _watchdog() -> void:
	await get_tree().create_timer(120.0).timeout
	if _finished:
		return
	_log.append("WATCHDOG: still running after 120s - aborting")
	_flush_log()
	print("screenshot probe: watchdog timeout")
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
	_game = load("res://scenes/game/game.tscn").instantiate()
	add_child(_game)
	await _frames(40)

	_player = get_tree().get_first_node_in_group("player") as Player
	_ui = _find_ui()
	_note("scene ready: player=%s ui=%s" % [str(_player != null), str(_ui != null)])
	if _player == null:
		push_error("screenshot probe: no player")
		get_tree().quit(1)
		return

	# Fixed morning light so every capture is comparable run-to-run.
	if GameManager.world != null:
		GameManager.world.hour = 9.0

	for shot: Dictionary in SHOTS:
		await _capture(shot)

	# Main menu last (needs the game scene gone).
	_game.queue_free()
	await _frames(6)
	var menu: Node = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu)
	await _frames(15)
	await _save("09_main_menu")
	_note("done")
	_finished = true
	get_tree().quit(0)

func _capture(shot: Dictionary) -> void:
	_player.global_position = shot["pos"] as Vector3
	_player.velocity = Vector3.ZERO
	var rig := _player.camera_rig
	if rig == null:
		_note("ERROR: camera_rig is null")
		return
	rig.yaw = deg_to_rad(float(shot["yaw"]))
	rig.pitch = float(shot["pitch"])
	rig._target_distance = float(shot["dist"])
	if rig.spring_arm != null:
		rig.spring_arm.spring_length = float(shot["dist"])
	if _ui != null:
		_ui.visible = bool(shot["hud"])
	await _frames(18)
	await _save(String(shot["name"]))
	_note("captured %s" % String(shot["name"]))
	if _ui != null:
		_ui.visible = true

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

func _find_ui() -> Node:
	for child: Node in _game.get_children():
		if child is CanvasLayer and child.name.to_lower().contains("ui"):
			return child
	for child: Node in _game.get_children():
		if child is CanvasLayer:
			return child
	return null

func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
