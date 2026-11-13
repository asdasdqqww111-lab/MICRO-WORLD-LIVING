class_name VillageNPC
extends Interactable
## Living Eldoria Villager & Adventurers Guild NPC.
## Preserves 100% of v0.1 contracts (setup, activity_for_hour, dialog_payload,
## execute_action, visual, activity) while adding human KayKit rigs + role gear,
## patrol routes, obstacle steering, quest markers, Guild registration/promotion,
## Blacksmith forge access, Chapel blessing, Inn rest, and Merchant shops.

const SPEED := 1.85

var npc_id: String = ""
var display_name: String = ""
var role: String = "villager"
var role_title: String = ""
var model_path: String = ""
var model_scale: float = 1.0
var dialog_lines: Array = []
var schedule: Dictionary = {}     # {"work": Vector3, "rest": Vector3, "sleep": Vector3}
var patrol_points: Array[Vector3] = []
var visible_gear: Array = []
var hidden_gear: Array = ["axe", "sword", "shield", "mug", "dagger", "crossbow", "staff", "wand", "spellbook"]
var guild_role: String = ""       # "", "receptionist", "master", "quartermaster", "trainer"
var service_type: String = ""     # "", "healer", "innkeeper", "forge"
var has_shop: bool = false
var always_awake: bool = false

var visual: CharacterVisual
var activity: String = "work"

var _target: Vector3 = Vector3.ZERO
var _patrol_idx: int = 0
var _patrol_pause: float = 0.0
var _distant_accum: float = 0.0
var _nameplate: Label3D
var _quest_marker: Label3D

func setup(id: String, npc_name: String, npc_role: String, path: String, positions: Dictionary) -> void:
	npc_id = id
	display_name = npc_name
	role = npc_role
	model_path = path
	schedule = positions
	prompt_text = "Talk to %s" % npc_name
	_target = positions.get("work", Vector3.ZERO) as Vector3

func _ready() -> void:
	super._ready()
	add_to_group("npc")
	interaction_radius = 2.8
	_build_visual()
	_build_labels()
	if schedule.is_empty():
		schedule = {"work": global_position, "rest": global_position, "sleep": global_position}
	EventBus.quest_updated.connect(_on_quest_or_guild_changed)
	EventBus.guild_updated.connect(_on_guild_changed)
	EventBus.language_changed.connect(func(_l: String) -> void: _refresh_nameplate())
	_refresh_nameplate()
	_refresh_marker()

func _build_visual() -> void:
	visual = CharacterVisual.new()
	visual.name = "Visual"
	visual.rotation.y = PI
	add_child(visual)
	var fallback_human := "res://assets/characters/npcs/Rogue.glb"
	var chosen := model_path if (not model_path.is_empty() and AssetLibrary.has_model(model_path)) else fallback_human
	if not visual.setup(chosen, model_scale * 0.76):
		var fb := ProceduralModels.build("slime")
		add_child(fb)
	else:
		visual.configure_gear(visible_gear, hidden_gear)
		visual.play("idle")
	add_child(ArtDirection.make_contact_ao(0.52, 0.34))
	_apply_lod_recursive(visual, 16.0)

func _apply_lod_recursive(node: Node, dist: float) -> void:
	if node is GeometryInstance3D:
		var gi := node as GeometryInstance3D
		gi.visibility_range_end = dist
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c: Node in node.get_children():
		_apply_lod_recursive(c, dist)

func _build_labels() -> void:
	_nameplate = Label3D.new()
	_nameplate.font_size = 20
	_nameplate.outline_size = 6
	_nameplate.modulate = Color(0.96, 0.92, 0.80)
	_nameplate.visibility_range_end = 18.0
	_nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nameplate.position = Vector3(0.0, 2.22 * model_scale, 0.0)
	_nameplate.visibility_range_end = 26.0
	add_child(_nameplate)
	_refresh_nameplate()

	_quest_marker = Label3D.new()
	_quest_marker.text = "!"
	_quest_marker.font_size = 42
	_quest_marker.outline_size = 8
	_quest_marker.modulate = Color(1.0, 0.84, 0.22)
	_quest_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_quest_marker.position = Vector3(0.0, 2.68 * model_scale, 0.0)
	_quest_marker.visibility_range_end = 34.0
	_quest_marker.visible = false
	add_child(_quest_marker)

func _refresh_nameplate() -> void:
	if _nameplate == null:
		return
	var nm := Localization.npc_name(npc_id, display_name)
	var sub_fb := role_title if not role_title.is_empty() else role.capitalize()
	var subtitle := Localization.npc_title(npc_id, sub_fb)
	_nameplate.text = "%s\n<%s>" % [nm, subtitle]

