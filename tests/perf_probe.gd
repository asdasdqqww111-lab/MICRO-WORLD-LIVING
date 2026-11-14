extends Node3D
## Real GLES3 Performance Probe across Eldoria Overworld, Biomes, Guild Hall, Cottage & Dungeon.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 tests/perf_probe.tscn

const OUT_PATH := "res://docs/reports/perf_probe_results.txt"
const SETTLE_FRAMES := 14
const SAMPLE_FRAMES := 10

var _game: Node
var _player: Player
var _world: WorldRoot
var _lines: PackedStringArray = []
var _finished: bool = false

func _ready() -> void:
	_watchdog()
	_run()

func _watchdog() -> void:
	await get_tree().create_timer(360.0).timeout
	if _finished:
		return
	_lines.append("WATCHDOG: perf_probe timed out after 360s")
	_flush(true)
	get_tree().quit(2)

func _run() -> void:
	_lines.append("MICRO WORLD: LIVING — Polished Stylized/Chibi PBR Mobile Vulkan Probe")
	_lines.append("engine: %s" % Engine.get_version_info().get("string", "?"))
	_lines.append("rendering method: %s" % ProjectSettings.get_setting(
		"rendering/renderer/rendering_method"))
	_lines.append("video adapter: %s" % RenderingServer.get_video_adapter_name())
	_lines.append("driver: %s" % RenderingServer.get_video_adapter_api_version())
	_lines.append("run at: %s" % Time.get_datetime_string_from_system(true))
	_lines.append("")
	_lines.append("budget: draw calls < 300 · triangles < 180k · target 60 FPS")
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
	var ui := _game.find_child("UI", true, false)
	var intro := _game.find_child("StoryIntroOverlay", true, false) as Control
	if intro != null:
		intro.visible = false
	get_tree().paused = false
	_player.teleport(Vector3(0.0, 0.6, 14.0), "village")
	await _frames(8)

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

	# Attribute the per-frame draw calls to their source (UI layers vs 3D).
	await _ui_draw_call_breakdown(ui as UIRoot)

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
	await _frames(5)
	await _measure(label)

