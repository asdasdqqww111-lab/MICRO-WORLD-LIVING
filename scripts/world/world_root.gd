class_name WorldRoot
extends Node3D
## Builds and owns the Eldoria Open World:
##   - Sky, Directional Sun/Moon, Drifting Clouds & Scalable Weather
##   - Overworld Container (Terrain, Village, Water, 6 Forests, Landmarks, Resource Nodes)
##   - Zone Containers (Cottage Interior, Adventurers Guild Hall, Sunken Crypt Dungeon)
##     with automatic Active-Zone Visibility Culling for peak mobile GLES3 FPS
##   - 18 Living Human NPCs (12 Village Roles + 6 Guild Roles)
##   - Passive Wildlife, Biome Monsters, Elites & Multi-Phase Dungeon Boss

var spawn_point: Vector3 = Vector3(0.0, 0.6, 14.0)
var landmarks: Dictionary = {}
var interior: Dictionary = {}
var guild_interior: Dictionary = {}
var dungeon: Dictionary = {}
var forest_spawns: Array = []

var terrain: Terrain
var overworld_root: Node3D
var house_root: Node3D
var guild_root: Node3D
var dungeon_root: Node3D

var sun: DirectionalLight3D
var moon: DirectionalLight3D
var clouds: CloudLayer
var world_environment: WorldEnvironment
var environment: Environment
var day_night: DayNightCycle
var weather: WeatherSystem
var raid: RaidEvent
var quest_waypoint: QuestWaypoint3D

var _creatures: Dictionary = {}     # uid -> Creature
var _npcs: Dictionary = {}          # npc_id -> VillageNPC

func _ready() -> void:
	add_to_group("world_root")
	_build_environment()
	_build_world()
	_build_systems()
	_spawn_population()
	quest_waypoint = QuestWaypoint3D.new()
	quest_waypoint.name = "QuestWaypoint3D"
	quest_waypoint.setup(self)
	add_child(quest_waypoint)
	_optimize_static_props()
	call_deferred("_optimize_static_props")
	_apply_graphics()
	EventBus.zone_entered.connect(_on_zone_entered)
	_apply_zone_visibility(GameManager.pending_zone if not GameManager.pending_zone.is_empty() else "village")
	if AudioManager != null:
		AudioManager.play_music_for_zone("village")

func _build_environment() -> void:
	# Reuse scene-level WorldEnvironment / DirectionalLight3D from game.tscn if present,
	# or construct identically when WorldRoot is instantiated standalone.
	var p := get_parent()
	if p != null and p.has_node("WorldEnvironment"):
		world_environment = p.get_node("WorldEnvironment") as WorldEnvironment
	else:
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnvironment"
		add_child(world_environment)

	environment = world_environment.environment if world_environment.environment != null else Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := environment.sky if environment.sky != null else Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	var hdri_path := "res://assets/stylized_nature/stylized_meadow_sky_1k.hdr"
	var pano := sky.sky_material as PanoramaSkyMaterial
	if pano == null:
		pano = PanoramaSkyMaterial.new()
	if ResourceLoader.exists(hdri_path):
		pano.panorama = ResourceLoader.load(hdri_path) as Texture2D
	pano.energy_multiplier = 1.04
	sky.sky_material = pano
	environment.sky = sky

	var vp := get_viewport()
	if vp != null:
		vp.msaa_3d = Viewport.MSAA_4X
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	# Phase 1 Stylized/Chibi PBR Mobile Lighting:
	# ACES Tonemap (1.1), Softlight Glow (0.4 / 0.1), Depth Fog (30..150m), Low-Res SSAO (1.0 / 1.5)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.88
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.1
	environment.tonemap_white = 6.0

	environment.glow_enabled = true
	environment.glow_intensity = 0.4
	environment.glow_strength = 0.88
	environment.glow_bloom = 0.1
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	environment.glow_hdr_threshold = 1.0

	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = Color(0.6, 0.75, 0.9)
	environment.fog_sun_scatter = 0.30
	environment.fog_density = 0.0025
	environment.fog_aerial_perspective = 0.52
	environment.fog_sky_affect = 0.20
	environment.fog_depth_curve = 1.35
	environment.fog_depth_begin = 30.0
	environment.fog_depth_end = 150.0

	environment.ssao_enabled = true
	environment.ssao_radius = 1.0
	environment.ssao_intensity = 1.5
	environment.ssao_power = 1.5
	environment.ssao_detail = 0.25
	RenderingServer.environment_set_ssao_quality(
		RenderingServer.ENV_SSAO_QUALITY_VERY_LOW, true, 0.5, 1, 25.0, 45.0
	)

	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.06
	environment.adjustment_saturation = 1.12
	world_environment.environment = environment

	if p != null and p.has_node("DirectionalLight3D"):
		sun = p.get_node("DirectionalLight3D") as DirectionalLight3D
	else:
		sun = DirectionalLight3D.new()
		sun.name = "Sun"
		add_child(sun)
	sun.rotation_degrees = Vector3(-35.0, -45.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.20
	sun.shadow_blur = 2.0
	sun.light_energy = 1.24
	sun.light_color = Color(1.0, 0.95, 0.85)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)

	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.shadow_enabled = false
	moon.light_energy = 0.0
	moon.light_color = Color(0.62, 0.72, 1.0)
	add_child(moon)

	# HDRI Panorama provides photographic clouds at 0 draw calls; keep CloudLayer hidden for API compatibility
	clouds = CloudLayer.new()
	clouds.name = "CloudLayer"
	clouds.visible = false
	add_child(clouds)

