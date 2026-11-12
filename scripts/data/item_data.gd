class_name ItemData
extends Resource
## Data-driven item definition. One .tres per concrete item in resources/items/.

enum Category { MATERIAL, CONSUMABLE, WEAPON, ARMOR, HELMET, QUEST, MISC }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: Category = Category.MATERIAL
@export var max_stack: int = 1
@export var value: int = 1
@export var attack_bonus: float = 0.0
@export var defense_bonus: float = 0.0
@export var heal_amount: float = 0.0
@export var icon_color: Color = Color(0.75, 0.75, 0.8)
@export_enum("none", "weapon", "armor", "helmet") var equip_slot: String = "none"

func is_equippable() -> bool:
	return equip_slot != "none"

func is_consumable() -> bool:
	return category == Category.CONSUMABLE

func is_stackable() -> bool:
	return max_stack > 1

func icon_letter() -> String:
	return display_name.substr(0, 1).to_upper()
