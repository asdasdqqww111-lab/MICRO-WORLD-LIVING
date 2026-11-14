class_name CityPlan
extends RefCounted
## Single source of truth for the walled town of Eldoria.
##
## The town is a compact cross plan inside a round wall (radius 36 m):
##
##                      N  (-Z)
##               +---- Citadel ----+        The Guild citadel closes the north
##               |  tower  tower   |        side and is built into the wall.
##      garden   |                 |  chapel garden
##   [C] [A] [B] |  forecourt      | [Tavern] [Chapel] [Alchemist]
##  W ===========(  Royal Plaza   )============ E gate -> bridge -> crypt
##   [H] [Mill] [Smith]           [Market] [Barracks] [H]
##      farm  ---- alley ----  |  ---- alley ----  training yard
##               [H]           |            [H]
##               [H]           |            [H]
##                          S gate -> lake
##
## Every building sits on a lot whose front faces a street, lots never overlap,
## and nothing natural (pines, boulders, meadow grass) grows on a street.
## Terrain, the world builder, the forest scatter, the minimap and the world
## map all read this file, so they cannot drift apart again.

const WALL_RADIUS := 36.0
const WALL_SEGMENTS := 20
const PLAZA_RADIUS := 7.0
const AVENUE_HALF := 2.6
const ALLEY_HALF := 1.3
## Distance from an avenue centre line to the building fronts.
const FRONT := 4.4
const GATE_HALF_OPENING := 2.8

# Facing yaw: model fronts are local +Z, so yaw 0 looks south (+Z).
const FACE_SOUTH := 0.0
const FACE_EAST := PI * 0.5
const FACE_NORTH := PI
const FACE_WEST := -PI * 0.5

const HEX := "res://assets/models/hexagon/"

const PLAZA := Vector3(0.0, 0.0, 0.0)
const SPAWN := Vector3(0.0, 0.6, 14.0)
const CASTLE_CENTER := Vector3(0.0, 0.0, -23.5)
const CASTLE_SCALE := 9.0
const GUILD_DOOR := Vector3(0.0, 0.0, -12.4)
const HOUSE_DOOR := Vector3(-19.0, 0.0, -3.5)
const BRIDGE_Z := 0.0

## Compass bearings (degrees, 0 = north, clockwise) of the three town gates.
## The north side is closed by the citadel.
const GATE_BEARINGS := [90.0, 180.0, 270.0]

## Unit-space footprints (width, depth, height) of the KayKit hexagon models.
const MODEL_SIZE := {
	"castle": Vector3(1.98, 2.26, 3.98),
	"tower_A": Vector3(1.00, 1.15, 2.19),
	"tower_B": Vector3(1.20, 1.38, 2.49),
	"tavern": Vector3(1.17, 1.33, 1.40),
	"church": Vector3(1.02, 1.16, 1.65),
	"home_A": Vector3(0.80, 0.86, 0.93),
	"home_B": Vector3(0.88, 1.10, 1.28),
	"blacksmith": Vector3(1.29, 1.25, 0.98),
	"market": Vector3(1.80, 1.31, 0.98),
	"barracks": Vector3(1.44, 1.57, 1.64),
	"lumbermill": Vector3(1.37, 1.19, 1.70),
	"windmill": Vector3(1.13, 0.82, 1.46),
	"stage": Vector3(1.16, 1.12, 0.98),
	"well": Vector3(0.65, 0.76, 0.83),
}

static var _lots: Array[Dictionary] = []
static var _streets: Array = []

static func _lot(node_name: String, kind: String, file: String, x: float, z: float,
		yaw: float, model_scale: float, roof: Color) -> Dictionary:
	var unit: Vector3 = MODEL_SIZE[kind]
	var w := unit.x * model_scale
	var d := unit.y * model_scale
	# World-space half extents of the (axis aligned) lot.
	var sideways := absf(sin(yaw)) > 0.5
	return {
		"name": node_name, "kind": kind, "path": HEX + file,
		"pos": Vector3(x, 0.0, z), "yaw": yaw, "scale": model_scale,
		"size": Vector3(w, unit.z * model_scale, d),
		"half": Vector2(d * 0.5, w * 0.5) if sideways else Vector2(w * 0.5, d * 0.5),
		"roof": roof,
	}

