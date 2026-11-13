class_name TowerDB
extends RefCounted
## Data-driven definitions for the 100-floor Celestial Ascent Tower.
## Ten themed regions, one unique Floor Master per floor, bilingual names.
## Pure static data: zero scene build cost, headless-testable.

const FLOOR_COUNT := 100
const TOWER_ORIGIN := Vector3(-500.0, 0.0, -200.0)
const FLOOR_STRIDE := 6.0          # vertical distance between stacked floor origins
const FLOOR_HALF := 13.0            # half-size of one floor platform
const SPAWN_OFFSET := Vector3(0.0, 1.2, 9.0)
const TOWER_GATE_OVERWORLD := Vector3(-52.0, 0.0, 34.0)

## 10 themed regions. Keys must stay stable: floor region = region_for_floor().
const REGIONS := {
	"ancient_ruins": {
		"en": "Ancient Ruins", "ar": "الأطلال القديمة",
		"palette": [Color(0.42, 0.40, 0.36), Color(0.30, 0.27, 0.24)],
		"accent": Color(0.95, 0.90, 0.72), "mob": "skeleton_dungeon",
		"mob_count": 4, "floor": 1,
	},
	"crystal_caverns": {
		"en": "Crystal Caverns", "ar": "الكهوف البلورية",
		"palette": [Color(0.28, 0.36, 0.52), Color(0.16, 0.22, 0.38)],
		"accent": Color(0.45, 0.85, 1.0), "mob": "cave_bat",
		"mob_count": 4, "floor": 2,
	},
	"magical_forest": {
		"en": "Magical Forest", "ar": "الغابة السحرية",
		"palette": [Color(0.22, 0.40, 0.26), Color(0.14, 0.26, 0.18)],
		"accent": Color(0.55, 1.0, 0.65), "mob": "forest_goblin",
		"mob_count": 4, "floor": 3,
	},
	"volcanic_depths": {
		"en": "Volcanic Depths", "ar": "الأعماق البركانية",
		"palette": [Color(0.42, 0.20, 0.14), Color(0.24, 0.10, 0.08)],
		"accent": Color(1.0, 0.55, 0.20), "mob": "rock_golem",
		"mob_count": 4, "floor": 4,
	},
	"frozen_kingdom": {
		"en": "Frozen Kingdom", "ar": "المملكة المتجمدة",
		"palette": [Color(0.55, 0.70, 0.86), Color(0.32, 0.44, 0.62)],
		"accent": Color(0.80, 0.95, 1.0), "mob": "wraith_elite",
		"mob_count": 4, "floor": 5,
	},
	"undead_fortress": {
		"en": "Undead Fortress", "ar": "قلعة الأموات",
		"palette": [Color(0.34, 0.32, 0.40), Color(0.20, 0.19, 0.26)],
		"accent": Color(0.70, 1.0, 0.55), "mob": "skeleton_dungeon",
		"mob_count": 5, "floor": 6,
	},
	"buried_temples": {
		"en": "Buried Desert Temples", "ar": "المعابد المدفونة",
		"palette": [Color(0.66, 0.56, 0.34), Color(0.44, 0.36, 0.22)],
		"accent": Color(1.0, 0.85, 0.45), "mob": "forest_goblin",
		"mob_count": 5, "floor": 7,
	},
	"sky_isles": {
		"en": "Floating Sky Isles", "ar": "جزر السماء العائمة",
		"palette": [Color(0.50, 0.60, 0.80), Color(0.30, 0.38, 0.60)],
		"accent": Color(0.90, 0.95, 1.0), "mob": "cave_bat",
		"mob_count": 5, "floor": 8,
	},
	"demon_realms": {
		"en": "Demon Realms", "ar": "ممالك الشياطين",
		"palette": [Color(0.36, 0.14, 0.22), Color(0.20, 0.08, 0.12)],
		"accent": Color(0.98, 0.30, 0.42), "mob": "wraith_elite",
		"mob_count": 5, "floor": 9,
	},
	"divine_battlefield": {
		"en": "Divine Battlefield", "ar": "ساحة المعركة الإلهية",
		"palette": [Color(0.70, 0.66, 0.50), Color(0.46, 0.42, 0.32)],
		"accent": Color(1.0, 0.95, 0.60), "mob": "rock_golem",
		"mob_count": 5, "floor": 10,
	},
}

