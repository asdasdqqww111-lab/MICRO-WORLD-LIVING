class_name MinimapControl
extends Control
## Square Top-Right Stylized Valley Minimap with Camera FOV Cone,
## Pine Groves, Winding Dirt Trail, Castle Footprint & Wildflower/POI Dots.

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

func _clamp_box(pt: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clampf(pt.x, rect.position.x, rect.position.x + rect.size.x),
		clampf(pt.y, rect.position.y, rect.position.y + rect.size.y)
	)

func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	var inner := box.grow(-2.0)
	var c := size * 0.5
	var half_w := minf(inner.size.x, inner.size.y) * 0.5

	# Stylized meadow green base
	draw_rect(box, Color(0.10, 0.13, 0.16, 0.92), true)
	draw_rect(inner, Color(0.36, 0.50, 0.25, 0.95), true)

	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null:
		draw_rect(box, Color(0.82, 0.76, 0.54, 0.78), false, 1.8)
		return

	var ppos := p.global_position
	var scale_px := half_w / MAP_RANGE

	if p.zone == "village":
		# Sunlit lighter meadow clearing around center-right
		var meadow_c := _clamp_box(c + Vector2(6.0 - ppos.x, -2.0 - ppos.z) * scale_px, inner)
		draw_circle(meadow_c, minf(26.0 * scale_px, half_w * 0.62), Color(0.45, 0.59, 0.29, 0.85))

		# Dark-green stylized pine forest clusters on northwest & southwest slopes
		for grove: Vector3 in [
			Vector3(-22.0, -24.0, 14.0), Vector3(-28.0, -6.0, 13.0),
			Vector3(-20.0, 14.0, 11.0), Vector3(24.0, -28.0, 10.0),
		]:
			var gp := c + Vector2(grove.x - ppos.x, grove.y - ppos.z) * scale_px
			if inner.grow(-6.0).has_point(gp):
				draw_circle(gp, minf(grove.z * scale_px, 18.0), Color(0.20, 0.34, 0.16, 0.85))

		# Winding Country Dirt Trail & Cross Paths
		var prev_t := Vector2.ZERO
		for ti in 12:
			var wz := -18.0 + float(ti) * 5.2
			var wx := -4.8 * smoothstep(-10.0, 26.0, wz) + sin(wz * 0.14) * 1.65
			var tp := c + Vector2(wx - ppos.x, wz - ppos.z) * scale_px
			if ti > 0:
				draw_line(_clamp_box(prev_t, inner), _clamp_box(tp, inner), Color(0.56, 0.46, 0.32, 0.88), 3.2)
			prev_t = tp

		# Eastern River
		var prev_r := Vector2.ZERO
		for ri in 12:
			var rz := -60.0 + float(ri) * 10.0
			var rx := 45.5 + sin(rz * 0.055) * 4.5
			var rp := c + Vector2(rx - ppos.x, rz - ppos.z) * scale_px
			if ri > 0 and (inner.has_point(rp) or inner.has_point(prev_r)):
				draw_line(_clamp_box(prev_r, inner), _clamp_box(rp, inner), Color(0.24, 0.58, 0.86, 0.88), 4.0)
			prev_r = rp

		# Castle & Village Building Footprints
		for b: Array in [
			[1.8, -24.5, 7.5, 6.5, Color(0.56, 0.58, 0.64)],
			[2.2, -16.8, 5.0, 4.5, Color(0.62, 0.44, 0.28)],
			[9.6, -17.6, 4.5, 4.2, Color(0.74, 0.36, 0.28)],
			[14.6, -17.8, 4.5, 4.2, Color(0.74, 0.36, 0.28)],
			[-16.0, -8.0, 4.8, 4.5, Color(0.74, 0.36, 0.28)],
			[-19.0, 11.0, 5.2, 4.8, Color(0.52, 0.44, 0.40)],
		]:
			var bp := c + Vector2(float(b[0]) - ppos.x, float(b[1]) - ppos.z) * scale_px
			var bsz := Vector2(float(b[2]), float(b[3])) * scale_px
			var brect := Rect2(bp - bsz * 0.5, bsz)
			if inner.encloses(brect):
				draw_rect(brect, b[4] as Color, true)

	# Colored POI / Resource / NPC dots (matching bottom-right cluster on minimap!)
	for rnode: Node in get_tree().get_nodes_in_group("resource_node"):
		if rnode is Node3D:
			var d := (rnode as Node3D).global_position - ppos
			var pt := c + Vector2(d.x, d.z) * scale_px
			if inner.grow(-3.0).has_point(pt):
				draw_circle(pt, 2.2, Color(0.56, 0.86, 1.0))

	for n: Node in get_tree().get_nodes_in_group("npc"):
		if n is Node3D:
			var d := (n as Node3D).global_position - ppos
			var pt := c + Vector2(d.x, d.z) * scale_px
			if inner.grow(-3.0).has_point(pt):
				draw_circle(pt, 2.4, Color(1.0, 0.88, 0.42))

	# Translucent Camera Field-of-View (FOV) Cone pointing in camera direction!
	var cam_yaw := p.camera_rig.yaw if p.camera_rig != null else p.rotation.y
	var look_dir := Vector2(-sin(cam_yaw), -cos(cam_yaw))
	var look_ang := atan2(look_dir.y, look_dir.x)
	var half_fov := deg_to_rad(27.5)
	var cone_pts := PackedVector2Array([c])
	for ci in 9:
		var a := look_ang - half_fov + float(ci) / 8.0 * (half_fov * 2.0)
		cone_pts.append(_clamp_box(c + Vector2(cos(a), sin(a)) * (half_w * 0.68), inner))
	draw_colored_polygon(cone_pts, Color(0.98, 1.0, 0.84, 0.24))

	# Crisp Player Center Pin
	draw_circle(c, 3.6, Color(1.0, 0.98, 0.88))
	draw_circle(c, 1.8, Color(0.95, 0.76, 0.24))

	# Metallic Silver-Gold Square Frame
	draw_rect(box, Color(0.76, 0.74, 0.64, 0.85), false, 1.8)
	draw_rect(box.grow(-1.5), Color(0.12, 0.16, 0.18, 0.65), false, 1.0)
