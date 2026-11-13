class_name QuestData
extends Resource
## Data-driven quest & Adventurers Guild contract definition (resources/quests/*.tres).
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
@export var reward_items: Array = []
@export var is_main_quest: bool = false
@export var is_guild_contract: bool = false
@export var contract_category: String = "hunting"
@export var required_guild_rank: String = "F"
@export var reward_reputation: int = 35
@export var story_flag_on_complete: String = ""

func objective_count() -> int:
	return objectives.size()