## Schedule: work 06-18, rest 18-22, sleep 22-06 (preserved for unit tests).
static func activity_for_hour(hour: int) -> String:
	if hour >= 22 or hour < 6:
		return "sleep"
	if hour >= 18:
		return "rest"
	return "work"

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		var d2 := global_position.distance_squared_to(player.global_position)
		if _nameplate != null:
			_nameplate.visible = d2 < 24.0 * 24.0
		if d2 > 44.0 * 44.0:
			_distant_accum += delta
			if _distant_accum < 0.25:
				return
			delta = _distant_accum
			_distant_accum = 0.0

	var new_activity := "work" if always_awake else activity_for_hour(GameManager.world.hour())
	if new_activity != activity:
		activity = new_activity
		_target = schedule.get(activity, global_position) as Vector3
		GameManager.world.npc_overrides[npc_id] = activity
	if not GameManager.world.npc_overrides.has(npc_id):
		GameManager.world.npc_overrides[npc_id] = activity

	if activity == "work" and patrol_points.size() > 1:
		if _patrol_pause > 0.0:
			_patrol_pause -= delta
			if visual != null:
				visual.play("idle")
			return
		_target = patrol_points[_patrol_idx % patrol_points.size()]

	var to_target := _target - global_position
	to_target.y = 0.0
	if to_target.length() > 0.38:
		var dir := _steer(to_target.normalized())
		var next_pos := global_position + dir * minf(SPEED * delta, to_target.length())
		var world_root := get_tree().get_first_node_in_group("world_root")
		if world_root != null and world_root.get("terrain") != null and next_pos.distance_to(Vector3.ZERO) < 118.0:
			var terr: Terrain = world_root.get("terrain") as Terrain
			if terr != null:
				next_pos.y = terr.height_at(next_pos.x, next_pos.z)
		global_position = next_pos
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.14)
		if visual != null:
			visual.play("walk")
	else:
		if activity == "work" and patrol_points.size() > 1:
			_patrol_idx = (_patrol_idx + 1) % patrol_points.size()
			_patrol_pause = 2.5
		if visual != null:
			match activity:
				"sleep":
					visual.play("lie")
				"rest":
					visual.play("sit")
				_:
					if role == "blacksmith" or service_type == "forge":
						visual.play("work_hammer")
					elif service_type == "healer":
						visual.play("work_pray")
					elif role == "guard" or guild_role == "master" or guild_role == "trainer":
						visual.play("idle_combat")
					else:
						visual.play("idle")

func _steer(desired: Vector3) -> Vector3:
	var w3d := get_world_3d()
	if w3d == null or w3d.direct_space_state == null:
		return desired
	var origin := global_position + Vector3(0.0, 0.8, 0.0)
	var q := PhysicsRayQueryParameters3D.create(origin, origin + desired * 1.2, 1)
	if w3d.direct_space_state.intersect_ray(q).is_empty():
		return desired
	for ang: float in [0.7, -0.7, 1.35, -1.35]:
		var alt := desired.rotated(Vector3.UP, ang)
		var q2 := PhysicsRayQueryParameters3D.create(origin, origin + alt * 1.2, 1)
		if w3d.direct_space_state.intersect_ray(q2).is_empty():
			return alt
	return desired

func can_interact(_player: Node) -> bool:
	return always_awake or activity != "sleep"

func prompt_for(_player: Node) -> String:
	var nm := Localization.npc_name(npc_id, display_name)
	if not always_awake and activity == "sleep":
		return ("%s نائم الآن" % nm) if Localization.is_arabic() else ("%s is asleep" % nm)
	return ("تحدّث مع %s" % nm) if Localization.is_arabic() else ("Talk to %s" % nm)

func interact(player: Node) -> void:
	if player is Node3D:
		var to_player := (player as Node3D).global_position - global_position
		if to_player.length() > 0.1:
			rotation.y = atan2(-to_player.x, -to_player.z)
	if visual != null:
		visual.play("interact", true)
	if AudioManager != null:
		AudioManager.play_sfx("npc_greet", -3.0, randf_range(0.92, 1.08))
	EventBus.dialog_requested.emit(self)