func _build_world() -> void:
	overworld_root = Node3D.new()
	overworld_root.name = "OverworldZone"
	add_child(overworld_root)

	house_root = Node3D.new()
	house_root.name = "HouseZone"
	add_child(house_root)

	guild_root = Node3D.new()
	guild_root.name = "GuildZone"
	add_child(guild_root)

	dungeon_root = Node3D.new()
	dungeon_root.name = "DungeonZone"
	add_child(dungeon_root)

	terrain = Terrain.build(overworld_root, WorldBuilder.GROUND_SIZE)
	landmarks = WorldBuilder.build_village(overworld_root, terrain)
	forest_spawns = WorldBuilder.build_forest(overworld_root, terrain)
	_spawn_resource_nodes()

	interior = WorldBuilder.build_house_interior(house_root)
	guild_interior = WorldBuilder.build_guild_interior(guild_root)
	dungeon = WorldBuilder.build_dungeon(dungeon_root)

	spawn_point = landmarks.get("spawn", spawn_point) as Vector3
	_build_zone_doors()

func _on_zone_entered(zone_id: String) -> void:
	_apply_zone_visibility(zone_id)
	if AudioManager != null:
		AudioManager.play_music_for_zone(zone_id)
	if zone_id != "dungeon":
		EventBus.boss_health_changed.emit("", 0.0, 100.0, 1, false)

func _apply_zone_visibility(zone_id: String) -> void:
	var in_overworld := (zone_id == "" or zone_id == "village")
	if overworld_root != null:
		overworld_root.visible = in_overworld
	if clouds != null:
		clouds.visible = false
	if sun != null:
		sun.visible = in_overworld
		sun.shadow_enabled = in_overworld and SettingsManager.graphics_preset != SettingsManager.GraphicsPreset.LOW
	if moon != null:
		moon.visible = in_overworld
	if environment != null:
		if zone_id == "dungeon":
			environment.background_mode = Environment.BG_COLOR
			environment.background_color = Color(0.05, 0.05, 0.08)
			environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			environment.ambient_light_color = Color(0.24, 0.22, 0.30)
			environment.ambient_light_energy = 0.78
			environment.fog_enabled = false
		elif not in_overworld:
			environment.background_mode = Environment.BG_COLOR
			environment.background_color = Color(0.10, 0.11, 0.15)
			environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			environment.ambient_light_color = Color(0.76, 0.74, 0.72)
			environment.ambient_light_energy = 0.72
			environment.fog_enabled = false
		else:
			environment.background_mode = Environment.BG_SKY
			environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			environment.ambient_light_energy = 0.56
			environment.fog_enabled = SettingsManager.graphics_preset != SettingsManager.GraphicsPreset.LOW
	if house_root != null:
		house_root.visible = (zone_id == "house")
	if guild_root != null:
		guild_root.visible = (zone_id == "guild")
	if dungeon_root != null:
		dungeon_root.visible = (zone_id == "dungeon")

func _optimize_static_props() -> void:
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		if node is MultiMeshInstance3D:
			var mmi := node as MultiMeshInstance3D
			var mname := String(mmi.name)
			if mname != "ForestOaks" and mname != "StylizedPines":
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			continue
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		if _is_player_branch(mi):
			continue
		if _is_animated_branch(mi):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_end = 26.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			continue
		if mi.name == "TerrainMesh" or mi.name == "RiverMesh" or mi.name == "LakeMesh":
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			continue
		var aabb := mi.get_aabb()
		var sz := aabb.size.length() * mi.global_transform.basis.get_scale().x
		if sz < 13.5:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if sz < 5.5:
			mi.visibility_range_end = 36.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		elif sz < 22.0:
			mi.visibility_range_end = 58.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

