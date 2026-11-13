class_name SkillTree
extends RefCounted
## Manages unlocked ranks, prerequisites, level gates, skill resets, and
## real gameplay bonuses across all 4 branches (Warrior, Mage, Ranger, Survival).

signal changed()

var ranks: Dictionary = {}
var points: int = 0

func rank_of(skill_id: String) -> int:
	return int(ranks.get(skill_id, 0))

func add_points(amount: int) -> void:
	if amount > 0:
		points += amount
		changed.emit()

func can_unlock(skill_id: String) -> bool:
	return can_upgrade(skill_id)

func unlock(skill_id: String) -> bool:
	return upgrade(skill_id)

func spent_points() -> int:
	return total_spent_points()

func is_unlocked(skill_id: String) -> bool:
	return rank_of(skill_id) > 0

func prerequisites_met(skill_id: String) -> bool:
	var skill := SkillDB.get_skill(skill_id)
	if skill == null:
		return false
	for prereq_id: String in skill.prerequisites:
		if rank_of(prereq_id) < 1:
			return false
	return true

func can_upgrade(skill_id: String, player_level: int = -1) -> bool:
	var skill := SkillDB.get_skill(skill_id)
	if skill == null:
		return false
	if points < skill.point_cost:
		return false
	if rank_of(skill_id) >= skill.max_rank:
		return false
	var lv := player_level
	if lv < 0 and GameManager != null and GameManager.progression != null:
		lv = GameManager.progression.level
	if lv > 0 and lv < skill.required_level:
		return false
	return prerequisites_met(skill_id)

func upgrade(skill_id: String, player_level: int = -1) -> bool:
	if not can_upgrade(skill_id, player_level):
		return false
	var skill := SkillDB.get_skill(skill_id)
	points -= skill.point_cost
	ranks[skill_id] = rank_of(skill_id) + 1
	changed.emit()
	return true

func total_spent_points() -> int:
	var spent := 0
	for skill_id: String in ranks.keys():
		var skill := SkillDB.get_skill(skill_id)
		if skill != null:
			spent += rank_of(skill_id) * skill.point_cost
	return spent

func reset_all() -> int:
	var refunded := total_spent_points()
	if refunded <= 0:
		return 0
	ranks.clear()
	points += refunded
	changed.emit()
	return refunded

func bonus_total(effect: int) -> float:
	var total := 0.0
	for skill_id: String in ranks.keys():
		var skill := SkillDB.get_skill(skill_id)
		if skill == null or skill.effect != effect:
			continue
		total += skill.per_rank * float(rank_of(skill_id))
	return total

func attack_bonus() -> float:
	var flat := bonus_total(SkillData.Effect.ATTACK_FLAT) + bonus_total(SkillData.Effect.RANGED_POWER)
	flat += float(rank_of("nightstalker_apex")) * 5.0
	return flat

func defense_bonus() -> float:
	return bonus_total(SkillData.Effect.DEFENSE_FLAT) + float(rank_of("guardian_vitality")) * 2.5

func speed_multiplier() -> float:
	return 1.0 + bonus_total(SkillData.Effect.SPEED_PCT) + float(rank_of("wind_dancer")) * 0.04 + float(rank_of("nightstalker_apex")) * 0.10

func health_bonus() -> float:
	return bonus_total(SkillData.Effect.MAX_HEALTH_FLAT) + float(rank_of("berserker_rage")) * 20.0 + float(rank_of("sovereign_vanguard")) * 45.0

func stamina_bonus() -> float:
	return float(rank_of("vital_endurance")) * 10.0

func mana_bonus() -> float:
	return float(rank_of("mana_flow")) * 15.0 + float(rank_of("mana_ward")) * 12.0 + float(rank_of("celestial_focus")) * 20.0 + float(rank_of("archmage_ascension")) * 45.0

func combo_finisher_bonus() -> float:
	return bonus_total(SkillData.Effect.COMBO_FINISHER_PCT)

func lifesteal_ratio() -> float:
	return bonus_total(SkillData.Effect.LIFESTEAL_PCT) + float(rank_of("sovereign_vanguard")) * 0.08

func spell_power_bonus() -> float:
	var base := bonus_total(SkillData.Effect.SPELL_POWER)
	return base * (1.0 + bonus_total(SkillData.Effect.ELEMENTAL_MASTERY))

func mana_cost_multiplier() -> float:
	return clampf(1.0 - bonus_total(SkillData.Effect.MANA_EFFICIENCY), 0.45, 1.0)

func heavy_damage_multiplier() -> float:
	return 1.45 + bonus_total(SkillData.Effect.HEAVY_PCT)

func block_mitigation() -> float:
	return clampf(0.60 + bonus_total(SkillData.Effect.BLOCK_PCT), 0.60, 0.90)

func crit_chance_bonus() -> float:
	return bonus_total(SkillData.Effect.CRIT_PCT)

func crit_damage_multiplier() -> float:
	return 1.60 + bonus_total(SkillData.Effect.CRIT_DAMAGE_PCT)

func creature_damage_multiplier() -> float:
	return 1.0 + bonus_total(SkillData.Effect.BEAST_DMG_PCT) + bonus_total(SkillData.Effect.TRAP_SNARE) + bonus_total(SkillData.Effect.BERSERKER_RAGE)

func dodge_cost_multiplier() -> float:
	return clampf(1.0 - bonus_total(SkillData.Effect.DODGE_BONUS), 0.5, 1.0)

func gather_extra_yield() -> int:
	return int(round(bonus_total(SkillData.Effect.GATHER_BONUS)))

func loot_gold_multiplier() -> float:
	return 1.0 + bonus_total(SkillData.Effect.LOOT_BONUS)

func xp_multiplier() -> float:
	return 1.0 + bonus_total(SkillData.Effect.EXPLORATION_PCT) + float(rank_of("immortal_warden")) * 0.20

func potion_multiplier() -> float:
	return 1.0 + bonus_total(SkillData.Effect.RESOURCE_EFFICIENCY) + float(rank_of("immortal_warden")) * 0.25

func active_spell_element() -> String:
	if rank_of("storm_lance") > 0:
		return "lightning"
	if rank_of("frost_nova") > 0:
		return "ice"
	if rank_of("fire_bolt") > 0:
		return "fire"
	return ""

func to_dict() -> Dictionary:
	return {"ranks": ranks.duplicate(true), "points": points}

func from_dict(data: Dictionary) -> void:
	ranks.clear()
	var raw: Dictionary = data.get("ranks", {})
	for skill_id: String in raw.keys():
		if SkillDB.get_skill(skill_id) == null:
			continue
		ranks[skill_id] = maxi(0, int(raw[skill_id]))
	points = maxi(0, int(data.get("points", 0)))
	changed.emit()
