class_name WorldMapScreen
extends MenuScreen
## Illustrated Eldoria Valley World Map (240m x 240m) showing Biomes, River,
## Crystal Lake, Stone Bridge, Village, Adventurers Guild, Outer Landmarks,
## and Live Player Location!

class EldoriaMapCanvas extends Control:
	var player_pos: Vector3 = Vector3.ZERO
	var player_zone: String = "village"

	func _to_px(wx: float, wz: float) -> Vector2:
		var u := clampf((wx + 120.0) / 240.0, 0.0, 1.0)
		var v := clampf((wz + 120.0) / 240.0, 0.0, 1.0)
		return Vector2(u * size.x, v * size.y)

	func _draw() -> void:
		# Alpine rim & verdant valley background
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.24, 0.27, 0.25), true)
		var inner := Rect2(size * 0.14, size * 0.72)
		draw_rect(inner, Color(0.20, 0.36, 0.20), true)

		# Western Dense Woodland & Northern Pine Highlands shading
		draw_circle(_to_px(-58.0, 0.0), size.x * 0.18, Color(0.14, 0.28, 0.15, 0.85))
		draw_circle(_to_px(0.0, -68.0), size.x * 0.18, Color(0.15, 0.30, 0.22, 0.80))

		# Eldoria River & Crystal Lake
		var prev := Vector2.ZERO
		for i: int in 14:
			var rz := -58.0 + float(i) * 8.2
			var rx := 39.0 + sin(rz * 0.055) * 5.5 - maxf(0.0, rz - 16.0) * 0.55
			var pt := _to_px(rx, rz)
			if i > 0:
				draw_line(prev, pt, Color(0.18, 0.54, 0.78), 6.0, true)
			prev = pt
		draw_circle(_to_px(16.0, 49.0), size.x * 0.075, Color(0.16, 0.50, 0.76))

		# Village Plateau & Roads
		draw_circle(_to_px(0.0, 0.0), size.x * 0.115, Color(0.42, 0.40, 0.34))
		draw_line(_to_px(0.0, -22.0), _to_px(0.0, 32.0), Color(0.58, 0.52, 0.40), 3.5)
		draw_line(_to_px(-46.0, 2.0), _to_px(54.0, -4.0), Color(0.58, 0.52, 0.40), 3.5)

		# Named Landmarks
		var pois := [
			{"pos": Vector2(0.0, 2.0), "col": Color(0.95, 0.90, 0.72), "name": "Eldoria Square"},
			{"pos": Vector2(0.0, -24.0), "col": Color(0.42, 0.78, 1.0), "name": "★ Adventurers Guild"},
			{"pos": Vector2(-19.0, 11.0), "col": Color(0.95, 0.55, 0.30), "name": "Forge"},
			{"pos": Vector2(39.0, -4.0), "col": Color(0.82, 0.80, 0.75), "name": "Stone Bridge"},
			{"pos": Vector2(16.0, 49.0), "col": Color(0.55, 0.88, 1.0), "name": "Crystal Lake"},
			{"pos": Vector2(62.0, -18.0), "col": UIFactory.GOLD, "name": "Ancient Ruins"},
			{"pos": Vector2(-14.0, -64.0), "col": Color(0.75, 0.72, 0.85), "name": "Shadowfang Cave"},
			{"pos": Vector2(-60.0, -24.0), "col": UIFactory.DANGER, "name": "Monster Camp"},
			{"pos": Vector2(-54.0, 42.0), "col": Color(0.52, 0.94, 0.76), "name": "Sacred Grove"},
			{"pos": Vector2(52.0, 24.0), "col": Color(0.86, 0.44, 0.98), "name": "☠ Sunken Crypt"},
		]
		var font := ThemeDB.fallback_font
		for poi: Dictionary in pois:
			var p2 := poi["pos"] as Vector2
			var px := _to_px(p2.x, p2.y)
			draw_circle(px, 5.5, poi["col"] as Color)
			if font != null:
				draw_string(font, px + Vector2(8.0, 4.0), String(poi["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

		# Player Live Marker
		var marker_world := Vector2(player_pos.x, player_pos.z)
		if player_zone == "guild":
			marker_world = Vector2(0.0, -24.0)
		elif player_zone == "dungeon":
			marker_world = Vector2(52.0, 24.0)
		elif player_zone == "house":
			marker_world = Vector2(-16.0, -8.0)
		var mp := _to_px(marker_world.x, marker_world.y)
		draw_circle(mp, 8.5, Color(1.0, 1.0, 1.0, 0.35))
		draw_circle(mp, 5.0, Color(0.25, 1.0, 0.45))
		draw_rect(Rect2(Vector2.ZERO, size), UIFactory.BORDER_GOLD, false, 2.5)

var player: Player

func _ready() -> void:
	configure("World Map — Eldoria Valley", "world_map")
	super._ready()

func refresh() -> void:
	clear_content()
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 14)
	content.add_child(split)

	var map_canvas := EldoriaMapCanvas.new()
	map_canvas.custom_minimum_size = Vector2(460, 430)
	map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if player != null:
		map_canvas.player_pos = player.global_position
		map_canvas.player_zone = player.zone
	split.add_child(map_canvas)

	var legend := UIFactory.card_panel()
	legend.custom_minimum_size = Vector2(260, 0)
	split.add_child(legend)
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 6)
	legend.add_child(lbox)
	lbox.add_child(UIFactory.label("🧭 Eldoria Regions", 18, UIFactory.GOLD))
	lbox.add_child(UIFactory.label("● You Are In: %s" % (player.zone.capitalize() if player != null else "Eldoria"), 15, UIFactory.ACCENT))
	lbox.add_child(UIFactory.hsep())
	var notes := [
		"★ Adventurers Guild — North Square",
		"🔨 Blacksmith Forge — SW District",
		"🌾 Windmill Farms — South Gate",
		"🌉 East Stone Bridge — River Crossing",
		"💧 Crystal Lake — Moonpetal Shore",
		"🏛 Ancient Ruins — East Terrace (Elite)",
		"🦇 Shadowfang Cave — North Crags",
		"🌿 Sacred Grove — SW Woods (Hidden)",
		"☠ Sunken Crypt — SE Vaults (Boss)",
	]
	for n: String in notes:
		lbox.add_child(UIFactory.wrapped_label(n, 14, UIFactory.TEXT_DIM))