func _is_player_branch(node: Node) -> bool:
	var current := node
	while current != null and current != self:
		if current is Player or current is QuestWaypoint3D:
			return true
		current = current.get_parent()
	return false

func _is_animated_branch(node: Node) -> bool:
	var current := node
	while current != null and current != self:
		if current is Player:
			return false
		if current is VillageNPC or current is Creature or current is CharacterVisual:
			return true
		if current is ResourceNode or current is TreasureChest or current is CraftingStation or current is QuestBoardProp:
			return true
		if current is Skeleton3D or current is AnimationPlayer or current is AnimationTree:
			return true
		current = current.get_parent()
	return false

func _build_zone_doors() -> void:
	# 1. Village <-> Player Cottage
	var house_door := ZoneDoor.new()
	house_door.name = "HouseDoor"
	house_door.setup(interior.get("spawn", Vector3.ZERO) as Vector3, "house", "Enter Your Cottage")
	house_door.transition_text = "You step inside your cottage"
	overworld_root.add_child(house_door)
	house_door.global_position = landmarks.get("house_door", Vector3.ZERO) as Vector3
	_add_beacon(house_door, Color(0.95, 0.82, 0.42))

	var house_exit := ZoneDoor.new()
	house_exit.name = "HouseExit"
	house_exit.setup(Vector3(-16.0, 0.6, -1.2), "village", "Step Outside to Eldoria")
	house_exit.transition_text = "Back in Eldoria Square"
	house_root.add_child(house_exit)
	house_exit.global_position = interior.get("exit", Vector3.ZERO) as Vector3
	_add_beacon(house_exit, Color(0.95, 0.82, 0.42))

	# 2. Village <-> Grand Adventurers Guild Hall
	var guild_door := ZoneDoor.new()
	guild_door.name = "GuildDoor"
	guild_door.setup(guild_interior.get("spawn", Vector3.ZERO) as Vector3, "guild", "Enter Adventurers Guild Hall")
	guild_door.transition_text = "Welcome to the Eldoria Adventurers Guild"
	overworld_root.add_child(guild_door)
	guild_door.global_position = landmarks.get("guild_door", Vector3(0.0, 0.0, -18.4)) as Vector3
	_add_beacon(guild_door, Color(0.38, 0.72, 1.0))

	var guild_exit := ZoneDoor.new()
	guild_exit.name = "GuildExit"
	guild_exit.setup(Vector3(0.0, 0.6, -16.8), "village", "Exit to Eldoria Square")
	guild_exit.transition_text = "Stepping out onto Eldoria Square"
	guild_root.add_child(guild_exit)
	guild_exit.global_position = guild_interior.get("exit", Vector3.ZERO) as Vector3
	_add_beacon(guild_exit, Color(0.38, 0.72, 1.0))

	# 3. Overworld <-> Sunken Crypt Dungeon
	var dungeon_ent := landmarks.get("dungeon_entrance", Vector3(52.0, 0.2, 26.8)) as Vector3
	var dungeon_door := ZoneDoor.new()
	dungeon_door.name = "DungeonDoor"
	dungeon_door.setup(dungeon.get("spawn", Vector3.ZERO) as Vector3, "dungeon", "Descend into the Sunken Crypt")
	dungeon_door.transition_text = "Cold ancient air rises from the Sunken Crypt..."
	overworld_root.add_child(dungeon_door)
	dungeon_door.global_position = dungeon_ent
	_add_beacon(dungeon_door, Color(0.55, 0.72, 0.98))

	var dungeon_exit := ZoneDoor.new()
	dungeon_exit.name = "DungeonExit"
	dungeon_exit.setup(dungeon_ent + Vector3(0.0, 0.6, 2.2), "village", "Ascend to Daylight")
	dungeon_exit.transition_text = "Fresh Eldoria air greets you"
	dungeon_root.add_child(dungeon_exit)
	dungeon_exit.global_position = dungeon.get("exit", Vector3.ZERO) as Vector3
	_add_beacon(dungeon_exit, Color(0.55, 0.72, 0.98))

func _add_beacon(parent: Node3D, color: Color) -> void:
	var marker := MeshInstance3D.new()
	marker.name = "Beacon"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.18
	cylinder.bottom_radius = 0.18
	cylinder.height = 1.05
	marker.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.82)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.75
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override = mat
	marker.position = Vector3(0.0, 0.95, 0.0)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(marker)