## 100 Floor Master identities: (en, ar) names, deterministic by floor index.
## Names are unique across the tower; the final floor is a unique final boss.
const FLOOR_MASTER_EN := [
	"Gravelord Vash", "Tombkeeper Nol", "Dust Warden Hex", "Rune Tyrant Korr", "Bone Sentinel Ix",
	"Crypt Adept Zama", "Sand Reaver Tul", "Relic Ghoul Vex", "Ashen Duke Marn", "Ruins Archon Kel",
	"Crystal Tyrant Ohm", "Shardwing Myla", "Deep Geode Zeth", "Prism Revenant Kaal", "Glimmerfang Rou",
	"Quartz Archon Vyl", "Splinter Duke Ebn", "Lumen Stalker Siv", "Aurora Shade Tama", "Cavern Sovereign Ozz",
	"Verdant Herald Fenn", "Thornmaw Grod", "Saplord Mire", "Bloom Warden Iris", "Rootbound Giant Uko",
	"Sporecaller Vani", "Grove Banshee Lys", "Vine Tyrant Drel", "Petal Reaver Mox", "Forest Sovereign Syl",
	"Magma Marshal Brand", "Emberjaw Karg", "Cinder Ghoul Dross", "Lava Weaver Ilm", "Ashborn Captain Rusk",
	"Forge Revenant Thod", "Flame Djinn Zara", "Obsidian Duke Vark", "Pyroclast Titan Ond", "Volcano Sovereign Mag",
	"Frost Baron Kold", "Icebound Sister Meya", "Glacier Ghoul Rime", "Snow Wraith Vassa", "Frozen Lancer Tuk",
	"Blizzard Herald Una", "Wintershade Count Nix", "Aurora Lich Vey", "Polar Titan Orm", "Frozen Sovereign Isa",
	"Bone Captain Dreg", "Grave Marshal Ost", "Crypt Baroness Vay", "Dread Knight Ulm", "Sepulcher Wraith Nom",
	"Skull Warlord Thass", "Charnel Priest Azu", "Mausoleum Lord Krex", "Deathshroud Titan Vok", "Undead Sovereign Mor",
	"Sand Prophet Geru", "Dune Colossus Bhur", "Scarab Lord Khep", "Oasis Horror Nef", "Temple Guardian Anu",
	"Sunstroke Wraith Ra", "Dust Archon Set", "Gilded Mummy Onkh", "Desert Titan Geb", "Buried Sovereign Nei",
	"Cloud Serpent Ryu", "Wind Djinn Siro", "Sky Corsair Vela", "Storm Herald Kaze", "Thunder Roc Zeph",
	"Zephyr Archon Nota", "Cumulon Lord Nimbus", "Starfall Revenant Astra", "Aether Titan Kael", "Sky Sovereign Ur",
	"Pactbreaker Fiend Zorg", "Bloodwing Duchess Lil", "Hellforge Smith Gor", "Nightmare Steed Vhal", "Sin Lord Bel",
	"Voidweaver Nyx", "Doomsayer Malz", "Chaos Archon Koth", "Infernal Titan Bael", "Demon Sovereign Ark",
	"Seraph Blade Auri", "Archjudge Thal", "Halo Warden Mic", "Radiant Twin Sol", "Eclipse Saint Umbra",
	"Choir of Ruin Cano", "Zenith Revenant Pol", "Astral Marshal Vor", "Apocalypse Titan Ktulu",
	"Celestial Sovereign Astraeus, the Eternal Crown",
]

const FLOOR_MASTER_AR := [
	"فاش سيد الحصى", "نول حافظ القبور", "هكس وارن الغبار", "كور مستبد الرون", "إكس حرس العظام",
	"زاما خبير السرداب", "تول مُقطِّع الرمال", "فكس غول الآثار", "مارن دوق الرماد", "كل أرخص الأطلال",
	"أوم مستبد البلور", "مايلا جناح الشظية", "زيث الجيود العميق", "كال شبح المنشور", "رو نابض اللمعان",
	"فيل أرخص الكوارتز", "إبن دوق الشظايا", "سيف مُطارد الأنوار", "تاما ظل الشفق", "أوز سياح الكهوف",
	"فين مبعوث الخضرة", "غرد فك الأشواك", "ماير سيد النسغ", "آيريس حارسة الإزهار", "أوكو العملاق الجذوري",
	"فاني منادي الأبواغ", "ليس شبح الأدغال", "دريل مستبد الكروم", "مكس مغير البتلات", "سيل سيادة الغابة",
	"براند مارشال الصهارة", "كارج فك الجمر", "دروس غول الرماد", "إيلم ناسج الحمم", "روسك كابتن المولود من الرماد",
	"ثود شبح الورشة", "زارا جنية اللهب", "فارك دوق السبج", "أوند تيتان الحمم البركانية", "ماج سيادة البركان",
	"كولد بارون الصقيع", "ميا الأخت المتجمدة", "رايم غول الجليد", "فاسا شبح الثلج", "توك الرامح المتجمد",
	"أونا مبعث العاصفة", "نيكس كونت ظل الشتاء", "في ملك الجليد الشفق", "أورم تيتان القطب", "إيزا سيادة المتجمد",
	"دريغ كابتن العظام", "أوست مارشال القبر", "فاي بارونة السرداب", "أولم فارس الرعب", "نوم شبح المقبرة",
	"ثاس زعيم حرب الجماجم", "أزو كاهن العظام", "كريكس سيد الضريح", "فوك تيتان أكفان الموت", "مور سيادة الأموات",
	"جيرو نبي الرمال", "بهور كولوسس الكثبان", "خِب سيد الجعارب", "نيف رعب الواحة", "آنو حارس المعبد",
	"را شبح ضربة الشمس", "ست أرخص الغبار", "أونخ المومياو المذهّب", "جب تيتان الصحراء", "ني سيادة المدفون",
	"ريو أفعى السحاب", "سيرو جنية الريح", "فيلا قرصان السماء", "كازي مبعث العاصفة", "زِف رعد الروك",
	"نوتا أرخص الزفير", "نيمبوس سيد الركام", "أسترا شبح سقوط النجوم", "كايل تيتان الأثير", "أور سيادة السماء",
	"زورغ شرير نقض العهود", "ليل دوقة الأجنحة الدامية", "غور حدّاد جهنم الزائفة", "فهال جواد الكابوس", "بيل سيد الخطيئة",
	"نيكس ناسج العدم", "مالز نذير الهلاك", "كوث أرخص الفوضى", "بعل تيتان الجحيم", "آرك سيادة الشياطين",
	"أوري نصل السيرافيم", "ثال قاضي السماء", "ميك حارس الهالة", "سول التوأم المشع", "أومبرا قدّيسة الخسوف",
	"كانو جوقة الخراب", "بول شبح الذروة", "فور مارشال النجوم", "كتولو تيتان نهاية العالم",
	"أسترايوس سيادة السماوات، التاج الأبدي",
]

