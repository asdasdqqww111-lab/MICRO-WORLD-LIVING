class_name MinimapControl
extends Control
## Compact live overhead radar & Eldoria minimap (126x126 px) in top-right HUD.
## Renders Eldoria Plaza, River/Lake, Guild, Dungeon, NPCs, Hostiles & Player heading.

const MAP_SPAN := 95.0   # metres radius shown around player

var player: Player
var _redraw_timer: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(126, 126)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_redraw_timer += delta
	if _redraw_timer >= 0.10:
		_redraw_timer = 0.0
		queue_redraw()

func _to_map(world_xz: Vector2, center_xz: Vector2, half: Vector2) -> Vector2:
	var rel := (world_xz - center_xz) / MAP_SPAN
	rel.x = clampf(rel.x, -0.94, 0.94)
	rel.y = clampf(rel.y, -0.94, 0.94)
	return half + Vector2(rel.x * half.x, rel.y * half.y)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var half := size * 0.5
	draw_rect(rect, Color(0.06, 0.09, 0.12, 0.92), true)

	if player == null or not is_instance_valid(player):
		draw_rect(rect, UIFactory.BORDER_GOLD, false, 2.0)
		return

	var p_xz := Vector2(player.global_position.x, player.global_position.z)
	if player.zone == "village":
		# Eldoria Village circle
		var v_pos := _to_map(Vector2.ZERO, p_xz, half)
		var v_rad := (30.0 / MAP_SPAN) * half.x
		if v_pos.distance_to(half) < half.x + v_rad:
			draw_circle(v_pos, minf(v_rad, half.x * 0.85), Color(0.26, 0.32, 0.24, 0.55))

		# Eldoria River & Crystal Lake
		var prev_r := Vector2.ZERO
		for step_i: int in 9:
			var rz := -52.0 + float(step_i) * 12.5
			var rx := 39.0 + sin(rz * 0.055) * 5.5 - maxf(0.0, rz - 16.0) * 0.55
			var pt := _to_map(Vector2(rx, rz), p_xz, half)
			if step_i > 0:
				draw_line(prev_r, pt, Color(0.22, 0.56, 0.78, 0.75), 3.5)
			prev_r = pt
		var lake_pt := _to_map(Vector2(16.0, 49.0), p_xz, half)
		draw_circle(lake_pt, 10.0, Color(0.20, 0.54, 0.78, 0.70))

		# Key POIs: Guild (North), Crypt (SE), Ruins (E), Sacred Grove (SW)
		draw_circle(_to_map(Vector2(0.0, -22.0), p_xz, half), 4.0, Color(0.42, 0.78, 1.0))
		draw_circle(_to_map(Vector2(52.0, 24.0), p_xz, half), 3.8, Color(0.85, 0.45, 0.95))
		draw_circle(_to_map(Vector2(62.0, -18.0), p_xz, half), 3.2, UIFactory.GOLD)

	# Nearby NPCs (gold/amber dots) & Hostile Creatures (red dots)
	if get_tree() != null:
		for npc: Node in get_tree().get_nodes_in_group("npc"):
			if npc is Node3D and (npc as Node3D).is_visible_in_tree():
				var np := (npc as Node3D).global_position
				if Vector2(np.x, np.z).distance_to(p_xz) <= MAP_SPAN:
					draw_circle(_to_map(Vector2(np.x, np.z), p_xz, half), 2.4, Color(0.96, 0.84, 0.36))
		for cr: Node in get_tree().get_nodes_in_group("creature"):
			if cr is Node3D and (cr as Node3D).is_visible_in_tree():
				var cp := (cr as Node3D).global_position
				if Vector2(cp.x, cp.z).distance_to(p_xz) <= MAP_SPAN:
					var is_h := true
					var cdata: CreatureData = cr.get("data") as CreatureData
					if cdata != null:
						is_h = cdata.hostile
					draw_circle(_to_map(Vector2(cp.x, cp.z), p_xz, half), 2.6,
						Color(0.94, 0.32, 0.32) if is_h else Color(0.55, 0.88, 0.55))

	# Player directional chevron at center
	var yaw := player.rotation.y
	var fwd := Vector2(-sin(yaw), -cos(yaw)).normalized()
	var side := Vector2(fwd.y, -fwd.x)
	var p1 := half + fwd * 6.5
	var p2 := half - fwd * 4.5 + side * 4.2
	var p3 := half - fwd * 4.5 - side * 4.2
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(1.0, 1.0, 1.0))
	draw_rect(rect, UIFactory.BORDER_GOLD, false, 2.0)