func _build_systems() -> void:
	day_night = DayNightCycle.new()
	day_night.name = "DayNightCycle"
	add_child(day_night)
	day_night.setup(sun, environment, moon, clouds)

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
	var in_overworld := overworld_root == null or overworld_root.visible
	sun.shadow_enabled = in_overworld and SettingsManager.graphics_preset != SettingsManager.GraphicsPreset.LOW
	sun.directional_shadow_max_distance = 40.0 if SettingsManager.graphics_preset == SettingsManager.GraphicsPreset.LOW else 60.0
	sun.shadow_blur = 2.0
	RenderingServer.directional_soft_shadow_filter_set_quality(quality)
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.fog_enabled = SettingsManager.graphics_preset != SettingsManager.GraphicsPreset.LOW

# --- Gathering Nodes, Chests, Living NPCs & Creature Ecosystems --------------

func _spawn_resource_nodes() -> void:
	var defs := [
		# Iron Ore Veins (Eastern Crags & Northern Cave)
		{"uid": "ore_east_1", "kind": "ore", "item": "iron_ore", "label": "Highland Iron Vein", "x": 54.0, "z": -10.0},
		{"uid": "ore_east_2", "kind": "ore", "item": "iron_ore", "label": "Highland Iron Vein", "x": 61.0, "z": -6.0},
		{"uid": "ore_cave_1", "kind": "ore", "item": "iron_ore", "label": "Cave Iron Vein", "x": -10.0, "z": -56.0},
		{"uid": "ore_north_1", "kind": "ore", "item": "iron_ore", "label": "Alpine Iron Vein", "x": 8.0, "z": -48.0},
		# Timber Logs (Western Forest Edge & South Timberline)
		{"uid": "wood_west_1", "kind": "wood", "item": "wood", "label": "Seasoned Oak Log", "x": -44.0, "z": 6.0},
		{"uid": "wood_west_2", "kind": "wood", "item": "wood", "label": "Fallen Timber", "x": -49.0, "z": -10.0},
		{"uid": "wood_south_1", "kind": "wood", "item": "wood", "label": "Lakeside Timber", "x": -22.0, "z": 46.0},
		# Redcap Herbs (Western Woodland & Meadow)
		{"uid": "herb_red_1", "kind": "herb", "item": "herb_redcap", "label": "Redcap Mushroom Patch", "x": -43.0, "z": -2.0},
		{"uid": "herb_red_2", "kind": "herb", "item": "herb_redcap", "label": "Redcap Mushroom Patch", "x": -50.0, "z": 14.0},
		{"uid": "herb_red_3", "kind": "herb", "item": "herb_redcap", "label": "Redcap Mushroom Patch", "x": -36.0, "z": 30.0},
		# Moonpetal Blooms (Crystal Lake Shore & Sacred Grove)
		{"uid": "moon_lake_1", "kind": "moonpetal", "item": "herb_moonpetal", "label": "Moonpetal Bloom", "x": 4.0, "z": 49.0},
		{"uid": "moon_lake_2", "kind": "moonpetal", "item": "herb_moonpetal", "label": "Moonpetal Bloom", "x": 28.0, "z": 46.0},
		{"uid": "moon_grove_1", "kind": "moonpetal", "item": "herb_moonpetal", "label": "Sacred Moonpetal", "x": -53.0, "z": 41.0},
	]
	for d: Dictionary in defs:
		var rn := ResourceNode.new()
		rn.name = "Res_" + String(d["uid"])
		rn.setup(String(d["uid"]), String(d["kind"]), String(d["item"]), String(d["label"]), 2)
		overworld_root.add_child(rn)
		var rx := float(d["x"])
		var rz := float(d["z"])
		rn.global_position = Vector3(rx, terrain.height_at(rx, rz), rz)

