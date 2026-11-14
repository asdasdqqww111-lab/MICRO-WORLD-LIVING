class_name VillageNPC
extends Interactable
## A townsperson of Eldoria.
##
## Daily life (hours from WorldState):
##   06-18  work   - stay at the workplace, moving between a few nearby spots
##                   and doing the job's animation there
##   18-22  rest   - walk to the evening spot and stand around with neighbours
##   22-06  sleep  - walk home and go indoors (hidden until morning)
## Guards, shopkeepers and anybody the player currently needs for a quest stay
## at their post through the night, so nothing the player has to do is ever
## locked behind the clock.
##
## Awareness: a villager stops and turns towards the player when approached,
## greets once, and goes back to what they were doing when the player leaves.
## Walking is checked against the world's colliders, so nobody walks through
## buildings, stalls or trees; a villager who cannot reach a spot picks another.

const SPEED := 1.3
## Characters are drawn up to this distance from the camera and animated a
## little further out, so nobody is seen frozen.
const DRAW_DISTANCE := 22.0
const ANIMATE_DISTANCE := 27.0
## Obstacle probing runs at 5 Hz, not every frame.
const STEER_INTERVAL := 0.2
const NOTICE_RADIUS := 3.2
const FORGET_RADIUS := 4.4
const GREET_COOLDOWN := 22.0
const BODY_RADIUS := 0.26
const BODY_HEIGHT := 1.25
const ARRIVE_DISTANCE := 0.32

## Short lines said out loud (speech bubble) - [arabic, english] per role.
const GREETINGS := {
	"blacksmith": [["أهلاً! النار جاهزة.", "السندان بانتظارك."], ["Welcome! The forge is hot.", "Need steel?"]],
	"merchant": [["بضائع طازجة اليوم!", "تفضّل، انظر بنفسك."], ["Fresh goods today!", "Have a look."]],
	"guard": [["الطرق آمنة اليوم.", "ابقَ حذراً خارج الأسوار."], ["Roads are quiet today.", "Stay sharp outside the walls."]],
	"healer": [["النور يحفظك.", "هل أنت مصاب؟"], ["Light keep you.", "Are you hurt?"]],
	"farmer": [["صباح الخير!", "المحصول جيد هذا العام."], ["Good day!", "The harvest looks fine."]],
	"child": [["هل أنت بطل حقيقي؟", "انظر إليّ!"], ["Are you a real hero?", "Look at me!"]],
	"guild": [["النقابة ترحب بك.", "عقود جديدة على اللوحة."], ["The Guild welcomes you.", "New contracts on the board."]],
	"default": [["مرحباً أيها المغامر.", "يوم جميل، أليس كذلك؟"], ["Hello, adventurer.", "Fine day, isn't it?"]],
}

enum Mode { IDLE, WALK, ATTEND, INDOORS }

static var _shared_player: Node3D = null
static var _shared_terrain: Terrain = null

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
## Set for staff who man a desk or counter: they stay on the spot and look this way.
var post_facing: Vector3 = Vector3.ZERO

var visual: CharacterVisual
var activity: String = "work"
var mode: Mode = Mode.IDLE

var _target: Vector3 = Vector3.ZERO
var _spots: Array[Vector3] = []
var _spot_idx: int = 0
var _pause: float = 0.0
var _distant_accum: float = 0.0
var _steer_accum: float = 1.0
var _steer_dir: Vector3 = Vector3.ZERO
var _stuck_time: float = 0.0
var _stuck_from: Vector3 = Vector3.ZERO
var _greet_cooldown: float = 0.0
var _bubble_time: float = 0.0
var _idle_action: String = "idle"
var _indoor: bool = false
var _wants_marker: bool = false
var _needed_now: bool = false
var _rng := RandomNumberGenerator.new()
var _nameplate: Label3D
var _quest_marker: Label3D
var _bubble: Label3D
var _body: AnimatableBody3D

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
	interaction_radius = 2.4
	_rng.seed = hash(npc_id) + 77
	_indoor = global_position.length() > 200.0
	_build_visual()
	_build_body()
	_build_labels()
	if schedule.is_empty():
		schedule = {"work": global_position, "rest": global_position, "sleep": global_position}
	EventBus.quest_updated.connect(_on_quest_or_guild_changed)
	EventBus.guild_updated.connect(_on_guild_changed)
	EventBus.language_changed.connect(func(_l: String) -> void: _refresh_nameplate())
	_refresh_nameplate()
	_refresh_marker()
	_pause = _rng.randf_range(0.5, 4.0)

