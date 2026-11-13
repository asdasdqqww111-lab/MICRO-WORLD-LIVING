class_name WorldMapScreen
extends MenuScreen
## Illustrated Royal Cartography World Map with Hillshaded Topographic Relief,
## Contour Lines, Walled Capital City Architecture, Zoom/Pan & Click-to-Pin 3D Waypoints.

var player: Player
var _canvas: Control
var _zoom: float = 1.0
var _pan_world: Vector2 = Vector2.ZERO
var _show_resources: bool = true
var _show_npcs: bool = true
var _dragging: bool = false
var _drag_Moved: bool = false
var _pulse: float = 0.0
static var _relief_tex: ImageTexture = null

func _ready() -> void:
	configure("World Map of Eldoria", "map")
	super._ready()

func _process(delta: float) -> void:
	if visible and _canvas != null:
		_pulse += delta * 3.2
		_canvas.queue_redraw()

static func _ensure_relief_texture(terrain: Terrain) -> ImageTexture:
	if _relief_tex != null or terrain == null:
		return _relief_tex
	var res := 224
	var half := 115.0
	var img := Image.create(res, res, false, Image.FORMAT_RGBA8)
	var light_dir := Vector3(-0.55, 0.72, -0.42).normalized()

	for py: int in res:
		var wz := ((float(py) + 0.5) / float(res) * 2.0 - 1.0) * half
		for px: int in res:
			var wx := ((float(px) + 0.5) / float(res) * 2.0 - 1.0) * half
			var h := terrain.height_at(wx, wz)
			var r := Vector2(wx, wz).length()
			var col := Color(0.32, 0.46, 0.25)

			if terrain.is_water_at(wx, wz):
				var depth := clampf((-0.24 - h) * 0.72, 0.0, 1.0)
				col = Color(0.20, 0.52, 0.68).lerp(Color(0.09, 0.27, 0.46), depth)
				# Subtle shoreline foam ring
				if depth < 0.14:
					col = col.lerp(Color(0.68, 0.82, 0.86), 0.38)
			else:
				var biome := terrain.biome_at(wx, wz)
				match biome:
					"village": col = Color(0.62, 0.57, 0.46)
					"meadow": col = Color(0.43, 0.57, 0.30)
					"lakeside_birch": col = Color(0.38, 0.55, 0.34)
					"dense_woodland", "ancient_grove": col = Color(0.22, 0.39, 0.21)
					"rocky_hills": col = Color(0.48, 0.45, 0.39)
					"pine_highlands": col = Color(0.27, 0.38, 0.28)
					"alpine": col = Color(0.84, 0.86, 0.90)
				# Inside Royal City walls: warm parchment-stone districts
				if r < 37.0:
					col = col.lerp(Color(0.68, 0.62, 0.50), 0.65)
				if terrain.is_road_at(wx, wz):
					col = Color(0.78, 0.70, 0.54) if r < 38.5 else Color(0.68, 0.56, 0.39)

				# Hillshade normal from finite differences
				var hx1 := terrain.height_at(wx + 1.2, wz)
				var hx0 := terrain.height_at(wx - 1.2, wz)
				var hz1 := terrain.height_at(wx, wz + 1.2)
				var hz0 := terrain.height_at(wx, wz - 1.2)
				var nrm := Vector3(hx0 - hx1, 2.4, hz0 - hz1).normalized()
				var shade := clampf(nrm.dot(light_dir) * 0.65 + 0.52, 0.58, 1.22)
				col = Color(col.r * shade, col.g * shade, col.b * shade, 1.0)

				# Cartographic contour lines every 2.5m outside flat city
				if r > 39.0 and h > 0.6:
					var cf := absf(fposmod(h, 2.5) - 1.25)
					if cf > 1.13:
						col = col.lerp(Color(0.22, 0.18, 0.13), 0.32)

			# Parchment vignette near outer border
			var edge := maxf(absf(wx), absf(wz)) / half
			if edge > 0.88:
				col = col.lerp(Color(0.18, 0.14, 0.10), (edge - 0.88) / 0.12 * 0.55)
			img.set_pixel(px, py, col)

	_relief_tex = ImageTexture.create_from_image(img)
	return _relief_tex

