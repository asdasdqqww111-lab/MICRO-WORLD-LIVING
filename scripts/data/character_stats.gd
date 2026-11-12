class_name CharacterStats
extends RefCounted
## Base attributes derived from level (before gear and skills).

const BASE_STRENGTH := 8.0
const BASE_DEFENSE := 4.0
const BASE_AGILITY := 5.0
const BASE_HEALTH := 100.0
const BASE_STAMINA := 100.0

var strength: float = BASE_STRENGTH
var defense: float = BASE_DEFENSE
var agility: float = BASE_AGILITY
var max_health: float = BASE_HEALTH
var max_stamina: float = BASE_STAMINA

func recalc_for_level(level: int) -> void:
	var l := float(maxi(1, level) - 1)
	strength = BASE_STRENGTH + 1.6 * l
	defense = BASE_DEFENSE + 1.1 * l
	agility = BASE_AGILITY + 0.8 * l
	max_health = BASE_HEALTH + 12.0 * l
	max_stamina = BASE_STAMINA + 2.5 * l

func crit_chance() -> float:
	return clampf(0.04 + agility * 0.0025, 0.0, 0.35)

func to_dict() -> Dictionary:
	return {
		"strength": strength, "defense": defense, "agility": agility,
		"max_health": max_health, "max_stamina": max_stamina,
	}

func from_dict(data: Dictionary) -> void:
	strength = float(data.get("strength", BASE_STRENGTH))
	defense = float(data.get("defense", BASE_DEFENSE))
	agility = float(data.get("agility", BASE_AGILITY))
	max_health = float(data.get("max_health", BASE_HEALTH))
	max_stamina = float(data.get("max_stamina", BASE_STAMINA))
