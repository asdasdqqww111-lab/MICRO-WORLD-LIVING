class_name Market
extends RefCounted
## Fixed stock, deterministic daily price swings (same day = same price).

const STOCK: Array[String] = [
	"health_potion", "bread", "iron_sword", "leather_armor", "iron_helmet", "torch",
]
const SELL_RATIO := 0.4
const MAX_SWING := 0.18

static func price(item_id: String, day: int) -> int:
	var data := ItemDB.get_item(item_id)
	if data == null:
		return 0
	var swing := _swing(item_id, day)
	return maxi(1, int(round(float(data.value) * (1.0 + swing))))

static func sell_price(item_id: String, day: int) -> int:
	return maxi(1, int(round(float(price(item_id, day)) * SELL_RATIO)))

static func _swing(item_id: String, day: int) -> float:
	var seed_value: int = absi(hash(item_id) + day * 7919)
	var normalized: float = float(seed_value % 1000) / 999.0    # 0..1
	return (normalized * 2.0 - 1.0) * MAX_SWING

static func stock_for(day: int) -> Array:
	var out: Array = []
	for item_id: String in STOCK:
		if not ItemDB.has(item_id):
			continue
		out.append({"id": item_id, "price": price(item_id, day)})
	return out

static func sellable_items() -> Array:
	return ["bone", "iron_ore", "iron_ingot", "wolf_pelt", "slime_gel", "wood"]
