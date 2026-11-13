class_name QuestWaypoint3D
extends Node3D
## Live 3D Active Quest Waypoint Beacon & Objective Resolver.
## Guides the player in 3D space (and feeds HUD/Minimap distance) toward the
## current quest objective, dungeon entrance, or turn-in NPC across zones!

var world_root: WorldRoot
var has_waypoint: bool = false
var target_position: Vector3 = Vector3.ZERO
var target_title: String = ""
var custom_pin_active: bool = false
var custom_pin_pos: Vector3 = Vector3.ZERO
var custom_pin_title: String = ""
var focused_quest_id: String = ""

var _diamond_top: MeshInstance3D
var _diamond_bot: MeshInstance3D
var _ring: MeshInstance3D
var _label: Label3D
var _time: float = 0.0
var _refresh_accum: float = 0.0

func setup(world: WorldRoot) -> void:
	world_root = world

func _ready() -> void:
	add_to_group("quest_waypoint")
	top_level = true
	_build_meshes()
	EventBus.quest_started.connect(func(_q: String) -> void: refresh_target())
	EventBus.quest_updated.connect(func(_q: String) -> void: refresh_target())
	EventBus.quest_completed.connect(func(_q: String) -> void: refresh_target())
	EventBus.zone_entered.connect(func(_z: String) -> void: refresh_target())
	EventBus.language_changed.connect(func(_l: String) -> void: refresh_target())
	call_deferred("refresh_target")

func _build_meshes() -> void:
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(1.0, 0.84, 0.24, 0.94)
	gold_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gold_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(0.38, 0.38, 0.38)
	_diamond_top = MeshInstance3D.new()
	_diamond_top.mesh = top_mesh
	_diamond_top.position = Vector3(0.0, 2.75, 0.0)
	_diamond_top.rotation_degrees = Vector3(45.0, 0.0, 45.0)
	_diamond_top.material_override = gold_mat
	_diamond_top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_diamond_top)

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.52
	ring_mesh.outer_radius = 0.66
	ring_mesh.rings = 16
	ring_mesh.ring_segments = 6
	_ring = MeshInstance3D.new()
	_ring.mesh = ring_mesh
	_ring.position = Vector3(0.0, 0.12, 0.0)
	_ring.material_override = gold_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 24
	_label.outline_size = 7
	_label.modulate = Color(1.0, 0.90, 0.42)
	_label.position = Vector3(0.0, 3.45, 0.0)
	add_child(_label)

func _process(delta: float) -> void:
	_time += delta
	_refresh_accum += delta
	if _refresh_accum >= 0.6:
		_refresh_accum = 0.0
		refresh_target()
	if not has_waypoint:
		visible = false
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		visible = false
		return
	var dist := player.global_position.distance_to(target_position)
	visible = dist > 2.2 and dist < 190.0
	if not visible:
		return
	global_position = target_position
	var bob := sin(_time * 3.2) * 0.16
	_diamond_top.position.y = 2.75 + bob
	_diamond_top.rotation.y = _time * 1.9
	_ring.rotation.y = -_time * 1.2
	if _label != null:
		var m_unit := "م" if Localization.is_arabic() else "m"
		_label.text = "◆ %s (%d%s)" % [target_title, int(round(dist)), m_unit]

func set_custom_pin(world_pos: Vector3, pin_label: String) -> void:
	custom_pin_active = true
	custom_pin_pos = world_pos
	custom_pin_title = pin_label
	refresh_target()

func clear_custom_pin() -> void:
	custom_pin_active = false
	custom_pin_title = ""
	refresh_target()

func focus_quest(quest_id: String) -> void:
	custom_pin_active = false
	focused_quest_id = quest_id
	refresh_target()

