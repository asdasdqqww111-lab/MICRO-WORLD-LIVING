extends Node3D
## Real GLES3 Performance Probe across Eldoria Overworld, Biomes, Guild Hall, Cottage & Dungeon.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 tests/perf_probe.tscn

const OUT_PATH := "res://docs/reports/perf_probe_results.txt"
const SETTLE_FRAMES := 30
const SAMPLE_FRAMES := 50

var _game: Node
var _player: Player
var _world: WorldRoot
var _lines: PackedStringArray = []
var _finished: bool = false

func _ready() -> void:
	_watchdog()
	_run()

func _watchdog() -> void:
	await get_tree().create_timer(160.0).timeout
	if _finished:
		return
	_lines.append("WATCHDOG: perf_probe timed out after 160s")
	_flush(true)
	get_tree().quit(2)

func _run() -> void:
	_lines.append("MICRO WORLD: LIVING — Eldoria Edition v1.0 GLES3 Performance Probe")
	_lines.append("engine: %s" % Engine.get_version_info().get("string", "?"))
	_lines.append("rendering method: %s" % ProjectSettings.get_setting(
		"rendering/renderer/rendering_method"))
	_lines.append("video adapter: %s" % RenderingServer.get_video_adapter_name())
	_lines.append("driver: %s" % RenderingServer.get_video_adapter_api_version())
	_lines.append("run at: %s" % Time.get_datetime_string_from_system(true))
	_lines.append("")
	_lines.append("budget: draw calls < 250 (hard cap 350) · triangles < 180k · fps >= 30")
	_lines.append("")
	_flush()

	_game = load("res://scenes/game/game.tscn").instantiate()
	add_child(_game)
	await _frames(SETTLE_FRAMES)

	_player = get_tree().get_first_node_in_group("player") as Player
	_world = get_tree().get_first_node_in_group("world_root") as WorldRoot
	if _player == null or _world == null:
		_lines.append("FATAL: player or world missing")
		_flush(true)
		get_tree().quit(1)
		return

	await _measure("Zone 1 · Eldoria Village Square & Guild Exterior")

	for i in 3:
		_world.spawn_creature("skeleton_forest", "perf_probe_%d" % i,
			Vector3(4.0 + float(i) * 1.6, 0.6, 4.0 - float(i) * 1.2))
	await _frames(20)
	_lines.append("  creatures in world: %d" % _world.creature_count())
	await _measure("Zone 2 · Active Combat (Village + 3 Skeletons)")

	await _teleport_and_measure("Zone 3 · Western Woodland (MultiMesh Trees + Undergrowth)", Vector3(-52.0, 2.0, 6.0), "village")
	await _teleport_and_measure("Zone 4 · River, Stone Bridge & Crystal Lake", Vector3(36.0, 1.0, 18.0), "village")
	await _teleport_and_measure("Zone 5 · Adventurers Guild Grand Hall Interior", Vector3(500.0, 0.6, 207.5), "guild")
	await _teleport_and_measure("Zone 6 · Hero Cottage Interior", Vector3(500.0, 0.6, 2.2), "house")
	await _teleport_and_measure("Zone 7 · Sunken Crypt Dungeon & Boss Sanctum", Vector3(-496.0, 0.6, 28.5), "dungeon")

	# Return to village before structural audit so overworld counts are visible
	_player.teleport(Vector3(0.0, 0.6, 12.0), "village")
	await _frames(6)
	_safe_step("structural audit", _structural_audit)
	_safe_step("offenders", _offenders)

	_flush(true)
	print("\n".join(_lines))
	_finished = true
	get_tree().quit(0)

func _safe_step(label: String, method: Callable) -> void:
	_lines.append("")
	_lines.append("--- running %s ---" % label)
	_flush()
	method.call()
	_lines.append("--- %s done ---" % label)
	_flush()