func _measure(label: String) -> void:
	var max_draw := 0.0
	var max_3d_draw := 0
	var max_tris := 0.0
	var max_objects := 0.0
	var max_mem := 0.0
	var min_fps := 9999.0
	var vp_rid := get_viewport().get_viewport_rid()
	for i in SAMPLE_FRAMES:
		await get_tree().process_frame
		max_draw = maxf(max_draw, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var d_vis := RenderingServer.viewport_get_render_info(vp_rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
		var d_shd := RenderingServer.viewport_get_render_info(vp_rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
		max_3d_draw = maxi(max_3d_draw, d_vis + d_shd)
		max_tris = maxf(max_tris, Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		max_objects = maxf(max_objects, Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		max_mem = maxf(max_mem, Performance.get_monitor(Performance.MEMORY_STATIC))
		var fps := Engine.get_frames_per_second()
		if fps > 0.0:
			min_fps = minf(min_fps, fps)
	if min_fps > 9000.0:
		min_fps = 0.0
	var draw_flag := "OK" if max_draw < 300.0 else ("WARN" if max_draw < 350.0 else "FAIL")
	var tri_flag := "OK" if max_tris < 180000.0 else "OVER"
	_lines.append("%s" % label)
	_lines.append("  3D draw calls:    %d  [OK]" % max_3d_draw)
	_lines.append("  total draw calls: %d  [%s]" % [int(max_draw), draw_flag])
	_lines.append("  triangles (max):  %d  [%s]" % [int(max_tris), tri_flag])
	_lines.append("  objects:          %d" % int(max_objects))
	_lines.append("  static memory:    %.1f MB" % (max_mem / 1048576.0))
	_lines.append("  fps (min, this driver): %.1f" % min_fps)
	_flush()

## Peak draw calls / objects over SAMPLE_FRAMES, after letting the render
## statistics catch up with a visibility change (they lag by one frame).
func _sample_draws() -> Dictionary:
	await _frames(4)
	var vp_rid := get_viewport().get_viewport_rid()
	var total := 0.0
	var objects := 0.0
	var scene_3d := 0
	for i in SAMPLE_FRAMES:
		await get_tree().process_frame
		total = maxf(total, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		objects = maxf(objects, Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		var d_vis := RenderingServer.viewport_get_render_info(vp_rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
		var d_shd := RenderingServer.viewport_get_render_info(vp_rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
		scene_3d = maxi(scene_3d, d_vis + d_shd)
	return {"total": int(total), "objects": int(objects), "scene_3d": scene_3d}

## Hides UI layers one at a time in a cheap 3D zone and records how many draw
## calls each one accounts for. Everything is restored afterwards.
func _ui_draw_call_breakdown(ui: UIRoot) -> void:
	_lines.append("")
	_lines.append("UI DRAW-CALL BREAKDOWN (Hero Cottage Interior, peak per frame)")
	if ui == null or ui.hud == null or ui.touch == null:
		_lines.append("  skipped: UI root, HUD or touch controls missing")
		_flush()
		return
	_player.teleport(Vector3(500.0, 0.6, 2.2), "house")
	await _frames(5)
	var hud_was := ui.hud.visible
	var touch_was := ui.touch.visible
	var layer_was := ui.visible
	ui.hud.visible = true
	ui.touch.visible = true
	ui.visible = true

	var full: Dictionary = await _sample_draws()
	ui.touch.visible = false
	var no_touch: Dictionary = await _sample_draws()
	ui.touch.visible = true
	ui.hud.visible = false
	var no_hud: Dictionary = await _sample_draws()
	ui.touch.visible = false
	var no_hud_touch: Dictionary = await _sample_draws()
	ui.visible = false
	var no_ui: Dictionary = await _sample_draws()

	# Per-panel attribution inside the HUD (each panel hidden on its own).
	ui.visible = true
	ui.hud.visible = true
	ui.touch.visible = false
	var hud_base: Dictionary = await _sample_draws()
	var hud := ui.hud
	var panels: Array = [
		["vitals panel (StatsGlassPanel)", hud.find_child("StatsGlassPanel", true, false)],
		["quest tracker", hud.quest_panel],
		["top-centre action dock", hud.find_child("TopCenterActionDock", true, false)],
		["minimap", hud.minimap],
		["clock + weather pill", hud.find_child("DayWeatherPanel", true, false)],
		["city district pill", hud.find_child("RoyalCityDistrictPanel", true, false)],
		["notifications", hud.notifications],
	]
	var panel_lines: PackedStringArray = []
	for entry: Array in panels:
		var panel := entry[1] as CanvasItem
		if panel == null or not panel.visible:
			panel_lines.append("  HUD %-32s not visible" % String(entry[0]))
			continue
		panel.visible = false
		var without: Dictionary = await _sample_draws()
		panel.visible = true
		panel_lines.append("  HUD %-32s %4d draw calls" % [
			String(entry[0]), int(hud_base["total"]) - int(without["total"])])

	ui.visible = layer_was
	ui.hud.visible = hud_was
	ui.touch.visible = touch_was
	await _frames(2)

	var rows := [
		["all UI visible", full],
		["touch controls hidden", no_touch],
		["HUD hidden", no_hud],
		["HUD + touch hidden", no_hud_touch],
		["entire UI layer hidden", no_ui],
	]
	for row: Array in rows:
		var sample: Dictionary = row[1]
		_lines.append("  %-24s total %4d | 3D (visible+shadow) %4d | objects %4d" % [
			String(row[0]), int(sample["total"]), int(sample["scene_3d"]), int(sample["objects"])])
	_lines.append("  => touch controls: %d draw calls" % (int(full["total"]) - int(no_touch["total"])))
	_lines.append("  => HUD:            %d draw calls" % (int(full["total"]) - int(no_hud["total"])))
	_lines.append("  => other UI nodes: %d draw calls" % (int(no_hud_touch["total"]) - int(no_ui["total"])))
	_lines.append("  => non-UI (3D):    %d draw calls" % int(no_ui["total"]))
	_lines.append("  HUD per panel (touch hidden, HUD total %d):" % (int(hud_base["total"]) - int(no_ui["total"])))
	_lines.append_array(panel_lines)
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
