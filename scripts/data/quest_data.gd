class_name QuestData
extends Resource
## Data-driven quest definition (resources/quests/*.tres).
## objectives entries: {"type": "kill"|"collect"|"visit",
##                      "target": String, "required": int, "label": String}

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var giver_npc: String = ""
@export var turn_in_npc: String = ""
@export var objectives: Array = []
@export var reward_xp: int = 0
@export var reward_gold: int = 0
@export var reward_items: Array = []   # [{"id": String, "count": int}]

func objective_count() -> int:
	return objectives.size()
