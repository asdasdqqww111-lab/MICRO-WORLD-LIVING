class_name WorldRoot
extends Node3D
## Builds and owns the world: lighting, village, forest, house interior, dungeon,
## NPCs, creatures and the living-world systems.

var spawn_point: Vector3 = Vector3(0.0, 0.6, 14.0)
var landmarks: Dictionary = {}
var interior: Dictionary = {}
var dungeon: Dictionary = {}
var forest_spawns: Array = []

var terrain: StaticBody3D
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var clouds: CloudLayer
var world_environment: WorldEnvironment
var environment: Environment
var day_night: DayNightCycle
var weather: WeatherSystem
var raid: RaidEvent

var _creatures: Dictionary = {}     # uid -> Creature
var _npcs: Dictionary = {}          # npc_id -> VillageNPC

func _ready() -> void:
	add_to_group("world_root")
	_build_environment()
	_build_world()
	_build_systems()
	_spawn_population()
	_apply_graphics()

func _build_environment() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	# Semi-realistic stylized sky: deeper zenith, soft horizon haze, warm sun.
	sky_material.sky_top_color = Color(0.22, 0.42, 0.76)
	sky_material.sky_horizon_color = Color(0.66, 0.77, 0.88)
	sky_material.sky_curve = 0.12
	sky_material.ground_horizon_color = Color(0.42, 0.46, 0.44)
	sky_material.ground_bottom_color = Color(0.2, 0.22, 0.21)
	sky_material.ground_curve = 0.05
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.1
	sky_material.sky_energy_multiplier = 1.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 1.0
	environment.ambient_light_energy = 0.9
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	# Gentle grade so the world is not washed-out; keeps mobile cost at zero.
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.05
	environment.adjustment_saturation = 1.08
	environment.adjustment_brightness = 1.0
	environment.fog_enabled = true
	environment.fog_density = 0.0045
	environment.fog_light_color = Color(0.62, 0.7, 0.8)
	environment.fog_sky_affect = 0.3
	environment.fog_aerial_perspective = 0.35
	world_environment.environment = environment
	add_child(world_environment)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 44.0
	sun.shadow_bias = 0.04
	sun.light_energy = 1.05
	sun.light_color = Color(1.0, 0.96, 0.88)
	add_child(sun)

	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.shadow_enabled = false
	moon.light_energy = 0.0
	moon.light_color = Color(0.62, 0.72, 1.0)
	add_child(moon)

	clouds = CloudLayer.new()
	clouds.name = "CloudLayer"
	add_child(clouds)

func _build_world() -> void:
	# Terrain replaces the old flat plane (village + forest stay flat at y=0 so
	# every authored position/collider remains valid).
	terrain = Terrain.build(self, WorldBuilder.GROUND_SIZE)
	landmarks = WorldBuilder.build_village(self)
	interior = WorldBuilder.build_house_interior(self)
	dungeon = WorldBuilder.build_dungeon(self)
	forest_spawns = WorldBuilder.build_forest(self)
	spawn_point = landmarks.get("spawn", spawn_point) as Vector3
	_build_zone_doors()
	_optimize_static_props()

## Measured problem: 189 of 193 meshes were casting shadows, which roughly
## doubles draw calls (shadow pass). Small props (< 2.5 m) contribute detail but
## almost no meaningful shadow, so they are excluded from the shadow pass and
## given a visibility range instead. Big shapes (buildings, trees, rocks) keep
## their shadows so the world still reads as lit.
func _optimize_static_props() -> void:
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		if mi.is_in_group("player") or mi.is_in_group("creature"):
			continue
		if _is_animated_branch(mi):
			# Keep the silhouette's shadow, drop the tiny attached bits
			# (eyes, weapons, straps) which cost a shadow draw call each.
			if mi.get_aabb().size.length() < 1.4:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			continue
		var aabb := mi.get_aabb()
		var size := aabb.size.length()
		if size < 3.2:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if size < 2.2:
			mi.visibility_range_end = 70.0
			mi.visibility_range_end_margin = 10.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

func _is_animated_branch(node: Node) -> bool:
	var current := node
	while current != null and current != self:
		if current is Skeleton3D or current is AnimationPlayer or current is AnimationTree:
			return true
		current = current.get_parent()
	return false

