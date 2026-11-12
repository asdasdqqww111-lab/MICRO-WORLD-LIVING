class_name Progression
extends RefCounted
## Level / XP curve: xp_to_next(level) = 60 + 45*(l-1) + 10*(l-1)^2.

const MAX_LEVEL := 20

var level: int = 1
var xp: int = 0

func xp_to_next(current_level: int = -1) -> int:
	var l := level if current_level < 0 else current_level
	var n := float(maxi(1, l) - 1)
	return int(60.0 + 45.0 * n + 10.0 * n * n)

func add_xp(amount: int) -> int:
	if amount <= 0 or level >= MAX_LEVEL:
		return 0
	xp += amount
	var gained := 0
	while level < MAX_LEVEL and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		gained += 1
	if level >= MAX_LEVEL:
		xp = 0
	return gained

func progress_ratio() -> float:
	var need := xp_to_next()
	return 0.0 if need <= 0 else clampf(float(xp) / float(need), 0.0, 1.0)

func to_dict() -> Dictionary:
	return {"level": level, "xp": xp}

func from_dict(data: Dictionary) -> void:
	level = clampi(int(data.get("level", 1)), 1, MAX_LEVEL)
	xp = maxi(0, int(data.get("xp", 0)))
