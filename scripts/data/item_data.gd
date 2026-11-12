class_name ItemData
extends Resource
## Data-driven item definition. One .tres per concrete item in resources/items/.
## Enum order 0..6 preserved for compatibility with existing .tres resources.

enum Category { MATERIAL, CONSUMABLE, WEAPON, ARMOR, HELMET, QUEST, MISC, SHIELD, ACCESSORY }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: Category = Category.MATERIAL
@export var rarity: Rarity = Rarity.COMMON
@export var max_stack: int = 1
@export var value: int = 1
@export var attack_bonus: float = 0.0
@export var defense_bonus: float = 0.0
@export var magic_bonus: float = 0.0
@export var crit_bonus: float = 0.0
@export var heal_amount: float = 0.0
@export var mana_amount: float = 0.0
@export var stamina_amount: float = 0.0
@export var icon_color: Color = Color(0.75, 0.75, 0.8)
@export_enum("none", "weapon", "armor", "helmet", "shield", "accessory") var equip_slot: String = "none"

func is_equippable() -> bool:
	return equip_slot != "none"

func is_consumable() -> bool:
	return category == Category.CONSUMABLE

func is_stackable() -> bool:
	return max_stack > 1

func icon_letter() -> String:
	return display_name.substr(0, 1).to_upper() if not display_name.is_empty() else "?"

func rarity_name() -> String:
	match rarity:
		Rarity.UNCOMMON: return "Uncommon"
		Rarity.RARE: return "Rare"
		Rarity.EPIC: return "Epic"
		Rarity.LEGENDARY: return "Legendary"
		Rarity.MYTHIC: return "Mythic"
		_: return "Common"

func rarity_color() -> Color:
	match rarity:
		Rarity.UNCOMMON: return Color(0.38, 0.82, 0.44)
		Rarity.RARE: return Color(0.35, 0.62, 0.96)
		Rarity.EPIC: return Color(0.74, 0.42, 0.96)
		Rarity.LEGENDARY: return Color(0.96, 0.68, 0.22)
		Rarity.MYTHIC: return Color(0.98, 0.34, 0.42)
		_: return Color(0.82, 0.84, 0.86)
