class_name QuestDB
extends RefCounted

const QUEST_DIR := "res://resources/quests"

static var _quests: Dictionary = {}
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_quests.clear()
	var dir := DirAccess.open(QUEST_DIR)
	if dir == null:
		push_warning("QuestDB: missing " + QUEST_DIR)
		return
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res: Resource = ResourceLoader.load(QUEST_DIR + "/" + file_name)
		if res is QuestData:
			var quest: QuestData = res
			if quest.id.is_empty():
				quest.id = file_name.get_basename()
			_quests[quest.id] = quest

static func reload() -> void:
	_loaded = false
	ensure_loaded()

static func get_quest(quest_id: String) -> QuestData:
	ensure_loaded()
	return _quests.get(quest_id, null) as QuestData

static func all_quests() -> Array:
	ensure_loaded()
	return _quests.values()

static func count() -> int:
	ensure_loaded()
	return _quests.size()

static func quests_for_npc(npc_id: String) -> Array:
	ensure_loaded()
	var out: Array = []
	for quest: QuestData in _quests.values():
		if quest.giver_npc == npc_id:
			out.append(quest)
	return out

## Returns quests where `npc_id` is either the quest giver OR turn-in NPC!
static func quests_involving_npc(npc_id: String) -> Array:
	ensure_loaded()
	var out: Array = []
	for quest: QuestData in _quests.values():
		if quest.giver_npc == npc_id or quest.turn_in_npc == npc_id:
			out.append(quest)
	return out