## Row lot helper: places a building so its front sits exactly on the building
## line of the street it faces. `along` is the coordinate along the street.
static func _row_lot(node_name: String, kind: String, file: String, along: float,
		yaw: float, model_scale: float, roof: Color) -> Dictionary:
	var unit: Vector3 = MODEL_SIZE[kind]
	var off := FRONT + unit.y * model_scale * 0.5
	if is_equal_approx(yaw, FACE_SOUTH):
		return _lot(node_name, kind, file, along, -off, yaw, model_scale, roof)
	if is_equal_approx(yaw, FACE_NORTH):
		return _lot(node_name, kind, file, along, off, yaw, model_scale, roof)
	if is_equal_approx(yaw, FACE_EAST):
		return _lot(node_name, kind, file, -off, along, yaw, model_scale, roof)
	return _lot(node_name, kind, file, off, along, yaw, model_scale, roof)

## All solid buildings of the town. Order is stable (names are used by tests,
## quests and the minimap).
static func lots() -> Array[Dictionary]:
	if not _lots.is_empty():
		return _lots
	var red := Color(0.78, 0.36, 0.28)
	var blue := Color(0.36, 0.50, 0.78)
	var green := Color(0.40, 0.62, 0.36)
	var yellow := Color(0.84, 0.70, 0.32)
	var stone := Color(0.56, 0.59, 0.66)
	var wood := Color(0.60, 0.46, 0.30)
	_lots = [
		# --- Citadel (north) -------------------------------------------------
		_lot("AdventurersGuildExterior", "castle", "building_castle_blue.gltf",
			CASTLE_CENTER.x, CASTLE_CENTER.z, FACE_SOUTH, CASTLE_SCALE, stone),
		_lot("CastleHighKeepTower", "tower_A", "building_tower_A_green.gltf",
			13.2, -23.5, FACE_SOUTH, 6.6, stone),
		_lot("CastleBlueTurret", "tower_B", "building_tower_B_blue.gltf",
			-13.2, -23.5, FACE_SOUTH, 5.8, stone),
		# --- North side of the West Avenue (residential, facing south) --------
		_row_lot("HouseB", "home_B", "building_home_B_red.gltf", -9.5, FACE_SOUTH, 7.0, red),
		_row_lot("HouseA", "home_A", "building_home_A_red.gltf", -19.0, FACE_SOUTH, 7.6, red),
		_row_lot("HouseC", "home_A", "building_home_A_green.gltf", -28.0, FACE_SOUTH, 7.0, green),
		# --- North side of the East Avenue (inn, chapel, alchemist) -----------
		_row_lot("Tavern", "tavern", "building_tavern_red.gltf", 9.8, FACE_SOUTH, 6.6, wood),
		_row_lot("Chapel", "church", "building_church_blue.gltf", 20.4, FACE_SOUTH, 7.4, blue),
		_row_lot("RedCottageEastA", "home_B", "building_home_B_blue.gltf", 28.0, FACE_SOUTH, 6.4, blue),
		# --- South side of the West Avenue (artisans, facing north) -----------
		_row_lot("Blacksmith", "blacksmith", "building_blacksmith_red.gltf", -10.2, FACE_NORTH, 7.0, red),
		_row_lot("CityGranary", "lumbermill", "building_lumbermill_green.gltf", -20.0, FACE_NORTH, 6.0, green),
		_row_lot("ArtisanHouse", "home_B", "building_home_B_yellow.gltf", -28.0, FACE_NORTH, 6.2, yellow),
		# --- South side of the East Avenue (trade and garrison) --------------
		_row_lot("Market", "market", "building_market_red.gltf", 11.2, FACE_NORTH, 6.0, red),
		_row_lot("Barracks", "barracks", "building_barracks_blue.gltf", 21.5, FACE_NORTH, 5.6, blue),
		_row_lot("GateHouseEast", "home_A", "building_home_A_blue.gltf", 29.0, FACE_NORTH, 6.2, blue),
		# --- South Avenue (homes facing the avenue) --------------------------
		_row_lot("SouthHouseWestA", "home_B", "building_home_B_blue.gltf", 19.6, FACE_EAST, 6.4, blue),
		_row_lot("SouthHouseWestB", "home_A", "building_home_A_red.gltf", 27.0, FACE_EAST, 6.6, red),
		_row_lot("SouthHouseEastA", "home_A", "building_home_A_green.gltf", 19.6, FACE_WEST, 6.6, green),
		_row_lot("SouthHouseEastB", "home_B", "building_home_B_red.gltf", 27.2, FACE_WEST, 6.4, red),
		# --- Back yards (reached by the two alleys) --------------------------
		_lot("Windmill", "windmill", "building_windmill_yellow.gltf", -19.5, 20.6, FACE_NORTH, 6.6, yellow),
		_lot("MoonlightStage", "stage", "building_stage_C.gltf", 18.5, 20.8, FACE_NORTH, 6.0, wood),
		_lot("CentralWell", "well", "building_well_green.gltf", -20.5, -17.5, FACE_SOUTH, 4.6, green),
	]
	return _lots

