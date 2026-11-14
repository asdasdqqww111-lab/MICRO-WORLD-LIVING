class_name Interiors
extends RefCounted
## The furnished rooms the hero can walk into: the cottage and the guild hall.
## Each is laid out by hand as a few areas with a purpose, drawn almost
## entirely as vertex-coloured batches (see InteriorKit) so a whole room is a
## handful of draw calls. Lights are kept to three or four per room.

const FURNITURE_SCALE := 0.62          # KayKit furniture brought down to the 1.3 m hero
const WOOD := Color(0.50, 0.34, 0.20)
const DARK_WOOD := Color(0.30, 0.21, 0.13)
const IRON := Color(0.18, 0.17, 0.18)
const GOLD := Color(0.86, 0.68, 0.26)

# --- shared pieces --------------------------------------------------------------

## Four walls, baseboard, crown and ceiling. Visuals go into the batch,
## each wall gets one solid collider outside the room.
static func _shell(parent: Node3D, b: InteriorKit.Batch, o: Vector3, hw: float, hd: float, h: float,
		wall: Color, trim: Color, ceiling: Color, prefix: String) -> void:
	var t := 0.6
	InteriorKit.solid(parent, o + Vector3(0.0, 0.0, -hd - t * 0.5), Vector3(hw * 2.0 + t * 2.0, h, t), prefix + "WallN")
	InteriorKit.solid(parent, o + Vector3(0.0, 0.0, hd + t * 0.5), Vector3(hw * 2.0 + t * 2.0, h, t), prefix + "WallS")
	InteriorKit.solid(parent, o + Vector3(-hw - t * 0.5, 0.0, 0.0), Vector3(t, h, hd * 2.0), prefix + "WallW")
	InteriorKit.solid(parent, o + Vector3(hw + t * 0.5, 0.0, 0.0), Vector3(t, h, hd * 2.0), prefix + "WallE")
	var low := InteriorKit.tone(wall, 0.70)
	var high := InteriorKit.tone(wall, 0.94)
	b.quad(o + Vector3(-hw, 0, -hd), o + Vector3(hw, 0, -hd), o + Vector3(hw, h, -hd), o + Vector3(-hw, h, -hd), Vector3(0, 0, 1), low, high)
	b.quad(o + Vector3(-hw, 0, hd), o + Vector3(hw, 0, hd), o + Vector3(hw, h, hd), o + Vector3(-hw, h, hd), Vector3(0, 0, -1), low, high)
	b.quad(o + Vector3(-hw, 0, -hd), o + Vector3(-hw, 0, hd), o + Vector3(-hw, h, hd), o + Vector3(-hw, h, -hd), Vector3(1, 0, 0),
		InteriorKit.tone(low, 0.93), InteriorKit.tone(high, 0.93))
	b.quad(o + Vector3(hw, 0, -hd), o + Vector3(hw, 0, hd), o + Vector3(hw, h, hd), o + Vector3(hw, h, -hd), Vector3(-1, 0, 0),
		InteriorKit.tone(low, 0.93), InteriorKit.tone(high, 0.93))
	b.quad(o + Vector3(-hw, h, -hd), o + Vector3(hw, h, -hd), o + Vector3(hw, h, hd), o + Vector3(-hw, h, hd), Vector3.DOWN, ceiling, ceiling)
	for y: float in [0.0, h - 0.16]:
		b.box(o + Vector3(0.0, y, -hd + 0.035), Vector3(hw * 2.0, 0.16, 0.07), trim, 0.0, 0.0)
		b.box(o + Vector3(0.0, y, hd - 0.035), Vector3(hw * 2.0, 0.16, 0.07), trim, 0.0, 0.0)
		b.box(o + Vector3(-hw + 0.035, y, 0.0), Vector3(0.07, 0.16, hd * 2.0), trim, 0.0, 0.0)
		b.box(o + Vector3(hw - 0.035, y, 0.0), Vector3(0.07, 0.16, hd * 2.0), trim, 0.0, 0.0)

## Upright timbers set into the walls at a regular spacing.
static func _wall_posts(b: InteriorKit.Batch, o: Vector3, hw: float, hd: float, h: float, gap: float, col: Color, w: float = 0.14) -> void:
	var nx := maxi(1, int(round(hw * 2.0 / gap)))
	for i in nx + 1:
		var x := -hw + hw * 2.0 * float(i) / float(nx)
		b.box(o + Vector3(x, 0.0, -hd + 0.04), Vector3(w, h, 0.08), col, 0.0, 0.15)
		b.box(o + Vector3(x, 0.0, hd - 0.04), Vector3(w, h, 0.08), col, 0.0, 0.15)
	var nz := maxi(1, int(round(hd * 2.0 / gap)))
	for i in range(1, nz):
		var z := -hd + hd * 2.0 * float(i) / float(nz)
		b.box(o + Vector3(-hw + 0.04, 0.0, z), Vector3(0.08, h, w), col, 0.0, 0.15)
		b.box(o + Vector3(hw - 0.04, 0.0, z), Vector3(0.08, h, w), col, 0.0, 0.15)

## A KayKit furniture model with a collider that matches its footprint.
static func _prop(parent: Node3D, path: String, pos: Vector3, facing: Vector3, scale: float,
		node_name: String, solid: bool = true) -> Vector3:
	var yaw := atan2(facing.x, facing.z)
	var node := WorldBuilder.place_model(parent, path, pos, yaw, scale, Vector3.ZERO, node_name)
	if node == null:
		return Vector3.ZERO
	WorldBuilder._apply_model_lod(node, 60.0, false)
	var size := WorldBuilder._model_bounds(node).size * scale
	if solid and size != Vector3.ZERO:
		InteriorKit.solid(parent, pos, Vector3(maxf(size.x - 0.06, 0.1), size.y, maxf(size.z - 0.06, 0.1)), node_name + "Solid", yaw)
	return size

