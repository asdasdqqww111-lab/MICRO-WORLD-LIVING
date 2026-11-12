class_name QuestLog
extends RefCounted
## Quest state machine: NOT_STARTED -> ACTIVE -> READY -> COMPLETED.

const STATE_NOT_STARTED := 0
const STATE_ACTIVE := 1
const STATE_READY := 2
const STATE_COMPLETED := 3

var entries: Dictionary = {}   # quest_id -> {"state": int, "progress": Array}

func state_of(quest_id: String) -> int:
	var entry: Dictionary = entries.get(quest_id, {})
	return int(entry.get("state", STATE_NOT_STARTED))

func is_active(quest_id: String) -> bool:
	var s := state_of(quest_id)
	return s == STATE_ACTIVE or s == STATE_READY

func can_turn_in(quest_id: String) -> bool:
	return state_of(quest_id) == STATE_READY

func start_quest(quest_id: String) -> bool:
	var quest := QuestDB.get_quest(quest_id)
	if quest == null:
		push_warning("QuestLog: unknown quest '%s'" % quest_id)
		return false
	if state_of(quest_id) != STATE_NOT_STARTED:
		return false
	var progress: Array = []
	for _objective: Dictionary in quest.objectives:
		progress.append(0)
	entries[quest_id] = {"state": STATE_ACTIVE, "progress": progress}
	EventBus.quest_started.emit(quest_id)
	EventBus.quest_updated.emit(quest_id)
	return true

## type: "kill" | "collect" | "visit"; target: creature/item/zone id.
func record_event(type: String, target: String, amount: int = 1) -> void:
	var any_change := false
	for quest_id: String in entries.keys():
		var entry: Dictionary = entries[quest_id]
		if int(entry.get("state", STATE_NOT_STARTED)) != STATE_ACTIVE:
			continue
		var quest := QuestDB.get_quest(quest_id)
		if quest == null:
			continue
		var progress: Array = entry.get("progress", [])
		var changed_this_quest := false
		for i: int in quest.objectives.size():
			var objective: Dictionary = quest.objectives[i]
			if String(objective.get("type", "")) != type:
				continue
			if String(objective.get("target", "")) != target:
				continue
			var required := int(objective.get("required", 1))
			var current := int(progress[i]) if i < progress.size() else 0
			if current >= required:
				continue
			progress[i] = mini(required, current + amount)
			changed_this_quest = true
		if changed_this_quest:
			entry["progress"] = progress
			entries[quest_id] = entry
			any_change = true
			EventBus.quest_updated.emit(quest_id)
			if _all_objectives_done(quest_id):
				entry["state"] = STATE_READY
				entries[quest_id] = entry
				EventBus.quest_ready_to_turn_in.emit(quest_id)
	if any_change:
		pass

func _all_objectives_done(quest_id: String) -> bool:
	var quest := QuestDB.get_quest(quest_id)
	if quest == null:
		return false
	var entry: Dictionary = entries.get(quest_id, {})
	var progress: Array = entry.get("progress", [])
	for i: int in quest.objectives.size():
		var required := int((quest.objectives[i] as Dictionary).get("required", 1))
		var current := int(progress[i]) if i < progress.size() else 0
		if current < required:
			return false
	return true

func complete_quest(quest_id: String) -> bool:
	if not can_turn_in(quest_id):
		return false
	var entry: Dictionary = entries[quest_id]
	entry["state"] = STATE_COMPLETED
	entries[quest_id] = entry
	EventBus.quest_completed.emit(quest_id)
	EventBus.quest_updated.emit(quest_id)
	return true

func objective_progress(quest_id: String, index: int) -> int:
	var entry: Dictionary = entries.get(quest_id, {})
	var progress: Array = entry.get("progress", [])
	return int(progress[index]) if index < progress.size() else 0

func objectives_done(quest_id: String, index: int) -> bool:
	var quest := QuestDB.get_quest(quest_id)
	if quest == null or index >= quest.objectives.size():
		return false
	var required := int((quest.objectives[index] as Dictionary).get("required", 1))
	return objective_progress(quest_id, index) >= required

func tracked_quests() -> Array:
	var out: Array = []
	for quest_id: String in entries.keys():
		if is_active(quest_id):
			out.append(quest_id)
	out.sort()
	return out

func completed_quests() -> Array:
	var out: Array = []
	for quest_id: String in entries.keys():
		if state_of(quest_id) == STATE_COMPLETED:
			out.append(quest_id)
	out.sort()
	return out

func to_dict() -> Dictionary:
	return {
		"entries": entries.duplicate(true),
		"completed": completed_quests(),
	}

func from_dict(data: Dictionary) -> void:
	entries.clear()
	var raw: Dictionary = data.get("entries", {})
	for quest_id: String in raw.keys():
		if QuestDB.get_quest(quest_id) == null:
			continue
		var entry: Dictionary = raw[quest_id]
		var state := clampi(int(entry.get("state", STATE_NOT_STARTED)), STATE_NOT_STARTED, STATE_COMPLETED)
		var progress: Array = []
		for value: Variant in entry.get("progress", []):
			progress.append(int(value))
		entries[quest_id] = {"state": state, "progress": progress}
