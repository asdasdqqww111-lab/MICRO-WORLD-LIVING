class_name HeroClassDB
extends RefCounted
## Defines the 4 playable Hero Classes of Eldoria with real KayKit 3D rigs,
## class attribute bonuses, starting equipment, and signature starting skills.

const CLASS_ORDER: Array[String] = ["knight", "mage", "ranger", "barbarian"]

const CLASSES := {
	"knight": {
		"id": "knight",
		"title_en": "Vanguard Knight",
		"title_ar": "فارس الطليعة",
		"glyph": "🛡",
		"accent": Color(0.45, 0.72, 1.0),
		"model_path": "res://assets_realistic/models/characters/knight_hero.glb",
		"desc_en": "Armored defender of Eldoria. High defense, shield mastery, and balanced melee power.",
		"desc_ar": "مدافع مدرّع من فرسان إلدوريا؛ دفاع متين وإتقان للتروس وتوازن قتالي عالٍ.",
		"hp_bonus": 0.0,
		"mp_bonus": 0.0,
		"sp_bonus": 0.0,
		"atk_bonus": 0.0,
		"def_bonus": 3.0,
		"mag_bonus": 0.0,
		"crit_bonus": 0.0,
		"speed_mult": 1.0,
		"starting_skill": "",
		"items": [
			{"id": "rusty_sword", "count": 1},
			{"id": "oak_shield", "count": 1},
			{"id": "bread", "count": 2},
			{"id": "health_potion", "count": 2},
			{"id": "mana_elixir", "count": 1},
		],
		"equip": ["rusty_sword", "oak_shield"],
	},
	"mage": {
		"id": "mage",
		"title_en": "Arcane Battlemage",
		"title_ar": "ساحر الأثير",
		"glyph": "✦",
		"accent": Color(0.68, 0.52, 1.0),
		"model_path": "res://assets_realistic/models/characters/hero_mage.glb",
		"desc_en": "Wielder of Fire, Frost, and Storm magic. Deep Mana pool, rapid spellcasting, and arcane signet.",
		"desc_ar": "سيد تعاويذ النار والجليد والبرق؛ مخزون مانا واسع وقوة سحرية مدمّرة عن بُعد.",
		"hp_bonus": -8.0,
		"mp_bonus": 45.0,
		"sp_bonus": 0.0,
		"atk_bonus": -1.0,
		"def_bonus": 0.0,
		"mag_bonus": 9.0,
		"crit_bonus": 0.05,
		"speed_mult": 1.03,
		"starting_skill": "fire_bolt",
		"items": [
			{"id": "rusty_sword", "count": 1},
			{"id": "guild_ring", "count": 1},
			{"id": "bread", "count": 2},
			{"id": "health_potion", "count": 2},
			{"id": "mana_elixir", "count": 3},
		],
		"equip": ["rusty_sword", "guild_ring"],
	},
	"ranger": {
		"id": "ranger",
		"title_en": "Woodland Ranger",
		"title_ar": "حارس الغابات",
		"glyph": "🏹",
		"accent": Color(0.42, 0.88, 0.58),
		"model_path": "res://assets_realistic/models/characters/hero_ranger.glb",
		"desc_en": "Swift hooded scout of the western woods. Superior speed, stamina, dodge rolls, and critical strikes.",
		"desc_ar": "كشّاف رشيق من غابات إلدوريا؛ سرعة عالية ومراوغة خاطفة وضربات حرجة قاتلة.",
		"hp_bonus": 5.0,
		"mp_bonus": 10.0,
		"sp_bonus": 25.0,
		"atk_bonus": 2.5,
		"def_bonus": 1.5,
		"mag_bonus": 1.0,
		"crit_bonus": 0.12,
		"speed_mult": 1.10,
		"starting_skill": "swift_feet",
		"items": [
			{"id": "rusty_sword", "count": 1},
			{"id": "leather_armor", "count": 1},
			{"id": "bread", "count": 2},
			{"id": "health_potion", "count": 2},
			{"id": "mana_elixir", "count": 1},
		],
		"equip": ["rusty_sword", "leather_armor"],
	},
	"barbarian": {
		"id": "barbarian",
		"title_en": "Highland Berserker",
		"title_ar": "محارب المرتفعات",
		"glyph": "🪓",
		"accent": Color(0.96, 0.48, 0.34),
		"model_path": "res://assets_realistic/models/characters/npc_smith.glb",
		"desc_en": "Fierce northern warrior wielding heavy steel. Massive vitality and devastating cleave attacks.",
		"desc_ar": "محارب جبلي شرس؛ صحة عالية وقوة هجومية ساحقة في الضربات الثقيلة والالتحام.",
		"hp_bonus": 30.0,
		"mp_bonus": -10.0,
		"sp_bonus": 15.0,
		"atk_bonus": 5.5,
		"def_bonus": 2.0,
		"mag_bonus": 0.0,
		"crit_bonus": 0.06,
		"speed_mult": 1.04,
		"starting_skill": "mighty_blow",
		"items": [
			{"id": "iron_sword", "count": 1},
			{"id": "bread", "count": 2},
			{"id": "health_potion", "count": 3},
			{"id": "mana_elixir", "count": 1},
		],
		"equip": ["iron_sword"],
	},
}

static func has_class(class_id: String) -> bool:
	return CLASSES.has(class_id)

static func get_class_def(class_id: String) -> Dictionary:
	if CLASSES.has(class_id):
		return CLASSES[class_id] as Dictionary
	return CLASSES["knight"] as Dictionary

static func all_class_ids() -> Array[String]:
	return CLASS_ORDER.duplicate()

static func model_for(class_id: String) -> String:
	var def := get_class_def(class_id)
	return String(def.get("model_path", "res://assets/characters/player/Knight.glb"))