## Which creature archetype the Floor Master fights like (reuses combat rig).
## Uses only archetypes already shipped in resources/creatures/*.tres.
## EXACTLY 100 entries, one per floor.
const FLOOR_MASTER_ARCHETYPE := [
	"skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon",
	"skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon",
	"cave_bat", "cave_bat", "cave_bat", "cave_bat", "cave_bat",
	"cave_bat", "cave_bat", "cave_bat", "cave_bat", "cave_bat",
	"forest_goblin", "forest_goblin", "forest_goblin", "forest_goblin", "forest_goblin",
	"forest_goblin", "forest_goblin", "forest_goblin", "forest_goblin", "forest_goblin",
	"rock_golem", "rock_golem", "rock_golem", "rock_golem", "rock_golem",
	"rock_golem", "rock_golem", "rock_golem", "rock_golem", "rock_golem",
	"wraith_elite", "wraith_elite", "wraith_elite", "wraith_elite", "wraith_elite",
	"wraith_elite", "wraith_elite", "wraith_elite", "wraith_elite", "wraith_elite",
	"skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon",
	"skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon", "skeleton_dungeon",
	"forest_goblin", "forest_goblin", "forest_goblin", "forest_goblin", "forest_goblin",
	"forest_goblin", "forest_goblin", "forest_goblin", "forest_goblin", "forest_goblin",
	"cave_bat", "cave_bat", "cave_bat", "cave_bat", "cave_bat",
	"cave_bat", "cave_bat", "cave_bat", "cave_bat", "cave_bat",
	"wraith_elite", "wraith_elite", "wraith_elite", "wraith_elite", "wraith_elite",
	"wraith_elite", "wraith_elite", "wraith_elite", "wraith_elite", "wraith_elite",
	"cave_bat", "cave_bat", "cave_bat", "cave_bat", "cave_bat",
	"rock_golem", "rock_golem",
	"skeleton_dungeon", "wraith_elite",
	"skeleton_dungeon",
]

## Returns the 1-based region key for a floor number (1..100).
static func region_for_floor(floor_num: int) -> String:
	var idx := clampi(floor_num - 1, 0, FLOOR_COUNT - 1) / 10
	match idx:
		0: return "ancient_ruins"
		1: return "crystal_caverns"
		2: return "magical_forest"
		3: return "volcanic_depths"
		4: return "frozen_kingdom"
		5: return "undead_fortress"
		6: return "buried_temples"
		7: return "sky_isles"
		8: return "demon_realms"
		_: return "divine_battlefield"

static func region_display(region_key: String) -> String:
	var r: Dictionary = REGIONS.get(region_key, {})
	return String(r.get("en", region_key))

static func region_display_ar(region_key: String) -> String:
	var r: Dictionary = REGIONS.get(region_key, {})
	return String(r.get("ar", region_key))

static func master_name(floor_num: int) -> String:
	var idx := clampi(floor_num - 1, 0, FLOOR_COUNT - 1)
	return String(FLOOR_MASTER_EN[idx])