static func lot(node_name: String) -> Dictionary:
	for entry: Dictionary in lots():
		if String(entry["name"]) == node_name:
			return entry
	return {}

## Ground position of a lot centre (used for "sleeping indoors" NPC anchors).
static func lot_center(node_name: String) -> Vector3:
	var entry := lot(node_name)
	if entry.is_empty():
		return PLAZA
	return entry["pos"] as Vector3

## Point on the pavement in front of a lot's door, `out` metres off the facade.
static func lot_front(node_name: String, out: float = 1.0, side: float = 0.0) -> Vector3:
	var entry := lot(node_name)
	if entry.is_empty():
		return PLAZA
	var pos: Vector3 = entry["pos"]
	var yaw: float = entry["yaw"]
	var size: Vector3 = entry["size"]
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	return pos + fwd * (size.z * 0.5 + out) + right * side

# --- Streets --------------------------------------------------------------

## Street rectangles inside the wall: [min_x, min_z, max_x, max_z, kind].
## kind 0 = paved avenue, 1 = packed-earth alley.
static func street_rects() -> Array:
	if not _streets.is_empty():
		return _streets
	var r := WALL_RADIUS + 1.8
	_streets = [
		[-r, -AVENUE_HALF, r, AVENUE_HALF, 0],                       # West-East Avenue
		[-AVENUE_HALF, GUILD_DOOR.z - 1.0, AVENUE_HALF, r, 0],       # Citadel-South Avenue
		[-5.2, GUILD_DOOR.z - 1.0, 5.2, -PLAZA_RADIUS + 1.0, 0],     # Citadel forecourt
		[-27.0, 15.0 - ALLEY_HALF, -AVENUE_HALF, 15.0 + ALLEY_HALF, 1],  # Mill Alley
		[AVENUE_HALF, 15.0 - ALLEY_HALF, 27.0, 15.0 + ALLEY_HALF, 1],    # Garrison Alley
		[-14.3 - ALLEY_HALF, -17.0, -14.3 + ALLEY_HALF, -AVENUE_HALF, 1],  # Garden Lane
		[14.9 - ALLEY_HALF, -17.0, 14.9 + ALLEY_HALF, -AVENUE_HALF, 1],    # Chapel Lane
	]
	return _streets

