class_name GuildSystem
extends RefCounted
## Adventurers Guild progression, registration, reputation, and Rank F -> S
## management. Connected to QuestDB / GameManager / SaveManager.

const RANKS: Array[String] = ["F", "E", "D", "C", "B", "A", "S"]

const RANK_REQUIREMENTS := {
	"F": {"rep": 0, "level": 1, "contracts": 0, "title": "Novice Adventurer", "bonus_gold": 15, "reward_item": "health_potion"},
	"E": {"rep": 80, "level": 1, "contracts": 1, "title": "Bronze Scout", "bonus_gold": 40, "reward_item": "mana_elixir"},
	"D": {"rep": 200, "level": 3, "contracts": 3, "title": "Iron Vanguard", "bonus_gold": 75, "reward_item": "oak_shield"},
	"C": {"rep": 380, "level": 5, "contracts": 5, "title": "Silver Pathfinder", "bonus_gold": 130, "reward_item": "guild_ring"},
	"B": {"rep": 650, "level": 8, "contracts": 8, "title": "Gold Sentinel", "bonus_gold": 220, "reward_item": "guild_aegis"},
	"A": {"rep": 1050, "level": 11, "contracts": 11, "title": "Mythril Champion", "bonus_gold": 360, "reward_item": "knight_plate"},
	"S": {"rep": 1600, "level": 14, "contracts": 15, "title": "Grand Legend of Eldoria", "bonus_gold": 600, "reward_item": "eldoria_mythic_blade"},
}

var registered: bool = false
var rank_index: int = 0   # 0 = F .. 6 = S
var reputation: int = 0
var contracts_completed: int = 0

func current_rank() -> String:
	if not registered:
		return "Unregistered"
	return RANKS[clampi(rank_index, 0, RANKS.size() - 1)]

func rank_title() -> String:
	if not registered:
		return "Unregistered Traveler"
	var r := current_rank()
	return String((RANK_REQUIREMENTS.get(r, {}) as Dictionary).get("title", "Adventurer"))

static func index_of_rank(rank_letter: String) -> int:
	var idx := RANKS.find(rank_letter)
	return maxi(0, idx)

func meets_rank(required_rank: String) -> bool:
	if not registered:
		return false
	return rank_index >= index_of_rank(required_rank)

func register_adventurer() -> bool:
	if registered:
		return false
	registered = true
	rank_index = 0
	reputation = maxi(reputation, 10)
	return true

func register_member() -> bool:
	return register_adventurer()

func add_reputation(amount: int) -> void:
	if amount <= 0:
		return
	reputation += amount

func active_contract_limit() -> int:
	return 2 + mini(rank_index, 4)

func can_accept_more_contracts(active_count: int) -> bool:
	return registered and active_count < active_contract_limit()

func next_rank() -> String:
	if not registered:
		return "F"
	if rank_index + 1 >= RANKS.size():
		return ""
	return RANKS[rank_index + 1]

func next_promotion_requirements() -> Dictionary:
	var nxt := next_rank()
	if nxt.is_empty():
		return {}
	var req: Dictionary = RANK_REQUIREMENTS[nxt]
	return {
		"next_rank": nxt,
		"rep": int(req["rep"]),
		"level": int(req["level"]),
		"contracts": int(req.get("contracts", 1)),
	}

func can_promote(player_level: int = -1) -> bool:
	if not registered or rank_index + 1 >= RANKS.size():
		return false
	var lv := player_level
	if lv < 0 and GameManager != null and GameManager.progression != null:
		lv = GameManager.progression.level
	var nxt := RANKS[rank_index + 1]
	var req: Dictionary = RANK_REQUIREMENTS[nxt]
	if lv > 0 and lv < int(req["level"]):
		return false
	return reputation >= int(req["rep"]) and contracts_completed >= int(req.get("contracts", 0))

func promote(player_level: int = -1) -> Variant:
	if not can_promote(player_level):
		return {}
	rank_index += 1
	var new_rank := RANKS[rank_index]
	var req: Dictionary = RANK_REQUIREMENTS[new_rank]
	return {
		"rank": new_rank,
		"title": req["title"],
		"gold": req["bonus_gold"],
		"item": req["reward_item"],
	}

func available_contracts() -> Array[QuestData]:
	QuestDB.ensure_loaded()
	var out: Array[QuestData] = []
	for q: QuestData in QuestDB.all_quests():
		if q.is_guild_contract:
			out.append(q)
	out.sort_custom(func(a: QuestData, b: QuestData) -> bool:
		var ra := index_of_rank(a.required_guild_rank)
		var rb := index_of_rank(b.required_guild_rank)
		if ra != rb:
			return ra < rb
		return a.id < b.id)
	return out

func shop_discount_multiplier() -> float:
	if not registered:
		return 1.0
	return clampf(1.0 - float(rank_index) * 0.03, 0.80, 1.0)

func to_dict() -> Dictionary:
	return {
		"registered": registered,
		"rank_index": rank_index,
		"reputation": reputation,
		"contracts_completed": contracts_completed,
	}

func from_dict(data: Dictionary) -> void:
	registered = bool(data.get("registered", false))
	rank_index = clampi(int(data.get("rank_index", 0)), 0, RANKS.size() - 1)
	reputation = maxi(0, int(data.get("reputation", 0)))
	contracts_completed = maxi(0, int(data.get("contracts_completed", 0)))
