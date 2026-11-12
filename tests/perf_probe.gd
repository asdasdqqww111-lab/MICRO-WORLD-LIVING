extends Node3D
## Real performance probe (Phase 1 + 2 acceptance).
##
## Headless (`--headless`) uses the dummy renderer and reports zeros — that is
## expected. Run it with a real rasteriser to get numbers:
##   xvfb-run -a godot --path . --rendering-driver opengl3 tests/perf_probe.tscn
## Results are appended to res://docs/reports/perf_probe_results.txt.

const OUT_PATH := "res://docs/reports/perf_probe_results.txt"
const SETTLE_FRAMES := 40
const SAMPLE_FRAMES := 90

var _game: Node
var _player: Player
var _world: WorldRoot
var _lines: PackedStringArray = []

func _ready() -> void:
	_run()

func _run() -> void:
	_lines.append("MICRO WORLD: LIVING — performance probe")
	_lines.append("engine: %s" % Engine.get_version_info().get("string", "?"))
	_lines.append("rendering method: %s" % ProjectSettings.get_setting(
		"rendering/renderer/rendering_method"))
	_lines.append("video adapter: %s" % RenderingServer.get_video_adapter_name())
	_lines.append("driver: %s" % RenderingServer.get_video_adapter_api_version())
	_lines.append("run at: %s" % Time.get_datetime_string_from_system(true))
	_lines.append("")
	_lines.append("budget: draw calls < 200 (hard cap 300) · triangles < 150k · fps >= 30")
	_lines.append("")

	_game = load("res://scenes/game/game.tscn").instantiate()
	add_child(_game)
	await _frames(SETTLE_FRAMES)

	_player = get_tree().get_first_node_in_group("player") as Player
	_world = get_tree().get_first_node_in_group("world_root") as WorldRoot
	if _player == null or _world == null:
		_lines.append("FATAL: player or world missing")
		_write()
		get_tree().quit(1)
		return

	# --- Phase 1: third person prototype scene -------------------------------
	await _measure("Phase 1 · village spawn (player + camera + ground)")

	# --- Phase 2: combat with 3 enemies --------------------------------------
	var spawn_uid := 0
	for i in 3:
		var offset := Vector3(4.0 + float(i) * 1.6, 0.6, -4.0 - float(i) * 1.2)
		_world.spawn_creature("skeleton_forest", "perf_probe_%d" % spawn_uid, offset)
		spawn_uid += 1
	await _frames(30)
	_lines.append("  creatures in world: %d" % _world.creature_count())
	await _measure("Phase 2 · village + 3 skeletons")

	# --- Phase 3/5: other zones ---------------------------------------------
	await _teleport_and_measure("Phase 3 · forest (MultiMesh trees)",
		Vector3(-60.0, 1.0, 0.0))
	await _teleport_and_measure("Phase 3 · house interior", Vector3(500.0, 1.0, 2.0))
	await _teleport_and_measure("Phase 5 · dungeon", Vector3(-500.0, 1.0, 3.0))

	_structural_audit()

	_write()
	print("\n".join(_lines))
	get_tree().quit(0)

## Renderer-independent scene audit. Works even with the dummy driver, so CI
## still produces useful data if the software GL path is unavailable.
func _structural_audit() -> void:
	var meshes := 0
	var multimeshes := 0
	var multimesh_instances := 0
	var particles := 0
	var omni_lights := 0
	var shadow_lights := 0
	var total_nodes := 0
	var stack: Array[Node] = [_game]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		total_nodes += 1
		if node is MeshInstance3D:
			meshes += 1
		elif node is MultiMeshInstance3D:
			multimeshes += 1
			var mm := (node as MultiMeshInstance3D).multimesh
			if mm != null:
				multimesh_instances += mm.instance_count
		elif node is GPUParticles3D:
			particles += 1
		elif node is OmniLight3D:
			omni_lights += 1
		elif node is DirectionalLight3D:
			if (node as DirectionalLight3D).shadow_enabled:
				shadow_lights += 1
		for child: Node in node.get_children():
			stack.append(child)
	_lines.append("")
	_lines.append("SCENE AUDIT (renderer independent)")
	_lines.append("  nodes total:          %d" % total_nodes)
	_lines.append("  MeshInstance3D:       %d" % meshes)
	_lines.append("  MultiMeshInstance3D:  %d (batches) / %d instances" % [multimeshes, multimesh_instances])
	_lines.append("  GPUParticles3D:       %d" % particles)
	_lines.append("  omni lights:          %d" % omni_lights)
	_lines.append("  shadow casting dir:   %d" % shadow_lights)
	_lines.append("  => worst-case draw call bound (1 per MeshInstance3D surface,")
	_lines.append("     1 per MultiMesh batch): %d + surfaces" % (meshes + multimeshes))

func _teleport_and_measure(label: String, position: Vector3) -> void:
	_player.global_position = position
	_player.velocity = Vector3.ZERO
	await _frames(25)
	await _measure(label)

func _measure(label: String) -> void:
	var max_draw := 0.0
	var max_tris := 0.0
	var max_objects := 0.0
	var max_mem := 0.0
	var min_fps := 9999.0
	for i in SAMPLE_FRAMES:
		await get_tree().process_frame
		max_draw = maxf(max_draw, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		max_tris = maxf(max_tris, Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		max_objects = maxf(max_objects, Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		max_mem = maxf(max_mem, Performance.get_monitor(Performance.MEMORY_STATIC))
		var fps := Performance.get_monitor(Performance.TIME_FPS)
		if fps > 0.0:
			min_fps = minf(min_fps, fps)
	var draw_ok := "OK" if max_draw < 200.0 else ("OVER" if max_draw < 300.0 else "FAIL")
	var tri_ok := "OK" if max_tris < 150000.0 else "OVER"
	_lines.append("%s" % label)
	_lines.append("  draw calls (max): %d  [%s]" % [int(max_draw), draw_ok])
	_lines.append("  triangles (max):  %d  [%s]" % [int(max_tris), tri_ok])
	_lines.append("  objects:          %d" % int(max_objects))
	_lines.append("  static memory:    %.1f MB" % (max_mem / 1048576.0))
	_lines.append("  fps (min, this driver): %.1f" % min_fps)

func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func _write() -> void:
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("perf probe: cannot write " + OUT_PATH)
		return
	file.store_string("\n".join(_lines) + "\n")
	file.close()