func refresh() -> void:
	clear_content()
	var ar := Localization.is_arabic()

	# Top Cartography Toolbar (Zoom, Layer Toggles, Clear Waypoint)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	content.add_child(toolbar)

	var hint := UIFactory.label(
		"انقر على أي موقع لتحديد منارة توجيه ثلاثية الأبعاد ◆  ·  اسحب لتحريك الخريطة" if ar else
		"Click anywhere to pin a 3D Waypoint Beacon ◆  ·  Drag to pan",
		13, UIFactory.GOLD)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(hint)

	var z_out := UIFactory.button("−", 34)
	z_out.custom_minimum_size.x = 40
	z_out.pressed.connect(func() -> void:
		_zoom = clampf(_zoom - 0.35, 1.0, 2.45)
		if _zoom <= 1.02:
			_pan_world = Vector2.ZERO
		if _canvas != null: _canvas.queue_redraw())
	toolbar.add_child(z_out)

	var z_lbl := UIFactory.button("تكبير %d%%" % int(round(_zoom * 100.0)) if ar else "Zoom %d%%" % int(round(_zoom * 100.0)), 34)
	z_lbl.pressed.connect(func() -> void:
		_zoom = 1.85 if _zoom < 1.4 else 1.0
		_pan_world = Vector2.ZERO
		refresh())
	toolbar.add_child(z_lbl)

	var z_in := UIFactory.button("+", 34)
	z_in.custom_minimum_size.x = 40
	z_in.pressed.connect(func() -> void:
		_zoom = clampf(_zoom + 0.35, 1.0, 2.45)
		if _canvas != null: _canvas.queue_redraw())
	toolbar.add_child(z_in)

	var res_btn := UIFactory.button(("الموارد ✔" if _show_resources else "الموارد ○") if ar else ("Nodes ✔" if _show_resources else "Nodes ○"), 34)
	res_btn.pressed.connect(func() -> void:
		_show_resources = not _show_resources
		refresh())
	toolbar.add_child(res_btn)

	var clear_btn := UIFactory.button("مسح الدبوس" if ar else "Clear Pin", 34)
	clear_btn.pressed.connect(func() -> void:
		var wp := get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
		if wp != null:
			wp.clear_custom_pin()
		if _canvas != null: _canvas.queue_redraw())
	toolbar.add_child(clear_btn)

	var holder := HBoxContainer.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.add_theme_constant_override("separation", 14)
	content.add_child(holder)

	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(460, 410)
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.clip_contents = true
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_map)
	_canvas.gui_input.connect(_on_map_input)
	holder.add_child(_canvas)

	var legend := VBoxContainer.new()
	legend.custom_minimum_size = Vector2(245, 0)
	legend.add_theme_constant_override("separation", 6)
	holder.add_child(legend)
	legend.add_child(UIFactory.label("دليل الخريطة الملكية" if ar else "Royal Atlas Legend", 17, UIFactory.GOLD))
	var entries := [
		[Color(0.32, 0.96, 0.56), "موقع البطل واتجاهه" if ar else "Your Hero & Facing"],
		[Color(1.0, 0.86, 0.24), "منارة المهمة / الدبوس ◆" if ar else "Active Quest / Pin ◆"],
		[Color(0.95, 0.78, 0.30), "مواطنو المدينة ومانحو المهام" if ar else "City Citizens & Quest Givers"],
		[Color(0.96, 0.32, 0.30), "وحوش ومخاطر برية" if ar else "Hostile Creatures"],
		[Color(0.56, 0.82, 0.98), "عروق الحديد والأعشاب والأخشاب" if ar else "Ore, Herbs & Timber"],
		[Color(0.86, 0.80, 0.68), "أسوار مدينة إلدوريا وأبراجها" if ar else "Royal City Walls & Gates"],
	]
	for item: Array in entries:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		var sw := ColorRect.new()
		sw.color = item[0]
		sw.custom_minimum_size = Vector2(14, 14)
		r.add_child(sw)
		r.add_child(UIFactory.label(String(item[1]), 13, UIFactory.TEXT))
		legend.add_child(r)

	legend.add_child(UIFactory.hsep())
	legend.add_child(UIFactory.label("انتقال التوجيه السريع" if ar else "Quick Waypoint Focus", 15, UIFactory.GOLD))
	var quick_spots := [
		[Vector3(0.0, 0.0, -18.5), "نقابة المغامرين" if ar else "Adventurers Guild"],
		[Vector3(-23.0, 0.0, -19.5), "القلعة الملكية" if ar else "Royal Citadel"],
		[Vector3(14.5, 0.0, -5.5), "الحدادة الملكية" if ar else "Royal Forge"],
		[Vector3(58.0, 0.2, 22.0), "مدخل السرداب الغارق" if ar else "Sunken Crypt"],
		[Vector3(66.0, 1.0, -18.0), "الأطلال القديمة" if ar else "Ancient Ruins"],
		[Vector3(-56.0, 1.0, 44.0), "الأجمة المقدسة" if ar else "Sacred Grove"],
	]
	for sp: Array in quick_spots:
		var qbtn := UIFactory.button("◆ " + String(sp[1]), 31)
		var wpos: Vector3 = sp[0]
		var wtitle := String(sp[1])
		qbtn.pressed.connect(func() -> void:
			var wp := get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
			if wp != null:
				wp.set_custom_pin(wpos, wtitle)
			EventBus.notify.emit(("تم وضع منارة التوجيه: %s" if ar else "Waypoint pinned: %s") % wtitle)
			if _canvas != null: _canvas.queue_redraw())
		legend.add_child(qbtn)

