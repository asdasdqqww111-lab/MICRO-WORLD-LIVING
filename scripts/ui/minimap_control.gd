class_name MinimapControl
extends Control
## Real-time Cartographic Minimap Radar showing Walled Royal City Architecture,
## Cobblestone Roads, Shifted River/Lake, NPCs, Enemies, Resource Nodes & 3D Waypoint Arrow.
## Tapping the minimap opens the full Illustrated World Map!

const MAP_RANGE := 46.0

var player: Player
var world_root: WorldRoot
var _accum: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(126, 126)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			EventBus.screen_changed.emit("request_map")

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 0.10:
		_accum = 0.0
		queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 3.0
	draw_circle(c, r + 2.5, Color(0.06, 0.08, 0.12, 0.92))
	draw_circle(c, r, Color(0.18, 0.27, 0.17, 0.94))

	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		draw_arc(c, r, 0.0, TAU, 40, UIFactory.GOLD, 2.0)
		return

	var ppos := player.global_position
	var scale_px := r / MAP_RANGE
	var ar := Localization.is_arabic()

	if player.zone == "village":
		var city_c := c + Vector2(-ppos.x, -ppos.z) * scale_px
		var city_r := 37.2 * scale_px

		# Warm stone interior of Royal Capital City
		if city_c.distance_to(c) < r + city_r:
			var vis_r := minf(city_r, r - 2.0)
			if ppos.length() < 37.2:
				draw_circle(c, r - 1.5, Color(0.36, 0.34, 0.29, 0.72))

		# Cardinal Cobblestone Boulevards & Ring Road
		for seg: Array in [
			[Vector2(-75, 0), Vector2(75, 0)],
			[Vector2(0, -75), Vector2(0, 75)],
			[Vector2(38, 2), Vector2(66, -18)],
			[Vector2(38, 8), Vector2(58, 22)],
		]:
			var a := c + ((seg[0] as Vector2) - Vector2(ppos.x, ppos.z)) * scale_px
			var b := c + ((seg[1] as Vector2) - Vector2(ppos.x, ppos.z)) * scale_px
			if a.distance_to(c) < r * 2.2 or b.distance_to(c) < r * 2.2:
				draw_line(_clamp_circle(a, c, r - 2.0), _clamp_circle(b, c, r - 2.0), Color(0.68, 0.60, 0.44, 0.80), 3.2)

		# Shifted Eastern River (x ≈ 45.5) & Crystal Lake (16, 54)
		var prev_pt := Vector2.ZERO
		for i: int in 14:
			var wz := -95.0 + float(i) * 14.6
			var wx := 45.5 + sin(wz * 0.045) * 9.5 + cos(wz * 0.021) * 4.0
			var mp := c + Vector2(wx - ppos.x, wz - ppos.z) * scale_px
			if i > 0 and (mp.distance_to(c) < r * 1.4 or prev_pt.distance_to(c) < r * 1.4):
				draw_line(_clamp_circle(prev_pt, c, r - 2.0), _clamp_circle(mp, c, r - 2.0), Color(0.20, 0.56, 0.84, 0.88), 4.8)
			prev_pt = mp

		var lake_c := c + Vector2(16.0 - ppos.x, 54.0 - ppos.z) * scale_px
		if lake_c.distance_to(c) < r - 8.0:
			draw_circle(lake_c, minf(13.0 * scale_px, r - lake_c.distance_to(c) - 2.0), Color(0.20, 0.56, 0.84, 0.85))

		# Royal City Stone Wall Arc Segments (Visible as you walk near the ramparts!)
		var prev_w := Vector2.ZERO
		for wi: int in 37:
			var wang := float(wi) / 36.0 * TAU
			var wp2 := c + (Vector2(cos(wang), sin(wang)) * 37.2 - Vector2(ppos.x, ppos.z)) * scale_px
			if wi > 0 and wp2.distance_to(c) < r - 1.5 and prev_w.distance_to(c) < r - 1.5:
				draw_line(prev_w, wp2, Color(0.88, 0.82, 0.70, 0.92), 2.2)
			prev_w = wp2

		# Nearby City Building Roof Footprints
		for b: Array in [
			[0.0, -23.5, 7.0, 5.5], [-25.0, -22.0, 7.0, 6.5], [15.5, -23.0, 6.0, 5.5],
			[-16.0, -6.0, 4.8, 4.4], [15.5, -5.5, 5.2, 4.8], [-13.5, -17.5, 5.5, 4.8],
			[12.5, 10.5, 4.8, 4.4], [23.5, 4.0, 5.5, 4.8], [23.0, 16.0, 5.5, 5.0],
		]:
			var bp := c + Vector2(float(b[0]) - ppos.x, float(b[1]) - ppos.z) * scale_px
			if bp.distance_to(c) < r - 6.0:
				var bsz := Vector2(float(b[2]), float(b[3])) * scale_px
				draw_rect(Rect2(bp - bsz * 0.5, bsz), Color(0.62, 0.48, 0.36, 0.88), true)
	else:
		# Interior Zone Floor Indicator
		draw_circle(c, r - 2.0, Color(0.24, 0.22, 0.28, 0.86))

	# Resource Nodes (Cyan/Green tiny dots)
	for rnode: Node in get_tree().get_nodes_in_group("resource_node"):
		if rnode is ResourceNode and (rnode as ResourceNode).can_interact(null):
			var d := (rnode as Node3D).global_position - ppos
			var pt := c + Vector2(d.x, d.z) * scale_px
			if pt.distance_to(c) < r - 3.0:
				draw_circle(pt, 2.0, Color(0.54, 0.84, 0.98))

	# Living NPCs (Gold dots)
	for n: Node in get_tree().get_nodes_in_group("npc"):
		if n is Node3D:
			var d := (n as Node3D).global_position - ppos
			var pt := c + Vector2(d.x, d.z) * scale_px
			if pt.distance_to(c) < r - 3.0:
				draw_circle(pt, 2.7, UIFactory.GOLD)

	# Hostile Creatures (Crimson dots)
	for cr: Node in get_tree().get_nodes_in_group("creature"):
		if cr is Creature and not (cr as Creature).dead:
			var d := (cr as Creature).global_position - ppos
			var pt := c + Vector2(d.x, d.z) * scale_px
			if pt.distance_to(c) < r - 3.0:
				var col := Color(0.55, 0.86, 0.50) if (cr as Creature).passive else Color(0.96, 0.28, 0.26)
				draw_circle(pt, 2.8, col)

	# Active 3D Quest / Custom Pin Golden Diamond (clamped to rim so you ALWAYS know which way to walk!)
	var wp := get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
	if wp != null and wp.has_waypoint:
		var wd := wp.target_position - ppos
		var wpt := _clamp_circle(c + Vector2(wd.x, wd.z) * scale_px, c, r - 5.0)
		var diamond := PackedVector2Array([
			wpt + Vector2(0, -4.5),
			wpt + Vector2(4.5, 0),
			wpt + Vector2(0, 4.5),
			wpt + Vector2(-4.5, 0),
		])
		draw_colored_polygon(diamond, Color(1.0, 0.88, 0.24))

	# Player Directional Chevron at Center
	var yaw: float = player.rotation.y + PI
	var fwd := Vector2(sin(yaw), cos(yaw)).normalized()
	var side := Vector2(fwd.y, -fwd.x)
	var tri := PackedVector2Array([
		c + fwd * 5.8,
		c - fwd * 3.8 + side * 3.8,
		c - fwd * 3.8 - side * 3.8,
	])
	draw_colored_polygon(tri, Color(0.32, 0.98, 0.60))

	draw_arc(c, r, 0.0, TAU, 44, UIFactory.GOLD, 2.2)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(c.x - 5, 13), "ش" if ar else "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, UIFactory.GOLD)

func _clamp_circle(pt: Vector2, center: Vector2, radius: float) -> Vector2:
	var v := pt - center
	if v.length() > radius:
		return center + v.normalized() * radius
	return pt