func _build_visual() -> void:
	visual = CharacterVisual.new()
	visual.name = "Visual"
	visual.rotation.y = PI
	add_child(visual)
	var fallback_human := "res://assets/characters/npcs/Rogue.glb"
	var chosen := model_path if (not model_path.is_empty() and AssetLibrary.has_model(model_path)) else fallback_human
	if not visual.setup(chosen, model_scale * CharacterVisual.HUMAN_SCALE):
		var fb := ProceduralModels.build("slime")
		add_child(fb)
	else:
		visual.configure_gear(visible_gear, hidden_gear)
		visual.play("idle")
	add_child(ArtDirection.make_contact_ao(0.40 * model_scale, 0.30))
	_apply_lod_recursive(visual, DRAW_DISTANCE)

## A solid body so the player and monsters cannot walk through a villager.
func _build_body() -> void:
	_body = AnimatableBody3D.new()
	_body.name = "Body"
	_body.sync_to_physics = false
	_body.collision_layer = CollisionLayers.NPC
	_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS * model_scale
	capsule.height = BODY_HEIGHT * model_scale
	shape.shape = capsule
	shape.position = Vector3(0.0, capsule.height * 0.5, 0.0)
	_body.add_child(shape)
	add_child(_body)

func _apply_lod_recursive(node: Node, dist: float) -> void:
	if node is GeometryInstance3D:
		var gi := node as GeometryInstance3D
		gi.visibility_range_end = dist
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c: Node in node.get_children():
		_apply_lod_recursive(c, dist)

func _head_height() -> float:
	var hat := 0.36 if (visible_gear.has("hat") or model_path.contains("Mage")) else 0.0
	return (1.36 + hat) * model_scale

func _build_labels() -> void:
	_nameplate = Label3D.new()
	_nameplate.name = "Nameplate"
	_nameplate.font_size = 22
	_nameplate.outline_size = 7
	_nameplate.pixel_size = 0.0036
	_nameplate.modulate = Color(0.97, 0.93, 0.82)
	_nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nameplate.no_depth_test = false
	_nameplate.position = Vector3(0.0, _head_height() + 0.26, 0.0)
	_nameplate.visibility_range_end = 16.0
	add_child(_nameplate)

	_quest_marker = Label3D.new()
	_quest_marker.name = "QuestMarker"
	_quest_marker.text = "!"
	_quest_marker.font_size = 56
	_quest_marker.outline_size = 12
	_quest_marker.pixel_size = 0.0046
	_quest_marker.modulate = Color(1.0, 0.84, 0.22)
	_quest_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_quest_marker.position = Vector3(0.0, _head_height() + 0.62, 0.0)
	_quest_marker.visibility_range_end = 34.0
	_quest_marker.visible = false
	add_child(_quest_marker)

	_bubble = Label3D.new()
	_bubble.name = "SpeechBubble"
	_bubble.font_size = 22
	_bubble.outline_size = 8
	_bubble.pixel_size = 0.0042
	_bubble.modulate = Color(1.0, 1.0, 1.0)
	_bubble.outline_modulate = Color(0.10, 0.12, 0.18, 0.95)
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.position = Vector3(0.0, _head_height() + 0.62, 0.0)
	_bubble.visible = false
	add_child(_bubble)

func _refresh_nameplate() -> void:
	if _nameplate == null:
		return
	var nm := Localization.npc_name(npc_id, display_name)
	var sub_fb := role_title if not role_title.is_empty() else role.capitalize()
	var subtitle := Localization.npc_title(npc_id, sub_fb)
	_nameplate.text = "%s\n%s" % [nm, subtitle] if not subtitle.is_empty() else nm

## Schedule: work 06-18, rest 18-22, sleep 22-06 (preserved for unit tests).
static func activity_for_hour(hour: int) -> String:
	if hour >= 22 or hour < 6:
		return "sleep"
	if hour >= 18:
		return "rest"
	return "work"

## Villagers the player needs right now do not go to bed.
func _stays_available() -> bool:
	return always_awake or has_shop or _needed_now or not service_type.is_empty() or not guild_role.is_empty() or role == "guard"