static func _sign(parent: Node3D, pos: Vector3, facing: Vector3, text_ar: String, text_en: String,
		b: InteriorKit.Batch, width: float = 1.5) -> void:
	var n := facing.normalized()
	var sx := absf(n.z)
	var sz := absf(n.x)
	b.box(pos - Vector3(0.0, 0.19, 0.0) - n * 0.03, Vector3(sx * width + sz * 0.05, 0.38, sz * width + sx * 0.05), DARK_WOOD, 0.0, 0.0)
	b.box(pos - Vector3(0.0, 0.16, 0.0) - n * 0.015, Vector3(sx * (width - 0.1) + sz * 0.05, 0.32, sz * (width - 0.1) + sx * 0.05),
		Color(0.80, 0.70, 0.50), 0.0, 0.0)
	var label := Label3D.new()
	label.name = "Sign"
	label.text = text_ar if Localization.is_arabic() else text_en
	label.font_size = 56
	label.pixel_size = 0.0034
	label.outline_size = 0
	label.modulate = Color(0.22, 0.14, 0.08)
	label.shaded = false
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
	label.position = pos + n * 0.02
	label.rotation.y = atan2(n.x, n.z)

static func _tableware(b: InteriorKit.Batch, top: Vector3, rng: RandomNumberGenerator, places: int, radius: float) -> void:
	for i in places:
		var a := TAU * float(i) / float(places) + rng.randf() * 0.5
		var p := top + Vector3(cos(a), 0.0, sin(a)) * radius
		b.cyl(p, 0.09, 0.10, 0.012, Color(0.86, 0.82, 0.72), 8, 0.0)
		var m := p + Vector3(cos(a + 1.2), 0.0, sin(a + 1.2)) * 0.15
		b.cyl(m, 0.04, 0.045, 0.10, Color(0.46, 0.32, 0.18), 6, 0.0)
		b.cyl(m + Vector3(0.0, 0.10, 0.0), 0.04, 0.04, 0.012, Color(0.94, 0.90, 0.78), 6, 0.0)

static func _candle(b: InteriorKit.Batch, glow: InteriorKit.Batch, base: Vector3, height: float = 0.16) -> void:
	b.cyl(base, 0.045, 0.03, 0.02, GOLD, 6, 0.0)
	b.cyl(base + Vector3(0.0, 0.02, 0.0), 0.022, 0.022, height, Color(0.94, 0.90, 0.78), 5, 0.0)
	glow.cyl(base + Vector3(0.0, 0.02 + height, 0.0), 0.024, 0.0, 0.07, Color(1.0, 0.86, 0.48), 5, 0.0)

# --- 1. Hero's cottage ---------------------------------------------------------