func _spawn_population() -> void:
	_spawn_npcs()

	# 1. Western Forest Skeletons & Bramble Stalkers (preserves skeleton_menace quest + contract_forest_cull!)
	for i: int in 3:
		if forest_spawns.size() > i:
			spawn_creature("skeleton_forest", "forest_skeleton_%d" % i, forest_spawns[i] as Vector3, overworld_root)
	spawn_creature("forest_goblin", "forest_goblin_0", _pos_on_terrain(-46.0, -14.0), overworld_root)
	spawn_creature("forest_goblin", "forest_goblin_1", _pos_on_terrain(-58.0, -30.0), overworld_root)
	spawn_creature("forest_goblin", "forest_goblin_2", _pos_on_terrain(-52.0, 22.0), overworld_root)
	spawn_creature("wolf", "forest_wolf_0", _pos_on_terrain(-44.0, -34.0), overworld_root)
	spawn_creature("wolf", "forest_wolf_1", _pos_on_terrain(-54.0, -16.0), overworld_root)
	spawn_creature("wolf", "forest_wolf_2", _pos_on_terrain(-32.0, -46.0), overworld_root)
	spawn_creature("slime", "lake_slime_0", _pos_on_terrain(2.0, 52.0), overworld_root)
	spawn_creature("slime", "lake_slime_1", _pos_on_terrain(26.0, 56.0), overworld_root)

	# 2. Passive Grazing Wildlife (Highland Stags in Southern Meadows & Lakeside)
	spawn_creature("meadow_stag", "stag_meadow_0", _pos_on_terrain(-18.0, 45.0), overworld_root)
	spawn_creature("meadow_stag", "stag_lake_1", _pos_on_terrain(30.0, 43.0), overworld_root)

	# 3. Northern Cave Shadowfang Bats & Eastern Crag Granite Golem
	spawn_creature("cave_bat", "cave_bat_0", _pos_on_terrain(-16.0, -56.0), overworld_root)
	spawn_creature("cave_bat", "cave_bat_1", _pos_on_terrain(-11.0, -58.0), overworld_root)
	spawn_creature("cave_bat", "cave_bat_2", _pos_on_terrain(-6.0, -61.0), overworld_root)
	spawn_creature("rock_golem", "east_golem_0", _pos_on_terrain(58.0, -2.0), overworld_root)
	spawn_creature("rock_golem", "east_golem_1", _pos_on_terrain(68.0, 6.0), overworld_root)

	# 4. Overworld Elites: Ruins Wraith & Sacred Grove Warden!
	spawn_creature("wraith_elite", "ruins_wraith_0", _pos_on_terrain(64.0, -18.0), overworld_root)
	spawn_creature("grove_guardian", "grove_warden_0", _pos_on_terrain(-54.0, 46.0), overworld_root)

	# 5. Overworld Treasure Chests (Sacred Grove, Ancient Ruins, Monster Camp, Royal Citadel Vault)
	_place_chest(overworld_root, "SacredGroveChest", "grove_chest_0",
		(landmarks.get("sacred_grove", Vector3(-56, 2, 44)) as Vector3) + Vector3(2.2, 0.0, -1.6),
		[{"id": "oak_shield", "count": 1}, {"id": "mana_elixir", "count": 2}])
	_place_chest(overworld_root, "RuinsChest", "ruins_chest_0",
		(landmarks.get("ruins", Vector3(66, 4, -18)) as Vector3) + Vector3(-2.0, 0.0, -1.5),
		[{"id": "iron_ingot", "count": 2}, {"id": "health_potion", "count": 2}])
	_place_chest(overworld_root, "CampChest", "camp_chest_0",
		(landmarks.get("monster_camp", Vector3(-62, 2, -24)) as Vector3) + Vector3(-1.8, 0.0, -2.2),
		[{"id": "iron_ore", "count": 3}, {"id": "venison", "count": 2}])
	_place_chest(overworld_root, "CitadelGardenChest", "citadel_chest_0",
		Vector3(-22.5, 0.0, -26.5),
		[{"id": "health_potion", "count": 2}, {"id": "bread", "count": 3}])

	# 6. Sunken Crypt Dungeon: Guards, Secret Chest, Relic Chest & Boss Malakor!
	var dungeon_spawns: Array = dungeon.get("enemy_spawns", [])
	for i: int in dungeon_spawns.size():
		spawn_creature("skeleton_dungeon", "dungeon_skeleton_%d" % i, dungeon_spawns[i] as Vector3, dungeon_root)
	if dungeon.has("boss_spawn"):
		spawn_creature("crypt_boss", "malakor_crypt_boss", dungeon["boss_spawn"] as Vector3, dungeon_root)

	_place_chest(dungeon_root, "DungeonChest", "dungeon_chest_0",
		dungeon.get("chest", Vector3.ZERO) as Vector3,
		[{"id": "ancient_relic", "count": 1}, {"id": "health_potion", "count": 2}, {"id": "bone", "count": 3}])
	if dungeon.has("secret_chest"):
		_place_chest(dungeon_root, "SecretCryptChest", "dungeon_secret_chest_0",
			dungeon["secret_chest"] as Vector3,
			[{"id": "knight_plate", "count": 1}, {"id": "mana_elixir", "count": 2}])

func _place_chest(parent: Node3D, node_name: String, uid: String, pos: Vector3, contents: Array) -> void:
	var chest := TreasureChest.new()
	chest.name = node_name
	chest.setup(uid, contents)
	parent.add_child(chest)
	chest.global_position = pos

func _pos_on_terrain(x: float, z: float) -> Vector3:
	var y := terrain.height_at(x, z) if terrain != null else 0.0
	return Vector3(x, y + 0.35, z)

