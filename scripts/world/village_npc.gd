class_name VillageNPC
extends Interactable
## Villager with a simple 3-state daily schedule and quest/shop dialog.

const SPEED := 1.5

var npc_id: String = ""
var display_name: String = ""
var role: String = "villager"
var model_path: String = ""
var model_scale: float = 1.0
var dialog_lines: Array = []
var schedule: Dictionary = {}     # {"work": Vector3, "rest": Vector3, "sleep": Vector3}
var visual: CharacterVisual
var activity: String = "work"

var _target: Vector3 = Vector3.ZERO
var _idle_time: float = 0.0

func setup(id: String, name: String, npc_role: String, path: String, positions: Dictionary) -> void:
	npc_id = id
	display_name = name
	role = npc_role
	model_path = path
	schedule = positions
	prompt_text = "Talk to %s" % name
	_target = positions.get("work", Vector3.ZERO) as Vector3

func _ready() -> void:
	super._ready()
	add_to_group("npc")
	interaction_radius = 2.8
	_build_visual()
	if schedule.is_empty():
		schedule = {"work": global_position, "rest": global_position, "sleep": global_position}

func _build_visual() -> void:
	visual = CharacterVisual.new()
	visual.name = "Visual"
	visual.rotation.y = PI
	add_child(visual)
	if model_path.is_empty() or not visual.setup(model_path, model_scale):
		var fallback := ProceduralModels.build("slime")
		add_child(fallback)
	else:
		visual.play("idle")

## Schedule: work 06-18, rest 18-22, sleep 22-06.
static func activity_for_hour(hour: int) -> String:
	if hour >= 22 or hour < 6:
		return "sleep"
	if hour >= 18:
		return "rest"
	return "work"

func _process(delta: float) -> void:
	var new_activity := activity_for_hour(GameManager.world.hour())
	if new_activity != activity:
		activity = new_activity
		_target = schedule.get(activity, global_position) as Vector3
		GameManager.world.npc_overrides[npc_id] = activity
	if not GameManager.world.npc_overrides.has(npc_id):
		GameManager.world.npc_overrides[npc_id] = activity

	var to_target := _target - global_position
	to_target.y = 0.0
	if to_target.length() > 0.35:
		var dir := to_target.normalized()
		global_position += dir * minf(SPEED * delta, to_target.length())
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.12)
		if visual != null:
			visual.play("walk")
		_idle_time = 0.0
	else:
		_idle_time += delta
		if visual != null:
			match activity:
				"sleep":
					visual.play("lie")
				"rest":
					visual.play("sit")
				_:
					visual.play("idle")

func can_interact(_player: Node) -> bool:
	return activity != "sleep"

func prompt_for(_player: Node) -> String:
	if activity == "sleep":
		return "%s is asleep" % display_name
	return "Talk to %s" % display_name

func interact(player: Node) -> void:
	if player is Node3D:
		var to_player := (player as Node3D).global_position - global_position
		if to_player.length() > 0.1:
			rotation.y = atan2(-to_player.x, -to_player.z)
	EventBus.dialog_requested.emit(self)

## Dialog payload consumed by the UI layer.
func dialog_payload() -> Dictionary:
	var actions: Array = []
	for quest: QuestData in QuestDB.quests_for_npc(npc_id):
		match GameManager.quest_log.state_of(quest.id):
			QuestLog.STATE_NOT_STARTED:
				actions.append({"type": "quest_offer", "quest_id": quest.id, "label": "Quest: %s" % quest.title})
			QuestLog.STATE_ACTIVE:
				actions.append({"type": "quest_progress", "quest_id": quest.id, "label": "About: %s" % quest.title})
			QuestLog.STATE_READY:
				actions.append({"type": "quest_turnin", "quest_id": quest.id, "label": "Turn in: %s" % quest.title})
	if role == "blacksmith":
		actions.append({"type": "shop", "label": "Trade with %s" % display_name})
	actions.append({"type": "close", "label": "Leave"})
	return {
		"npc_id": npc_id,
		"name": display_name,
		"role": role,
		"lines": _contextual_lines(),
		"actions": actions,
	}

func _contextual_lines() -> Array:
	var lines: Array = []
	for quest: QuestData in QuestDB.quests_for_npc(npc_id):
		match GameManager.quest_log.state_of(quest.id):
			QuestLog.STATE_READY:
				lines.append("%s: You actually did it. Here, take this." % quest.title)
			QuestLog.STATE_COMPLETED:
				lines.append("%s: Thank you again, friend." % quest.title)
	for line: String in dialog_lines:
		lines.append(line)
	return lines

## Executes a dialog action, returns an optional status line for the UI.
func execute_action(action: Dictionary) -> String:
	match String(action.get("type", "")):
		"quest_offer":
			var quest_id := String(action.get("quest_id", ""))
			if GameManager.start_quest(quest_id):
				var quest := QuestDB.get_quest(quest_id)
				return "Quest started: %s" % (quest.title if quest != null else quest_id)
			return "You cannot take that quest right now."
		"quest_progress":
			var quest := QuestDB.get_quest(String(action.get("quest_id", "")))
			if quest == null:
				return ""
			var parts: PackedStringArray = []
			for i: int in quest.objectives.size():
				var objective: Dictionary = quest.objectives[i]
				parts.append("%s: %d/%d" % [String(objective.get("label", "Objective")),
					GameManager.quest_log.objective_progress(quest.id, i),
					int(objective.get("required", 1))])
			return " | ".join(parts)
		"quest_turnin":
			var quest_id := String(action.get("quest_id", ""))
			var quest := QuestDB.get_quest(quest_id)
			if GameManager.turn_in_quest(quest_id):
				return "Reward: %d xp, %d gold" % [quest.reward_xp, quest.reward_gold] if quest != null else "Reward granted"
			return "Finish the objectives first."
		"shop":
			EventBus.shop_requested.emit(self)
			return ""
		"close":
			return ""
	return ""