func is_indoors_asleep() -> bool:
	return mode == Mode.INDOORS

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return

	if not is_instance_valid(_shared_player):
		_shared_player = get_tree().get_first_node_in_group("player") as Node3D
	var player := _shared_player
	var d2 := INF
	if player != null:
		d2 = global_position.distance_squared_to(player.global_position)
		if visual != null:
			visual.set_lod_active(d2 < ANIMATE_DISTANCE * ANIMATE_DISTANCE)
		# Out of sight: think and move four times a second instead of every frame.
		if d2 > ANIMATE_DISTANCE * ANIMATE_DISTANCE:
			_distant_accum += delta
			if _distant_accum < 0.25:
				return
			delta = _distant_accum
			_distant_accum = 0.0

	_greet_cooldown = maxf(0.0, _greet_cooldown - delta)
	if _bubble_time > 0.0:
		_bubble_time -= delta
		if _bubble_time <= 0.0 and _bubble != null:
			_bubble.visible = false

	_update_activity()
	if mode == Mode.INDOORS:
		return

	# --- Awareness of the player -------------------------------------------
	if player != null and activity != "sleep":
		if mode != Mode.ATTEND and d2 < NOTICE_RADIUS * NOTICE_RADIUS:
			_begin_attend()
		elif mode == Mode.ATTEND and d2 > FORGET_RADIUS * FORGET_RADIUS:
			mode = Mode.IDLE
			_pause = _rng.randf_range(0.6, 1.6)
	if mode == Mode.ATTEND:
		if player != null:
			_face(player.global_position, delta, 7.0)
		_play_idle("idle")
		return

	# --- Routine --------------------------------------------------------------
	if mode == Mode.IDLE:
		_pause -= delta
		_play_idle(_idle_action)
		if post_facing != Vector3.ZERO:
			_face(global_position + post_facing, delta, 4.0)
		if _pause <= 0.0:
			_choose_next_target()
		return
	_walk(delta)

func _update_activity() -> void:
	var wanted := "work"
	if not always_awake:
		wanted = activity_for_hour(GameManager.world.hour())
		if wanted == "sleep" and _stays_available():
			wanted = "rest" if role != "guard" else "work"
	if wanted != activity:
		activity = wanted
		GameManager.world.npc_overrides[npc_id] = activity
		_spots.clear()
		if mode == Mode.INDOORS:
			_come_outside()
		mode = Mode.IDLE
		_pause = _rng.randf_range(0.2, 2.5)
	elif not GameManager.world.npc_overrides.has(npc_id):
		GameManager.world.npc_overrides[npc_id] = activity

## The few places this villager moves between for the current activity.
func _activity_spots() -> Array[Vector3]:
	if not _spots.is_empty():
		return _spots
	var anchor := schedule.get(activity, global_position) as Vector3
	if activity == "work" and patrol_points.size() > 1:
		_spots.assign(patrol_points)
		return _spots
	if activity == "sleep" or post_facing != Vector3.ZERO:
		_spots = [anchor]
		return _spots
	_spots = [anchor]
	# Shopkeepers and craftsmen stay within a step or two of their post;
	# everybody else has a slightly larger beat.
	var stays_put := has_shop or not service_type.is_empty() or not guild_role.is_empty() or role == "guard"
	var reach := 1.5 if stays_put else 3.4
	var start_angle := _rng.randf() * TAU
	for i in 8:
		if _spots.size() >= (2 if stays_put else 4):
			break
		var ang := start_angle + float(i) * (TAU / 8.0) * 3.0
		var cand := anchor + Vector3(cos(ang), 0.0, sin(ang)) * reach * _rng.randf_range(0.7, 1.0)
		if _spot_is_free(anchor, cand):
			_spots.append(cand)
	return _spots

func _spot_is_free(from_pos: Vector3, cand: Vector3) -> bool:
	if not _indoor:
		if CityPlan.on_lot(cand.x, cand.z, 0.5):
			return false
		var terrain := _terrain()
		if terrain != null and terrain.is_water_at(cand.x, cand.z):
			return false
	return not _segment_blocked(from_pos, cand)

