class_name CraftingScreen
extends MenuScreen
## Blacksmith Forge & Apothecary Alchemy Crafting Interface.

var station_filter: String = "all"

func _ready() -> void:
	configure("Forge & Alchemy Crafting", "crafting")
	super._ready()

func refresh() -> void:
	clear_content()
	var ar := Localization.is_arabic()
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)

	var st_defs := [
		["all", "جميع الورش" if ar else "All Stations"],
		["forge", "🔥 سندان الحدادة" if ar else "🔥 Blacksmith Forge"],
		["alchemy", "⚗ منضدة الخيمياء" if ar else "⚗ Alchemy Table"],
	]
	for st: Array in st_defs:
		var key := String(st[0])
		var btn := UIFactory.button(String(st[1]), 38)
		btn.toggle_mode = true
		btn.button_pressed = (station_filter == key)
		btn.pressed.connect(func() -> void:
			station_filter = key
			refresh())
		tabs.add_child(btn)

	content.add_child(UIFactory.label(
		("الذهب: %d  ·  اجمع خام الحديد والأخشاب والأعشاب حول مدينة إلدوريا!" if ar else "Gold: %d  ·  Gather Iron Ore, Timber & Herbs across Eldoria!") % GameManager.gold,
		15, UIFactory.GOLD))
	content.add_child(UIFactory.hsep())

	var recipes := CraftingDB.all_recipes()
	for recipe: Dictionary in recipes:
		var st_kind := String(recipe.get("station", "forge"))
		if station_filter != "all" and st_kind != station_filter:
			continue
		content.add_child(_build_recipe_row(recipe))

func _build_recipe_row(recipe: Dictionary) -> Control:
	var ar := Localization.is_arabic()
	var rid := String(recipe.get("id", ""))
	var out_id := String(recipe.get("output_id", ""))
	var out_cnt := int(recipe.get("output_count", 1))
	var item := ItemDB.get_item(out_id)
	var can := CraftingDB.can_craft(rid, GameManager.inventory)

	var card := UIFactory.card_panel(item.rarity_color() if item != null else UIFactory.GOLD_DIM)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 3)
	row.add_child(left)

	var rname := Localization.item_name(item) if (ar and item != null) else String(recipe.get("title", item.display_name if item != null else rid))
	left.add_child(UIFactory.label("%s ×%d  [%s]" % [
		rname, out_cnt, item.rarity_name() if item != null else ("تصنيع" if ar else "Craft")], 18,
		item.rarity_color() if item != null else UIFactory.GOLD))
	if item != null:
		left.add_child(UIFactory.wrapped_label(Localization.item_desc(item), 14, UIFactory.TEXT_DIM))

	var req_parts: PackedStringArray = []
	for ing: Dictionary in recipe.get("ingredients", []):
		var mat_id := String(ing.get("id", ""))
		var need := int(ing.get("count", 1))
		var have := GameManager.inventory.count_item(mat_id)
		var mat_item := ItemDB.get_item(mat_id)
		var mname := Localization.item_name(mat_item) if mat_item != null else mat_id
		req_parts.append("%s (%d/%d)" % [mname, have, need])
	left.add_child(UIFactory.wrapped_label((("المواد المطلوبة: " if ar else "Materials: ") + "  ·  ".join(req_parts)), 14,
		UIFactory.ACCENT if can else UIFactory.TEXT_DIM))

	var craft_btn := UIFactory.button(Localization.tr_key("craft"), 46)
	craft_btn.custom_minimum_size = Vector2(138, 46)
	craft_btn.disabled = not can
	craft_btn.pressed.connect(func() -> void:
		if GameManager.craft_recipe(rid):
			refresh())
	row.add_child(craft_btn)
	return card
