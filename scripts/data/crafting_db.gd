class_name CraftingDB
extends RefCounted
## Data-driven Crafting Recipes for Blacksmith Forge, Alchemy & Survival.

const RECIPES: Array[Dictionary] = [
	{
		"id": "smelt_iron_ingot",
		"title": "Smelt Iron Ingot",
		"station": "forge",
		"output_id": "iron_ingot",
		"output_count": 1,
		"ingredients": [{"id": "iron_ore", "count": 2}, {"id": "wood", "count": 1}],
		"xp": 15,
	},
	{
		"id": "brew_health_potion",
		"title": "Brew Health Potion",
		"station": "alchemy",
		"output_id": "health_potion",
		"output_count": 1,
		"ingredients": [{"id": "herb_redcap", "count": 2}, {"id": "slime_gel", "count": 1}],
		"xp": 18,
	},
	{
		"id": "brew_mana_elixir",
		"title": "Brew Mana Elixir",
		"station": "alchemy",
		"output_id": "mana_elixir",
		"output_count": 1,
		"ingredients": [{"id": "herb_moonpetal", "count": 2}, {"id": "bone", "count": 1}],
		"xp": 20,
	},
	{
		"id": "craft_oak_shield",
		"title": "Craft Oak Round Shield",
		"station": "forge",
		"output_id": "oak_shield",
		"output_count": 1,
		"ingredients": [{"id": "wood", "count": 3}, {"id": "iron_ore", "count": 1}],
		"xp": 25,
	},
	{
		"id": "forge_iron_sword",
		"title": "Forge Iron Sword",
		"station": "forge",
		"output_id": "iron_sword",
		"output_count": 1,
		"ingredients": [{"id": "iron_ingot", "count": 2}, {"id": "wood", "count": 1}],
		"xp": 35,
	},
	{
		"id": "craft_hunter_jerkin",
		"title": "Stitch Ranger Leather Armor",
		"station": "forge",
		"output_id": "leather_armor",
		"output_count": 1,
		"ingredients": [{"id": "wolf_pelt", "count": 2}, {"id": "wood", "count": 1}],
		"xp": 30,
	},
	{
		"id": "forge_steel_greatsword",
		"title": "Forge Steel Greatsword (Rare)",
		"station": "forge",
		"output_id": "steel_greatsword",
		"output_count": 1,
		"ingredients": [{"id": "iron_ingot", "count": 3}, {"id": "bone", "count": 3}, {"id": "wood", "count": 2}],
		"xp": 55,
	},
	{
		"id": "forge_knight_plate",
		"title": "Forge Knight's Plate (Rare)",
		"station": "forge",
		"output_id": "knight_plate",
		"output_count": 1,
		"ingredients": [{"id": "iron_ingot", "count": 4}, {"id": "wolf_pelt", "count": 2}],
		"xp": 60,
	},
	{
		"id": "craft_guild_ring",
		"title": "Inscribe Wayfarer's Signet",
		"station": "alchemy",
		"output_id": "guild_ring",
		"output_count": 1,
		"ingredients": [{"id": "iron_ingot", "count": 1}, {"id": "herb_moonpetal", "count": 2}],
		"xp": 45,
	},
	{
		"id": "forge_eldoria_mythic_blade",
		"title": "Reforge Blade of Eldoria (Mythic)",
		"station": "forge",
		"output_id": "eldoria_mythic_blade",
		"output_count": 1,
		"ingredients": [{"id": "crypt_heart", "count": 1}, {"id": "iron_ingot", "count": 4}, {"id": "herb_moonpetal", "count": 2}],
		"xp": 140,
	},
]

static func all_recipes() -> Array[Dictionary]:
	return RECIPES

static func get_recipe(recipe_id: String) -> Dictionary:
	for r: Dictionary in RECIPES:
		if String(r.get("id", "")) == recipe_id:
			return r
	return {}

static func can_craft(recipe_id: String, inventory: Inventory = null) -> bool:
	var inv: Inventory = inventory if inventory != null else (GameManager.inventory if GameManager != null else null)
	var r := get_recipe(recipe_id)
	if r.is_empty() or inv == null:
		return false
	for ing: Dictionary in r.get("ingredients", []):
		if inv.count_item(String(ing["id"])) < int(ing["count"]):
			return false
	return not inv.is_full()

static func craft(recipe_id: String, inventory: Inventory = null, craft_skill_rank: int = 0) -> Variant:
	var inv: Inventory = inventory if inventory != null else (GameManager.inventory if GameManager != null else null)
	var r := get_recipe(recipe_id)
	if r.is_empty() or inv == null or not can_craft(recipe_id, inv):
		return false
	for ing: Dictionary in r.get("ingredients", []):
		inv.remove_item(String(ing["id"]), int(ing["count"]))
	var out_id := String(r["output_id"])
	var out_count := int(r["output_count"])
	var item_data := ItemDB.get_item(out_id)
	if craft_skill_rank > 0 and item_data != null and item_data.is_consumable():
		out_count += 1
	inv.add_item(out_id, out_count)
	return {
		"item_id": out_id,
		"count": out_count,
		"xp": int(r.get("xp", 15)),
	}