func _choose_next_target() -> void:
	var spots := _activity_spots()
	if spots.is_empty():
		_pause = 2.0
		return
	if spots.size() == 1:
		_spot_idx = 0
	elif activity == "work" and patrol_points.size() > 1:
		_spot_idx = (_spot_idx + 1) % spots.size()
	else:
		var next := _rng.randi_range(0, spots.size() - 1)
		if next == _spot_idx:
			next = (next + 1) % spots.size()
		_spot_idx = next
	_target = spots[_spot_idx]
	var flat := _target - global_position
	flat.y = 0.0
	if flat.length() <= ARRIVE_DISTANCE:
		_arrive()
		return
	mode = Mode.WALK
	_steer_dir = Vector3.ZERO
	_stuck_time = 0.0
	_stuck_from = global_position

func _arrive() -> void:
	mode = Mode.IDLE
	_steer_dir = Vector3.ZERO
	if activity == "sleep":
		_go_indoors()
		return
	_idle_action = _action_at_spot()
	_pause = _rng.randf_range(3.5, 8.0) if _idle_action != "idle" else _rng.randf_range(2.0, 5.0)
	if activity == "rest":
		_pause = _rng.randf_range(5.0, 11.0)
		_face_nearest_neighbour()

## What the villager does while standing at a spot.
func _action_at_spot() -> String:
	if activity != "work":
		return "idle"
	var at_post := _spot_idx == 0
	if (role == "blacksmith" or service_type == "forge") and at_post:
		return "work_hammer"
	if service_type == "healer" and at_post:
		return "work_pray"
	if role == "guard" or guild_role == "master" or guild_role == "trainer":
		return "idle_combat" if at_post else "idle"
	if role == "farmer" and not at_post:
		return "interact"
	return "idle"

func _play_idle(action: String) -> void:
	if visual == null:
		return
	if action != "idle" and not visual.has_state(action):
		action = "idle"
	visual.play(action)

func _walk(delta: float) -> void:
	var to_target := _target - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	if dist <= ARRIVE_DISTANCE:
		_arrive()
		return
	_steer_accum += delta
	if _steer_accum >= STEER_INTERVAL or _steer_dir == Vector3.ZERO:
		_steer_accum = 0.0
		_steer_dir = _steer(to_target / dist)
		if _steer_dir == Vector3.ZERO:
			# Boxed in: stand a moment, then try somewhere else.
			mode = Mode.IDLE
			_idle_action = "idle"
			_pause = _rng.randf_range(1.0, 2.5)
			if activity == "sleep":
				_go_indoors()
			return
	var step := minf(SPEED * model_scale * delta, dist)
	var next_pos := global_position + _steer_dir * step
	if not _indoor:
		var terrain := _terrain()
		if terrain != null:
			next_pos.y = terrain.height_at(next_pos.x, next_pos.z)
	global_position = next_pos
	_face(global_position + _steer_dir, delta, 9.0)
	if visual != null:
		visual.play("walk")
	# Not getting anywhere (walking round an obstacle forever): give up on it.
	_stuck_time += delta
	if _stuck_time >= 2.0:
		if global_position.distance_to(_stuck_from) < 0.6:
			mode = Mode.IDLE
			_idle_action = "idle"
			_pause = _rng.randf_range(0.8, 2.0)
			if activity == "sleep":
				_go_indoors()
		_stuck_time = 0.0
		_stuck_from = global_position

func _face(point: Vector3, delta: float, speed: float) -> void:
	var to := point - global_position
	to.y = 0.0
	if to.length_squared() < 0.0004:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(speed * delta, 0.0, 1.0))

func _face_nearest_neighbour() -> void:
	var best: Node3D = null
	var best_d := 5.0 * 5.0
	for n: Node in get_tree().get_nodes_in_group("npc"):
		if n == self or not (n is Node3D):
			continue
		var d := global_position.distance_squared_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n as Node3D
	if best != null:
		var to := best.global_position - global_position
		rotation.y = atan2(-to.x, -to.z)

func _begin_attend() -> void:
	mode = Mode.ATTEND
	_steer_dir = Vector3.ZERO
	if _greet_cooldown <= 0.0:
		_greet_cooldown = GREET_COOLDOWN
		say(_pick_greeting())
		if visual != null and visual.has_state("cheer") and _rng.randf() < 0.6:
			visual.play("cheer", true)

func _pick_greeting() -> String:
	var key := role
	if not guild_role.is_empty():
		key = "guild"
	elif has_shop and role != "blacksmith":
		key = "merchant"
	elif service_type == "healer":
		key = "healer"
	var entry: Array = GREETINGS.get(key, GREETINGS["default"])
	var lines: Array = entry[0] if Localization.is_arabic() else entry[1]
	return String(lines[_rng.randi_range(0, lines.size() - 1)])