func refresh_target() -> void:
	if world_root == null or GameManager == null or GameManager.quest_log == null:
		has_waypoint = false
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	var pzone := player.zone if player != null else "village"

	if custom_pin_active and pzone == "village":
		if player != null and player.global_position.distance_to(custom_pin_pos) < 3.8:
			custom_pin_active = false
		else:
			has_waypoint = true
			target_position = custom_pin_pos
			target_title = custom_pin_title
			return

	var chosen_quest: QuestData = null
	var is_ready := false
	if not focused_quest_id.is_empty():
		var fq_st := GameManager.quest_log.state_of(focused_quest_id)
		if fq_st == QuestLog.STATE_ACTIVE or fq_st == QuestLog.STATE_READY:
			chosen_quest = QuestDB.get_quest(focused_quest_id)
			is_ready = (fq_st == QuestLog.STATE_READY)

	# 1. Prioritize READY-TO-TURN-IN quests first
	if chosen_quest == null:
		for qid: String in GameManager.quest_log.entries.keys():
			var st := GameManager.quest_log.state_of(qid)
			if st == QuestLog.STATE_READY:
				chosen_quest = QuestDB.get_quest(qid)
				is_ready = true
				break
	# 2. Otherwise first ACTIVE quest
	if chosen_quest == null:
		for qid: String in GameManager.quest_log.entries.keys():
			if GameManager.quest_log.state_of(qid) == QuestLog.STATE_ACTIVE:
				chosen_quest = QuestDB.get_quest(qid)
				break

	# 3. Brand-new adventure with no quests yet -> guide to Elder Theron in Eldoria Square!
	if chosen_quest == null:
		if GameManager.quest_log.entries.is_empty() and pzone == "village":
			var elder := world_root.find_npc("elder")
			if elder != null:
				has_waypoint = true
				target_position = elder.global_position
				target_title = Localization.npc_name("elder", elder.display_name)
				return
		has_waypoint = false
		return

	target_title = Localization.quest_title(chosen_quest)
	if is_ready and not chosen_quest.turn_in_npc.is_empty():
		target_position = _resolve_npc_or_door(chosen_quest.turn_in_npc, pzone)
		has_waypoint = true
		return

	target_position = _resolve_quest_objective_pos(chosen_quest.id, pzone)
	has_waypoint = true

func _resolve_npc_or_door(npc_id: String, pzone: String) -> Vector3:
	var guild_npcs := ["guild_receptionist", "guild_master", "quartermaster", "combat_trainer", "veteran_lyra", "recruit_finn"]
	var npc_in_guild := guild_npcs.has(npc_id)
	if npc_in_guild and pzone != "guild":
		return world_root.landmarks.get("guild_door", Vector3(0.0, 0.0, -18.4)) as Vector3
	if not npc_in_guild and pzone == "guild":
		return world_root.guild_interior.get("exit", Vector3(500.0, 0.0, 211.4)) as Vector3
	if not npc_in_guild and pzone == "dungeon":
		return world_root.dungeon.get("exit", Vector3(-496.0, 0.0, 1.0)) as Vector3
	var npc := world_root.find_npc(npc_id)
	if npc != null:
		return npc.global_position
	return Vector3(0.0, 0.2, 2.0)

func _terrain_pos(x: float, z: float) -> Vector3:
	var y := world_root.terrain.height_at(x, z) if world_root.terrain != null else 0.0
	return Vector3(x, y, z)

func _resolve_quest_objective_pos(quest_id: String, pzone: String) -> Vector3:
	match quest_id:
		"main_guild_call":
			if pzone == "guild":
				return _resolve_npc_or_door("guild_receptionist", pzone)
			return world_root.landmarks.get("guild_door", Vector3(0.0, 0.0, -18.4)) as Vector3
		"skeleton_menace", "contract_forest_cull", "healer_herbs", "city_west_timber_aid":
			if pzone != "village":
				return _resolve_npc_or_door("farmer", pzone)
			return _terrain_pos(-48.0, 4.0)
		"city_citadel_camp":
			return _terrain_pos(-62.0, -24.0)
		"contract_herb_harvest", "city_alchemist_slime":
			return _terrain_pos(16.0, 50.0)
		"city_jeweler_pelts", "city_archery_wolves":
			return _terrain_pos(-44.0, -34.0)
		"city_north_cave_sweep", "contract_bridge_escort":
			return _terrain_pos(-14.0, -56.0)
		"smith_ore_supply", "city_scholar_golem", "contract_rank_b_golem":
			return _terrain_pos(58.0, -6.0)
		"city_apprentice_ingots":
			return Vector3(13.8, 0.0, -6.2)
		"city_innkeeper_feast":
			return _terrain_pos(-20.0, 44.0)
		"city_ranger_grove":
			return _terrain_pos(-56.0, 44.0)
		"contract_ruins_survey", "contract_rank_a_wraith":
			return _terrain_pos(66.0, -18.0)
		"sunken_cellar", "main_dread_crypt", "contract_crypt_lord", "main_sovereign_champion":
			if pzone == "dungeon":
				return world_root.dungeon.get("boss_spawn", Vector3(-496.0, 0.4, 34.0)) as Vector3
			return world_root.landmarks.get("dungeon_entrance", Vector3(58.0, 0.2, 22.0)) as Vector3
		_:
			return Vector3(0.0, 0.2, 2.0)