func dialog_payload() -> Dictionary:
	var ar := Localization.is_arabic()
	var nm := Localization.npc_name(npc_id, display_name)
	var sub_fb := role_title if not role_title.is_empty() else role.capitalize()
	var stitle := Localization.npc_title(npc_id, sub_fb)
	var actions: Array = []
	for quest: QuestData in QuestDB.quests_involving_npc(npc_id):
		var st := GameManager.quest_log.state_of(quest.id)
		var qtitle := Localization.quest_title(quest)
		if st == QuestLog.STATE_READY and quest.turn_in_npc == npc_id:
			actions.append({"type": "quest_turnin", "quest_id": quest.id,
				"label": ("تسليم المهمة: %s" % qtitle) if ar else ("Turn in: %s" % qtitle)})
		elif st == QuestLog.STATE_NOT_STARTED and quest.giver_npc == npc_id:
			if not quest.is_guild_contract or GameManager.guild.meets_rank(quest.required_guild_rank):
				actions.append({"type": "quest_offer", "quest_id": quest.id,
					"label": ("مهمة: %s" % qtitle) if ar else ("Quest: %s" % qtitle)})
		elif st == QuestLog.STATE_ACTIVE:
			actions.append({"type": "quest_progress", "quest_id": quest.id,
				"label": ("حول المهمة: %s" % qtitle) if ar else ("About: %s" % qtitle)})

	if guild_role == "receptionist":
		if not GameManager.guild.registered:
			actions.append({"type": "guild_register", "label": Localization.tr_key("register_guild")})
		else:
			if GameManager.guild.can_promote(GameManager.progression.level):
				actions.append({"type": "guild_promote",
					"label": ("ترقية إلى الرتبة %s!" % GameManager.guild.next_rank()) if ar else ("Promote to Rank %s!" % GameManager.guild.next_rank())})
			actions.append({"type": "open_guild", "label": "عقود النقابة والرتب" if ar else "Guild Contracts & Ranks"})
	elif guild_role == "master":
		actions.append({"type": "open_guild", "label": "سجل نقابة المغامرين" if ar else "Guild Ledger"})
	elif guild_role == "trainer":
		actions.append({"type": "open_skills", "label": "شجرة المهارات القتالية" if ar else "Skill Tree Mastery"})

	if service_type == "healer":
		actions.append({"type": "heal_blessing", "label": "بركة المعبد (شفاء كامل)" if ar else "Chapel Blessing (Full Heal)"})
	elif service_type == "innkeeper":
		actions.append({"type": "inn_rest", "label": "استراحة حتى الفجر (10 ذهب)" if ar else "Rest Until Dawn (10g)"})
	elif service_type == "forge" or role == "blacksmith":
		actions.append({"type": "open_forge", "label": "التصنيع في كور الحدادة" if ar else "Craft at Forge"})

	if has_shop or role == "blacksmith" or role == "merchant" or guild_role == "quartermaster":
		actions.append({"type": "shop", "label": ("المتاجرة مع %s" % nm) if ar else ("Trade with %s" % nm)})

	actions.append({"type": "close", "label": Localization.tr_key("leave")})
	return {
		"npc_id": npc_id,
		"name": "%s · %s" % [nm, stitle] if not stitle.is_empty() else nm,
		"role": role,
		"lines": _contextual_lines(),
		"actions": actions,
	}

func _contextual_lines() -> Array:
	var ar := Localization.is_arabic()
	var lines: Array = []
	if guild_role == "receptionist" and not GameManager.guild.registered:
		lines.append("مرحباً بك في نقابة مغامري إلدوريا! سجّل اسمك لديّ لتحصل على شارة الرتبة F وتبدأ قبول العقود الرسمية." if ar else "Welcome to the Eldoria Adventurers Guild! Register at my desk to earn your Rank F badge and accept official contracts.")
	for quest: QuestData in QuestDB.quests_involving_npc(npc_id):
		var st := GameManager.quest_log.state_of(quest.id)
		if st == QuestLog.STATE_READY and quest.turn_in_npc == npc_id:
			var qt := Localization.quest_title(quest)
			lines.append(("%s: أحسنت صنعاً أيها المغامر! تفضّل مكافأتك المستحقة." % qt) if ar else ("%s: Splendid work, adventurer! Here is your reward." % qt))
	if GameManager.world.weather == "rain" and lines.is_empty():
		lines.append("تهطل الأمطار من قمم إلدوريا الشمالية — احذر الانزلاق على الحجارة." if ar else "Rain sweeps down from the Eldoria peaks — mind your footing on the cobbles.")
	for line: Variant in Localization.npc_lines(npc_id, dialog_lines):
		lines.append(String(line))
	return lines