func _teleport_and_measure(label: String, position: Vector3, zone: String) -> void:
	_player.teleport(position, zone)
	await _frames(20)
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
		var fps := Engine.get_frames_per_second()
		if fps > 0.0:
			min_fps = minf(min_fps, fps)
	if min_fps > 9000.0:
		min_fps = 0.0
	var draw_flag := "OK" if max_draw < 250.0 else ("WARN" if max_draw < 350.0 else "FAIL")
	var tri_flag := "OK" if max_tris < 180000.0 else "OVER"
	_lines.append("%s" % label)
	_lines.append("  draw calls (max): %d  [%s]" % [int(max_draw), draw_flag])
	_lines.append("  triangles (max):  %d  [%s]" % [int(max_tris), tri_flag])
	_lines.append("  objects:          %d" % int(max_objects))
	_lines.append("  static memory:    %.1f MB" % (max_mem / 1048576.0))
	_lines.append("  fps (min, this driver): %.1f" % min_fps)
	_flush()

func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

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
		if not is_instance_valid(node):
			continue
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
	_lines.append("SCENE AUDIT (renderer independent)")
	_lines.append("  nodes total:          %d" % total_nodes)
	_lines.append("  MeshInstance3D:       %d" % meshes)
	_lines.append("  MultiMeshInstance3D:  %d (batches) / %d instances" % [multimeshes, multimesh_instances])
	_lines.append("  GPUParticles3D:       %d" % particles)
	_lines.append("  omni lights:          %d" % omni_lights)
	_lines.append("  shadow casting dir:   %d" % shadow_lights)
	_flush()

func _mesh_triangles(mesh: Mesh) -> int:
	var total := 0
	if mesh == null:
		return 0
	var surfaces := mesh.get_surface_count()
	for i in surfaces:
		var arrays: Array = []
		if mesh is ArrayMesh:
			arrays = (mesh as ArrayMesh).surface_get_arrays(i)
		if arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] != null:
			var verts: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var indices := 0
			if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null:
				indices = (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()
			total += (indices / 3) if indices > 0 else (verts / 3)
	return total

func _offenders() -> void:
	var rows: Array = []
	var shadow_casters := 0
	var unshadowed := 0
	var with_lod := 0
	var stack: Array[Node] = [_game]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if not is_instance_valid(node):
			continue
		for child: Node in node.get_children():
			stack.append(child)
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			var surfaces := mi.mesh.get_surface_count()
			if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				shadow_casters += 1
			else:
				unshadowed += 1
			if mi.visibility_range_end > 0.0:
				with_lod += 1
			rows.append({"name": _path_of(mi), "surfaces": surfaces,
				"tris": _mesh_triangles(mi.mesh)})
			continue
		var mmi := node as MultiMeshInstance3D
		if mmi != null and mmi.multimesh != null and mmi.multimesh.mesh != null:
			rows.append({"name": "%s [x%d]" % [_path_of(mmi), mmi.multimesh.instance_count],
				"surfaces": mmi.multimesh.mesh.get_surface_count(),
				"tris": _mesh_triangles(mmi.multimesh.mesh) * mmi.multimesh.instance_count})
	_lines.append("")
	_lines.append("TOP TRIANGLE CONSUMERS (whole world)")
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["tris"]) > int(b["tris"]))
	for i in mini(14, rows.size()):
		var r: Dictionary = rows[i]
		_lines.append("  %7d tris | %2d surf | %s" % [int(r["tris"]), int(r["surfaces"]), String(r["name"])])
	_lines.append("")
	_lines.append("SHADOW / LOD: casters=%d  shadow_off=%d  with_visibility_range=%d" % [
		shadow_casters, unshadowed, with_lod])
	_flush()

func _path_of(node: Node) -> String:
	var parts: PackedStringArray = []
	var current := node
	while current != null and current != _game and parts.size() < 4:
		parts.insert(0, String(current.name))
		current = current.get_parent()
	return "/".join(parts)

func _flush(final: bool = false) -> void:
	var text := "\n".join(_lines) + "\n"
	if final:
		text += "\nSTATUS: COMPLETE\n"
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("perf probe: cannot write " + OUT_PATH)
		return
	file.store_string(text)
	file.close()
