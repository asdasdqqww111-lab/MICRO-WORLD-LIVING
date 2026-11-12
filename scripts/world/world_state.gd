class_name WorldState
extends RefCounted
## Persistent world clock, weather, harvested nodes, defeated creatures, and story flags.

const DAY_SECONDS := 86400.0
const HOURS_PER_DAY := 24

var time_of_day: float = 8.5 * 3600.0
var day: int = 1
var weather: String = "clear"
var weather_remaining: float = 240.0
var dead_creatures: Array[String] = []
var looted_containers: Array[String] = []
var harvested_nodes: Dictionary = {}   # node_uid -> day_harvested (respawns next day!)
var flags: Dictionary = {}
var raid_active: bool = false
var raid_day: int = -1
var npc_overrides: Dictionary = {}

func hour() -> int:
	return int(time_of_day / 3600.0) % HOURS_PER_DAY

func minute() -> int:
	return int(fmod(time_of_day, 3600.0) / 60.0)

func hour_float() -> float:
	return time_of_day / 3600.0

func is_night() -> bool:
	var h := hour()
	return h >= 20 or h < 6

func clock_text() -> String:
	return "%02d:%02d" % [hour(), minute()]

func advance(game_seconds: float) -> bool:
	if game_seconds <= 0.0:
		return false
	time_of_day += game_seconds
	var new_day := false
	while time_of_day >= DAY_SECONDS:
		time_of_day -= DAY_SECONDS
		day += 1
		new_day = true
	return new_day

func mark_dead(creature_uid: String) -> void:
	if not dead_creatures.has(creature_uid):
		dead_creatures.append(creature_uid)

func is_dead(creature_uid: String) -> bool:
	return dead_creatures.has(creature_uid)

func mark_looted(container_uid: String) -> void:
	if not looted_containers.has(container_uid):
		looted_containers.append(container_uid)

func is_looted(container_uid: String) -> bool:
	return looted_containers.has(container_uid)

func mark_harvested(node_uid: String) -> void:
	harvested_nodes[node_uid] = day

func is_harvested_today(node_uid: String) -> bool:
	return int(harvested_nodes.get(node_uid, -99)) >= day

func set_flag(key: String, value: Variant) -> void:
	flags[key] = value

func get_flag(key: String, default_value: Variant = null) -> Variant:
	return flags.get(key, default_value)

func to_dict() -> Dictionary:
	return {
		"time_of_day": time_of_day,
		"day": day,
		"weather": weather,
		"weather_remaining": weather_remaining,
		"dead_creatures": dead_creatures.duplicate(),
		"looted_containers": looted_containers.duplicate(),
		"harvested_nodes": harvested_nodes.duplicate(),
		"flags": flags.duplicate(true),
		"raid_active": raid_active,
		"raid_day": raid_day,
		"npc_overrides": npc_overrides.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	time_of_day = clampf(float(data.get("time_of_day", 8.5 * 3600.0)), 0.0, DAY_SECONDS - 1.0)
	day = maxi(1, int(data.get("day", 1)))
	weather = String(data.get("weather", "clear"))
	weather_remaining = maxf(0.0, float(data.get("weather_remaining", 240.0)))
	dead_creatures.clear()
	for uid: Variant in data.get("dead_creatures", []):
		dead_creatures.append(String(uid))
	looted_containers.clear()
	for uid: Variant in data.get("looted_containers", []):
		looted_containers.append(String(uid))
	var raw_harv: Dictionary = data.get("harvested_nodes", {})
	harvested_nodes = raw_harv.duplicate()
	var raw_flags: Dictionary = data.get("flags", {})
	flags = raw_flags.duplicate(true)
	raid_active = bool(data.get("raid_active", false))
	raid_day = int(data.get("raid_day", -1))
	var raw_npc: Dictionary = data.get("npc_overrides", {})
	npc_overrides = raw_npc.duplicate()