func _map_rect() -> Rect2:
	var sz := _canvas.size
	var side := minf(sz.x, sz.y) - 12.0
	return Rect2((sz.x - side) * 0.5, (sz.y - side) * 0.5, side, side)

func _world_to_map(wx: float, wz: float, rect: Rect2) -> Vector2:
	var half := 115.0 / _zoom
	var nx := clampf(((wx - _pan_world.x) / half) * 0.5 + 0.5, -0.2, 1.2)
	var nz := clampf(((wz - _pan_world.y) / half) * 0.5 + 0.5, -0.2, 1.2)
	return rect.position + Vector2(nx * rect.size.x, nz * rect.size.y)

func _map_to_world(mpos: Vector2, rect: Rect2) -> Vector2:
	var half := 115.0 / _zoom
	var nx := ((mpos.x - rect.position.x) / maxf(1.0, rect.size.x) - 0.5) * 2.0
	var nz := ((mpos.y - rect.position.y) / maxf(1.0, rect.size.y) - 0.5) * 2.0
	return Vector2(_pan_world.x + nx * half, _pan_world.y + nz * half)

func _on_map_input(event: InputEvent) -> void:
	if _canvas == null:
		return
	var rect := _map_rect()
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom = clampf(_zoom + 0.22, 1.0, 2.45)
			_canvas.queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom = clampf(_zoom - 0.22, 1.0, 2.45)
			if _zoom <= 1.02: _pan_world = Vector2.ZERO
			_canvas.queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and rect.has_point(mb.position):
				_dragging = true
				_drag_Moved = false
			elif not mb.pressed and _dragging:
				_dragging = false
				if not _drag_Moved and rect.has_point(mb.position):
					var w2 := _map_to_world(mb.position, rect)
					w2.x = clampf(w2.x, -110.0, 110.0)
					w2.y = clampf(w2.y, -110.0, 110.0)
					var wr := get_tree().get_first_node_in_group("world_root") as WorldRoot
					var wy := wr.terrain.height_at(w2.x, w2.y) if (wr != null and wr.terrain != null) else 0.0
					var wp := get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
					var title := "دبوس الخريطة" if Localization.is_arabic() else "Map Waypoint"
					if wp != null:
						wp.set_custom_pin(Vector3(w2.x, wy, w2.y), title)
					if AudioManager != null:
						AudioManager.play_sfx("ui_click")
					EventBus.notify.emit(("تم تحديد وجهة على الخريطة (%.0f, %.0f)" if Localization.is_arabic() else "Pinned 3D Waypoint at (%.0f, %.0f)") % [w2.x, w2.y])
					_canvas.queue_redraw()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		if mm.relative.length() > 1.5:
			_drag_Moved = true
			var world_per_px := (230.0 / _zoom) / maxf(1.0, rect.size.x)
			_pan_world -= mm.relative * world_per_px
			var max_pan := 115.0 * (1.0 - 1.0 / _zoom)
			_pan_world.x = clampf(_pan_world.x, -max_pan, max_pan)
			_pan_world.y = clampf(_pan_world.y, -max_pan, max_pan)
			_canvas.queue_redraw()

