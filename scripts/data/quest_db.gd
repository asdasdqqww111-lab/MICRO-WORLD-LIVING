class_name QuestDB
extends RefCounted
## Loads quest .tres resources and registers the expanded 24-Quest Royal City
## Storyline, District Side-Quests, and Ranks F–S Guild Contracts.

const QUEST_DIR := "res://resources/quests"

static var _quests: Dictionary = {}
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_quests.clear()
	var dir := DirAccess.open(QUEST_DIR)
	if dir != null:
		for file_name: String in dir.get_files():
			if not file_name.ends_with(".tres"):
				continue
			var res: Resource = ResourceLoader.load(QUEST_DIR + "/" + file_name)
			if res is QuestData:
				var quest: QuestData = res
				if quest.id.is_empty():
					quest.id = file_name.get_basename()
				_quests[quest.id] = quest
	_register_royal_city_quests()

static func _register_royal_city_quests() -> void:
	var defs: Array[Dictionary] = [
		{
			"id": "city_citadel_camp",
			"title": "Banner of the Royal Citadel",
			"desc": "Commander Vaelen at the Northwest Royal Citadel asks you to scout the Western Monster Camp and eliminate two Bramble Stalkers threatening the forest road.",
			"giver": "citadel_commander", "turn_in": "citadel_commander",
			"main": true, "guild": false, "cat": "story", "rank": "F",
			"objs": [
				{"type": "visit", "target": "monster_camp", "required": 1, "label": "Scout Western Monster Camp"},
				{"type": "kill", "target": "forest_goblin", "required": 2, "label": "Bramble Stalkers defeated"},
			],
			"xp": 140, "gold": 65, "rep": 45,
			"items": [{"id": "iron_helmet", "count": 1}],
		},
		{
			"id": "city_alchemist_slime",
			"title": "Elixirs of the Arcane Conservatory",
			"desc": "Master Alchemist Zenia in the Arcane Conservatory needs fresh Slime Gel from Crystal Lake to brew royal mana elixirs.",
			"giver": "alchemist_master", "turn_in": "alchemist_master",
			"main": false, "guild": false, "cat": "gathering", "rank": "F",
			"objs": [
				{"type": "kill", "target": "slime", "required": 2, "label": "Crystal Lake Slimes defeated"},
				{"type": "collect", "target": "slime_gel", "required": 2, "label": "Slime Gel collected"},
			],
			"xp": 110, "gold": 45, "rep": 35,
			"items": [{"id": "mana_elixir", "count": 2}],
		},
		{
			"id": "city_jeweler_pelts",
			"title": "Pelts for the East Exchange",
			"desc": "Royal Jeweler Nader at the East Trade Exchange commissions two fine Wolf Pelts for noble cloaks.",
			"giver": "bazaar_jeweler", "turn_in": "bazaar_jeweler",
			"main": false, "guild": false, "cat": "hunting", "rank": "F",
			"objs": [
				{"type": "kill", "target": "wolf", "required": 2, "label": "Grey Wolves hunted"},
				{"type": "collect", "target": "wolf_pelt", "required": 2, "label": "Wolf Pelts delivered"},
			],
			"xp": 125, "gold": 60, "rep": 40,
			"items": [{"id": "guild_ring", "count": 1}],
		},
		{
			"id": "city_archery_wolves",
			"title": "Garrison Timberline Patrol",
			"desc": "Archery Captain Selene needs an able fighter to thin out the Grey Wolf pack prowling the northern timberline.",
			"giver": "archery_captain", "turn_in": "archery_captain",
			"main": false, "guild": false, "cat": "hunting", "rank": "F",
			"objs": [
				{"type": "kill", "target": "wolf", "required": 3, "label": "Timberline Wolves slain"},
			],
			"xp": 135, "gold": 55, "rep": 40,
			"items": [{"id": "leather_armor", "count": 1}],
		},
		{
			"id": "city_north_cave_sweep",
			"title": "Watch on the Northern Crags",
			"desc": "Sentinel Rakan at the North City Gate reports Shadowfang Bats swarming travelers descending from the Alpine Pass.",
			"giver": "north_sentinel", "turn_in": "north_sentinel",
			"main": false, "guild": false, "cat": "hunting", "rank": "F",
			"objs": [
				{"type": "kill", "target": "cave_bat", "required": 3, "label": "Shadowfang Bats slain"},
			],
			"xp": 125, "gold": 50, "rep": 35,
			"items": [{"id": "health_potion", "count": 2}],
		},
		{
			"id": "city_west_timber_aid",
			"title": "Timber for the West Ramparts",
			"desc": "Warden Layan at the West Woodland Gate requires seasoned oak timber to reinforce the city palisades.",
			"giver": "west_warden", "turn_in": "west_warden",
			"main": false, "guild": false, "cat": "gathering", "rank": "F",
			"objs": [
				{"type": "collect", "target": "wood", "required": 4, "label": "Seasoned Timber gathered"},
			],
			"xp": 95, "gold": 40, "rep": 30,
			"items": [{"id": "oak_shield", "count": 1}],
		},
		{
			"id": "city_apprentice_ingots",
			"title": "Toma's Royal Smelting Trial",
			"desc": "Smith's Apprentice Toma wants to prove his craft to Master Grim. Smelt or gather two Iron Ingots and bring them to Toma.",
			"giver": "apprentice", "turn_in": "apprentice",
			"main": false, "guild": false, "cat": "crafting", "rank": "F",
			"objs": [
				{"type": "collect", "target": "iron_ingot", "required": 2, "label": "Iron Ingots forged or found"},
			],
			"xp": 115, "gold": 50, "rep": 35,
			"items": [{"id": "iron_sword", "count": 1}],
		},
		{
			"id": "city_innkeeper_feast",
			"title": "Banquet of the Hearthstone Inn",
			"desc": "Innkeeper Marta is preparing a Royal City banquet! Bring her two cuts of Venison and two Redcap Herbs.",
			"giver": "innkeeper", "turn_in": "innkeeper",
			"main": false, "guild": false, "cat": "gathering", "rank": "F",
			"objs": [
				{"type": "collect", "target": "venison", "required": 2, "label": "Venison cuts gathered"},
				{"type": "collect", "target": "herb_redcap", "required": 2, "label": "Redcap Herbs gathered"},
			],
			"xp": 105, "gold": 45, "rep": 35,
			"items": [{"id": "bread", "count": 3}],
		},
		{
			"id": "city_ranger_grove",
			"title": "Guardian of the Sacred Grove",
			"desc": "Woodland Ranger Rowan speaks of an ancient corrupted Guardian awakening in the Southwest Sacred Grove. Venture there and restore peace.",
			"giver": "hunter", "turn_in": "hunter",
			"main": true, "guild": false, "cat": "story", "rank": "E",
			"objs": [
				{"type": "visit", "target": "sacred_grove", "required": 1, "label": "Reach the Sacred Ancient Grove"},
				{"type": "kill", "target": "grove_guardian", "required": 1, "label": "Defeat the Corrupted Grove Warden"},
			],
			"xp": 195, "gold": 90, "rep": 55,
			"items": [{"id": "steel_greatsword", "count": 1}],
		},
		{
			"id": "city_scholar_golem",
			"title": "Colossus of the Eastern Crags",
			"desc": "Wayfaring Scholar Vane near the East Stone Bridge asks you to neutralize two living Granite Golems blocking the ruins road.",
			"giver": "traveler", "turn_in": "traveler",
			"main": false, "guild": false, "cat": "hunting", "rank": "E",
			"objs": [
				{"type": "kill", "target": "rock_golem", "required": 2, "label": "Granite Golems shattered"},
			],
			"xp": 180, "gold": 80, "rep": 50,
			"items": [{"id": "iron_shield", "count": 1}],
		},
		{
			"id": "contract_rank_b_golem",
			"title": "[Rank B] Shatter the Granite Sentinels",
			"desc": "High-Rank Guild Contract: Destroy two Granite Golems on the eastern crags and bring back three chunks of Highland Iron Ore.",
			"giver": "guild_receptionist", "turn_in": "guild_receptionist",
			"main": false, "guild": true, "cat": "hunting", "rank": "B",
			"objs": [
				{"type": "kill", "target": "rock_golem", "required": 2, "label": "Granite Golems destroyed"},
				{"type": "collect", "target": "iron_ore", "required": 3, "label": "Highland Iron Ore recovered"},
			],
			"xp": 220, "gold": 100, "rep": 75,
			"items": [{"id": "health_potion", "count": 2}, {"id": "mana_elixir", "count": 2}],
		},
		{
			"id": "contract_rank_a_wraith",
			"title": "[Rank A] Purge the Ancient Phantoms",
			"desc": "Elite Guild Contract: Banish both the Ruins Wraith in the east and the Corrupted Grove Warden in the southwest.",
			"giver": "guild_master", "turn_in": "guild_master",
			"main": false, "guild": true, "cat": "boss", "rank": "A",
			"objs": [
				{"type": "kill", "target": "wraith_elite", "required": 1, "label": "Banish the Ruins Wraith"},
				{"type": "kill", "target": "grove_guardian", "required": 1, "label": "Subdue the Grove Warden"},
			],
			"xp": 290, "gold": 145, "rep": 95,
			"items": [{"id": "guild_aegis", "count": 1}],
		},
		{
			"id": "main_sovereign_champion",
			"title": "Crowned Champion of Royal Eldoria",
			"desc": "Grandmaster Aldric calls upon Eldoria's finest hero: descend into the Sunken Crypt, vanquish Malakor the Bone Warden, and claim the Mythic Sunblade!",
			"giver": "guild_master", "turn_in": "guild_master",
			"main": true, "guild": false, "cat": "story", "rank": "C",
			"objs": [
				{"type": "kill", "target": "crypt_boss", "required": 1, "label": "Vanquish Malakor the Bone Warden"},
				{"type": "collect", "target": "crypt_heart", "required": 1, "label": "Claim the Dark Crypt Heart"},
			],
			"xp": 420, "gold": 260, "rep": 130,
			"items": [{"id": "eldoria_mythic_blade", "count": 1}],
		},
	]
	for d: Dictionary in defs:
		var qid := String(d["id"])
		if _quests.has(qid):
			continue
		var q := QuestData.new()
		q.id = qid
		q.title = String(d["title"])
		q.description = String(d["desc"])
		q.giver_npc = String(d["giver"])
		q.turn_in_npc = String(d["turn_in"])
		q.is_main_quest = bool(d["main"])
		q.is_guild_contract = bool(d["guild"])
		q.contract_category = String(d["cat"])
		q.required_guild_rank = String(d["rank"])
		q.objectives = d["objs"] as Array
		q.reward_xp = int(d["xp"])
		q.reward_gold = int(d["gold"])
		q.reward_reputation = int(d["rep"])
		q.reward_items = d["items"] as Array
		_quests[qid] = q

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
