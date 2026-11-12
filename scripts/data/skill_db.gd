class_name SkillDB
extends RefCounted
## Loads skill .tres resources and ensures the complete 24-node 4-branch
## RPG Skill Tree (Warrior, Mage, Ranger, Survival) is always available.

const SKILL_DIR := "res://resources/skills"
const BRANCHES: Array[String] = ["warrior", "mage", "ranger", "survival"]

static var _skills: Dictionary = {}
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_skills.clear()
	var dir := DirAccess.open(SKILL_DIR)
	if dir != null:
		for file_name: String in dir.get_files():
			if not file_name.ends_with(".tres"):
				continue
			var res: Resource = ResourceLoader.load(SKILL_DIR + "/" + file_name)
			if res is SkillData:
				var skill: SkillData = res
				if skill.id.is_empty():
					skill.id = file_name.get_basename()
				_skills[skill.id] = skill
	_register_full_tree()

static func _register_full_tree() -> void:
	var defs: Array[Dictionary] = [
		# --- WARRIOR BRANCH (6 nodes) ---
		{"id": "mighty_blow", "title": "Sword Mastery", "ar": "إتقان السيف", "glyph": "⚔",
			"branch": "warrior", "tier": 0, "col": 0, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.ATTACK_FLAT, "per": 2.5, "max": 3, "cost": 1,
			"desc": "+2.5 Melee Attack per rank. Foundation of blade combat."},
		{"id": "iron_skin", "title": "Iron Bulwark", "ar": "درع الحديد", "glyph": "🛡",
			"branch": "warrior", "tier": 0, "col": 1, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.DEFENSE_FLAT, "per": 2.0, "max": 3, "cost": 1,
			"desc": "+2.0 Defense per rank. Hardens stance against blows."},
		{"id": "heavy_cleave", "title": "Heavy Cleave", "ar": "الضربة الثقيلة", "glyph": "🪓",
			"branch": "warrior", "tier": 1, "col": 0, "req_lv": 2, "prereq": ["mighty_blow"],
			"eff": SkillData.Effect.HEAVY_PCT, "per": 0.18, "max": 3, "cost": 1,
			"desc": "+18% Heavy Whirlwind damage per rank."},
		{"id": "shield_mastery", "title": "Shield Mastery", "ar": "إتقان الترس", "glyph": "⛨",
			"branch": "warrior", "tier": 1, "col": 1, "req_lv": 2, "prereq": ["iron_skin"],
			"eff": SkillData.Effect.BLOCK_PCT, "per": 0.10, "max": 3, "cost": 1,
			"desc": "+10% damage mitigation while Blocking and reduces block stamina cost."},
		{"id": "lethal_precision", "title": "Critical Strikes", "ar": "الضربات الحرجة", "glyph": "✦",
			"branch": "warrior", "tier": 2, "col": 0, "req_lv": 4, "prereq": ["heavy_cleave"],
			"eff": SkillData.Effect.CRIT_PCT, "per": 0.05, "max": 3, "cost": 1,
			"desc": "+5% Critical Strike chance per rank."},
		{"id": "berserker_rage", "title": "Berserker Fury", "ar": "غضب المحارب", "glyph": "🔥",
			"branch": "warrior", "tier": 3, "col": 0, "req_lv": 6, "prereq": ["lethal_precision", "shield_mastery"],
			"eff": SkillData.Effect.BERSERKER_RAGE, "per": 0.15, "max": 2, "cost": 2,
			"desc": "+15% Attack & +20 Max Health per rank; empowers low-HP strikes."},

		# --- MAGE BRANCH (6 nodes) ---
		{"id": "fire_bolt", "title": "Fire Magic", "ar": "سحر النار", "glyph": "🔥",
			"branch": "mage", "tier": 0, "col": 0, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.SPELL_POWER, "per": 4.0, "max": 3, "cost": 1, "elem": "fire",
			"desc": "Unlocks & empowers Fireball spell (+4 Spell Power per rank)."},
		{"id": "mana_flow", "title": "Mana Efficiency", "ar": "كفاءة المانا", "glyph": "💧",
			"branch": "mage", "tier": 0, "col": 1, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.MANA_EFFICIENCY, "per": 0.12, "max": 3, "cost": 1,
			"desc": "-12% Spell Mana cost and +15 Max Mana per rank."},
		{"id": "frost_nova", "title": "Ice Magic", "ar": "سحر الجليد", "glyph": "❄",
			"branch": "mage", "tier": 1, "col": 0, "req_lv": 2, "prereq": ["fire_bolt"],
			"eff": SkillData.Effect.SPELL_POWER, "per": 4.5, "max": 3, "cost": 1, "elem": "ice",
			"desc": "Infuses arcane casts with Frost chill (+4.5 Spell Power & slow)."},
		{"id": "arcane_potency", "title": "Spell Power", "ar": "قوة التعويذات", "glyph": "✧",
			"branch": "mage", "tier": 1, "col": 1, "req_lv": 2, "prereq": ["mana_flow"],
			"eff": SkillData.Effect.SPELL_POWER, "per": 5.0, "max": 3, "cost": 1,
			"desc": "+5.0 Spell Power and faster Mana regeneration per rank."},
		{"id": "storm_lance", "title": "Lightning Magic", "ar": "سحر البرق", "glyph": "⚡",
			"branch": "mage", "tier": 2, "col": 0, "req_lv": 4, "prereq": ["frost_nova"],
			"eff": SkillData.Effect.SPELL_POWER, "per": 6.0, "max": 3, "cost": 1, "elem": "lightning",
			"desc": "Unleashes high-velocity Lightning surges (+6 Spell Power)."},
		{"id": "elemental_mastery", "title": "Elemental Mastery", "ar": "سيادة العناصر", "glyph": "☀",
			"branch": "mage", "tier": 3, "col": 0, "req_lv": 6, "prereq": ["storm_lance", "arcane_potency"],
			"eff": SkillData.Effect.ELEMENTAL_MASTERY, "per": 0.22, "max": 2, "cost": 2,
			"desc": "+22% total Elemental Spell damage & wider blast radius per rank."},

		# --- RANGER BRANCH (6 nodes) ---
		{"id": "swift_feet", "title": "Mobility", "ar": "خفة الحركة", "glyph": "💨",
			"branch": "ranger", "tier": 0, "col": 0, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.SPEED_PCT, "per": 0.06, "max": 3, "cost": 1,
			"desc": "+6% movement & sprint speed per rank."},
		{"id": "bow_mastery", "title": "Bow & Finesse", "ar": "إتقان الرماية", "glyph": "🏹",
			"branch": "ranger", "tier": 0, "col": 1, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.RANGED_POWER, "per": 2.2, "max": 3, "cost": 1,
			"desc": "+2.2 Agility & Finesse Attack bonus per rank."},
		{"id": "shadow_step", "title": "Stealth & Evasion", "ar": "خطوة الظل", "glyph": "🌙",
			"branch": "ranger", "tier": 1, "col": 0, "req_lv": 2, "prereq": ["swift_feet"],
			"eff": SkillData.Effect.DODGE_BONUS, "per": 0.15, "max": 3, "cost": 1,
			"desc": "-15% Dodge stamina cost and longer Dodge invulnerability."},
		{"id": "eagle_eye", "title": "Critical Aiming", "ar": "عين الصقر", "glyph": "🎯",
			"branch": "ranger", "tier": 1, "col": 1, "req_lv": 2, "prereq": ["bow_mastery"],
			"eff": SkillData.Effect.CRIT_DAMAGE_PCT, "per": 0.18, "max": 3, "cost": 1,
			"desc": "+18% Critical Hit damage multiplier per rank."},
		{"id": "snare_trap", "title": "Hunter Traps", "ar": "فخاخ الصياد", "glyph": "🕸",
			"branch": "ranger", "tier": 2, "col": 0, "req_lv": 4, "prereq": ["shadow_step"],
			"eff": SkillData.Effect.TRAP_SNARE, "per": 0.12, "max": 3, "cost": 1,
			"desc": "Attacks snare foes and deal +12% bonus damage to aggroed targets."},
		{"id": "beast_bane", "title": "Beast Mastery", "ar": "قاهر الوحوش", "glyph": "🐺",
			"branch": "ranger", "tier": 3, "col": 0, "req_lv": 6, "prereq": ["snare_trap", "eagle_eye"],
			"eff": SkillData.Effect.BEAST_DMG_PCT, "per": 0.20, "max": 2, "cost": 2,
			"desc": "+20% damage against all monsters, wildlife, and dungeon bosses."},

		# --- SURVIVAL BRANCH (6 nodes) ---
		{"id": "vital_endurance", "title": "Endurance", "ar": "قوة التحمل", "glyph": "❤",
			"branch": "survival", "tier": 0, "col": 0, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.MAX_HEALTH_FLAT, "per": 20.0, "max": 3, "cost": 1,
			"desc": "+20 Max Health & +10 Max Stamina per rank."},
		{"id": "keen_gatherer", "title": "Gathering", "ar": "جمع الموارد", "glyph": "⛏",
			"branch": "survival", "tier": 0, "col": 1, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.GATHER_BONUS, "per": 1.0, "max": 3, "cost": 1,
			"desc": "+1 bonus ore, timber, or herb yield when harvesting resource nodes."},
		{"id": "master_hunter", "title": "Hunting Instinct", "ar": "غريزة الصيد", "glyph": "🦌",
			"branch": "survival", "tier": 1, "col": 0, "req_lv": 2, "prereq": ["vital_endurance"],
			"eff": SkillData.Effect.LOOT_BONUS, "per": 0.15, "max": 3, "cost": 1,
			"desc": "+15% bonus gold & material drop rate from defeated creatures."},
		{"id": "artisan_smith", "title": "Master Crafting", "ar": "حرفية التصنيع", "glyph": "🔨",
			"branch": "survival", "tier": 1, "col": 1, "req_lv": 2, "prereq": ["keen_gatherer"],
			"eff": SkillData.Effect.CRAFT_BONUS, "per": 0.15, "max": 3, "cost": 1,
			"desc": "Crafted consumables yield extra charges; unlocks bonus forge efficiency."},
		{"id": "pathfinder", "title": "Exploration", "ar": "مستكشف البراري", "glyph": "🧭",
			"branch": "survival", "tier": 2, "col": 0, "req_lv": 4, "prereq": ["master_hunter"],
			"eff": SkillData.Effect.EXPLORATION_PCT, "per": 0.12, "max": 3, "cost": 1,
			"desc": "+12% Experience & Guild Reputation earned from all sources."},
		{"id": "resource_thrift", "title": "Resource Efficiency", "ar": "كفاءة الموارد", "glyph": "⚗",
			"branch": "survival", "tier": 3, "col": 0, "req_lv": 6, "prereq": ["pathfinder", "artisan_smith"],
			"eff": SkillData.Effect.RESOURCE_EFFICIENCY, "per": 0.25, "max": 2, "cost": 2,
			"desc": "+25% Potion healing/mana restoration & +25% Stamina regen."},
	]
	for d: Dictionary in defs:
		var sid := String(d["id"])
		var s: SkillData = _skills.get(sid, null) as SkillData
		if s == null:
			s = SkillData.new()
			s.id = sid
		s.title = String(d["title"])
		s.title_ar = String(d["ar"])
		s.icon_glyph = String(d["glyph"])
		s.branch = String(d["branch"])
		s.tier = int(d["tier"])
		s.column = int(d["col"])
		s.required_level = int(d["req_lv"])
		var prereq_typed: Array[String] = []
		for p: Variant in d["prereq"]:
			prereq_typed.append(String(p))
		s.prerequisites = prereq_typed
		s.effect = int(d["eff"]) as SkillData.Effect
		s.per_rank = float(d["per"])
		s.max_rank = int(d["max"])
		s.point_cost = int(d["cost"])
		s.active_element = String(d.get("elem", ""))
		s.description = String(d["desc"])
		_skills[sid] = s

static func reload() -> void:
	_loaded = false
	ensure_loaded()

static func get_skill(skill_id: String) -> SkillData:
	ensure_loaded()
	return _skills.get(skill_id, null) as SkillData

static func all_skills() -> Array:
	ensure_loaded()
	return _skills.values()

static func skills_for_branch(branch_name: String) -> Array[SkillData]:
	ensure_loaded()
	var out: Array[SkillData] = []
	for s: SkillData in _skills.values():
		if s.branch == branch_name:
			out.append(s)
	out.sort_custom(func(a: SkillData, b: SkillData) -> bool:
		if a.tier != b.tier:
			return a.tier < b.tier
		return a.column < b.column)
	return out

static func count() -> int:
	ensure_loaded()
	return _skills.size()
