extends Node
## Owns the authoritative player, progression, inventory, quest, guild, skill
## and world state (autoload: GameManager).

const SAVE_VERSION := 3
const STARTING_GOLD := 35
const SKILL_RESET_COST := 50
const STARTING_ITEMS := [
	{"id": "rusty_sword", "count": 1},
	{"id": "oak_shield", "count": 1},
	{"id": "bread", "count": 2},
	{"id": "health_potion", "count": 2},
	{"id": "mana_elixir", "count": 1},
]

var stats: CharacterStats
var progression: Progression
var inventory: Inventory
var quest_log: QuestLog
var skills: SkillTree
var guild: GuildSystem
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
	guild = GuildSystem.new()
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
		var item_id := String(entry.get("id", ""))
		if ItemDB.has(item_id):
			inventory.add_item(item_id, int(entry.get("count", 1)))
	inventory.equip("rusty_sword")
	if inventory.count_item("oak_shield") > 0:
		inventory.equip("oak_shield")
	world = WorldState.new()
	skills.points = 1   # Grant 1 starting skill point so players can pick their initial specialization!
	recalc_stats()
	_emit_all_state()

func recalc_stats() -> void:
	stats.recalc_for_level(progression.level)

func is_new_game() -> bool:
	return quest_log.entries.is_empty() and progression.level == 1 and play_time < 1.0

# --- Derived combat & magic values -------------------------------------------
func attack_power() -> float:
	return (stats.strength + inventory.total_attack_bonus() + skills.attack_bonus()) * skills.creature_damage_multiplier()

func defense_power() -> float:
	return stats.defense + inventory.total_defense_bonus() + skills.defense_bonus()

func spell_power() -> float:
	return stats.intelligence + inventory.total_magic_bonus() + skills.spell_power_bonus()

func max_health() -> float:
	return stats.max_health + skills.health_bonus()

func max_stamina() -> float:
	return stats.max_stamina + skills.stamina_bonus()

func max_mana() -> float:
	return stats.max_mana + skills.mana_bonus()

func move_speed_multiplier() -> float:
	return skills.speed_multiplier()

func crit_chance() -> float:
	return clampf(stats.crit_chance() + inventory.total_crit_bonus() + skills.crit_chance_bonus(), 0.0, 0.75)

func compute_damage(attack: float, defense: float, crit_allowed: bool = true) -> Dictionary:
	var raw := maxf(1.0, attack - defense * 0.5)
	var variance := randf_range(0.92, 1.08)
	var is_crit := crit_allowed and randf() < crit_chance()
	var crit_mult := skills.crit_damage_multiplier() if is_crit else 1.0
	var amount := raw * variance * crit_mult
	return {"amount": maxf(1.0, amount), "crit": is_crit}

# --- Progression & Skills ----------------------------------------------------
func gain_xp(amount: int) -> void:
	if amount <= 0:
		return
	var scaled := int(round(float(amount) * skills.xp_multiplier()))
	var levels := progression.add_xp(scaled)
	if levels > 0:
		skills.points += levels
		recalc_stats()
		EventBus.player_level_up.emit(progression.level)
		EventBus.skill_tree_changed.emit()
		EventBus.notify.emit("Level up! Reached Level %d (+%d Skill Pt)" % [progression.level, levels])
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
	if not skills.upgrade(skill_id, progression.level):
		return false
	recalc_stats()
	var s := SkillDB.get_skill(skill_id)
	if s != null:
		EventBus.notify.emit("Skill unlocked: %s (%d/%d)" % [s.title, skills.rank_of(skill_id), s.max_rank])
	EventBus.skill_tree_changed.emit()
	return true

