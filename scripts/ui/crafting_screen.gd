class_name CraftingScreen
extends MenuScreen
## Blacksmith Anvil Forge & Alchemy Workbench Screen (Section 16.6).

var station_filter: String = "all"

func _ready() -> void:
	configure("Crafting & Forge", "crafting")
	super._ready()

func open_station(station_kind: String = "all") -> void:
	station_filter = station_kind if not station_kind.is_empty() else "all"
	open()

func refresh() -> void:
	clear_content()
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)

	for st: Array in [["all", "All Recipes"], ["forge", "🔨 Blacksmith Forge"], ["alchemy", "⚗ Alchemy Bench"]]:
		var key := String(st[0])
		var b := UIFactory.button(String(st[1]), 40)
		b.toggle_mode = true
		b.button_pressed = (station_filter == key)
		b.pressed.connect(func() -> void:
			station_filter = key
			refresh())
		tabs.add_child(b)

	content.add_child(UIFactory.hsep())

	for recipe: Dictionary in CraftingDB.all_recipes():
		if station_filter != "all" and String(recipe.get("station", "")) != station_filter:
			continue
		content.add_child(_build_recipe_row(recipe))

func _build_recipe_row(recipe: Dictionary) -> Control:
	var rec_id := String(recipe["id"])
	var out_id := String(recipe["output_id"])
	var out_item := ItemDB.get_item(out_id)
	var can_make := CraftingDB.can_craft(rec_id, GameManager.inventory)

	var card := UIFactory.card_panel(out_item.rarity_color() if out_item != null else UIFactory.BORDER_GOLD)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)

	var r_badge := (" [%s]" % out_item.rarity_name()) if out_item != null else ""
	info.add_child(UIFactory.label(String(recipe["title"]) + r_badge, 18,
		out_item.rarity_color() if out_item != null else UIFactory.GOLD))

	if out_item != null:
		info.add_child(UIFactory.wrapped_label(out_item.description, 14, UIFactory.TEXT_DIM))

	var ing_parts: PackedStringArray = []
	for ing: Dictionary in recipe.get("ingredients", []):
		var iid := String(ing["id"])
		var need := int(ing["count"])
		var have := GameManager.inventory.count_item(iid)
		var idata := ItemDB.get_item(iid)
		var nm := idata.display_name if idata != null else iid
		ing_parts.append("%s %d/%d %s" % ["✔" if have >= need else "✖", have, need, nm])
	info.add_child(UIFactory.label("Materials: " + "   ·   ".join(ing_parts), 14,
		UIFactory.ACCENT if can_make else UIFactory.TEXT_DIM))

	var craft_btn := UIFactory.button(Localization.tr_key("craft"), 46)
	craft_btn.custom_minimum_size = Vector2(135, 46)
	craft_btn.disabled = not can_make
	craft_btn.pressed.connect(func() -> void:
		if GameManager.craft_recipe(rec_id):
			refresh())
	row.add_child(craft_btn)
	return card