static func master_name_ar(floor_num: int) -> String:
	var idx := clampi(floor_num - 1, 0, FLOOR_COUNT - 1)
	return String(FLOOR_MASTER_AR[idx])

static func master_archetype(floor_num: int) -> String:
	var idx := clampi(floor_num - 1, 0, FLOOR_COUNT - 1)
	return String(FLOOR_MASTER_ARCHETYPE[idx])

## Deterministic stat scaling for a Floor Master. Level 20 cap-safe.
static func master_stats(floor_num: int) -> Dictionary:
	var f := clampi(floor_num, 1, FLOOR_COUNT)
	var base := CreatureDB.get_creature(master_archetype(f))
	var hp := 120.0 + f * 18.0
	var dmg := 10.0 + f * 1.1
	var def := 2.0 + f * 0.35
	var xp := 45 + f * 7
	var gold := 12 + f * 3
	if base != null:
		hp = maxf(hp, base.max_health * 1.6)
		dmg = maxf(dmg, base.damage * 1.5)
	return {"hp": hp, "damage": dmg, "defense": def, "xp": xp, "gold": gold}

## Deterministic mob stat scaling per floor region.
static func mob_stats(floor_num: int) -> Dictionary:
	var region := REGIONS.get(region_for_floor(floor_num), {})
	var base_id := String(region.get("mob", "skeleton_dungeon"))
	var base := CreatureDB.get_creature(base_id)
	var f := clampi(floor_num, 1, FLOOR_COUNT)
	var hp := 34.0 + f * 2.2
	var dmg := 6.0 + f * 0.45
	if base != null:
		hp = maxf(hp, base.max_health)
		dmg = maxf(dmg, base.damage)
	return {"id": base_id, "hp": hp, "damage": dmg, "count": int(region.get("mob_count", 4))}

## Position helpers ------------------------------------------------------------
static func floor_origin(floor_num: int) -> Vector3:
	var f := clampi(floor_num, 1, FLOOR_COUNT)
	return TOWER_ORIGIN + Vector3(0.0, (f - 1) * FLOOR_STRIDE, 0.0)

static func floor_spawn(floor_num: int) -> Vector3:
	return floor_origin(floor_num) + SPAWN_OFFSET

## Every reward chest on a floor, deterministic.
static func floor_reward_items(floor_num: int) -> Array:
	var f := clampi(floor_num, 1, FLOOR_COUNT)
	var out: Array = []
	if f % 10 == 0:
		out.append({"id": "knight_plate", "count": 1})
	elif f % 5 == 0:
		out.append({"id": "mana_elixir", "count": 2})
	elif f % 3 == 0:
		out.append({"id": "health_potion", "count": 2})
	else:
		out.append({"id": "health_potion", "count": 1})
	return out

## Gold & XP reward for clearing a floor (granted on master defeat via
## normal Creature death flow — no free rewards).
static func floor_clear_gold(floor_num: int) -> int:
	return 25 + floor_num * 4

static func validate() -> Dictionary:
	var errors: Array[String] = []
	if FLOOR_MASTER_EN.size() != FLOOR_COUNT:
		errors.append("EN master names size %d != 100" % FLOOR_MASTER_EN.size())
	if FLOOR_MASTER_AR.size() != FLOOR_COUNT:
		errors.append("AR master names size %d != 100" % FLOOR_MASTER_AR.size())
	if FLOOR_MASTER_ARCHETYPE.size() != FLOOR_COUNT:
		errors.append("Archetype list size %d != 100" % FLOOR_MASTER_ARCHETYPE.size())
	var seen_en := {}
	var seen_ar := {}
	for i in FLOOR_MASTER_EN.size():
		var en := String(FLOOR_MASTER_EN[i])
		var ar := String(FLOOR_MASTER_AR[i])
		if en.is_empty() or ar.is_empty():
			errors.append("Empty master name at index %d" % i)
		if seen_en.has(en):
			errors.append("Duplicate EN master name: %s" % en)
		if seen_ar.has(ar):
			errors.append("Duplicate AR master name: %s" % ar)
		seen_en[en] = true
		seen_ar[ar] = true
	for i in FLOOR_MASTER_ARCHETYPE.size():
		var a := String(FLOOR_MASTER_ARCHETYPE[i])
		if CreatureDB.get_creature(a) == null:
			errors.append("Master archetype '%s' has no CreatureDB entry" % a)
	for key in REGIONS.keys():
		var r: Dictionary = REGIONS[key]
		if not r.has("palette") or (r["palette"] as Array).size() != 2:
			errors.append("Region '%s' palette malformed" % key)
		var m := String(r.get("mob", ""))
		if CreatureDB.get_creature(m) == null:
			errors.append("Region '%s' mob '%s' missing from CreatureDB" % [key, m])
	return {"valid": errors.is_empty(), "errors": errors}
