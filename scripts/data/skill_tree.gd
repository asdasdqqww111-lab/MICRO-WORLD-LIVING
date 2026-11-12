class_name SkillTree
extends RefCounted

signal changed()

var ranks: Dictionary = {}
var points: int = 0

func rank_of(skill_id: String) -> int:
	return int(ranks.get(skill_id, 0))

func can_upgrade(skill_id: String) -> bool:
	var skill := SkillDB.get_skill(skill_id)
	if skill == null:
		return false
	if points < skill.point_cost:
		return false
	return rank_of(skill_id) < skill.max_rank

func upgrade(skill_id: String) -> bool:
	if not can_upgrade(skill_id):
		return false
	var skill := SkillDB.get_skill(skill_id)
	points -= skill.point_cost
	ranks[skill_id] = rank_of(skill_id) + 1
	changed.emit()
	return true

func bonus_total(effect: int) -> float:
	var total := 0.0
	for skill_id: String in ranks.keys():
		var skill := SkillDB.get_skill(skill_id)
		if skill == null or skill.effect != effect:
			continue
		total += skill.per_rank * float(rank_of(skill_id))
	return total

func attack_bonus() -> float:
	return bonus_total(SkillData.Effect.ATTACK_FLAT)

func defense_bonus() -> float:
	return bonus_total(SkillData.Effect.DEFENSE_FLAT)

func speed_multiplier() -> float:
	return 1.0 + bonus_total(SkillData.Effect.SPEED_PCT)

func health_bonus() -> float:
	return bonus_total(SkillData.Effect.MAX_HEALTH_FLAT)

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
