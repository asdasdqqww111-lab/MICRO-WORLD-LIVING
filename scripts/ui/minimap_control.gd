class_name MinimapControl
extends Control
## Square Top-Right Stylized Valley Minimap backed by ONE baked 192x192 ImageTexture
## (4 Vulkan Mobile draw calls total instead of 55+ primitive calls!), with live Camera FOV Cone.

const MAP_RANGE := 46.0
const TEX_SIZE := 192
const WORLD_EXTENT := 120.0

static var _valley_tex: ImageTexture = null

var player: Player
var world_root: WorldRoot
var _accum: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(126, 126)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	_ensure_valley_texture()

static func _ensure_valley_texture() -> void:
	if _valley_tex != null:
		return
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var groves := [
		Vector3(-22.0, -24.0, 15.0), Vector3(-28.0, -6.0, 14.0),
		Vector3(-20.0, 14.0, 12.0), Vector3(24.0, -28.0, 11.0),
		Vector3(-42.0, 6.0, 18.0), Vector3(-8.0, -40.0, 14.0),
	]
	var roofs := [
		[1.8, -24.5, 8.0, 7.0, Color(0.56, 0.59, 0.66)],
		[2.8, -17.8, 5.2, 4.6, Color(0.64, 0.45, 0.28)],
		[9.6, -17.6, 4.6, 4.2, Color(0.78, 0.36, 0.28)],
		[14.6, -17.8, 4.6, 4.2, Color(0.78, 0.36, 0.28)],
		[-16.0, -8.0, 4.8, 4.5, Color(0.76, 0.36, 0.28)],
		[-19.0, 11.0, 5.4, 4.8, Color(0.54, 0.45, 0.40)],
	]
	for py in TEX_SIZE:
		var wz := ((float(py) + 0.5) / float(TEX_SIZE) * 2.0 - 1.0) * WORLD_EXTENT
		for px in TEX_SIZE:
			var wx := ((float(px) + 0.5) / float(TEX_SIZE) * 2.0 - 1.0) * WORLD_EXTENT
			var col := Color(0.35, 0.50, 0.24, 1.0)
			if Vector2(wx - 4.0, wz + 2.0).length() < 26.0:
				col = col.lerp(Color(0.45, 0.60, 0.29, 1.0), 0.78)
			for g: Vector3 in groves:
				if Vector2(wx - g.x, wz - g.y).length() < g.z:
					col = col.lerp(Color(0.19, 0.33, 0.15, 1.0), 0.80)
			if wz >= -22.0 and wz <= 48.0:
				var trail_x := -2.0 - 3.2 * smoothstep(-10.0, 18.0, wz) + sin(wz * 0.14) * 1.25
				if absf(wx - trail_x) < 2.2:
					col = Color(0.57, 0.46, 0.32, 1.0)
			var river_x := 45.5 + sin(wz * 0.055) * 4.5
			if absf(wx - river_x) < 3.6 or Vector2((wx - 16.0) / 16.0, (wz - 54.0) / 12.5).length() < 1.0:
				col = Color(0.24, 0.58, 0.86, 1.0)
			for b: Array in roofs:
				if absf(wx - float(b[0])) < float(b[2]) * 0.5 and absf(wz - float(b[1])) < float(b[3]) * 0.5:
					col = b[4] as Color
			img.set_pixel(px, py, col)
	# Bake warm golden POI dots around village hamlet
	for dot: Vector2 in [
		Vector2(-4.6, -15.5), Vector2(5.2, -15.2), Vector2(11.5, -14.5),
		Vector2(14.5, 7.8), Vector2(-15.0, 10.5), Vector2(19.5, -16.5),
		Vector2(-10.5, 26.5), Vector2(20.0, 2.5), Vector2(18.0, 20.5),
	]:
		var dpx := clampi(int(((dot.x / WORLD_EXTENT) * 0.5 + 0.5) * float(TEX_SIZE)), 2, TEX_SIZE - 3)
		var dpy := clampi(int(((dot.y / WORLD_EXTENT) * 0.5 + 0.5) * float(TEX_SIZE)), 2, TEX_SIZE - 3)
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				img.set_pixel(dpx + ox, dpy + oy, Color(1.0, 0.90, 0.44, 1.0))
	_valley_tex = ImageTexture.create_from_image(img)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			EventBus.screen_changed.emit("request_map")

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 0.12:
		_accum = 0.0
		queue_redraw()

func _clamp_box(pt: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clampf(pt.x, rect.position.x, rect.position.x + rect.size.x),
		clampf(pt.y, rect.position.y, rect.position.y + rect.size.y)
	)

func _draw() -> void:
	_ensure_valley_texture()
	var box := Rect2(Vector2.ZERO, size)
	var inner := box.grow(-2.0)
	var c := size * 0.5
	var half_w := minf(inner.size.x, inner.size.y) * 0.5

	var p := get_tree().get_first_node_in_group("player") as Player
	if p != null and p.zone == "village" and _valley_tex != null:
		var ppos := p.global_position
		var u0 := clampf((ppos.x - MAP_RANGE + WORLD_EXTENT) / (2.0 * WORLD_EXTENT), 0.0, 0.85)
		var v0 := clampf((ppos.z - MAP_RANGE + WORLD_EXTENT) / (2.0 * WORLD_EXTENT), 0.0, 0.85)
		var span := (2.0 * MAP_RANGE / (2.0 * WORLD_EXTENT)) * float(TEX_SIZE)
		var src := Rect2(u0 * float(TEX_SIZE), v0 * float(TEX_SIZE), span, span)
		draw_texture_rect_region(_valley_tex, inner, src)
	else:
		draw_rect(inner, Color(0.24, 0.30, 0.24, 0.95), true)

	if p != null:
		var cam_yaw := p.camera_rig.yaw if p.camera_rig != null else p.rotation.y
		var look_dir := Vector2(-sin(cam_yaw), -cos(cam_yaw))
		var look_ang := atan2(look_dir.y, look_dir.x)
		var half_fov := deg_to_rad(27.5)
		var cone_pts := PackedVector2Array([c])
		for ci in 7:
			var a := look_ang - half_fov + float(ci) / 6.0 * (half_fov * 2.0)
			cone_pts.append(_clamp_box(c + Vector2(cos(a), sin(a)) * (half_w * 0.68), inner))
		draw_colored_polygon(cone_pts, Color(0.98, 1.0, 0.84, 0.25))
		draw_circle(c, 3.2, Color(1.0, 0.96, 0.82))

	draw_rect(box, Color(0.78, 0.75, 0.62, 0.88), false, 2.0)