static func is_street(x: float, z: float) -> bool:
	if x * x + z * z > (WALL_RADIUS + 2.0) * (WALL_RADIUS + 2.0):
		return false
	if x * x + z * z <= PLAZA_RADIUS * PLAZA_RADIUS:
		return true
	for rect: Array in street_rects():
		if x >= float(rect[0]) and x <= float(rect[2]) and z >= float(rect[1]) and z <= float(rect[3]):
			return true
	return false

static func inside_walls(x: float, z: float, margin: float = 0.0) -> bool:
	var r := WALL_RADIUS + margin
	return x * x + z * z <= r * r

## True when (x, z) is inside a building lot grown by `margin` metres.
static func on_lot(x: float, z: float, margin: float = 0.6) -> bool:
	for entry: Dictionary in lots():
		var pos: Vector3 = entry["pos"]
		var half: Vector2 = entry["half"]
		if absf(x - pos.x) <= half.x + margin and absf(z - pos.z) <= half.y + margin:
			return true
	return false

## Garden / yard rectangles: the only places inside the walls where trees,
## flowers and a little grass may grow. [min_x, min_z, max_x, max_z].
static func gardens() -> Array:
	return [
		[-25.0, -20.5, -16.0, -13.5],   # Royal Garden (north-west, around the well)
		[17.0, -21.0, 25.0, -14.5],     # Chapel herb garden (north-east)
		[-17.0, 17.5, -12.5, 28.0],     # Farm plots (south-west)
		[12.5, 25.2, 18.5, 27.5],       # Training yard edge (south-east)
	]

static func in_garden(x: float, z: float) -> bool:
	for g: Array in gardens():
		if x >= float(g[0]) and x <= float(g[2]) and z >= float(g[1]) and z <= float(g[3]):
			return true
	return false

# --- Wall ring ------------------------------------------------------------

static func wall_apothem() -> float:
	return WALL_RADIUS * cos(PI / float(WALL_SEGMENTS))

static func wall_segment_length() -> float:
	return 2.0 * WALL_RADIUS * sin(PI / float(WALL_SEGMENTS))

## World position for a compass bearing (degrees, 0 = north, clockwise).
static func bearing_point(bearing_deg: float, radius: float) -> Vector3:
	var b := deg_to_rad(bearing_deg)
	return Vector3(sin(b) * radius, 0.0, -cos(b) * radius)

static func is_gate_segment(index: int) -> bool:
	var step := 360.0 / float(WALL_SEGMENTS)
	for g: float in GATE_BEARINGS:
		if index == int(round(g / step)):
			return true
	return false

static func gate_position(gate_index: int) -> Vector3:
	return bearing_point(float(GATE_BEARINGS[gate_index]), wall_apothem())

# --- Country roads outside the walls ---------------------------------------

## Distance (m) from (x, z) to the nearest country road centre line, or a
## large number when no road is near. Roads leave the three gates:
## east to the stone bridge and the crypt hills, west into the woods, south
## to Crystal Lake.
static func country_road_distance(x: float, z: float) -> float:
	var best := 999.0
	var r := WALL_RADIUS - 1.0
	if x >= r and x <= 62.0:
		best = minf(best, absf(z - BRIDGE_Z))
	if x <= -r and x >= -56.0:
		best = minf(best, absf(z))
	if z >= r and z <= 47.0:
		var trail_x := (z - WALL_RADIUS) * 0.42 + sin((z - WALL_RADIUS) * 0.45) * 0.9
		best = minf(best, absf(x - trail_x))
	return best

## Which named quarter a point belongs to. Returned keys: "outside", "plaza",
## "citadel", "residential", "chapel", "craft", "market", "south".
static func district_at(x: float, z: float) -> String:
	if not inside_walls(x, z):
		return "outside"
	if Vector2(x - PLAZA.x, z - PLAZA.z).length() < PLAZA_RADIUS + 2.0:
		return "plaza"
	if z < -13.5:
		return "citadel"
	if z >= 14.0:
		return "south"
	if z < 0.0:
		return "residential" if x < 0.0 else "chapel"
	return "craft" if x < 0.0 else "market"