func _spawn_npcs() -> void:
	var k_knight := "res://assets/kaykit_adventurers/Knight.glb"
	var k_barb := "res://assets/characters/npcs/Barbarian.glb"
	var k_mage := "res://assets/characters/npcs/Mage.glb"
	var k_rogue := "res://assets/characters/npcs/Rogue.glb"
	var k_hood := "res://assets/characters/npcs/Rogue_Hooded.glb"

	# --- LIVING VILLAGE NPCS (Stylized KayKit Chibi Cast!) ---
	# 1. Blacksmith (Grim — preserved id "blacksmith")
	var smith := _make_npc(overworld_root, "blacksmith", "Grim", "blacksmith", "Master Blacksmith",
		k_barb,
		{"work": landmarks["blacksmith_pos"], "rest": Vector3(-11.0, 0.0, -14.0), "sleep": landmarks["blacksmith_sleep"]},
		["My anvil rings from dawn till dusk. Bring highland ore or use my forge!",
		 "A good shield and tempered blade will save your life in the Sunken Crypt."],
		["axe"])
	smith.service_type = "forge"
	smith.has_shop = true

	# 2. Farmer (Mira — preserved id "farmer")
	var farmer := _make_npc(overworld_root, "farmer", "Mira", "farmer", "Windmill Farmer",
		k_rogue,
		{"work": landmarks["farmer_pos"], "rest": landmarks["farmer_rest"], "sleep": landmarks["farmer_sleep"]},
		["Skeletons crept out of the western woods again last night!",
		 "Our golden wheat feeds all of Eldoria — help us keep the roads safe."],
		[])
	farmer.patrol_points = [Vector3(-12.0, 0.0, 18.0), Vector3(-15.5, 0.0, 22.0), Vector3(-9.5, 0.0, 21.0)]

	# 3. East Gate Guard (Osk — preserved id "guard")
	var guard := _make_npc(overworld_root, "guard", "Osk", "guard", "Captain of the Watch",
		k_knight,
		{"work": landmarks["guard_pos"], "rest": Vector3(20.0, 0.0, 6.0), "sleep": landmarks["guard_sleep"]},
		["Beyond the stone bridge lies the Sunken Crypt and the Ancient Ruins.",
		 "My patrol lost an Ancient Relic down in those vaults — recover it if you dare."],
		["1h_sword", "rectangle_shield", "helmet"])
	guard.always_awake = true
	guard.patrol_points = [Vector3(24.0, 0.0, 8.0), Vector3(25.0, 0.0, -3.5), Vector3(18.0, 0.0, 2.0)]

	# 4. Village Elder (Elder Theron — Main Quest giver!)
	_make_npc(overworld_root, "elder", "Elder Theron", "elder", "Village Elder",
		k_mage,
		{"work": Vector3(-4.6, 0.0, -15.5), "rest": Vector3(-8.0, 0.0, -15.0), "sleep": Vector3(15.0, 0.0, -16.5)},
		["Welcome to Eldoria, young traveler. Dark tremors stir beneath the eastern hills.",
		 "Visit the Grand Adventurers Guild to the north and register your name."],
		["staff", "hat"])

	# 5. Merchant (Tariq — Market Trader)
	var merch := _make_npc(overworld_root, "merchant", "Tariq", "merchant", "Caravan Merchant",
		k_rogue,
		{"work": Vector3(14.5, 0.0, 7.8), "rest": Vector3(-10.0, 0.0, -15.5), "sleep": Vector3(16.5, 0.0, -16.5)},
		["Finest potions, elixirs, and trail rations in the valley! Guild members earn a discount.",
		 "Prices shift slightly with each passing day's caravan."],
		[])
	merch.has_shop = true

	# 6. Chapel Healer (Sister Sera)
	var healer := _make_npc(overworld_root, "healer", "Sister Sera", "healer", "Chapel Healer",
		k_mage,
		{"work": Vector3(19.5, 0.0, -16.5), "rest": Vector3(14.0, 0.0, -15.0), "sleep": Vector3(21.0, 0.0, -18.5)},
		["Step into the Chapel's warmth if you are wounded or drained of Mana.",
		 "Redcap mushrooms and Moonpetals make potent restorative draughts."],
		["wand"])
	healer.service_type = "healer"

	# 7. Innkeeper (Marta — Barrel Tavern)
	var inn := _make_npc(overworld_root, "innkeeper", "Marta", "innkeeper", "Hearthstone Innkeeper",
		k_rogue,
		{"work": Vector3(5.2, 0.0, -15.2), "rest": Vector3(4.0, 0.0, -14.5), "sleep": Vector3(2.2, 0.0, -16.5)},
		["Warm stew, foaming cider, and a soft featherbed for ten gold coins!",
		 "Hunters say a spectral Wraith haunts the Eastern Ruins past the bridge."],
		["mug"])
	inn.service_type = "innkeeper"

	# 8. South Gate Guard (Varek — Night & Day Patrol)
	var sguard := _make_npc(overworld_root, "south_guard", "Varek", "guard", "South Gate Sentinel",
		k_knight,
		{"work": Vector3(-10.5, 0.0, 26.5), "rest": Vector3(-8.5, 0.0, 25.5), "sleep": Vector3(22.0, 0.0, 14.0)},
		["South Meadow stands secure! Watch for Highland Stags by Crystal Lake.",
		 "Every third night, undead raiders test our perimeter — stay ready."],
		["1h_sword", "round_shield", "helmet"])
	sguard.always_awake = true
	sguard.patrol_points = [Vector3(-10.5, 0.0, 26.5), Vector3(-6.5, 0.0, 28.5), Vector3(-13.0, 0.0, 24.0)]

	# 9. Woodland Ranger / Hunter (Rowan)
	var ranger := _make_npc(overworld_root, "hunter", "Rowan", "hunter", "Woodland Ranger",
		k_hood,
		{"work": Vector3(-24.5, 0.0, 3.5), "rest": Vector3(-12.0, 0.0, -14.0), "sleep": Vector3(-24.0, 0.0, -3.0)},
		["Keep your eyes peeled in the western timber. Bramble Stalkers move in pairs.",
		 "Southwest of the woods lies a hidden Sacred Grove blessed with Moonpetals."],
		["crossbow"])
	ranger.patrol_points = [Vector3(-24.5, 0.0, 3.5), Vector3(-31.0, 0.0, 1.5), Vector3(-20.0, 0.0, 7.0)]

	# 10. Forge Apprentice (Toma)
	_make_npc(overworld_root, "apprentice", "Toma", "apprentice", "Smith's Apprentice",
		k_barb,
		{"work": Vector3(-13.2, 0.0, 8.8), "rest": Vector3(-12.5, 0.0, 6.5), "sleep": Vector3(-18.5, 0.0, 9.5)},
		["Master Grim lets me tend the bellows! Two Iron Ore and Wood smelt an Iron Ingot.",
		 "Someday I'll forge a Mythic Sunblade worthy of Rank S heroes."],
		[])

	# 11. Village Child (Pip — playful cottage runner, scaled 0.74x!)
	var child := _make_npc(overworld_root, "child", "Pip", "child", "Village Youth",
		k_rogue,
		{"work": Vector3(11.5, 0.0, -14.5), "rest": Vector3(-13.0, 0.0, -6.0), "sleep": Vector3(-16.0, 0.0, -7.0)},
		["Whoa, real knight armor! Are you going to join the Adventurers Guild?",
		 "I saw glowing blue flowers down by Crystal Lake!"],
		[])
	child.model_scale = 0.74
	child.patrol_points = [Vector3(11.5, 0.0, -14.5), Vector3(15.0, 0.0, -14.0), Vector3(9.0, 0.0, -14.8)]

	# 12. Wayfaring Traveler (Vane — near East Stone Bridge!)
	_make_npc(overworld_root, "traveler", "Vane", "traveler", "Wayfaring Scholar",
		k_mage,
		{"work": Vector3(33.5, 0.0, -3.2), "rest": Vector3(-9.5, 0.0, -15.0), "sleep": Vector3(-14.5, 0.0, -18.5)},
		["Look how clear the Eldoria River runs beneath this stone arch bridge!",
		 "Shadowfang Bats near the northern cave forced my caravan to turn back."],
		["spellbook"])

	# --- 6 ADVENTURERS GUILD INTERIOR NPCS (Stylized Chibi Cast!) ---
	# 13. Guild Receptionist (Elena — Registration, Promotions F->S & Contracts!)
	var recep := _make_npc(guild_root, "guild_receptionist", "Elena", "guild", "Guild Receptionist",
		k_rogue,
		{"work": guild_interior["receptionist_pos"], "rest": guild_interior["receptionist_pos"], "sleep": guild_interior["receptionist_pos"]},
		["Every completed contract raises your Guild Reputation toward Ranks E, D, C, B, A, and S!",
		 "Check the Quest Board beside me anytime for fresh bounties."],
		["spellbook"])
	recep.guild_role = "receptionist"
	recep.always_awake = true

	# 14. Guild Master (Grandmaster Aldric — Main Storyline!)
	var gmaster := _make_npc(guild_root, "guild_master", "Grandmaster Aldric", "guild", "Guild Master",
		k_knight,
		{"work": guild_interior["master_pos"], "rest": guild_interior["master_pos"], "sleep": guild_interior["master_pos"]},
		["I founded this hall after the First Crypt War. Now Malakor stirs once more.",
		 "Prove your mettle, sharpen your skills, and bring peace to Eldoria."],
		["2h_sword", "cape"])
	gmaster.guild_role = "master"
	gmaster.always_awake = true

	# 15. Guild Quartermaster (Bram — Guild Armory Shop!)
	var qm := _make_npc(guild_root, "quartermaster", "Bram", "quartermaster", "Guild Quartermaster",
		k_barb,
		{"work": guild_interior["quartermaster_pos"], "rest": guild_interior["quartermaster_pos"], "sleep": guild_interior["quartermaster_pos"]},
		["Shields, greatswords, signet rings, and mana elixirs — stocked exclusively for Guild members!",
		 "Higher Guild Ranks unlock steeper discounts across Eldoria."],
		["axe", "shield"])
	qm.guild_role = "quartermaster"
	qm.has_shop = true
	qm.always_awake = true

	# 16. Combat & Skill Trainer (Master Kael)
	var trainer := _make_npc(guild_root, "combat_trainer", "Master Kael", "trainer", "Combat & Skill Master",
		k_knight,
		{"work": guild_interior["trainer_pos"], "rest": guild_interior["trainer_pos"], "sleep": guild_interior["trainer_pos"]},
		["Four paths await every hero: Warrior, Mage, Ranger, and Survival.",
		 "Time your Dodge Roll through red boss telegraphs, or raise your Shield to absorb blows!"],
		["1h_sword", "badge_shield"])
	trainer.guild_role = "trainer"
	trainer.always_awake = true

	# 17. Veteran Adventurer (Lyra — Rank B Ranger)
	var vet := _make_npc(guild_root, "veteran_lyra", "Lyra", "adventurer", "Rank B Veteran",
		k_hood,
		{"work": guild_interior["veteran_pos"], "rest": guild_interior["veteran_pos"], "sleep": guild_interior["veteran_pos"]},
		["Tip from a Rank B scout: Ice Magic slows heavy foes cold in their tracks.",
		 "And don't miss the hidden east wall chamber inside the Sunken Crypt!"],
		["dagger", "crossbow"])
	vet.always_awake = true

	# 18. Rookie Recruit (Finn — Rank F Novice)
	var rec := _make_npc(guild_root, "recruit_finn", "Finn", "adventurer", "Rank F Recruit",
		k_rogue,
		{"work": guild_interior["recruit_pos"], "rest": guild_interior["recruit_pos"], "sleep": guild_interior["recruit_pos"]},
		["I just earned my Rank F badge today! Starting with Moonpetal gathering by Crystal Lake.",
		 "Maybe once I forge an Iron Sword I'll tackle the Bramble Stalker contract!"],
		["dagger"])
	rec.always_awake = true