func execute_action(action: Dictionary) -> String:
	var ar := Localization.is_arabic()
	match String(action.get("type", "")):
		"quest_offer":
			var quest_id := String(action.get("quest_id", ""))
			if GameManager.start_quest(quest_id):
				_refresh_marker()
				var quest := QuestDB.get_quest(quest_id)
				var qt := Localization.quest_title(quest) if quest != null else quest_id
				return ("بدأت المهمة: %s" % qt) if ar else ("Quest started: %s" % qt)
			return "لا تستوفي متطلبات هذه المهمة بعد." if ar else "You do not meet the requirements for that quest yet."
		"quest_progress":
			var quest := QuestDB.get_quest(String(action.get("quest_id", "")))
			if quest == null:
				return ""
			var parts: PackedStringArray = []
			for i: int in quest.objectives.size():
				var objective: Dictionary = quest.objectives[i]
				var olabel := Localization.quest_obj_label(quest, i, String(objective.get("label", "Objective")))
				parts.append("%s: %d/%d" % [olabel,
					GameManager.quest_log.objective_progress(quest.id, i),
					int(objective.get("required", 1))])
			return " | ".join(parts)
		"quest_turnin":
			var quest_id := String(action.get("quest_id", ""))
			var quest := QuestDB.get_quest(quest_id)
			if GameManager.turn_in_quest(quest_id):
				_refresh_marker()
				if quest != null:
					return ("المكافأة: %d خبرة، %d ذهب" % [quest.reward_xp, quest.reward_gold]) if ar else ("Reward: %d XP, %d Gold" % [quest.reward_xp, quest.reward_gold])
				return "تم استلام المكافأة" if ar else "Reward granted"
			return "أكمل أهداف المهمة أولاً." if ar else "Finish the objectives first."
		"guild_register":
			GameManager.register_in_guild()
			_refresh_marker()
			return "تم تسجيلك كمغامر رتبة F! راجع لوحة عقود النقابة." if ar else "Registered as Rank F Adventurer! Check the Quest Board for contracts."
		"guild_promote":
			var info := GameManager.promote_guild_rank()
			_refresh_marker()
			if not info.is_empty():
				return ("تمت ترقيتك إلى الرتبة %s!" % String(info["rank"])) if ar else ("Promoted to Guild Rank %s — %s!" % [String(info["rank"]), String(info["title"])])
			return "واصل إنجاز العقود لرفع سمعتك والترقية." if ar else "Keep completing contracts to earn promotion."
		"open_guild":
			EventBus.guild_board_opened.emit()
			return "__close__"
		"open_forge":
			EventBus.crafting_opened.emit("forge")
			return "__close__"
		"open_skills":
			EventBus.screen_changed.emit("request_skills")
			return "__close__"
		"heal_blessing":
			var p := get_tree().get_first_node_in_group("player") as Player
			if p != null:
				p.heal(999.0)
				p.restore_mana(999.0)
			return "نور المعبد استعاد صحتك والمانا بالكامل!" if ar else "Chapel light restores your Health & Mana!"
		"inn_rest":
			if GameManager.spend_gold(10):
				var p := get_tree().get_first_node_in_group("player") as Player
				if p != null:
					p.sleep_until_morning()
				return "استرحت في نُزل الموقد حتى إشراقة الفجر!" if ar else "Rested at the Hearthstone Inn until dawn!"
			return "تحتاج إلى 10 قطع ذهبية لاستئجار غرفة دافئة." if ar else "You need 10 gold to rent a warm room."
		"shop":
			EventBus.shop_requested.emit(self)
			return ""
		"close":
			return ""
	return ""

func _on_quest_or_guild_changed(_id: String) -> void:
	_refresh_marker()

func _on_guild_changed() -> void:
	_refresh_marker()

func _refresh_marker() -> void:
	if _quest_marker == null:
		return
	for quest: QuestData in QuestDB.quests_involving_npc(npc_id):
		var st := GameManager.quest_log.state_of(quest.id)
		if st == QuestLog.STATE_READY and quest.turn_in_npc == npc_id:
			_quest_marker.text = "?"
			_quest_marker.modulate = Color(0.42, 0.96, 0.55)
			_quest_marker.visible = true
			return
		if st == QuestLog.STATE_NOT_STARTED and quest.giver_npc == npc_id:
			if not quest.is_guild_contract or GameManager.guild.meets_rank(quest.required_guild_rank):
				_quest_marker.text = "!"
				_quest_marker.modulate = Color(1.0, 0.85, 0.25)
				_quest_marker.visible = true
				return
	if guild_role == "receptionist" and (not GameManager.guild.registered or GameManager.guild.can_promote(GameManager.progression.level)):
		_quest_marker.text = "★"
		_quest_marker.modulate = Color(0.45, 0.82, 1.0)
		_quest_marker.visible = true
		return
	_quest_marker.visible = false
