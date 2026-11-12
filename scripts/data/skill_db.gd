class_name SkillDB
extends RefCounted

const SKILL_DIR := "res://resources/skills"

static var _skills: Dictionary = {}
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_skills.clear()
	var dir := DirAccess.open(SKILL_DIR)
	if dir == null:
		push_warning("SkillDB: missing " + SKILL_DIR)
		return
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res: Resource = ResourceLoader.load(SKILL_DIR + "/" + file_name)
		if res is SkillData:
			var skill: SkillData = res
			if skill.id.is_empty():
				skill.id = file_name.get_basename()
			_skills[skill.id] = skill

static func reload() -> void:
	_loaded = false
	ensure_loaded()

static func get_skill(skill_id: String) -> SkillData:
	ensure_loaded()
	return _skills.get(skill_id, null) as SkillData

static func all_skills() -> Array:
	ensure_loaded()
	return _skills.values()

static func count() -> int:
	ensure_loaded()
	return _skills.size()
