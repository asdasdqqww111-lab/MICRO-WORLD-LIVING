class_name ShopScreen
extends MenuScreen
## Role-aware Merchant, Blacksmith & Guild Quartermaster Trading Screen.

var _npc: Node

func _ready() -> void:
	configure("Merchant Trade", "shop")
	super._ready()

func open_for(npc: Node = null) -> void:
	_npc = npc
	open()

func refresh() -> void:
	clear_content()
	var ar := Localization.is_arabic()
	var day := GameManager.world.day
	var role_hint := ""
	if _npc != null and _npc.get("role") != null:
		role_hint = String(_npc.get("role"))
		if title_label != null and _npc.get("display_name") != null:
			var nid := String(_npc.get("npc_id")) if _npc.get("npc_id") != null else ""
			var nm := Localization.npc_name(nid, String(_npc.get("display_name")))
			title_label.text = ("✦  متجر — %s" if ar else "✦  Trade — %s") % nm

	var disc := int(round((1.0 - GameManager.guild.shop_discount_multiplier()) * 100.0))
	var hdr_txt := ("الذهب: %d   ·   أسعار اليوم %d" if ar else "Gold: %d   ·   Day %d Prices") % [GameManager.gold, day]
	if disc > 0:
		hdr_txt += ("   ·   خصم رتبة النقابة %s: -%d%%" if ar else "   ·   Guild Rank %s Discount: -%d%%") % [GameManager.guild.current_rank(), disc]
	content.add_child(UIFactory.label(hdr_txt, 16, UIFactory.GOLD))
	content.add_child(UIFactory.hsep())

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 18)
	content.add_child(split)

	# Buy Column
	var buy_col := VBoxContainer.new()
	buy_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_col.add_theme_constant_override("separation", 6)
	split.add_child(buy_col)
	buy_col.add_child(UIFactory.label("✦ " + Localization.tr_key("buy"), 18, UIFactory.ACCENT))

	var g_unit := " ذهب" if ar else "g"
	for entry: Dictionary in Market.stock_for(day, role_hint):
		var item := ItemDB.get_item(String(entry["id"]))
		if item == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var info := UIFactory.label("%s [%s] — %d%s" % [Localization.item_name(item), item.rarity_name(), int(entry["price"]), g_unit], 15, item.rarity_color())
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var buy := UIFactory.button(Localization.tr_key("buy"), 40)
		buy.custom_minimum_size = Vector2(90, 40)
		buy.disabled = GameManager.gold < int(entry["price"])
		buy.pressed.connect(func() -> void:
			if GameManager.spend_gold(int(entry["price"])):
				GameManager.gain_item(String(entry["id"]), 1)
				if AudioManager != null:
					AudioManager.play_sfx("coin_pickup")
				refresh())
		row.add_child(buy)
		buy_col.add_child(row)

	# Sell Column
	var sell_col := VBoxContainer.new()
	sell_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_col.add_theme_constant_override("separation", 6)
	split.add_child(sell_col)
	sell_col.add_child(UIFactory.label("✦ " + Localization.tr_key("sell"), 18, UIFactory.GOLD))

	var sold_any := false
	for item_id: String in Market.sellable_items():
		var count := GameManager.inventory.count_item(item_id)
		if count <= 0:
			continue
		var item := ItemDB.get_item(item_id)
		if item == null:
			continue
		sold_any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var price := Market.sell_price(item_id, day)
		var info := UIFactory.label(("%s ×%d — %d ذهب للقطعة" if ar else "%s ×%d — %dg ea.") % [Localization.item_name(item), count, price], 15, item.rarity_color())
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var sell := UIFactory.button(Localization.tr_key("sell"), 40)
		sell.custom_minimum_size = Vector2(90, 40)
		sell.pressed.connect(func() -> void:
			if GameManager.inventory.remove_item(item_id, 1):
				GameManager.gain_gold(price)
				if AudioManager != null:
					AudioManager.play_sfx("coin_pickup")
				refresh())
		row.add_child(sell)
		sell_col.add_child(row)
	if not sold_any:
		sell_col.add_child(UIFactory.label("لا توجد غنائم قابلة للبيع في الحقيبة." if ar else "No sellable items in bag.", 15, UIFactory.TEXT_DIM))
