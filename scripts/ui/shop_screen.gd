class_name ShopScreen
extends MenuScreen
## Blacksmith trade window: fixed stock, daily prices, buy + sell.

var _npc: Node

func _ready() -> void:
	configure("Blacksmith")
	super._ready()

func open_for(npc: Node = null) -> void:
	_npc = npc
	open()

func refresh() -> void:
	clear_content()
	var day := GameManager.world.day
	content.add_child(UIFactory.label("Gold: %d   ·   prices for day %d" % [GameManager.gold, day],
		17, UIFactory.GOLD))
	content.add_child(UIFactory.hsep())
	content.add_child(UIFactory.label("Buy", 19, UIFactory.ACCENT))
	for entry: Dictionary in Market.stock_for(day):
		var item := ItemDB.get_item(String(entry["id"]))
		if item == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := UIFactory.label("%s  —  %d gold" % [item.display_name, int(entry["price"])], 17)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var buy := UIFactory.button("Buy", 44)
		buy.custom_minimum_size = Vector2(110, 44)
		buy.disabled = GameManager.gold < int(entry["price"])
		buy.pressed.connect(func() -> void:
			if GameManager.spend_gold(int(entry["price"])):
				GameManager.gain_item(String(entry["id"]), 1)
				refresh())
		row.add_child(buy)
		content.add_child(row)

	content.add_child(UIFactory.hsep())
	content.add_child(UIFactory.label("Sell", 19, UIFactory.TEXT_DIM))
	for item_id: String in Market.sellable_items():
		var count := GameManager.inventory.count_item(item_id)
		if count <= 0:
			continue
		var item := ItemDB.get_item(item_id)
		if item == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var price := Market.sell_price(item_id, day)
		var info := UIFactory.label("%s x%d  —  %d gold each" % [item.display_name, count, price], 17)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var sell := UIFactory.button("Sell", 44)
		sell.custom_minimum_size = Vector2(110, 44)
		sell.pressed.connect(func() -> void:
			if GameManager.inventory.remove_item(item_id, 1):
				GameManager.gain_gold(price)
				refresh())
		row.add_child(sell)
		content.add_child(row)
	if GameManager.inventory.used_slots() == 0:
		content.add_child(UIFactory.label("Nothing to sell yet.", 16, UIFactory.TEXT_DIM))