static func build_house(parent: Node3D) -> Dictionary:
	var o := WorldBuilder.INTERIOR_ORIGIN
	var hw := 4.2
	var hd := 3.4
	var h := 2.7
	var rng := RandomNumberGenerator.new()
	rng.seed = 4101
	var b := InteriorKit.Batch.new()
	var glow := InteriorKit.Batch.new()
	var panes := InteriorKit.Batch.new()
	var shafts := InteriorKit.Batch.new()
	var fs := FURNITURE_SCALE
	var fur := AssetLibrary.FURNITURE_DIR
	var stone := Color(0.56, 0.53, 0.50)

	# Shell: plank floor, plastered walls in a timber frame, beamed ceiling.
	InteriorKit.solid(parent, o + Vector3(0.0, -0.5, 0.0), Vector3(hw * 2.0 + 1.2, 0.5, hd * 2.0 + 1.2), "HouseFloor")
	InteriorKit.plank_floor(b, o, Rect2(-hw, -hd, hw * 2.0, hd * 2.0), Color(0.56, 0.39, 0.24), rng)
	_shell(parent, b, o, hw, hd, h, Color(0.86, 0.78, 0.64), DARK_WOOD, Color(0.34, 0.25, 0.17), "House")
	_wall_posts(b, o, hw, hd, h, 2.1, DARK_WOOD)
	for z: float in [-2.2, 0.0, 2.2]:
		b.box(o + Vector3(0.0, h - 0.20, z), Vector3(hw * 2.0, 0.20, 0.22), DARK_WOOD, 0.0, 0.0)
	b.box(o + Vector3(0.0, h - 0.30, 0.0), Vector3(0.20, 0.12, hd * 2.0), InteriorKit.tone(DARK_WOOD, 0.85), 0.0, 0.0)

	# Hearth in the middle of the north wall: the heart of the room.
	var fire_pos := InteriorKit.fireplace(b, glow, parent, o + Vector3(0.0, 0.0, -hd), Vector3(0, 0, 1), 1.9, 0.95, h, stone)
	InteriorKit.solid(parent, o + Vector3(0.0, 0.0, -hd + 0.36), Vector3(2.1, h, 0.72), "HouseHearthSolid")
	InteriorKit.flicker_light(parent, fire_pos, Color(1.0, 0.60, 0.28), 2.0, 7.5, 0.20, "HearthLight")
	_candle(b, glow, o + Vector3(-0.85, 1.38, -hd + 0.50))
	_candle(b, glow, o + Vector3(0.85, 1.38, -hd + 0.50))
	b.box(o + Vector3(0.25, 1.38, -hd + 0.50), Vector3(0.26, 0.05, 0.18), Color(0.50, 0.16, 0.14), 0.25, 0.0)
	InteriorKit.wall_shield(b, o + Vector3(0.0, 2.05, -hd + 0.47), Vector3(0, 0, 1), 0.30, Color(0.20, 0.34, 0.62), GOLD)
	InteriorKit.rug(b, o, Rect2(-1.35, -2.45, 2.7, 1.75), Color(0.60, 0.18, 0.16), Color(0.84, 0.66, 0.30))
	_prop(parent, fur + "chair_A_wood.gltf", o + Vector3(-0.95, 0.0, -1.35), Vector3(0.3, 0, -1), fs, "HouseFireChairA")
	_prop(parent, fur + "chair_A_wood.gltf", o + Vector3(0.95, 0.0, -1.35), Vector3(-0.3, 0, -1), fs, "HouseFireChairB")
	InteriorKit.stool(b, o + Vector3(0.0, 0.0, -1.2), WOOD, 0.30)
	b.cyl(o + Vector3(0.05, 0.30, -1.2), 0.04, 0.045, 0.10, Color(0.46, 0.32, 0.18), 6, 0.0)
	# firewood stack
	for i in 5:
		b.box(o + Vector3(1.55, 0.11 * float(int(i / 3.0)), -2.98 + 0.13 * float(i % 3)), Vector3(0.46, 0.11, 0.11), Color(0.44, 0.30, 0.18).lerp(DARK_WOOD, rng.randf() * 0.6), 0.0, 0.2)

	# Sleeping corner (north-west): bed, bedside cabinet with a lamp, chest, rug.
	_prop(parent, fur + "bed_single_A.gltf", o + Vector3(-3.55, 0.0, -2.25), Vector3(0, 0, 1), fs, "HouseBed")
	var cab := _prop(parent, fur + "cabinet_small.gltf", o + Vector3(-2.60, 0.0, -3.02), Vector3(0, 0, 1), fs, "HouseBedside")
	_prop(parent, fur + "lamp_table.gltf", o + Vector3(-2.60, cab.y, -3.02), Vector3(0, 0, 1), fs * 0.62, "HouseLamp", false)
	_prop(parent, AssetLibrary.DUNGEON_DIR + "chest.glb", o + Vector3(-3.55, 0.0, -0.95), Vector3(0, 0, 1), 0.40, "HouseChest")
	InteriorKit.rug(b, o, Rect2(-2.95, -2.6, 0.95, 1.7), Color(0.20, 0.34, 0.56), Color(0.78, 0.74, 0.62))
	InteriorKit.banner(b, o + Vector3(-hw, 2.35, -2.25), Vector3(1, 0, 0), 0.9, 1.0, Color(0.20, 0.36, 0.60), GOLD)
	InteriorKit.painting(b, o + Vector3(-2.35, 1.75, -hd), Vector3(0, 0, 1), 0.7, 0.5, Color(0.62, 0.80, 0.94), Color(0.34, 0.56, 0.30))

	# Kitchen corner (north-east): worktop, jars, barrel, sacks.
	InteriorKit.counter(b, o + Vector3(2.75, 0.0, -3.05), Vector3(1.9, 0.62, 0.6), WOOD)
	InteriorKit.solid(parent, o + Vector3(2.75, 0.0, -3.05), Vector3(1.9, 0.62, 0.6), "HouseWorktopSolid")
	b.cyl(o + Vector3(2.2, 0.62, -3.05), 0.13, 0.15, 0.16, IRON, 8, 0.0)
	b.cyl(o + Vector3(2.75, 0.62, -3.10), 0.07, 0.05, 0.20, Color(0.30, 0.50, 0.30), 6, 0.0)
	b.cyl(o + Vector3(2.98, 0.62, -3.00), 0.06, 0.06, 0.14, Color(0.74, 0.50, 0.26), 6, 0.0)
	b.box(o + Vector3(3.35, 0.62, -3.05), Vector3(0.30, 0.09, 0.18), Color(0.80, 0.60, 0.34), 0.3, 0.0)
	b.box(o + Vector3(2.75, 1.55, -hd + 0.11), Vector3(1.7, 0.04, 0.22), WOOD, 0.0, 0.0)
	for i in 6:
		b.cyl(o + Vector3(2.05 + 0.27 * float(i), 1.59, -hd + 0.12), 0.06, 0.06, 0.13,
			Color.from_hsv(0.08 + 0.07 * float(i), 0.45, 0.72), 6, 0.0)
	InteriorKit.barrel(b, o + Vector3(3.78, 0.0, -2.15), WOOD)
	InteriorKit.solid_cyl(parent, o + Vector3(3.78, 0.0, -2.15), 0.30, 0.72, "HouseBarrelSolid")
	InteriorKit.sack(b, o + Vector3(3.80, 0.0, -1.55), Color(0.72, 0.62, 0.44))
	InteriorKit.sack(b, o + Vector3(3.45, 0.0, -1.75), Color(0.66, 0.56, 0.40), 0.8)

	# Dining spot (south-east): table laid for two under the east window.
	var table_pos := o + Vector3(2.75, 0.0, 1.35)
	InteriorKit.table(b, table_pos, Vector3(0.9, 0.56, 1.3), WOOD)
	InteriorKit.solid(parent, table_pos, Vector3(0.9, 0.56, 1.3), "HouseTableSolid")
	_tableware(b, table_pos + Vector3(0.0, 0.56, 0.0), rng, 2, 0.36)
	_candle(b, glow, table_pos + Vector3(0.0, 0.56, 0.0), 0.13)
	b.box(table_pos + Vector3(-0.18, 0.56, 0.1), Vector3(0.24, 0.08, 0.13), Color(0.82, 0.62, 0.36), 0.5, 0.0)
	_prop(parent, fur + "chair_A_wood.gltf", table_pos + Vector3(-0.82, 0.0, -0.3), Vector3(1, 0, 0), fs, "HouseDiningChairA")
	_prop(parent, fur + "chair_A_wood.gltf", table_pos + Vector3(-0.82, 0.0, 0.4), Vector3(1, 0, 0), fs, "HouseDiningChairB")
	InteriorKit.rug(b, o, Rect2(1.45, 0.45, 2.3, 1.9), Color(0.36, 0.44, 0.26), Color(0.74, 0.66, 0.44), 0.012)

	# Study (south-west): bookshelf, writing desk under the west window.
	InteriorKit.shelf(b, o + Vector3(-hw + 0.18, 0.0, 2.35), 1.5, 1.55, WOOD, PI * 0.5, rng, "books")
	InteriorKit.solid(parent, o + Vector3(-hw + 0.18, 0.0, 2.35), Vector3(0.36, 1.55, 1.5), "HouseShelfSolid")
	var desk := o + Vector3(-3.72, 0.0, 0.55)
	InteriorKit.table(b, desk, Vector3(0.7, 0.56, 1.2), InteriorKit.tone(WOOD, 0.9))
	InteriorKit.solid(parent, desk, Vector3(0.7, 0.56, 1.2), "HouseDeskSolid")
	_prop(parent, fur + "book_set.gltf", desk + Vector3(0.0, 0.56 + 0.25 * fs, -0.3), Vector3(1, 0, 0), fs, "HouseBooks", false)
	b.slab(-0.16, -0.11, 0.16, 0.11, 0.565, Color(0.90, 0.85, 0.70), desk + Vector3(0.05, 0.0, 0.2))
	_candle(b, glow, desk + Vector3(-0.2, 0.56, 0.5), 0.12)
	InteriorKit.stool(b, desk + Vector3(0.62, 0.0, 0.1), WOOD, 0.32)

	# Entrance (south): the door, a mat, a shield and boots by the wall.
	InteriorKit.door(b, o + Vector3(0.0, 0.0, hd), Vector3(0, 0, -1), 1.0, 1.8, WOOD)
	InteriorKit.rug(b, o, Rect2(-0.6, hd - 0.85, 1.2, 0.7), Color(0.50, 0.38, 0.22), Color(0.34, 0.25, 0.15), 0.012)
	InteriorKit.wall_shield(b, o + Vector3(1.6, 1.55, hd), Vector3(0, 0, -1), 0.28, Color(0.62, 0.20, 0.18), Color(0.70, 0.70, 0.72))
	InteriorKit.crate(b, o + Vector3(1.9, 0.0, hd - 0.4), 0.46, WOOD, 0.2)
	InteriorKit.crate(b, o + Vector3(1.95, 0.46, hd - 0.4), 0.32, InteriorKit.tone(WOOD, 1.1), -0.3)
	InteriorKit.solid(parent, o + Vector3(1.9, 0.0, hd - 0.4), Vector3(0.5, 0.78, 0.5), "HouseCrateSolid")
	b.box(o + Vector3(-1.5, 1.5, hd - 0.05), Vector3(0.9, 0.07, 0.05), DARK_WOOD, 0.0, 0.0)
	b.box(o + Vector3(-1.72, 0.95, hd - 0.10), Vector3(0.34, 0.56, 0.06), Color(0.24, 0.36, 0.26), 0.0, 0.2)
	b.box(o + Vector3(-1.28, 1.05, hd - 0.10), Vector3(0.30, 0.46, 0.06), Color(0.46, 0.30, 0.18), 0.0, 0.2)

	# Windows: one over the desk, two on the east wall. They follow the clock.
	InteriorKit.window(b, panes, shafts, o + Vector3(-hw, 1.55, 0.55), Vector3(1, 0, 0), 0.9, 0.9, 2.2)
	InteriorKit.window(b, panes, shafts, o + Vector3(hw, 1.55, -0.6), Vector3(-1, 0, 0), 0.9, 0.9, 2.2)
	InteriorKit.window(b, panes, shafts, o + Vector3(hw, 1.55, 1.35), Vector3(-1, 0, 0), 0.9, 0.9, 2.2)

	# Lantern hanging from the middle beam.
	var lantern := o + Vector3(0.0, 2.0, 0.55)
	b.cyl(lantern + Vector3(0.0, 0.22, 0.0), 0.012, 0.012, h - 2.22 - 0.2, IRON, 4, 0.0)
	b.cyl(lantern + Vector3(0.0, 0.16, 0.0), 0.11, 0.03, 0.07, IRON, 6, 0.0)
	b.cyl(lantern - Vector3(0.0, 0.02, 0.0), 0.08, 0.08, 0.02, IRON, 6, 0.0)
	glow.cyl(lantern, 0.07, 0.07, 0.16, Color(1.0, 0.84, 0.50), 6, 0.0)
	InteriorKit.steady_light(parent, lantern - Vector3(0.0, 0.1, 0.0), Color(1.0, 0.80, 0.54), 1.15, 6.5, "LanternLight")
	var sun := InteriorKit.steady_light(parent, o + Vector3(1.9, 1.7, 0.4), Color(1.0, 0.96, 0.88), 0.85, 6.0, "WindowLight")

	b.commit(parent, "HouseInterior")
	glow.commit(parent, "HouseGlow", true)
	InteriorKit.commit_daylight(parent, panes, shafts, [sun])
	InteriorKit.motes(parent, o + Vector3(1.6, 1.3, 0.3), Vector3(2.0, 0.9, 1.6), Color(1.0, 0.92, 0.72), 10, 0.04, "HouseDust")

	return {
		"spawn": o + Vector3(0.0, 0.6, 1.5),
		"exit": o + Vector3(0.0, 0.0, hd - 0.35),
		"exit_radius": 1.35,
		"origin": o,
		"bed": o + Vector3(-3.0, 0.0, -2.25),
		"size": Vector3(hw * 2.0, h, hd * 2.0),
		"ambient": Color(0.62, 0.52, 0.44),
		"ambient_energy": 0.55,
	}

