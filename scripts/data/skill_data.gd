class_name SkillData
extends Resource
## Interactive Skill Tree node definition (4 branches: warrior, mage, ranger, survival).
## Enum indices 0..3 preserved for existing .tres resources.

enum Effect {
	ATTACK_FLAT,
	DEFENSE_FLAT,
	SPEED_PCT,
	MAX_HEALTH_FLAT,
	HEAVY_PCT,
	BLOCK_PCT,
	CRIT_PCT,
	SPELL_POWER,
	MANA_EFFICIENCY,
	ELEMENTAL_MASTERY,
	RANGED_POWER,
	CRIT_DAMAGE_PCT,
	TRAP_SNARE,
	DODGE_BONUS,
	BEAST_DMG_PCT,
	GATHER_BONUS,
	LOOT_BONUS,
	CRAFT_BONUS,
	ENDURANCE_BONUS,
	EXPLORATION_PCT,
	RESOURCE_EFFICIENCY,
	BERSERKER_RAGE,
	COMBO_FINISHER_PCT,
	LIFESTEAL_PCT,
}

@export var id: String = ""
@export var title: String = ""
@export var title_ar: String = ""
@export_multiline var description: String = ""
@export_multiline var description_ar: String = ""
@export var icon_glyph: String = "✦"
@export_enum("warrior", "mage", "ranger", "survival") var branch: String = "warrior"
@export var tier: int = 0
@export var column: int = 0
@export var required_level: int = 1
@export var prerequisites: Array[String] = []
@export var effect: Effect = Effect.ATTACK_FLAT
@export var per_rank: float = 2.0
@export var max_rank: int = 3
@export var point_cost: int = 1
@export var active_element: String = ""
