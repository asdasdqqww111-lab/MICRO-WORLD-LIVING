class_name QuestManager
extends RefCounted
## Clean Resource-driven Quest System Facade (Godot equivalent of Unity ScriptableObject QuestManager):
##   - Queries Resource-based QuestData definitions via QuestDB
##   - Tracks active / ready-to-turn-in / completed states via GameManager.quest_log
##   - Dispatches progress updates & grants XP, Gold, Guild Reputation, and Item rewards

static func all_quests() -> Array:
	return QuestDB.all_quests()

static func get_quest(quest_id: String) -> QuestData:
	return QuestDB.get_quest(quest_id)

static func active_quests() -> Array[QuestData]:
	var out: Array[QuestData] = []
	if GameManager == null or GameManager.quest_log == null:
		return out
	for qid: String in GameManager.quest_log.tracked_quests():
		var q := QuestDB.get_quest(qid)
		if q != null:
			out.append(q)
	return out

static func accept_quest(quest_id: String) -> bool:
	if GameManager == null:
		return false
	return GameManager.start_quest(quest_id)

static func can_turn_in(quest_id: String) -> bool:
	if GameManager == null or GameManager.quest_log == null:
		return false
	return GameManager.quest_log.can_turn_in(quest_id)

static func complete_quest(quest_id: String) -> bool:
	if GameManager == null:
		return false
	return GameManager.turn_in_quest(quest_id)

static func objective_ratio(quest_id: String, obj_index: int) -> float:
	var q := QuestDB.get_quest(quest_id)
	if q == null or obj_index < 0 or obj_index >= q.objectives.size() or GameManager == null:
		return 0.0
	var req := maxi(1, int((q.objectives[obj_index] as Dictionary).get("required", 1)))
	var cur := GameManager.quest_log.objective_progress(quest_id, obj_index)
	return clampf(float(cur) / float(req), 0.0, 1.0)