func _build_zone_doors() -> void:
	# Village <-> house
	var house_door := ZoneDoor.new()
	house_door.name = "HouseDoor"
	house_door.setup(interior.get("spawn", Vector3.ZERO) as Vector3, "house", "Enter the house")
	house_door.transition_text = "You step inside"
	add_child(house_door)
	house_door.global_position = landmarks.get("house_door", Vector3.ZERO) as Vector3
	_add_beacon(house_door, Color(0.9, 0.8, 0.4))

	var house_exit := ZoneDoor.new()
	house_exit.name = "HouseExit"
	house_exit.setup(Vector3(-16.0, 0.6, -1.2), "village", "Leave the house")
	house_exit.transition_text = "Back outside"
	add_child(house_exit)
	house_exit.global_position = interior.get("exit", Vector3.ZERO) as Vector3
	_add_beacon(house_exit, Color(0.9, 0.8, 0.4))

	# Village <-> dungeon
	var dungeon_door := ZoneDoor.new()
	dungeon_door.name = "DungeonDoor"
	dungeon_door.setup(dungeon.get("spawn", Vector3.ZERO) as Vector3, "dungeon", "Descend into the cellar")
	dungeon_door.transition_text = "The air turns cold"
	add_child(dungeon_door)
	dungeon_door.global_position = landmarks.get("dungeon_entrance", Vector3.ZERO) as Vector3
	_add_beacon(dungeon_door, Color(0.5, 0.7, 0.95))

	var dungeon_exit := ZoneDoor.new()
	dungeon_exit.name = "DungeonExit"
	dungeon_exit.setup(Vector3(38.0, 0.6, 31.0), "village", "Climb back to the village")
	dungeon_exit.transition_text = "Daylight again"
	add_child(dungeon_exit)
	dungeon_exit.global_position = dungeon.get("exit", Vector3.ZERO) as Vector3
	_add_beacon(dungeon_exit, Color(0.5, 0.7, 0.95))

func _add_beacon(parent: Node3D, color: Color) -> void:
	var marker := MeshInstance3D.new()
	marker.name = "Beacon"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.18
	cylinder.bottom_radius = 0.18
	cylinder.height = 1.1
	marker.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.7
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	marker.material_override = mat
	marker.position = Vector3(0.0, 1.0, 0.0)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(marker)

func _build_systems() -> void:
	day_night = DayNightCycle.new()
	day_night.name = "DayNightCycle"
	add_child(day_night)
	day_night.setup(sun, environment)

	weather = WeatherSystem.new()
	weather.name = "WeatherSystem"
	add_child(weather)
	weather.setup(self, day_night)

	raid = RaidEvent.new()
	raid.name = "RaidEvent"
	add_child(raid)
	raid.setup(self)

	EventBus.graphics_settings_changed.connect(_apply_graphics)

func _apply_graphics() -> void:
	if sun == null:
		return
	var quality := SettingsManager.shadow_quality()
	sun.shadow_enabled = SettingsManager.graphics_preset != SettingsManager.GraphicsPreset.LOW
	sun.directional_shadow_max_distance = 45.0 if SettingsManager.graphics_preset == SettingsManager.GraphicsPreset.LOW else 70.0
	RenderingServer.directional_soft_shadow_filter_set_quality(quality)
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.fog_enabled = SettingsManager.graphics_preset != SettingsManager.GraphicsPreset.LOW

# --- population --------------------------------------------------------------

func _spawn_population() -> void:
	_spawn_npcs()
	# Forest population (quest targets + wildlife).
	for i: int in 3:
		if forest_spawns.size() > i:
			spawn_creature("skeleton_forest", "forest_skeleton_%d" % i, forest_spawns[i] as Vector3)
	if forest_spawns.size() > 3:
		spawn_creature("wolf", "forest_wolf_0", forest_spawns[3] as Vector3)
	if forest_spawns.size() > 4:
		spawn_creature("slime", "forest_slime_0", forest_spawns[4] as Vector3)
	# Dungeon population.
	var dungeon_spawns: Array = dungeon.get("enemy_spawns", [])
	for i: int in dungeon_spawns.size():
		spawn_creature("skeleton_dungeon", "dungeon_skeleton_%d" % i, dungeon_spawns[i] as Vector3)

	var chest := TreasureChest.new()
	chest.name = "DungeonChest"
	chest.setup("dungeon_chest_0", [
		{"id": "ancient_relic", "count": 1},
		{"id": "health_potion", "count": 1},
		{"id": "bone", "count": 2},
	])
	add_child(chest)
	chest.global_position = dungeon.get("chest", Vector3.ZERO) as Vector3

