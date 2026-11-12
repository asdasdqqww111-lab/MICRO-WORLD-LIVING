class_name CreatureDB
extends RefCounted

const CREATURE_DIR := "res://resources/creatures"

static var _creatures: Dictionary = {}
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_creatures.clear()
	var dir := DirAccess.open(CREATURE_DIR)
	if dir == null:
		push_warning("CreatureDB: missing " + CREATURE_DIR)
		return
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res: Resource = ResourceLoader.load(CREATURE_DIR + "/" + file_name)
		if res is CreatureData:
			var creature: CreatureData = res
			if creature.id.is_empty():
				creature.id = file_name.get_basename()
			_creatures[creature.id] = creature

static func reload() -> void:
	_loaded = false
	ensure_loaded()

static func get_creature(creature_id: String) -> CreatureData:
	ensure_loaded()
	return _creatures.get(creature_id, null) as CreatureData

static func all_creatures() -> Array:
	ensure_loaded()
	return _creatures.values()

static func count() -> int:
	ensure_loaded()
	return _creatures.size()