func reset_skill_tree(require_gold: bool = true) -> bool:
	if skills.total_spent_points() <= 0:
		return false
	if require_gold and not spend_gold(SKILL_RESET_COST):
		EventBus.notify.emit("Need %d Gold to reset skills" % SKILL_RESET_COST)
		return false
	var refunded := skills.reset_all()
	recalc_stats()
	EventBus.skill_tree_changed.emit()
	EventBus.notify.emit("Skills reset! Refunded %d points." % refunded)
	return true

# --- Quests, Guild & Crafting ------------------------------------------------
func start_quest(quest_id: String) -> bool:
	var q := QuestDB.get_quest(quest_id)
	if q == null:
		return false
	if q.is_guild_contract and not guild.meets_rank(q.required_guild_rank):
		EventBus.notify.emit("Requires Adventurers Guild Rank %s" % q.required_guild_rank)
		return false
	return quest_log.start_quest(quest_id)

func turn_in_quest(quest_id: String) -> bool:
	var quest := QuestDB.get_quest(quest_id)
	if quest == null or not quest_log.can_turn_in(quest_id):
		return false
	for item: Dictionary in quest.reward_items:
		gain_item(String(item.get("id", "")), int(item.get("count", 1)))
	gain_gold(quest.reward_gold)
	gain_xp(quest.reward_xp)
	if quest.reward_reputation > 0:
		var rep := int(round(float(quest.reward_reputation) * skills.xp_multiplier()))
		guild.add_reputation(rep)
		if quest.is_guild_contract:
			guild.contracts_completed += 1
		EventBus.guild_updated.emit()
	if not quest.story_flag_on_complete.is_empty():
		world.set_flag(quest.story_flag_on_complete, true)
	quest_log.complete_quest(quest_id)
	EventBus.notify.emit("Quest complete: %s" % quest.title)
	return true

func register_in_guild() -> bool:
	if not guild.register_adventurer():
		return false
	world.set_flag("guild_registered", true)
	EventBus.guild_updated.emit()
	EventBus.notify.emit("Registered in the Adventurers Guild — Rank F!")
	return true

func promote_guild_rank() -> Dictionary:
	var info := guild.promote(progression.level)
	if info.is_empty():
		return {}
	gain_gold(int(info.get("gold", 0)))
	var reward_item := String(info.get("item", ""))
	if not reward_item.is_empty() and ItemDB.has(reward_item):
		gain_item(reward_item, 1)
	EventBus.guild_updated.emit()
	EventBus.notify.emit("Promoted to Guild Rank %s — %s!" % [String(info["rank"]), String(info["title"])])
	return info

func craft_recipe(recipe_id: String) -> bool:
	var result := CraftingDB.craft(recipe_id, inventory, skills.rank_of("artisan_smith"))
	if result.is_empty():
		return false
	var out_id := String(result["item_id"])
	var out_cnt := int(result["count"])
	gain_xp(int(result.get("xp", 15)))
	quest_log.record_event("collect", out_id, out_cnt)
	var data := ItemDB.get_item(out_id)
	EventBus.item_crafted.emit(recipe_id, out_id)
	if AudioManager != null:
		AudioManager.play_sfx("craft_anvil")
	EventBus.notify.emit("Crafted %dx %s" % [out_cnt, data.display_name if data != null else out_id])
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
		"guild": guild.to_dict(),
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
	inventory.from_dict(data.get("inventory", {}) as Dictionary)
	quest_log.from_dict(data.get("quests", {}) as Dictionary)
	skills.from_dict(data.get("skills", {}) as Dictionary)
	guild.from_dict(data.get("guild", {}) as Dictionary)
	world.from_dict(data.get("world", {}) as Dictionary)
	is_playing = true
	_emit_all_state()

func _emit_all_state() -> void:
	EventBus.player_xp_changed.emit(progression.level, progression.xp, progression.xp_to_next())
	EventBus.player_gold_changed.emit(gold)
	EventBus.inventory_changed.emit()
	EventBus.equipment_changed.emit()
	EventBus.skill_tree_changed.emit()
	EventBus.guild_updated.emit()