func _make_npc(parent_zone: Node3D, npc_id: String, display_name: String, role: String, title: String,
		model_path: String, schedule: Dictionary, lines: Array, vis_gear: Array) -> VillageNPC:
	var npc := VillageNPC.new()
	npc.name = "NPC_" + npc_id
	npc.role_title = title
	npc.visible_gear = vis_gear
	npc.setup(npc_id, display_name, role, model_path, schedule)
	npc.dialog_lines = lines
	parent_zone.add_child(npc)
	npc.global_position = schedule.get("work", Vector3.ZERO) as Vector3
	_npcs[npc_id] = npc
	return npc

func npc_by_id(npc_id: String) -> VillageNPC:
	return _npcs.get(npc_id, null) as VillageNPC

# --- Runtime API -------------------------------------------------------------

func spawn_creature(creature_id: String, uid: String, position: Vector3, zone_parent: Node3D = null) -> Node:
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
	var target_parent: Node3D = zone_parent if zone_parent != null else (overworld_root if overworld_root != null else self)
	target_parent.add_child(creature)
	creature.global_position = position
	_creatures[uid] = creature
	creature.tree_exited.connect(func() -> void: _creatures.erase(uid))
	return creature

func spawn_loot_drop(items: Array, position: Vector3) -> LootDrop:
	var drop := LootDrop.new()
	drop.setup(items)
	var target_parent: Node3D = overworld_root if (overworld_root != null and overworld_root.visible) else self
	target_parent.add_child(drop)
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
		"guild":
			return guild_interior.get("spawn", spawn_point) as Vector3
		"dungeon":
			return dungeon.get("spawn", spawn_point) as Vector3
		_:
			return spawn_point