# --- 2. Adventurers' Guild hall ------------------------------------------------

static func _pillar(parent: Node3D, b: InteriorKit.Batch, base: Vector3, h: float, stone: Color, node_name: String) -> void:
	b.box(base, Vector3(0.86, 0.34, 0.86), InteriorKit.tone(stone, 0.9), 0.0, 0.2)
	b.cyl(base + Vector3(0.0, 0.34, 0.0), 0.33, 0.30, h - 0.34 - 0.40, stone, 8, 0.10)
	b.cyl(base + Vector3(0.0, h - 0.40, 0.0), 0.30, 0.46, 0.18, InteriorKit.tone(stone, 1.04), 8, 0.0)
	b.box(base + Vector3(0.0, h - 0.22, 0.0), Vector3(0.96, 0.22, 0.96), InteriorKit.tone(stone, 0.92), 0.0, 0.0)
	InteriorKit.solid(parent, base, Vector3(0.80, h, 0.80), node_name)

static func build_guild(parent: Node3D) -> Dictionary:
	var o := WorldBuilder.GUILD_ORIGIN
	var hw := 10.0
	var hd := 12.0
	var h := 5.2
	var rng := RandomNumberGenerator.new()
	rng.seed = 7702
	var b := InteriorKit.Batch.new()
	var glow := InteriorKit.Batch.new()
	var panes := InteriorKit.Batch.new()
	var shafts := InteriorKit.Batch.new()
	var stone := Color(0.62, 0.59, 0.55)
	var royal := Color(0.16, 0.30, 0.62)
	var fs := FURNITURE_SCALE

	# Shell: flagstones, stone walls with oak wainscot, trussed ceiling.
	InteriorKit.solid(parent, o + Vector3(0.0, -0.5, 0.0), Vector3(hw * 2.0 + 1.2, 0.5, hd * 2.0 + 1.2), "GuildFloor")
	InteriorKit.tile_floor(b, o, Rect2(-hw, -hd, hw * 2.0, hd * 2.0), Color(0.56, 0.54, 0.52), rng, 1.4)
	_shell(parent, b, o, hw, hd, h, stone, DARK_WOOD, Color(0.26, 0.19, 0.13), "Guild")
	for s: float in [-1.0, 1.0]:
		b.box(o + Vector3(s * (hw - 0.03), 0.16, 0.0), Vector3(0.06, 1.0, hd * 2.0), InteriorKit.tone(WOOD, 0.86), 0.0, 0.25)
		b.box(o + Vector3(s * (hw - 0.05), 1.16, 0.0), Vector3(0.10, 0.07, hd * 2.0), DARK_WOOD, 0.0, 0.0)
	b.box(o + Vector3(0.0, 0.16, -hd + 0.03), Vector3(hw * 2.0, 1.0, 0.06), InteriorKit.tone(WOOD, 0.86), 0.0, 0.25)
	b.box(o + Vector3(0.0, 1.16, -hd + 0.05), Vector3(hw * 2.0, 0.07, 0.10), DARK_WOOD, 0.0, 0.0)
	_wall_posts(b, o, hw, hd, h, 4.0, DARK_WOOD, 0.22)
	var rows: Array[float] = [-7.0, -1.0, 5.0]
	for z: float in rows:
		b.box(o + Vector3(0.0, h - 0.34, z), Vector3(hw * 2.0, 0.34, 0.36), DARK_WOOD, 0.0, 0.0)
		for x: float in [-6.2, 6.2]:
			_pillar(parent, b, o + Vector3(x, 0.0, z), h - 0.34, stone, "GuildPillar")
			var inward := Vector3(-signf(x), 0.0, 0.0)
			InteriorKit.banner(b, o + Vector3(x - signf(x) * 0.34, 4.0, z), inward, 0.72, 1.7, royal, GOLD)
	for x: float in [-6.2, 6.2]:
		b.box(o + Vector3(x, h - 0.26, 0.0), Vector3(0.30, 0.26, hd * 2.0), InteriorKit.tone(DARK_WOOD, 0.9), 0.0, 0.0)
	b.box(o + Vector3(0.0, h - 0.34, 10.2), Vector3(hw * 2.0, 0.34, 0.36), DARK_WOOD, 0.0, 0.0)

	# The aisle: royal runner from the doors to the Guild Master's dais.
	InteriorKit.rug(b, o, Rect2(-1.3, -6.3, 2.6, 17.0), royal, GOLD)

	# Entrance (south): double doors, flanking banners and torches.
	InteriorKit.door(b, o + Vector3(0.0, 0.0, hd), Vector3(0, 0, -1), 2.4, 2.7, WOOD, true)
	for s: float in [-1.0, 1.0]:
		InteriorKit.banner(b, o + Vector3(s * 2.6, 3.6, hd), Vector3(0, 0, -1), 0.8, 2.0, royal, GOLD)
		InteriorKit.torch(b, parent, o + Vector3(s * 1.75, 1.75, hd), Vector3(0, 0, -1), Color(1.0, 0.56, 0.18))

	# Reception (west of the aisle): counter, ledger, record shelves behind.
	var desk := o + Vector3(-5.3, 0.0, 1.9)
	InteriorKit.counter(b, desk, Vector3(3.4, 0.74, 0.8), WOOD)
	InteriorKit.solid(parent, desk, Vector3(3.5, 0.9, 0.9), "ReceptionDesk")
	b.box(desk + Vector3(-0.5, 0.74, 0.0), Vector3(0.50, 0.04, 0.36), Color(0.92, 0.87, 0.72), 0.08, 0.0)
	b.box(desk + Vector3(-0.5, 0.745, 0.0), Vector3(0.02, 0.045, 0.36), Color(0.40, 0.16, 0.14), 0.08, 0.0)
	b.cyl(desk + Vector3(0.25, 0.74, 0.1), 0.05, 0.04, 0.08, IRON, 6, 0.0)
	b.cyl(desk + Vector3(0.9, 0.74, 0.12), 0.08, 0.02, 0.07, GOLD, 8, 0.0)
	for i in 4:
		b.box(desk + Vector3(-1.35, 0.74 + 0.07 * float(int(i / 2.0)), -0.15 + 0.09 * float(i % 2)), Vector3(0.34, 0.07, 0.07),
			Color(0.90, 0.84, 0.66), 0.0, 0.1)
	_candle(b, glow, desk + Vector3(1.4, 0.74, -0.1), 0.18)
	InteriorKit.shelf(b, o + Vector3(-5.3, 0.0, -0.25), 3.2, 1.9, WOOD, 0.0, rng, "books")
	InteriorKit.solid(parent, o + Vector3(-5.3, 0.0, -0.25), Vector3(3.2, 1.9, 0.36), "ReceptionShelfSolid")
	_sign(parent, o + Vector3(-5.3, 2.55, 1.9), Vector3(0, 0, 1), "الاستقبال والتسجيل", "Reception", b, 2.0)
	b.cyl(o + Vector3(-6.2, 2.55, 1.9), 0.012, 0.012, h - 2.55 - 0.3, IRON, 4, 0.0)
	b.cyl(o + Vector3(-4.4, 2.55, 1.9), 0.012, 0.012, h - 2.55 - 0.3, IRON, 4, 0.0)

	# Contract board (east of the aisle) with a mat in front of it.
	var board := QuestBoardProp.new()
	board.name = "GuildHallQuestBoard"
	board.setup("Inspect Official Guild Contracts")
	parent.add_child(board)
	board.position = o + Vector3(4.6, 0.0, 1.6)
	board.rotation.y = -0.35
	InteriorKit.rug(b, o, Rect2(3.1, 1.9, 2.6, 1.6), Color(0.52, 0.20, 0.18), GOLD, 0.012)

	# Guild Master's dais (north): steps, desk, high seat, great banner.
	var dz0 := -7.5
	var dh := 0.36
	b.box(o + Vector3(0.0, 0.0, (dz0 - hd) * 0.5), Vector3(8.6, dh, hd + dz0), InteriorKit.tone(stone, 0.92), 0.0, 0.2)
	b.slab(-4.2, -hd + 0.1, 4.2, dz0 - 0.1, dh + 0.004, InteriorKit.tone(stone, 1.06), o)
	InteriorKit.solid(parent, o + Vector3(0.0, 0.0, (dz0 - hd) * 0.5), Vector3(8.6, dh, hd + dz0), "MasterDais")
	for i in 2:
		b.box(o + Vector3(0.0, 0.0, dz0 + 0.15 + 0.3 * float(i)), Vector3(4.6, dh - 0.12 * float(i + 1), 0.3),
			InteriorKit.tone(stone, 0.98 - 0.04 * float(i)), 0.0, 0.15)
	InteriorKit.ramp(parent, 0.0, 4.6, dz0 + 0.62, dz0 - 0.02, dh, o, "MasterDaisSteps")
	InteriorKit.rug(b, o + Vector3(0.0, dh, 0.0), Rect2(-1.3, -10.4, 2.6, 2.8), royal, GOLD)
	var mdesk := o + Vector3(0.0, dh, -8.7)
	InteriorKit.table(b, mdesk, Vector3(2.3, 0.72, 0.9), InteriorKit.tone(WOOD, 0.8))
	InteriorKit.solid(parent, mdesk, Vector3(2.3, 0.72, 0.9), "MasterDeskSolid")
	b.slab(-0.55, -0.3, 0.35, 0.3, 0.725, Color(0.88, 0.80, 0.60), mdesk)
	b.slab(-0.40, -0.18, 0.05, 0.1, 0.728, Color(0.50, 0.66, 0.44), mdesk)
	b.box(mdesk + Vector3(0.75, 0.72, -0.1), Vector3(0.30, 0.09, 0.22), Color(0.44, 0.16, 0.16), 0.3, 0.0)
	_candle(b, glow, mdesk + Vector3(-0.95, 0.72, 0.25), 0.22)
	_candle(b, glow, mdesk + Vector3(0.98, 0.72, 0.28), 0.22)
	var seat := o + Vector3(0.0, dh, -10.7)
	b.box(seat, Vector3(0.9, 0.5, 0.8), InteriorKit.tone(WOOD, 0.8), 0.0, 0.2)
	b.box(seat + Vector3(0.0, 0.5, -0.32), Vector3(0.9, 1.5, 0.16), InteriorKit.tone(WOOD, 0.8), 0.0, 0.1)
	b.box(seat + Vector3(0.0, 0.5, -0.22), Vector3(0.66, 1.2, 0.06), royal, 0.0, 0.1)
	for s: float in [-1.0, 1.0]:
		b.box(seat + Vector3(s * 0.45, 0.5, 0.0), Vector3(0.12, 0.3, 0.8), InteriorKit.tone(WOOD, 0.7), 0.0, 0.1)
		b.cyl(seat + Vector3(s * 0.45, 2.0, -0.32), 0.08, 0.0, 0.2, GOLD, 6, 0.0)
	InteriorKit.solid(parent, seat, Vector3(1.1, 2.0, 0.8), "MasterSeatSolid")
	InteriorKit.banner(b, o + Vector3(0.0, 4.75, -hd), Vector3(0, 0, 1), 1.9, 3.0, royal, GOLD)
	for s: float in [-1.0, 1.0]:
		InteriorKit.banner(b, o + Vector3(s * 3.1, 4.3, -hd), Vector3(0, 0, 1), 1.0, 2.2, Color(0.56, 0.16, 0.18), GOLD)
		InteriorKit.wall_shield(b, o + Vector3(s * 1.75, 2.3, -hd), Vector3(0, 0, 1), 0.36, Color(0.70, 0.70, 0.74), GOLD)
		InteriorKit.brazier(b, parent, o + Vector3(s * 3.6, dh, -8.1), Color(1.0, 0.56, 0.18), stone)
		InteriorKit.solid_cyl(parent, o + Vector3(s * 3.6, dh, -8.1), 0.28, 0.9, "MasterBrazierSolid")
	InteriorKit.flicker_light(parent, o + Vector3(0.0, 2.3, -8.3), Color(1.0, 0.66, 0.34), 1.5, 10.0, 0.12, "DaisLight")

	# Quartermaster's store (north-west): counter, stocked shelves, crates.
	var qc := o + Vector3(-5.5, 0.0, -4.4)
	InteriorKit.counter(b, qc, Vector3(0.8, 0.74, 2.8), WOOD)
	InteriorKit.solid(parent, qc, Vector3(0.9, 0.9, 2.9), "QuartermasterCounter")
	b.cyl(qc + Vector3(0.0, 0.74, -0.9), 0.06, 0.06, 0.15, Color(0.80, 0.22, 0.22), 6, 0.0)
	b.cyl(qc + Vector3(0.1, 0.74, -0.65), 0.06, 0.06, 0.15, Color(0.24, 0.44, 0.86), 6, 0.0)
	b.box(qc + Vector3(0.0, 0.74, 0.3), Vector3(0.16, 0.05, 0.7), Color(0.74, 0.74, 0.78), 0.1, 0.0)
	b.box(qc + Vector3(0.0, 0.74, 0.95), Vector3(0.34, 0.12, 0.3), InteriorKit.tone(WOOD, 0.7), 0.0, 0.0)
	InteriorKit.shelf(b, o + Vector3(-hw + 0.18, 0.0, -4.4), 4.2, 2.1, WOOD, PI * 0.5, rng, "bottles")
	InteriorKit.solid(parent, o + Vector3(-hw + 0.18, 0.0, -4.4), Vector3(0.36, 2.1, 4.2), "QuartermasterShelfSolid")
	InteriorKit.crate(b, o + Vector3(-8.9, 0.0, -2.0), 0.6, InteriorKit.tone(WOOD, 1.05), 0.2)
	InteriorKit.crate(b, o + Vector3(-8.2, 0.0, -2.1), 0.5, InteriorKit.tone(WOOD, 1.0), -0.3)
	InteriorKit.crate(b, o + Vector3(-8.85, 0.6, -2.0), 0.42, InteriorKit.tone(WOOD, 1.12), 0.5)
	InteriorKit.solid(parent, o + Vector3(-8.6, 0.0, -2.05), Vector3(1.3, 0.9, 0.7), "QuartermasterCratesSolid")
	InteriorKit.barrel(b, o + Vector3(-9.2, 0.0, -7.6), WOOD, 1.1)
	InteriorKit.barrel(b, o + Vector3(-8.5, 0.0, -7.9), WOOD, 1.1)
	InteriorKit.solid(parent, o + Vector3(-8.85, 0.0, -7.75), Vector3(1.4, 0.8, 0.8), "QuartermasterBarrelsSolid")
	InteriorKit.dummy(b, o + Vector3(-7.4, 0.0, -8.6))
	InteriorKit.wall_shield(b, o + Vector3(-7.4, 0.82, -8.42), Vector3(0, 0, 1), 0.26, Color(0.24, 0.40, 0.70), Color(0.74, 0.74, 0.78))
	InteriorKit.solid_cyl(parent, o + Vector3(-7.4, 0.0, -8.6), 0.26, 1.3, "QuartermasterStandSolid")
	_sign(parent, o + Vector3(-5.08, 2.3, -4.4), Vector3(1, 0, 0), "مخزن النقابة", "Guild Store", b, 1.7)
	b.cyl(o + Vector3(-5.08, 2.3, -5.1), 0.012, 0.012, h - 2.3 - 0.3, IRON, 4, 0.0)
	b.cyl(o + Vector3(-5.08, 2.3, -3.7), 0.012, 0.012, h - 2.3 - 0.3, IRON, 4, 0.0)

	# Hearth and lounge (east wall): where veterans trade stories.
	var fire_pos := InteriorKit.fireplace(b, glow, parent, o + Vector3(hw, 0.0, -4.0), Vector3(-1, 0, 0), 2.8, 1.35, h, InteriorKit.tone(stone, 0.9))
	InteriorKit.solid(parent, o + Vector3(hw - 0.36, 0.0, -4.0), Vector3(0.72, h, 3.0), "GuildHearthSolid")
	InteriorKit.flicker_light(parent, fire_pos, Color(1.0, 0.58, 0.26), 2.1, 9.5, 0.20, "HearthLight")
	InteriorKit.rug(b, o, Rect2(6.9, -5.3, 2.0, 2.6), Color(0.56, 0.20, 0.16), GOLD, 0.012)
	InteriorKit.bench(b, o + Vector3(7.5, 0.0, -5.75), 1.6, WOOD, 0.0)
	InteriorKit.bench(b, o + Vector3(7.5, 0.0, -2.25), 1.6, WOOD, 0.0)
	InteriorKit.solid(parent, o + Vector3(7.5, 0.0, -5.75), Vector3(1.6, 0.4, 0.34), "GuildBenchSolidA")
	InteriorKit.solid(parent, o + Vector3(7.5, 0.0, -2.25), Vector3(1.6, 0.4, 0.34), "GuildBenchSolidB")
	InteriorKit.wall_shield(b, o + Vector3(hw - 0.50, 2.7, -4.0), Vector3(-1, 0, 0), 0.42, Color(0.60, 0.18, 0.18), GOLD)
	_candle(b, glow, o + Vector3(hw - 0.5, 1.78, -5.1), 0.2)
	_candle(b, glow, o + Vector3(hw - 0.5, 1.78, -2.9), 0.2)

	# Ladder of ranks on the west wall: F to S, bronze to gold.
	var ranks := [Color(0.50, 0.36, 0.26), Color(0.62, 0.42, 0.26), Color(0.60, 0.62, 0.66), Color(0.30, 0.60, 0.44),
		Color(0.26, 0.48, 0.80), Color(0.60, 0.34, 0.78), Color(0.96, 0.78, 0.28)]
	for i in ranks.size():
		InteriorKit.wall_shield(b, o + Vector3(-hw, 2.2 + 0.07 * float(i), 6.9 - 0.72 * float(i)), Vector3(1, 0, 0),
			0.25 + 0.012 * float(i), ranks[i], Color(0.78, 0.74, 0.62))
	_sign(parent, o + Vector3(-hw + 0.06, 3.35, 4.75), Vector3(1, 0, 0), "سُلَّم الرتب  F ← S", "Ranks  F → S", b, 2.4)

	# Common room (south-west): tables, stools, kegs and a small bar.
	for t: Vector3 in [Vector3(-7.2, 0.0, 8.0), Vector3(-4.4, 0.0, 9.6)]:
		InteriorKit.round_table(b, o + t, 0.62, 0.58, WOOD)
		InteriorKit.solid_cyl(parent, o + t, 0.5, 0.58, "GuildTableSolid")
		_tableware(b, o + t + Vector3(0.0, 0.58, 0.0), rng, 3, 0.36)
		_candle(b, glow, o + t + Vector3(0.0, 0.58, 0.0), 0.12)
		for k in 3:
			var a := TAU * float(k) / 3.0 + t.x
			InteriorKit.stool(b, o + t + Vector3(cos(a), 0.0, sin(a)) * 0.98, WOOD)
	InteriorKit.counter(b, o + Vector3(-8.2, 0.0, 10.9), Vector3(2.6, 0.74, 0.6), InteriorKit.tone(WOOD, 0.9))
	InteriorKit.solid(parent, o + Vector3(-8.2, 0.0, 10.9), Vector3(2.7, 0.9, 0.7), "GuildBarSolid")
	for i in 3:
		b.cyl(o + Vector3(-8.9 + 0.5 * float(i), 0.74, 10.9), 0.045, 0.05, 0.11, Color(0.46, 0.32, 0.18), 6, 0.0)
	for i in 3:
		InteriorKit.barrel(b, o + Vector3(-9.35, 0.0, 6.2 + 0.72 * float(i)), InteriorKit.tone(WOOD, 0.9), 1.05)
	InteriorKit.barrel(b, o + Vector3(-9.35, 0.76, 6.56), InteriorKit.tone(WOOD, 0.9), 0.95)
	InteriorKit.solid(parent, o + Vector3(-9.35, 0.0, 6.92), Vector3(0.7, 1.4, 2.2), "GuildKegsSolid")
	InteriorKit.rug(b, o, Rect2(-8.4, 6.9, 5.2, 3.6), Color(0.40, 0.28, 0.20), Color(0.62, 0.50, 0.30), 0.011)

	# Training corner (south-east): sparring mat, dummies, target, racks.
	b.slab(3.6, 5.9, 9.3, 11.1, 0.010, Color(0.44, 0.34, 0.22), o)
	b.slab(3.8, 6.1, 9.1, 10.9, 0.014, Color(0.76, 0.66, 0.46), o)
	b.ring(o + Vector3(6.2, 0.018, 8.5), 1.5, 1.6, Color(0.58, 0.20, 0.18), 24)
	for dz: float in [6.7, 8.5, 10.3]:
		InteriorKit.dummy(b, o + Vector3(8.7, 0.0, dz))
		InteriorKit.solid_cyl(parent, o + Vector3(8.7, 0.0, dz), 0.24, 1.3, "GuildDummySolid")
	_prop(parent, AssetLibrary.HEXAGON_DIR + "target.gltf", o + Vector3(4.4, 0.0, 11.55), Vector3(0, 0, -1), 5.4, "GuildTarget")
	_prop(parent, AssetLibrary.HEXAGON_DIR + "weaponrack.gltf", o + Vector3(6.6, 0.0, 11.6), Vector3(0, 0, -1), 5.4, "GuildWeaponRack")
	_prop(parent, AssetLibrary.HEXAGON_DIR + "weaponrack.gltf", o + Vector3(-9.5, 0.0, -9.6), Vector3(1, 0, 0), 5.4, "GuildArmoryRack")

	# Tall windows high on the long walls, and the two great chandeliers.
	for z: float in [-9.6, 2.0, 8.4]:
		InteriorKit.window(b, panes, shafts, o + Vector3(-hw, 3.55, z), Vector3(1, 0, 0), 1.0, 1.6, 3.4)
	for z: float in [-9.6, 2.0, 8.4]:
		InteriorKit.window(b, panes, shafts, o + Vector3(hw, 3.55, z), Vector3(-1, 0, 0), 1.0, 1.6, 3.4)
	for z: float in [-1.0, 5.0]:
		for x: float in [-6.2, 6.2]:
			InteriorKit.torch(b, parent, o + Vector3(x, 1.85, z + 0.34), Vector3(0, 0, 1), Color(1.0, 0.56, 0.18))
	for cz: float in [4.2, -3.2]:
		var lp := InteriorKit.chandelier(b, glow, o + Vector3(0.0, 3.55, cz), h - 0.34, 1.35, 10)
		InteriorKit.flicker_light(parent, lp, Color(1.0, 0.82, 0.56), 1.7, 14.0, 0.05, "ChandelierLight")

	b.commit(parent, "GuildInterior")
	glow.commit(parent, "GuildGlow", true)
	InteriorKit.commit_daylight(parent, panes, shafts)
	InteriorKit.motes(parent, o + Vector3(0.0, 2.4, 0.0), Vector3(7.0, 1.6, 9.0), Color(1.0, 0.90, 0.70), 18, 0.04, "GuildDust")

	return {
		"origin": o,
		"spawn": o + Vector3(0.0, 0.6, 9.0),
		"exit": o + Vector3(0.0, 0.0, hd - 0.5),
		"exit_radius": 1.7,
		"size": Vector3(hw * 2.0, h, hd * 2.0),
		"receptionist_pos": o + Vector3(-5.3, 0.0, 0.95),
		"master_pos": o + Vector3(0.0, dh, -9.7),
		"quartermaster_pos": o + Vector3(-6.7, 0.0, -4.4),
		"trainer_pos": o + Vector3(6.2, 0.0, 8.5),
		"veteran_pos": o + Vector3(7.4, 0.0, -4.0),
		"recruit_pos": o + Vector3(-5.8, 0.0, 8.6),
		"ambient": Color(0.56, 0.50, 0.50),
		"ambient_energy": 0.58,
	}
