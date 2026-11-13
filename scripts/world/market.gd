class_name Market
extends RefCounted
## Eldoria Merchant, Blacksmith & Guild Quartermaster Economy.
## Deterministic daily price swings + Adventurers Guild Rank discount!

const STOCK: Array[String] = [
	"health_potion", "mana_elixir", "bread", "venison",
	"iron_sword", "steel_greatsword", "oak_shield", "iron_shield",
	"leather_armor", "knight_plate", "iron_helmet", "guild_ring", "torch",
]

const MERCHANT_STOCK: Array[String] = [
	"health_potion", "mana_elixir", "bread", "venison", "herb_redcap", "herb_moonpetal", "torch",
]

const BLACKSMITH_STOCK: Array[String] = [
	"iron_sword", "steel_greatsword", "oak_shield", "iron_shield",
	"leather_armor", "knight_plate", "iron_helmet", "iron_ingot",
]

const QUARTERMASTER_STOCK: Array[String] = [
	"health_potion", "mana_elixir", "iron_shield", "guild_aegis", "guild_ring", "steel_greatsword",
]

const SELL_RATIO := 0.45
const MAX_SWING := 0.16

static func price(item_id: String, day: int) -> int:
	var data := ItemDB.get_item(item_id)
	if data == null:
		return 0
	var swing := _swing(item_id, day)
	var disc := GameManager.guild.shop_discount_multiplier() if GameManager != null and GameManager.guild != null else 1.0
	return maxi(1, int(round(float(data.value) * (1.0 + swing) * disc)))

static func sell_price(item_id: String, day: int) -> int:
	var data := ItemDB.get_item(item_id)
	if data == null:
		return 0
	var swing := _swing(item_id, day)
	var raw := float(data.value) * (1.0 + swing) * SELL_RATIO
	return maxi(1, int(round(raw)))

static func _swing(item_id: String, day: int) -> float:
	var seed_value: int = absi(hash(item_id) + day * 7919)
	var normalized: float = float(seed_value % 1000) / 999.0
	return (normalized * 2.0 - 1.0) * MAX_SWING

static func stock_for(day: int, role_hint: String = "") -> Array:
	var list: Array[String] = STOCK
	match role_hint:
		"merchant": list = MERCHANT_STOCK
		"blacksmith": list = BLACKSMITH_STOCK
		"quartermaster": list = QUARTERMASTER_STOCK
	var out: Array = []
	for item_id: String in list:
		if not ItemDB.has(item_id):
			continue
		out.append({"id": item_id, "price": price(item_id, day)})
	return out

static func sellable_items() -> Array:
	var out: Array = []
	for item: ItemData in ItemDB.all_items():
		if item.category != ItemData.Category.QUEST:
			out.append(item.id)
	out.sort()
	return out