func _spawn_npcs() -> void:
	var blacksmith := _make_npc("blacksmith", "Grim the Smith", "blacksmith",
		AssetLibrary.CHARACTER_DIR + "Skeleton_Warrior.glb",
		{
			"work": landmarks.get("blacksmith_pos", Vector3(-15.0, 0.0, 10.5)) as Vector3,
			"rest": Vector3(-14.0, 0.0, 12.5),
			"sleep": landmarks.get("blacksmith_sleep", Vector3(-19.0, 0.0, 8.0)) as Vector3,
		},
		["Steel needs ore. Bring me iron and I will pay good coin.",
		 "Careful in the western woods. The bones walk there after dark."])
	var farmer := _make_npc("farmer", "Mira the Farmer", "farmer",
		AssetLibrary.CHARACTER_DIR + "Skeleton_Rogue.glb",
		{
			"work": landmarks.get("farmer_pos", Vector3(9.0, 0.0, 14.0)) as Vector3,
			"rest": landmarks.get("farmer_rest", Vector3(9.0, 0.0, 14.0)) as Vector3,
			"sleep": landmarks.get("farmer_sleep", Vector3(-16.0, 0.0, -4.0)) as Vector3,
		},
		["Three of them came out of the trees last night. Three!",
		 "My flock is scattered and my barn door is splinters."])
	var guard := _make_npc("guard", "Osk the Guard", "guard",
		AssetLibrary.CHARACTER_DIR + "Skeleton_Mage.glb",
		{
			"work": landmarks.get("guard_pos", Vector3(24.0, 0.0, 8.0)) as Vector3,
			"rest": Vector3(22.0, 0.0, 10.0),
			"sleep": landmarks.get("guard_sleep", Vector3(28.0, 0.0, 8.0)) as Vector3,
		},
		["The old cellar east of the village broke open in the storm.",
		 "Something down there is still moving. And it took my relic."])
	blacksmith.visual.tint(Color(1.0, 0.94, 0.88))
	farmer.visual.tint(Color(0.92, 1.0, 0.9))
	guard.visual.tint(Color(0.9, 0.95, 1.0))

func _make_npc(npc_id: String, display_name: String, role: String, model_path: String,
		schedule: Dictionary, lines: Array) -> VillageNPC:
	var npc := VillageNPC.new()
	npc.name = "NPC_" + npc_id
	npc.setup(npc_id, display_name, role, model_path, schedule)
	npc.dialog_lines = lines
	add_child(npc)
	npc.global_position = schedule.get("work", Vector3.ZERO) as Vector3
	_npcs[npc_id] = npc
	return npc

func npc_by_id(npc_id: String) -> VillageNPC:
	return _npcs.get(npc_id, null) as VillageNPC

# --- runtime API -------------------------------------------------------------

func spawn_creature(creature_id: String, uid: String, position: Vector3) -> Node:
	var data := CreatureDB.get_creature(creature_id)
	if data == null:
		push_warning("WorldRoot: unknown creature '%s'" % creature_id)
		return null
	if _creatures.has(uid):
		return _creatures[uid] as Node
	if GameManager.world.is_dead(uid):
		return null
	var creature := Creature.new()
	creature.name = "Creature_" + uid
	creature.setup(data, uid, position)
	add_child(creature)
	creature.global_position = position
	_creatures[uid] = creature
	creature.tree_exited.connect(func() -> void: _creatures.erase(uid))
	return creature

func spawn_loot_drop(items: Array, position: Vector3) -> LootDrop:
	var drop := LootDrop.new()
	drop.setup(items)
	add_child(drop)
	drop.global_position = position
	return drop

func creature_count() -> int:
	return _creatures.size()

func alive_creatures() -> Array:
	var out: Array = []
	for creature: Creature in _creatures.values():
		if is_instance_valid(creature) and not creature.health.is_dead():
			out.append(creature)
	return out

func find_npc(npc_id: String) -> VillageNPC:
	return npc_by_id(npc_id)

func player_spawn_point() -> Vector3:
	var zone := GameManager.pending_zone
	match zone:
		"house":
			return interior.get("spawn", spawn_point) as Vector3
		"dungeon":
			return dungeon.get("spawn", spawn_point) as Vector3
		_:
			return spawn_point
