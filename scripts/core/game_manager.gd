extends Node
## Owns the authoritative player/world state (autoload: GameManager).
## Nodes (player, world, UI) are views over this state.

const SAVE_VERSION := 3
const STARTING_GOLD := 30
const STARTING_ITEMS := [
	{"id": "rusty_sword", "count": 1},
	{"id": "bread", "count": 2},
	{"id": "health_potion", "count": 1},
]

var stats: CharacterStats
var progression: Progression
var inventory: Inventory
var quest_log: QuestLog
var skills: SkillTree
var world: WorldState

var gold: int = STARTING_GOLD
var play_time: float = 0.0
var is_playing: bool = false
var pending_zone: String = ""
var last_death_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	reset_state()
	EventBus.creature_died.connect(_on_creature_died)
	EventBus.item_picked_up.connect(_on_item_picked_up)

func reset_state() -> void:
	ItemDB.ensure_loaded()
	QuestDB.ensure_loaded()
	SkillDB.ensure_loaded()
	CreatureDB.ensure_loaded()
	stats = CharacterStats.new()
	progression = Progression.new()
	inventory = Inventory.new()
	quest_log = QuestLog.new()
	skills = SkillTree.new()
	world = WorldState.new()
	gold = STARTING_GOLD
	play_time = 0.0
	recalc_stats()

func start_new_game() -> void:
	reset_state()
	is_playing = true
	pending_zone = "village"
	gold = STARTING_GOLD
	for entry: Dictionary in STARTING_ITEMS:
		inventory.add_item(String(entry.get("id", "")), int(entry.get("count", 1)))
	inventory.equip("rusty_sword")
	world = WorldState.new()
	skills.points = 0
	recalc_stats()
	_emit_all_state()

func recalc_stats() -> void:
	stats.recalc_for_level(progression.level)

func is_new_game() -> bool:
	return quest_log.entries.is_empty() and progression.level == 1 and play_time < 1.0

# --- Derived combat values ---------------------------------------------------
func attack_power() -> float:
	return stats.strength + inventory.total_attack_bonus() + skills.attack_bonus()

func defense_power() -> float:
	return stats.defense + inventory.total_defense_bonus() + skills.defense_bonus()

func max_health() -> float:
	return stats.max_health + skills.health_bonus()

func max_stamina() -> float:
	return stats.max_stamina

func move_speed_multiplier() -> float:
	return skills.speed_multiplier()

func crit_chance() -> float:
	return stats.crit_chance()

## Damage formula shared by player and creatures:
## max(1, attack - defense * 0.5) with +/-8% variance and crit support.
func compute_damage(attack: float, defense: float, crit_allowed: bool = true) -> Dictionary:
	var raw := maxf(1.0, attack - defense * 0.5)
	var variance := randf_range(0.92, 1.08)
	var is_crit := crit_allowed and randf() < crit_chance()
	var amount := raw * variance * (1.6 if is_crit else 1.0)
	return {"amount": maxf(1.0, amount), "crit": is_crit}

# --- Progression -------------------------------------------------------------
func gain_xp(amount: int) -> void:
	var levels := progression.add_xp(amount)
	if levels > 0:
		skills.points += levels
		recalc_stats()
		EventBus.player_level_up.emit(progression.level)
		EventBus.notify.emit("Level up! You are now level %d" % progression.level)
	EventBus.player_xp_changed.emit(progression.level, progression.xp, progression.xp_to_next())

func gain_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	EventBus.player_gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if amount <= 0 or gold < amount:
		return false
	gold -= amount
	EventBus.player_gold_changed.emit(gold)
	return true

func gain_item(item_id: String, count: int = 1) -> void:
	var leftover := inventory.add_item(item_id, count)
	if leftover < count:
		var data := ItemDB.get_item(item_id)
		var label := data.display_name if data != null else item_id
		EventBus.notify.emit("+%d %s" % [count - leftover, label])
		EventBus.item_picked_up.emit(item_id, count - leftover)
	if leftover > 0:
		EventBus.notify.emit("Inventory full!")

func upgrade_skill(skill_id: String) -> bool:
	if not skills.upgrade(skill_id):
		return false
	recalc_stats()
	EventBus.notify.emit("Skill improved: %s" % SkillDB.get_skill(skill_id).title)
	return true

# --- Quests ------------------------------------------------------------------
func start_quest(quest_id: String) -> bool:
	return quest_log.start_quest(quest_id)

func turn_in_quest(quest_id: String) -> bool:
	var quest := QuestDB.get_quest(quest_id)
	if quest == null or not quest_log.can_turn_in(quest_id):
		return false
	for item: Dictionary in quest.reward_items:
		gain_item(String(item.get("id", "")), int(item.get("count", 1)))
	gain_gold(quest.reward_gold)
	gain_xp(quest.reward_xp)
	quest_log.complete_quest(quest_id)
	EventBus.notify.emit("Quest complete: %s" % quest.title)
	return true

func report_visit(zone_id: String) -> void:
	quest_log.record_event("visit", zone_id)

func _on_creature_died(creature_id: String, uid: String, _position: Vector3) -> void:
	quest_log.record_event("kill", creature_id)
	world.mark_dead(uid)

func _on_item_picked_up(item_id: String, amount: int) -> void:
	quest_log.record_event("collect", item_id, amount)

# --- Serialisation -----------------------------------------------------------
func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"play_time": play_time,
		"pending_zone": pending_zone,
		"level": progression.level,
		"xp": progression.xp,
		"stats": stats.to_dict(),
		"inventory": inventory.to_dict(),
		"quests": quest_log.to_dict(),
		"skills": skills.to_dict(),
		"world": world.to_dict(),
	}

func apply_dict(data: Dictionary) -> void:
	reset_state()
	gold = maxi(0, int(data.get("gold", STARTING_GOLD)))
	play_time = maxf(0.0, float(data.get("play_time", 0.0)))
	pending_zone = String(data.get("pending_zone", "village"))
	progression.level = clampi(int(data.get("level", 1)), 1, Progression.MAX_LEVEL)
	progression.xp = maxi(0, int(data.get("xp", 0)))
	var raw_stats: Dictionary = data.get("stats", {})
	if not raw_stats.is_empty():
		stats.from_dict(raw_stats)
	else:
		recalc_stats()
	var raw_inventory: Dictionary = data.get("inventory", {})
	inventory.from_dict(raw_inventory)
	var raw_quests: Dictionary = data.get("quests", {})
	quest_log.from_dict(raw_quests)
	var raw_skills: Dictionary = data.get("skills", {})
	skills.from_dict(raw_skills)
	var raw_world: Dictionary = data.get("world", {})
	world.from_dict(raw_world)
	is_playing = true
	_emit_all_state()

func _emit_all_state() -> void:
	EventBus.player_xp_changed.emit(progression.level, progression.xp, progression.xp_to_next())
	EventBus.player_gold_changed.emit(gold)
	EventBus.inventory_changed.emit()
	EventBus.equipment_changed.emit()