func _draw_map() -> void:
	var rect := _map_rect()
	var wr := get_tree().get_first_node_in_group("world_root") as WorldRoot
	if wr == null or wr.terrain == null:
		return
	var ar := Localization.is_arabic()
	var font := ThemeDB.fallback_font

	# 1. Outer Ornate Parchment Frame
	_canvas.draw_rect(rect.grow(5.0), Color(0.14, 0.11, 0.08, 0.98), true)
	var tex := _ensure_relief_texture(wr.terrain)
	if tex != null:
		var uv_half := 0.5 / _zoom
		var uv_cx := 0.5 + (_pan_world.x / 230.0)
		var uv_cy := 0.5 + (_pan_world.y / 230.0)
		var src := Rect2(
			Vector2((uv_cx - uv_half) * tex.get_width(), (uv_cy - uv_half) * tex.get_height()),
			Vector2(uv_half * 2.0 * tex.get_width(), uv_half * 2.0 * tex.get_height())
		)
		_canvas.draw_texture_rect_region(tex, rect, src)

	var px_per_m := rect.size.x / (230.0 / _zoom)

	# 2. Architectural Vector Layer: Walled Royal Capital City (Walls, Bastions, 4 Gates & 17 Buildings!)
	var city_center := _world_to_map(0.0, 0.0, rect)
	var wall_r_px := 37.2 * px_per_m
	# 4 Gate gaps at N (-PI/2), E (0), S (PI/2), W (PI)
	var gate_gap := 0.11
	for arc_seg: Array in [[gate_gap, PI * 0.5 - gate_gap], [PI * 0.5 + gate_gap, PI - gate_gap], [PI + gate_gap, PI * 1.5 - gate_gap], [-PI * 0.5 + gate_gap, -gate_gap]]:
		_canvas.draw_arc(city_center, wall_r_px, float(arc_seg[0]), float(arc_seg[1]), 24, Color(0.20, 0.16, 0.12, 0.95), maxf(3.0, 1.8 * px_per_m))
		_canvas.draw_arc(city_center, wall_r_px, float(arc_seg[0]), float(arc_seg[1]), 24, Color(0.88, 0.82, 0.70, 0.96), maxf(1.6, 1.0 * px_per_m))

	# 12 Bastion Watchtowers along City Ramparts
	for bi: int in 12:
		var bang := float(bi) / 12.0 * TAU + 0.26
		var bp := _world_to_map(cos(bang) * 37.2, sin(bang) * 37.2, rect)
		if rect.has_point(bp):
			_canvas.draw_circle(bp, maxf(2.6, 1.5 * px_per_m), Color(0.92, 0.86, 0.74))
			_canvas.draw_arc(bp, maxf(2.6, 1.5 * px_per_m), 0.0, TAU, 10, Color(0.18, 0.14, 0.10), 1.2)

	# 17 Hero City Buildings (Colored Architectural Roof Footprints!)
	var buildings := [
		[0.0, -23.5, 9.0, 7.0, Color(0.28, 0.48, 0.78)],   # Adventurers Guild Keep
		[-25.0, -22.0, 8.5, 8.0, Color(0.32, 0.52, 0.84)], # Royal Sovereign Citadel
		[15.5, -23.0, 7.5, 6.5, Color(0.82, 0.72, 0.42)],  # Royal Cathedral
		[26.5, -14.0, 6.5, 6.5, Color(0.56, 0.38, 0.76)],  # Arcane Conservatory
		[-16.0, -6.0, 5.5, 5.0, Color(0.76, 0.42, 0.28)],  # Hero's Cottage
		[15.5, -5.5, 6.0, 5.5, Color(0.72, 0.34, 0.24)],   # Grand Royal Forge
		[-13.5, -17.5, 6.5, 5.5, Color(0.78, 0.48, 0.26)], # Hearthstone Inn
		[12.5, 10.5, 5.5, 5.0, Color(0.36, 0.66, 0.52)],   # Royal Apothecary
		[23.5, 4.0, 6.5, 5.5, Color(0.80, 0.62, 0.28)],    # East Trade Exchange
		[23.0, 16.0, 6.5, 6.0, Color(0.54, 0.56, 0.62)],   # Garrison Barracks
		[-14.5, 11.5, 5.5, 5.5, Color(0.74, 0.62, 0.40)],  # Royal Granary Mill
		[-25.5, -3.5, 5.5, 5.0, Color(0.78, 0.52, 0.32)],  # Artisan Bakery
		[-23.5, 19.5, 5.5, 5.0, Color(0.68, 0.46, 0.32)],  # Timber Guildhall
	]
	for b: Array in buildings:
		var bc := _world_to_map(float(b[0]), float(b[1]), rect)
		if not rect.has_point(bc):
			continue
		var bw := maxf(4.0, float(b[2]) * px_per_m)
		var bh := maxf(3.5, float(b[3]) * px_per_m)
		var br := Rect2(bc - Vector2(bw * 0.5, bh * 0.5), Vector2(bw, bh))
		_canvas.draw_rect(br, b[4] as Color, true)
		_canvas.draw_rect(br, Color(0.14, 0.11, 0.08, 0.9), false, 1.1)

	# East Stone Bridge across River
	var bridge_p := _world_to_map(45.5, 2.0, rect)
	if rect.has_point(bridge_p):
		var br_rect := Rect2(bridge_p - Vector2(4.5 * px_per_m, 2.2 * px_per_m), Vector2(9.0 * px_per_m, 4.4 * px_per_m))
		_canvas.draw_rect(br_rect, Color(0.86, 0.80, 0.68), true)
		_canvas.draw_rect(br_rect, Color(0.20, 0.16, 0.12), false, 1.2)

	# 3. Harvestable Resource Nodes
	if _show_resources:
		for rnode: Node in get_tree().get_nodes_in_group("resource_node"):
			if rnode is ResourceNode and (rnode as ResourceNode).can_interact(null):
				var rn := rnode as ResourceNode
				var rp := _world_to_map(rn.global_position.x, rn.global_position.z, rect)
				if rect.has_point(rp):
					var rcol := Color(0.56, 0.82, 0.98) if rn.resource_kind == "ore" else (Color(0.82, 0.56, 0.96) if rn.resource_kind == "moonpetal" else Color(0.58, 0.88, 0.46))
					_canvas.draw_circle(rp, 2.6, rcol)

	# 4. Named World & City Landmarks
	var marks := [
		["city", Vector2(0.0, 2.0), "ساحة إلدوريا الملكية" if ar else "Royal Plaza"],
		["guild", Vector2(0.0, -24.0), "نقابة المغامرين" if ar else "Adventurers Guild"],
		["citadel", Vector2(-25.0, -22.0), "القلعة الملكية" if ar else "Royal Citadel"],
		["ruins", Vector2(66.0, -18.0), "الأطلال القديمة" if ar else "Ancient Ruins"],
		["crypt", Vector2(58.0, 22.0), "السرداب الغارق" if ar else "Sunken Crypt"],
		["lake", Vector2(16.0, 54.0), "بحيرة الكريستال" if ar else "Crystal Lake"],
		["camp", Vector2(-62.0, -24.0), "معسكر الوحوش" if ar else "Monster Camp"],
		["grove", Vector2(-56.0, 44.0), "الأجمة المقدسة" if ar else "Sacred Grove"],
		["cave", Vector2(-14.0, -64.0), "كهف الناب المظلم" if ar else "Shadowfang Cave"],
	]
	for m: Array in marks:
		var mp := _world_to_map((m[1] as Vector2).x, (m[1] as Vector2).y, rect)
		if not rect.has_point(mp):
			continue
		_canvas.draw_circle(mp, 3.8, Color(0.14, 0.11, 0.08, 0.92))
		_canvas.draw_circle(mp, 2.5, UIFactory.GOLD)
		if font != null:
			var lbl := String(m[2])
			_canvas.draw_string(font, mp + Vector2(6, 4), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.06, 0.05, 0.04, 0.92))
			_canvas.draw_string(font, mp + Vector2(5, 3), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.95, 0.80))

	# 5. Living NPCs & Quest Giver Markers (! / ?)
	if _show_npcs:
		for n: Node in get_tree().get_nodes_in_group("npc"):
			if n is VillageNPC:
				var npc := n as VillageNPC
				if absf(npc.global_position.x) > 120.0:
					continue
				var np := _world_to_map(npc.global_position.x, npc.global_position.z, rect)
				if rect.has_point(np):
					_canvas.draw_circle(np, 3.0, Color(0.96, 0.80, 0.30))
					_canvas.draw_arc(np, 3.0, 0.0, TAU, 8, Color(0.12, 0.10, 0.08), 1.0)

	# 6. Hostile Creatures
	for c: Node in get_tree().get_nodes_in_group("creature"):
		if c is Creature and not (c as Creature).dead and not (c as Creature).passive:
			var cr := c as Creature
			if absf(cr.global_position.x) > 120.0:
				continue
			var cp := _world_to_map(cr.global_position.x, cr.global_position.z, rect)
			if rect.has_point(cp):
				_canvas.draw_circle(cp, 3.0, Color(0.96, 0.28, 0.26))

	# 7. Pulsing Golden 3D Waypoint / Active Quest Beacon ◆
	var wp := get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
	if wp != null and wp.has_waypoint and absf(wp.target_position.x) < 120.0:
		var wmp := _world_to_map(wp.target_position.x, wp.target_position.z, rect)
		if rect.has_point(wmp):
			var pr := 6.5 + sin(_pulse) * 2.5
			_canvas.draw_arc(wmp, pr, 0.0, TAU, 20, Color(1.0, 0.86, 0.24, 0.88), 2.0)
			var dpts := PackedVector2Array([
				wmp + Vector2(0, -5.5), wmp + Vector2(5.5, 0),
				wmp + Vector2(0, 5.5), wmp + Vector2(-5.5, 0)
			])
			_canvas.draw_colored_polygon(dpts, Color(1.0, 0.88, 0.28))

	# 8. Player Directional Chevron + View Cone
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		var p3 := player.global_position if player.zone == "village" else Vector3.ZERO
		var pp := _world_to_map(p3.x, p3.z, rect)
		if rect.has_point(pp):
			var yaw := player._facing_yaw if "_facing_yaw" in player else 0.0
			var fwd := Vector2(sin(yaw), cos(yaw)).normalized()
			var side := Vector2(fwd.y, -fwd.x)
			_canvas.draw_circle(pp, 8.5, Color(0.20, 0.95, 0.55, 0.24))
			var tri := PackedVector2Array([
				pp + fwd * 7.5,
				pp - fwd * 4.5 + side * 4.8,
				pp - fwd * 4.5 - side * 4.8,
			])
			_canvas.draw_colored_polygon(tri, Color(0.28, 0.98, 0.58))
			_canvas.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(0.05, 0.14, 0.08), 1.5)

	# 9. Ornate Compass Rose (Top-Right) & Scale Bar (Bottom-Left)
	var rose := rect.position + Vector2(rect.size.x - 30.0, 30.0)
	_canvas.draw_circle(rose, 18.0, Color(0.12, 0.10, 0.08, 0.84))
	_canvas.draw_arc(rose, 18.0, 0.0, TAU, 24, UIFactory.GOLD, 1.4)
	_canvas.draw_line(rose + Vector2(0, -13), rose + Vector2(0, 13), UIFactory.GOLD, 1.5)
	_canvas.draw_line(rose + Vector2(-13, 0), rose + Vector2(13, 0), UIFactory.GOLD, 1.2)
	if font != null:
		_canvas.draw_string(font, rose + Vector2(-5, -19), "ش" if ar else "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIFactory.GOLD)
		# Scale bar (50m)
		var bar_w := 50.0 * px_per_m
		var sb := rect.position + Vector2(14.0, rect.size.y - 14.0)
		_canvas.draw_line(sb, sb + Vector2(bar_w, 0), Color(0.96, 0.90, 0.74), 2.5)
		_canvas.draw_string(font, sb + Vector2(4, -5), "50م" if ar else "50m", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.96, 0.90, 0.74))

	_canvas.draw_rect(rect, UIFactory.GOLD, false, 2.2)