## Shows a short line above the villager's head for a few seconds.
func say(text: String, seconds: float = 2.8) -> void:
	if _bubble == null or text.is_empty():
		return
	_bubble.text = text
	_bubble.visible = true
	_bubble_time = seconds

func _go_indoors() -> void:
	mode = Mode.INDOORS
	if visual != null:
		visual.visible = false
	if _nameplate != null:
		_nameplate.visible = false
	if _quest_marker != null:
		_quest_marker.visible = false
	if _body != null:
		_body.collision_layer = 0
	enabled = false

func _come_outside() -> void:
	if visual != null:
		visual.visible = true
	if _nameplate != null:
		_nameplate.visible = true
	if _body != null:
		_body.collision_layer = CollisionLayers.NPC
	enabled = true
	_refresh_marker()

func _terrain() -> Terrain:
	if not is_instance_valid(_shared_terrain):
		var world_root := get_tree().get_first_node_in_group("world_root")
		_shared_terrain = (world_root.get("terrain") as Terrain) if world_root != null else null
	return _shared_terrain

func _ray_blocked(from_pos: Vector3, to_pos: Vector3) -> bool:
	var w3d := get_world_3d()
	if w3d == null or w3d.direct_space_state == null:
		return false
	var q := PhysicsRayQueryParameters3D.create(from_pos, to_pos, CollisionLayers.ENVIRONMENT | CollisionLayers.NPC)
	if _body != null:
		q.exclude = [_body.get_rid()]
	return not w3d.direct_space_state.intersect_ray(q).is_empty()

## True when something solid stands between two ground points. The ray runs at
## knee height above the terrain at each end, so slopes do not count as walls.
func _segment_blocked(from_pos: Vector3, to_pos: Vector3) -> bool:
	var a := from_pos
	var b := to_pos
	if not _indoor:
		var terrain := _terrain()
		if terrain != null:
			a.y = terrain.height_at(a.x, a.z)
			b.y = terrain.height_at(b.x, b.z)
	return _ray_blocked(a + Vector3(0.0, 0.45, 0.0), b + Vector3(0.0, 0.45, 0.0))

## Direction to walk this instant: straight at the target when the way is
## clear, otherwise the first open direction to either side. Vector3.ZERO
## means every direction is blocked.
func _steer(desired: Vector3) -> Vector3:
	var look := 0.9
	if not _segment_blocked(global_position, global_position + desired * look):
		return desired
	for ang: float in [0.6, -0.6, 1.2, -1.2, 1.8, -1.8]:
		var alt := desired.rotated(Vector3.UP, ang)
		if not _segment_blocked(global_position, global_position + alt * look):
			return alt
	return Vector3.ZERO

func can_interact(_player: Node) -> bool:
	return enabled and mode != Mode.INDOORS

func prompt_for(_player: Node) -> String:
	var nm := Localization.npc_name(npc_id, display_name)
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
	_wants_marker = false
	_needed_now = false
	for quest: QuestData in QuestDB.quests_involving_npc(npc_id):
		var st := GameManager.quest_log.state_of(quest.id)
		if st == QuestLog.STATE_READY and quest.turn_in_npc == npc_id:
			_needed_now = true
			_show_marker("?", Color(0.42, 0.96, 0.55))
			return
		if st == QuestLog.STATE_ACTIVE and quest.turn_in_npc == npc_id:
			_needed_now = true
		if st == QuestLog.STATE_NOT_STARTED and quest.giver_npc == npc_id:
			if not quest.is_guild_contract or GameManager.guild.meets_rank(quest.required_guild_rank):
				if quest.is_main_quest:
					_needed_now = true
				_show_marker("!", Color(1.0, 0.85, 0.25))
				return
	if guild_role == "receptionist" and (not GameManager.guild.registered or GameManager.guild.can_promote(GameManager.progression.level)):
		_show_marker("★", Color(0.45, 0.82, 1.0))
		return
	_quest_marker.visible = false

func _show_marker(symbol: String, color: Color) -> void:
	_wants_marker = true
	_quest_marker.text = symbol
	_quest_marker.modulate = color
	_quest_marker.visible = mode != Mode.INDOORS
	if mode == Mode.INDOORS and _needed_now:
		# Somebody the player needs: come back out.
		_come_outside()
		mode = Mode.IDLE
		_pause = 0.5
