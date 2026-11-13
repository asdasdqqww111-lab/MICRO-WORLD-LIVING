class_name SkillDB
extends RefCounted
## Loads skill .tres resources and registers the massive 36-node 5-Tier
## Constellation Skill Tree across 4 branches (Warrior, Mage, Ranger, Survival).

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
		# ==================== WARRIOR BRANCH (9 nodes · 5 Tiers) ====================
		{"id": "mighty_blow", "title": "Sword Mastery", "ar": "إتقان السيف", "glyph": "⚔",
			"branch": "warrior", "tier": 0, "col": 0, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.ATTACK_FLAT, "per": 2.5, "max": 3, "cost": 1,
			"desc": "+2.5 Melee Attack per rank. Foundation of royal blade combat.",
			"desc_ar": "+2.5 قوة هجوم قريب لكل رتبة. حجر الأساس في فنون المبارزة الملكية."},
		{"id": "iron_skin", "title": "Iron Bulwark", "ar": "درع الحديد", "glyph": "🛡",
			"branch": "warrior", "tier": 0, "col": 1, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.DEFENSE_FLAT, "per": 2.0, "max": 3, "cost": 1,
			"desc": "+2.0 Defense per rank. Hardens stance against enemy blows.",
			"desc_ar": "+2.0 دفاع لكل رتبة. يصلّب وقفتك القتالية أمام ضربات الخصوم."},
		{"id": "heavy_cleave", "title": "Heavy Cleave", "ar": "الضربة الثقيلة", "glyph": "🪓",
			"branch": "warrior", "tier": 1, "col": 0, "req_lv": 2, "prereq": ["mighty_blow"],
			"eff": SkillData.Effect.HEAVY_PCT, "per": 0.18, "max": 3, "cost": 1,
			"desc": "+18% Heavy Whirlwind slash damage per rank.",
			"desc_ar": "+18% ضرر إضافي للضربة الثقيلة الدوّارة لكل رتبة."},
		{"id": "shield_mastery", "title": "Shield Mastery", "ar": "إتقان الترس", "glyph": "⛨",
			"branch": "warrior", "tier": 1, "col": 1, "req_lv": 2, "prereq": ["iron_skin"],
			"eff": SkillData.Effect.BLOCK_PCT, "per": 0.10, "max": 3, "cost": 1,
			"desc": "+10% damage mitigation while Blocking with your shield.",
			"desc_ar": "+10% تقليل للضرر أثناء الصد بالترس وتخفيف استهلاك النشاط."},
		{"id": "lethal_precision", "title": "Critical Strikes", "ar": "الضربات الحرجة", "glyph": "✦",
			"branch": "warrior", "tier": 2, "col": 0, "req_lv": 3, "prereq": ["heavy_cleave"],
			"eff": SkillData.Effect.CRIT_PCT, "per": 0.05, "max": 3, "cost": 1,
			"desc": "+5% Critical Strike chance per rank.",
			"desc_ar": "+5% فرصة ضربة حرجة قاتلة لكل رتبة."},
		{"id": "combo_finisher", "title": "Royal Blade Dance", "ar": "رقصة النصل الملكي", "glyph": "⚜",
			"branch": "warrior", "tier": 2, "col": 1, "req_lv": 3, "prereq": ["mighty_blow", "shield_mastery"],
			"eff": SkillData.Effect.COMBO_FINISHER_PCT, "per": 0.22, "max": 3, "cost": 1,
			"desc": "+22% bonus damage on your 3rd-hit Combo Finisher strike per rank.",
			"desc_ar": "+22% ضرر إضافي للضربة القاضية الثالثة في سلسلة الكومبو لكل رتبة."},
		{"id": "berserker_rage", "title": "Berserker Fury", "ar": "غضب المحارب", "glyph": "🔥",
			"branch": "warrior", "tier": 3, "col": 0, "req_lv": 5, "prereq": ["lethal_precision"],
			"eff": SkillData.Effect.BERSERKER_RAGE, "per": 0.15, "max": 2, "cost": 2,
			"desc": "+15% Attack & +20 Max Health per rank; empowers fierce melee chains.",
			"desc_ar": "+15% هجوم و+20 صحة قصوى لكل رتبة؛ يضاعف شراستك في الاشتباك."},
		{"id": "blood_thirst", "title": "Crimson Leech", "ar": "استنزاف القرمزي", "glyph": "🩸",
			"branch": "warrior", "tier": 3, "col": 1, "req_lv": 5, "prereq": ["combo_finisher"],
			"eff": SkillData.Effect.LIFESTEAL_PCT, "per": 0.06, "max": 2, "cost": 2,
			"desc": "Restores 6% of all melee & heavy slash damage dealt as Health per rank.",
			"desc_ar": "يستعيد 6% من ضرر ضرباتك القريبة والثقيلة كصحة فورية لكل رتبة."},
		{"id": "sovereign_vanguard", "title": "Sovereign of Eldoria", "ar": "سيّد طليعة إلدوريا", "glyph": "👑",
			"branch": "warrior", "tier": 4, "col": 0, "req_lv": 7, "prereq": ["berserker_rage", "blood_thirst"],
			"eff": SkillData.Effect.ATTACK_FLAT, "per": 9.0, "max": 1, "cost": 3,
			"desc": "Ultimate Warrior Capstone: +9 Attack, +45 Max Health, and +8% Life Leech.",
			"desc_ar": "ذروة المحارب الأسطورية: +9 هجوم، +45 صحة قصوى، و+8% استنزاف حياة."},

		# ==================== MAGE BRANCH (9 nodes · 5 Tiers) ====================
		{"id": "fire_bolt", "title": "Fire Magic", "ar": "سحر النار", "glyph": "🔥",
			"branch": "mage", "tier": 0, "col": 0, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.SPELL_POWER, "per": 4.0, "max": 3, "cost": 1, "elem": "fire",
			"desc": "Unlocks & empowers blazing Fireball casts (+4 Spell Power per rank).",
			"desc_ar": "يطلق ويعزّز كرات اللهب الحارقة (+4 قوة سحرية لكل رتبة)."},
		{"id": "mana_flow", "title": "Mana Efficiency", "ar": "كفاءة المانا", "glyph": "💧",
			"branch": "mage", "tier": 0, "col": 1, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.MANA_EFFICIENCY, "per": 0.12, "max": 3, "cost": 1,
			"desc": "-12% Spell Mana cost and +15 Max Mana per rank.",
			"desc_ar": "-12% تكلفة مانا للتعاويذ و+15 مانا قصوى لكل رتبة."},
		{"id": "frost_nova", "title": "Ice Magic", "ar": "سحر الجليد", "glyph": "❄",
			"branch": "mage", "tier": 1, "col": 0, "req_lv": 2, "prereq": ["fire_bolt"],
			"eff": SkillData.Effect.SPELL_POWER, "per": 4.5, "max": 3, "cost": 1, "elem": "ice",
			"desc": "Infuses spells with Frost chill (+4.5 Spell Power & slows enemies).",
			"desc_ar": "يشبع التعاويذ بصقيع الجليد (+4.5 قوة سحرية وإبطاء حركة الأعداء)."},
		{"id": "arcane_potency", "title": "Spell Power", "ar": "قوة التعويذات", "glyph": "✧",
			"branch": "mage", "tier": 1, "col": 1, "req_lv": 2, "prereq": ["mana_flow"],
			"eff": SkillData.Effect.SPELL_POWER, "per": 5.0, "max": 3, "cost": 1,
			"desc": "+5.0 Spell Power and faster Mana regeneration per rank.",
			"desc_ar": "+5.0 قوة سحرية وتجدد أسرع لطاقة المانا لكل رتبة."},
		{"id": "storm_lance", "title": "Lightning Magic", "ar": "سحر البرق", "glyph": "⚡",
			"branch": "mage", "tier": 2, "col": 0, "req_lv": 3, "prereq": ["frost_nova"],
			"eff": SkillData.Effect.SPELL_POWER, "per": 6.0, "max": 3, "cost": 1, "elem": "lightning",
			"desc": "Unleashes high-velocity Lightning surges (+6 Spell Power per rank).",
			"desc_ar": "يطلق صواعق برق خاطفة بعيدة المدى (+6 قوة سحرية لكل رتبة)."},
		{"id": "mana_ward", "title": "Arcane Aegis", "ar": "الحاجز الأثيري", "glyph": "🔮",
			"branch": "mage", "tier": 2, "col": 1, "req_lv": 3, "prereq": ["arcane_potency"],
			"eff": SkillData.Effect.DEFENSE_FLAT, "per": 3.0, "max": 3, "cost": 1,
			"desc": "+3.0 Arcane Ward Defense and +12 Max Mana per rank.",
			"desc_ar": "+3.0 دفاع سحري بدرع الأثير و+12 مانا قصوى لكل رتبة."},
		{"id": "elemental_mastery", "title": "Elemental Mastery", "ar": "سيادة العناصر", "glyph": "☀",
			"branch": "mage", "tier": 3, "col": 0, "req_lv": 5, "prereq": ["storm_lance"],
			"eff": SkillData.Effect.ELEMENTAL_MASTERY, "per": 0.22, "max": 2, "cost": 2,
			"desc": "+22% Elemental Spell damage & wider explosion radius per rank.",
			"desc_ar": "+22% ضرر إضافي لجميع التعاويذ العنصرية واتساع نطاق الانفجار."},
		{"id": "celestial_focus", "title": "Astral Resonance", "ar": "الرنين النجمي", "glyph": "🌟",
			"branch": "mage", "tier": 3, "col": 1, "req_lv": 5, "prereq": ["mana_ward"],
			"eff": SkillData.Effect.CRIT_PCT, "per": 0.07, "max": 2, "cost": 2,
			"desc": "+7% Spell & Weapon Critical chance and +20 Max Mana per rank.",
			"desc_ar": "+7% فرصة ضربة حرجة سحرية وقتالية و+20 مانا قصوى لكل رتبة."},
		{"id": "archmage_ascension", "title": "Archmage Cataclysm", "ar": "ارتقاء ساحر العرش", "glyph": "🌌",
			"branch": "mage", "tier": 4, "col": 0, "req_lv": 7, "prereq": ["elemental_mastery", "celestial_focus"],
			"eff": SkillData.Effect.ELEMENTAL_MASTERY, "per": 0.35, "max": 1, "cost": 3,
			"desc": "Ultimate Mage Capstone: +35% Elemental Power & +45 Max Mana.",
			"desc_ar": "ذروة الساحر الأسطورية: +35% قوة عنصرية شاملة و+45 مانا قصوى."},

		# ==================== RANGER BRANCH (9 nodes · 5 Tiers) ====================
		{"id": "swift_feet", "title": "Mobility", "ar": "خفة الحركة", "glyph": "💨",
			"branch": "ranger", "tier": 0, "col": 0, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.SPEED_PCT, "per": 0.06, "max": 3, "cost": 1,
			"desc": "+6% movement & sprint speed across Eldoria per rank.",
			"desc_ar": "+6% سرعة حركة وعدو سريع عبر أرجاء إلدوريا لكل رتبة."},
		{"id": "bow_mastery", "title": "Bow & Finesse", "ar": "إتقان الرماية والرشاقة", "glyph": "🏹",
			"branch": "ranger", "tier": 0, "col": 1, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.RANGED_POWER, "per": 2.4, "max": 3, "cost": 1,
			"desc": "+2.4 Agility & Finesse Attack power per rank.",
			"desc_ar": "+2.4 قوة هجوم دقيقة وبراعة قتالية لكل رتبة."},
		{"id": "shadow_step", "title": "Stealth & Evasion", "ar": "خطوة الظل", "glyph": "🌙",
			"branch": "ranger", "tier": 1, "col": 0, "req_lv": 2, "prereq": ["swift_feet"],
			"eff": SkillData.Effect.DODGE_BONUS, "per": 0.15, "max": 3, "cost": 1,
			"desc": "-15% Dodge stamina cost and extended invulnerability frames.",
			"desc_ar": "-15% استهلاك نشاط للمراوغة وإطالة فترة المناعة أثناء الاندفاع."},
		{"id": "eagle_eye", "title": "Critical Aiming", "ar": "عين الصقر", "glyph": "🎯",
			"branch": "ranger", "tier": 1, "col": 1, "req_lv": 2, "prereq": ["bow_mastery"],
			"eff": SkillData.Effect.CRIT_DAMAGE_PCT, "per": 0.18, "max": 3, "cost": 1,
			"desc": "+18% Critical Hit damage multiplier per rank.",
			"desc_ar": "+18% مضاعف ضرر الضربات الحرجة لكل رتبة."},
		{"id": "snare_trap", "title": "Hunter Traps", "ar": "فخاخ الصياد", "glyph": "🕸",
			"branch": "ranger", "tier": 2, "col": 0, "req_lv": 3, "prereq": ["shadow_step"],
			"eff": SkillData.Effect.TRAP_SNARE, "per": 0.12, "max": 3, "cost": 1,
			"desc": "Strikes snare foes and deal +12% bonus damage to monsters.",
			"desc_ar": "تُبطئ هجماتك الأعداء وتلحق +12% ضرراً إضافياً بالوحوش المشتبكة."},
		{"id": "wind_dancer", "title": "Gale Flurry", "ar": "عاصفة النصال", "glyph": "🌪",
			"branch": "ranger", "tier": 2, "col": 1, "req_lv": 3, "prereq": ["eagle_eye"],
			"eff": SkillData.Effect.COMBO_FINISHER_PCT, "per": 0.18, "max": 3, "cost": 1,
			"desc": "+18% Combo Finisher damage and +4% Sprint agility per rank.",
			"desc_ar": "+18% ضرر الضربة القاضية الثالثة و+4% خفة حركة لكل رتبة."},
		{"id": "beast_bane", "title": "Beast Mastery", "ar": "قاهر الوحوش", "glyph": "🐺",
			"branch": "ranger", "tier": 3, "col": 0, "req_lv": 5, "prereq": ["snare_trap"],
			"eff": SkillData.Effect.BEAST_DMG_PCT, "per": 0.20, "max": 2, "cost": 2,
			"desc": "+20% damage against all monsters, elites, and dungeon bosses.",
			"desc_ar": "+20% ضرر إضافي ضد جميع الوحوش والنخبة وزعماء السراديب."},
		{"id": "phantom_execution", "title": "Assassin's Edge", "ar": "شفرة الشبح القاتلة", "glyph": "🗡",
			"branch": "ranger", "tier": 3, "col": 1, "req_lv": 5, "prereq": ["wind_dancer"],
			"eff": SkillData.Effect.CRIT_DAMAGE_PCT, "per": 0.28, "max": 2, "cost": 2,
			"desc": "+28% Critical Damage multiplier for devastating ambushes.",
			"desc_ar": "+28% مضاعف ضرر الضربات الحرجة لهجمات خاطفة قاضية."},
		{"id": "nightstalker_apex", "title": "Shadow Sovereign", "ar": "سيّد الظلال الخاطف", "glyph": "🦅",
			"branch": "ranger", "tier": 4, "col": 0, "req_lv": 7, "prereq": ["beast_bane", "phantom_execution"],
			"eff": SkillData.Effect.CRIT_PCT, "per": 0.12, "max": 1, "cost": 3,
			"desc": "Ultimate Ranger Capstone: +12% Crit Chance, +10% Speed & +5 Attack.",
			"desc_ar": "ذروة الحارس الأسطورية: +12% فرصة ضربة حرجة، +10% سرعة، و+5 هجوم."},

		# ==================== SURVIVAL BRANCH (9 nodes · 5 Tiers) ====================
		{"id": "vital_endurance", "title": "Endurance", "ar": "قوة التحمل", "glyph": "❤",
			"branch": "survival", "tier": 0, "col": 0, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.MAX_HEALTH_FLAT, "per": 20.0, "max": 3, "cost": 1,
			"desc": "+20 Max Health & +10 Max Stamina per rank.",
			"desc_ar": "+20 صحة قصوى و+10 نشاط أقصى لكل رتبة."},
		{"id": "keen_gatherer", "title": "Gathering", "ar": "جمع الموارد", "glyph": "⛏",
			"branch": "survival", "tier": 0, "col": 1, "req_lv": 1, "prereq": [],
			"eff": SkillData.Effect.GATHER_BONUS, "per": 1.0, "max": 3, "cost": 1,
			"desc": "+1 bonus ore, timber, or herb yield when harvesting resource nodes.",
			"desc_ar": "+1 مورد إضافي من المعادن أو الأخشاب أو الأعشاب عند الحصاد."},
		{"id": "master_hunter", "title": "Hunting Instinct", "ar": "غريزة الصيد", "glyph": "🦌",
			"branch": "survival", "tier": 1, "col": 0, "req_lv": 2, "prereq": ["vital_endurance"],
			"eff": SkillData.Effect.LOOT_BONUS, "per": 0.15, "max": 3, "cost": 1,
			"desc": "+15% bonus gold & material drops from defeated creatures.",
			"desc_ar": "+15% ذهب وغنائم إضافية من الوحوش المهزومة لكل رتبة."},
		{"id": "artisan_smith", "title": "Master Crafting", "ar": "حرفية التصنيع", "glyph": "🔨",
			"branch": "survival", "tier": 1, "col": 1, "req_lv": 2, "prereq": ["keen_gatherer"],
			"eff": SkillData.Effect.CRAFT_BONUS, "per": 0.15, "max": 3, "cost": 1,
			"desc": "Crafted consumables yield extra charges; unlocks royal smithing efficiency.",
			"desc_ar": "شحنات إضافية عند تصنيع الجرعات وكفاءة متقدمة في الحدادة الملكية."},
		{"id": "pathfinder", "title": "Exploration", "ar": "مستكشف المملكة", "glyph": "🧭",
			"branch": "survival", "tier": 2, "col": 0, "req_lv": 3, "prereq": ["master_hunter"],
			"eff": SkillData.Effect.EXPLORATION_PCT, "per": 0.12, "max": 3, "cost": 1,
			"desc": "+12% Experience & Guild Reputation earned from all sources.",
			"desc_ar": "+12% خبرة وسمعة نقابة إضافية من جميع المهام والمعارك."},
		{"id": "royal_merchant", "title": "Golden Prosperity", "ar": "ثروة التجار الملكية", "glyph": "💰",
			"branch": "survival", "tier": 2, "col": 1, "req_lv": 3, "prereq": ["artisan_smith"],
			"eff": SkillData.Effect.LOOT_BONUS, "per": 0.20, "max": 3, "cost": 1,
			"desc": "+20% Gold rewards from quests, chests, and bounties per rank.",
			"desc_ar": "+20% مكافآت ذهب إضافية من الصناديق والعقود والغنائم لكل رتبة."},
		{"id": "resource_thrift", "title": "Alchemical Potency", "ar": "براعة الإكسير", "glyph": "⚗",
			"branch": "survival", "tier": 3, "col": 0, "req_lv": 5, "prereq": ["pathfinder"],
			"eff": SkillData.Effect.RESOURCE_EFFICIENCY, "per": 0.25, "max": 2, "cost": 2,
			"desc": "+25% Potion healing/mana restoration & +25% Stamina regen.",
			"desc_ar": "+25% فعالية جرعات الصحة والمانا و+25% سرعة تجدد النشاط."},
		{"id": "guardian_vitality", "title": "Titanic Heart", "ar": "قلب الحارس العملاق", "glyph": "🛡",
			"branch": "survival", "tier": 3, "col": 1, "req_lv": 5, "prereq": ["royal_merchant"],
			"eff": SkillData.Effect.MAX_HEALTH_FLAT, "per": 35.0, "max": 2, "cost": 2,
			"desc": "+35 Max Health and +2.5 Defense per rank.",
			"desc_ar": "+35 صحة قصوى و+2.5 دفاع صلب لكل رتبة."},
		{"id": "immortal_warden", "title": "Warden of Eldoria", "ar": "حارس إلدوريا الخالد", "glyph": "🌳",
			"branch": "survival", "tier": 4, "col": 0, "req_lv": 7, "prereq": ["resource_thrift", "guardian_vitality"],
			"eff": SkillData.Effect.MAX_HEALTH_FLAT, "per": 75.0, "max": 1, "cost": 3,
			"desc": "Ultimate Survival Capstone: +75 Max Health, +25% Potions & +20% XP.",
			"desc_ar": "ذروة النجاة الأسطورية: +75 صحة قصوى، +25% قوة الجرعات، و+20% خبرة."},
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
		s.description_ar = String(d.get("desc_ar", ""))
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
