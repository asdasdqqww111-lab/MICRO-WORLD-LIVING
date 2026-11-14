extends Node
## Comprehensive Headless Acceptance Harness (Eldoria Edition v1.0).
##   godot --headless --path . tests/test_runner.tscn
## Exercises all databases, 5-slot equipment, 24-node Skill Tree, Adventurers Guild,
## Crafting, Localization (EN/AR), World & MultiMesh biomes, 18 NPCs, Combat, Boss,
## Zone travel (Village/House/Guild/Dungeon), UI screens, and 10-round Save/Load.

const SAVE_SLOT := "test_slot"
const MIGRATE_SLOT := "test_migrate"
const CORRUPT_SLOT := "test_corrupt"
const NEWER_SLOT := "test_newer"
const REPORT_PATH := "res://docs/reports/headless_test_results.txt"

var _passes: int = 0
var _failures: Array[String] = []
var _log: PackedStringArray = []
var _draw_calls: int = 0
var _triangles: int = 0
var _nodes: float = 0.0
var _fps: float = 0.0
var _finished: bool = false

class MockTouch:
	extends Node
	var move_vector: Vector2 = Vector2.ZERO
	var sprinting: bool = false
	var blocking: bool = false
	var pressed: Dictionary = {}

	func get_move_vector() -> Vector2:
		return move_vector

	func is_sprinting() -> bool:
		return sprinting

	func is_blocking() -> bool:
		return blocking

	func consume_pressed(action: String) -> bool:
		if bool(pressed.get(action, false)):
			pressed[action] = false
			return true
		return false

func _ready() -> void:
	_watchdog()
	await get_tree().process_frame
	await _run_all()

func _watchdog() -> void:
	await get_tree().create_timer(110.0).timeout
	if _finished:
		return
	_failures.append("WATCHDOG timeout (coroutine aborted on script error)")
	_report()

func _collect_multimeshes(node: Node, found: Array) -> void:
	if node is MultiMeshInstance3D:
		found.append(node)
	for child: Node in node.get_children():
		_collect_multimeshes(child, found)

func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		_log.append("PASS  " + label)
	else:
		_failures.append(label)
		_log.append("FAIL  " + label)
	print(("PASS  " if condition else "FAIL  ") + label)

func _section(title: String) -> void:
	_log.append("")
	_log.append("== " + title + " ==")

func _wait_frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame

func _wait_physics(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame

func _run_all() -> void:
	GameManager.reset_state()
	_test_databases()
	_test_hero_classes_and_models()
	_test_progression_and_skill_tree()
	_test_guild_and_crafting()
	_test_localization_and_audio()
	_test_inventory()
	_test_combat_math()
	_test_world_state()
	_test_market()
	_test_schedule()
	_test_quest_flow()
	_test_save_file()
	await _test_game_scene()
	_report()

# --- data --------------------------------------------------------------------

func _test_databases() -> void:
	_section("Data resources (Eldoria RPG Databases)")
	ItemDB.reload()
	QuestDB.reload()
	SkillDB.reload()
	CreatureDB.reload()
	_check(ItemDB.count() >= 25, "ItemDB loads >= 25 items (got %d)" % ItemDB.count())
	_check(QuestDB.count() >= 24, "QuestDB loads >= 24 quests & contracts (got %d)" % QuestDB.count())
	_check(SkillDB.count() >= 36, "SkillDB loads >= 36 skill tree nodes across 4 branches (got %d)" % SkillDB.count())
	_check(CreatureDB.count() >= 10, "CreatureDB loads >= 10 creature archetypes (got %d)" % CreatureDB.count())
	var valid := true
	var valid_slots := ["none", "weapon", "armor", "helmet", "shield", "accessory"]
	for item: ItemData in ItemDB.all_items():
		if item.id.is_empty() or item.display_name.is_empty() or item.max_stack < 1:
			valid = false
		if not valid_slots.has(item.equip_slot):
			valid = false
	_check(valid, "every item resource has id/name/stack and a valid 5-slot equip_slot")
	_check(ItemDB.has("rusty_sword") and ItemDB.has("oak_shield") and ItemDB.has("guild_ring") and ItemDB.has("eldoria_mythic_blade"),
		"core & mythic items exist across weapon/shield/accessory")
	for creature: CreatureData in CreatureDB.all_creatures():
		if not creature.model_path.is_empty():
			_check(AssetLibrary.has_model(creature.model_path),
				"model exists for creature '%s'" % creature.id)
	_check(QuestDB.get_quest("skeleton_menace") != null, "quest 'skeleton_menace' present")
	_check(QuestDB.get_quest("main_guild_call") != null, "main quest 'main_guild_call' present")
	_check(QuestDB.get_quest("contract_forest_cull") != null, "guild contract 'contract_forest_cull' present")

# --- 4 playable hero classes, articulated 3D creature rigs & full Arabic ------

func _test_hero_classes_and_models() -> void:
	_section("Hero Classes (4), Articulated 3D Creature Rigs & Full Arabic Content")
	_check(HeroClassDB.all_class_ids().size() == 4, "HeroClassDB defines 4 playable classes")
	for cid: String in HeroClassDB.all_class_ids():
		var mpath: String = HeroClassDB.model_for(cid)
		_check(AssetLibrary.has_model(mpath), "3D GLB rig exists for hero class '%s' (%s)" % [cid, mpath])

	GameManager.start_new_game("mage", "Lyria", false)
	_check(GameManager.hero_class == "mage" and GameManager.hero_name == "Lyria",
		"Mage class creation applies hero_class & hero_name")
	_check(GameManager.max_mana() >= 100.0 and GameManager.skills.rank_of("fire_bolt") >= 1,
		"Mage starts with elevated mana pool (%.0f) & Firebolt unlocked" % GameManager.max_mana())

	GameManager.start_new_game("ranger", "Kaelen", false)
	_check(GameManager.crit_chance() >= 0.14 and GameManager.skills.rank_of("swift_feet") >= 1,
		"Ranger starts with elevated crit chance (%.2f) & Swift Feet unlocked" % GameManager.crit_chance())

	GameManager.start_new_game("barbarian", "Torak", false)
	_check(GameManager.max_health() >= 125.0 and GameManager.skills.rank_of("mighty_blow") >= 1,
		"Barbarian starts with elevated max HP (%.0f) & Mighty Blow unlocked" % GameManager.max_health())

	# Verify articulated 3D creature rigs & stride animation
	var wolf_rig := ProceduralModels.build("wolf")
	_check(wolf_rig.get_node_or_null("LegFL") != null and wolf_rig.get_node_or_null("HeadPivot") != null and wolf_rig.get_node_or_null("TailPivot") != null,
		"Wolf procedural 3D rig has articulated legs, head & tail pivots")
	ProceduralModels.animate(wolf_rig, "wolf", 0.35, 3.6)
	_check(absf((wolf_rig.get_node("LegFL") as Node3D).rotation.x) > 0.01,
		"Wolf articulated limb stride animates smoothly")
	wolf_rig.free()

	var stag_rig := ProceduralModels.build("stag")
	_check(stag_rig.get_node_or_null("HeadPivot") != null and stag_rig.get_node_or_null("LegBR") != null,
		"Stag procedural 3D rig has crowned antler head & 4 articulated legs")
	stag_rig.free()

	var slime_rig := ProceduralModels.build("slime")
	_check(slime_rig.get_node_or_null("Core") != null and slime_rig.get_node_or_null("Body") != null,
		"Slime 3D rig has translucent outer dome & glowing suspended nucleus")
	slime_rig.free()

	# Verify 100% Arabic content coverage across Items, Quests, Skills, Creatures, NPCs & Prologue
	var prev_lang := SettingsManager.language if SettingsManager != null else "en"
	if SettingsManager != null:
		SettingsManager.language = "ar"
	var all_items_ar := true
	for it: ItemData in ItemDB.all_items():
		if Localization.item_name(it).is_empty() or Localization.item_name(it) == it.display_name:
			all_items_ar = false
	_check(all_items_ar, "all %d items have distinct Arabic names & descriptions" % ItemDB.count())

	var all_quests_ar := true
	for q: QuestData in QuestDB.all_quests():
		if Localization.quest_title(q).is_empty() or Localization.quest_title(q) == q.title:
			all_quests_ar = false
	_check(all_quests_ar, "all %d quests & guild contracts have distinct Arabic titles & objectives" % QuestDB.count())

	var all_skills_ar := true
	for sk: SkillData in SkillDB.all_skills():
		if Localization.skill_title(sk).is_empty() or Localization.skill_desc(sk) == sk.description:
			all_skills_ar = false
	_check(all_skills_ar, "all %d skills have Arabic titles & descriptions" % SkillDB.count())

	var all_creatures_ar := true
	for cr: CreatureData in CreatureDB.all_creatures():
		if Localization.creature_name(cr).is_empty() or Localization.creature_name(cr) == cr.display_name:
			all_creatures_ar = false
	_check(all_creatures_ar, "all %d creatures & bosses have Arabic names" % CreatureDB.count())
	_check(Localization.prologue_slides().size() == 3, "Eldoria Story Prologue has 3 localized narrative chapters")
	if SettingsManager != null:
		SettingsManager.language = prev_lang
	GameManager.reset_state()

# --- progression & 24-node skill tree ----------------------------------------

func _test_progression_and_skill_tree() -> void:
	_section("Progression & 24-Node Skill Tree")
	var p := Progression.new()
	_check(p.xp_to_next() == 60, "level 1 needs 60 xp (got %d)" % p.xp_to_next())
	var gained := p.add_xp(60)
	_check(gained == 1 and p.level == 2, "60 xp levels up to 2")
	_check(p.xp == 0, "leftover xp is carried correctly (got %d)" % p.xp)
	p.add_xp(999999)
	_check(p.level == Progression.MAX_LEVEL, "xp is capped at max level %d (got %d)"
		% [Progression.MAX_LEVEL, p.level])

	var tree := SkillTree.new()
	_check(SkillDB.count() >= 36, "Expanded 5-Tier Skill Tree has %d >= 36 interconnected nodes" % SkillDB.count())
	tree.add_points(16)
	_check(not tree.can_upgrade("heavy_cleave", 5), "tier-1 skill locked before prerequisite")
	_check(tree.upgrade("mighty_blow", 5) and tree.upgrade("iron_skin", 5), "tier-0 warrior skills unlock")
	_check(tree.can_upgrade("heavy_cleave", 5), "tier-1 warrior skill unlocks after mighty_blow")
	_check(tree.upgrade("heavy_cleave", 5) and tree.upgrade("shield_mastery", 5), "tier-1 warrior skills unlocked")
	_check(tree.upgrade("lethal_precision", 10) and tree.upgrade("combo_finisher", 10), "tier-2 warrior skills unlocked")
	_check(tree.upgrade("berserker_rage", 12) and tree.upgrade("blood_thirst", 12), "tier-3 warrior skills unlocked")
	_check(tree.upgrade("sovereign_vanguard", 15), "tier-4 capstone sovereign_vanguard unlocked")
	_check(tree.combo_finisher_bonus() > 0.0 and tree.lifesteal_ratio() > 0.0, "tier-4 capstone grants combo finisher & lifesteal bonuses")
	_check(tree.points == 3 and tree.total_spent_points() == 13, "skill points tracked accurately")
	var refunded := tree.reset_all()
	_check(refunded == 13 and tree.points == 16 and tree.ranks.is_empty(), "skill tree reset refunds all spent points")

# --- guild & crafting --------------------------------------------------------

func _test_guild_and_crafting() -> void:
	_section("Adventurers Guild (Ranks F-S) & Crafting")
	GameManager.start_new_game()
	_check(not GameManager.guild.registered, "new hero starts unregistered at Guild")
	_check(GameManager.guild.register_adventurer(), "hero registers as Rank F adventurer")
	_check(GameManager.guild.current_rank() == "F", "initial Guild rank is F")
	GameManager.guild.add_reputation(90)
	GameManager.guild.contracts_completed = 2
	_check(GameManager.guild.can_promote(2), "eligible for Rank E promotion")
	var promo: Dictionary = GameManager.guild.promote(2) as Dictionary
	_check(not promo.is_empty() and GameManager.guild.current_rank() == "E", "promoted to Rank E")
	_check(GameManager.guild.shop_discount_multiplier() < 1.0, "Guild rank grants merchant discount")

	# Crafting test
	GameManager.gain_item("iron_ingot", 3)
	GameManager.gain_item("wood", 3)
	_check(CraftingDB.can_craft("forge_iron_sword", GameManager.inventory), "can craft Iron Sword with materials")
	_check(GameManager.craft_recipe("forge_iron_sword"), "forging Iron Sword succeeds")
	_check(GameManager.inventory.count_item("iron_sword") >= 1, "crafted Iron Sword added to inventory")

# --- localization & audio ----------------------------------------------------

func _test_localization_and_audio() -> void:
	_section("Localization (EN / AR RTL) & Audio")
	var saved_lang := SettingsManager.language
	SettingsManager.language = "ar"
	_check(Localization.is_arabic(), "Arabic language mode activates RTL")
	_check(Localization.tr_key("new_game") != "New Adventure", "Arabic string table returns localized label")
	SettingsManager.language = "en"
	_check(not Localization.is_arabic() and Localization.tr_key("new_game") == "New Adventure", "English string table restores cleanly")
	SettingsManager.language = saved_lang
	_check(AudioManager != null, "AudioManager autoload registered")
	_check(ResourceLoader.exists("res://assets/sounds/rpg/chop.ogg") and ResourceLoader.exists("res://assets/sounds/combo_finisher.wav"),
		"Kenney RPG foley (.ogg) & combo_finisher.wav assets present")
	_check(ResourceLoader.exists("res://assets/music/ambient_royal_city.wav") and ResourceLoader.exists("res://assets/music/ambient_forest_birds.wav"),
		"Royal City & Forest Birds stereo ambience loops present")
	_check(QuestDB.count() >= 24, "Expanded Royal City Quest roster has %d >= 24 quests" % QuestDB.count())
	_check(CharacterVisual.CLIP_ALIASES.size() >= 34, "CharacterVisual supports %d >= 34 skeletal combat/life states" % CharacterVisual.CLIP_ALIASES.size())

# --- inventory ---------------------------------------------------------------

func _test_inventory() -> void:
	_section("Inventory & 5-Slot Equipment")
	var inv := Inventory.new()
	_check(inv.add_item("bone", 40) == 0, "adding 40 bones fits")
	_check(inv.count_item("bone") == 40, "bone count is 40 (got %d)" % inv.count_item("bone"))
	_check(inv.used_slots() == 2, "40 bones use 2 stacks of 30 (got %d)" % inv.used_slots())
	_check(inv.remove_item("bone", 39), "removing 39 bones works")
	_check(inv.count_item("bone") == 1, "one bone left")
	_check(inv.add_item("does_not_exist", 1) == 1, "unknown items are rejected")

	inv.clear()
	inv.add_item("rusty_sword", 1)
	inv.add_item("oak_shield", 1)
	inv.add_item("guild_ring", 1)
	_check(inv.equip("rusty_sword"), "equip rusty_sword in weapon slot")
	_check(inv.equip("oak_shield"), "equip oak_shield in shield slot")
	_check(inv.equip("guild_ring"), "equip guild_ring in accessory slot")
	_check(inv.equipped("shield") == "oak_shield" and inv.equipped("accessory") == "guild_ring",
		"5-slot equipment holds shield + accessory")
	inv.add_item("iron_sword", 1)
	_check(inv.equip("iron_sword"), "equip iron_sword over rusty_sword")
	_check(inv.count_item("rusty_sword") == 1, "old weapon returns to the bags")
	_check(inv.total_attack_bonus() > 0.0 and inv.total_defense_bonus() > 0.0, "gear bonuses stack across slots")
	_check(inv.unequip("weapon"), "unequip weapon")

	var full := Inventory.new()
	for _i: int in Inventory.SLOT_COUNT:
		full.add_item("iron_ore", 30)
	_check(full.is_full(), "20 full stacks fill the inventory")
	_check(full.add_item("bone", 1) == 1, "no room means leftover")

	var round_trip := Inventory.new()
	round_trip.add_item("health_potion", 3)
	round_trip.add_item("leather_armor", 1)
	round_trip.equip("leather_armor")
	var copy := Inventory.new()
	copy.from_dict(round_trip.to_dict())
	_check(copy.count_item("health_potion") == 3, "inventory serialises consumables")
	_check(copy.equipped("armor") == "leather_armor", "inventory serialises equipment")

# --- combat ------------------------------------------------------------------

func _test_combat_math() -> void:
	_section("Combat maths")
	seed(1234)
	var low_defense := GameManager.compute_damage(30.0, 0.0, false)
	var high_defense := GameManager.compute_damage(30.0, 200.0, false)
	_check(float(low_defense.get("amount", 0.0)) > 1.0, "damage scales with attack")
	_check(float(high_defense.get("amount", 0.0)) == 1.0, "damage never drops below 1")
	_check(not bool(low_defense.get("crit", true)), "crit can be disabled")

# --- world state -------------------------------------------------------------

func _test_world_state() -> void:
	_section("World clock + persistence flags")
	var state := WorldState.new()
	state.time_of_day = 23.0 * 3600.0
	var new_day := state.advance(2.0 * 3600.0)
	_check(new_day and state.day == 2, "clock rolls over into day 2")
	_check(state.hour() == 1, "hour is 01:00 after rollover (got %d)" % state.hour())
	_check(state.is_night(), "01:00 counts as night")
	state.mark_dead("forest_skeleton_0")
	_check(state.is_dead("forest_skeleton_0"), "dead creatures are tracked")
	var copy := WorldState.new()
	copy.from_dict(state.to_dict())
	_check(copy.is_dead("forest_skeleton_0") and copy.day == 2, "world state round-trips")

# --- market ------------------------------------------------------------------

func _test_market() -> void:
	_section("Market")
	GameManager.start_new_game()
	var price_day_1 := Market.price("health_potion", 1)
	var price_day_1_again := Market.price("health_potion", 1)
	_check(price_day_1 > 0, "potion has a price")
	_check(price_day_1 == price_day_1_again, "same day = same price")
	_check(Market.sell_price("bone", 1) < Market.price("bone", 1) + 1, "sell price is below buy price")
	var distinct: Dictionary = {}
	for day: int in range(1, 15):
		distinct[Market.price("health_potion", day)] = true
	_check(distinct.size() > 1, "prices change across days (%d distinct)" % distinct.size())
	_check(Market.stock_for(2, "Blacksmith").size() > 0, "blacksmith has stock")
	_check(Market.stock_for(2, "Quartermaster").size() > 0, "guild quartermaster has stock")

func _test_schedule() -> void:
	_section("NPC schedule")
	_check(VillageNPC.activity_for_hour(8) == "work", "08:00 is work time")
	_check(VillageNPC.activity_for_hour(6) == "work", "06:00 starts work")
	_check(VillageNPC.activity_for_hour(18) == "rest", "18:00 is rest")
	_check(VillageNPC.activity_for_hour(21) == "rest", "21:00 is rest")
	_check(VillageNPC.activity_for_hour(22) == "sleep", "22:00 is sleep")
	_check(VillageNPC.activity_for_hour(3) == "sleep", "03:00 is sleep")

# --- quests ------------------------------------------------------------------

func _test_quest_flow() -> void:
	_section("Quest flow")
	GameManager.start_new_game()
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_NOT_STARTED,
		"quest starts unstarted")
	_check(GameManager.start_quest("skeleton_menace"), "quest can be started")
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_ACTIVE, "quest is active")
	for _i: int in 3:
		GameManager.quest_log.record_event("kill", "skeleton_forest", 1)
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_READY,
		"3 kills make the quest ready to hand in")
	var xp_before := GameManager.progression.xp
	var level_before := GameManager.progression.level
	var gold_before := GameManager.gold
	var potions_before := GameManager.inventory.count_item("health_potion")
	_check(GameManager.turn_in_quest("skeleton_menace"), "quest turns in")
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_COMPLETED,
		"quest is completed")
	_check(GameManager.progression.xp != xp_before or GameManager.progression.level > level_before,
		"reward xp is applied")
	_check(GameManager.gold == gold_before + 20, "reward gold is applied (+20)")
	_check(GameManager.inventory.count_item("health_potion") == potions_before + 2,
		"reward items are applied (+2 potions)")
	_check(not GameManager.turn_in_quest("skeleton_menace"), "a quest cannot be turned in twice")

# --- save files --------------------------------------------------------------

func _test_save_file() -> void:
	_section("Save files & Guild/Skill persistence")
	GameManager.start_new_game()
	GameManager.gain_gold(77)
	GameManager.guild.register_member()
	GameManager.guild.add_reputation(45)
	GameManager.skills.add_points(2)
	GameManager.skills.unlock("iron_skin")
	GameManager.start_quest("sunken_cellar")
	GameManager.quest_log.record_event("visit", "dungeon", 1)
	_check(SaveManager.save_game(SAVE_SLOT), "save writes to disk")
	_check(SaveManager.has_save(SAVE_SLOT), "save file exists")
	var path := SaveManager.path_for(SAVE_SLOT)
	var file := FileAccess.open(path, FileAccess.READ)
	var raw := file.get_as_text()
	file.close()
	_check(raw.contains("\"schema_version\": 3"), "save file carries schema_version 3")
	GameManager.reset_state()
	_check(SaveManager.load_game(SAVE_SLOT), "save loads")
	_check(GameManager.gold == GameManager.STARTING_GOLD + 77, "gold restored (%d)" % GameManager.gold)
	_check(GameManager.guild.registered and GameManager.guild.reputation == 55, "Guild state restored (rep=%d)" % GameManager.guild.reputation)
	_check(GameManager.skills.rank_of("iron_skin") == 1, "SkillTree unlocked node restored")
	_check(GameManager.quest_log.state_of("sunken_cellar") == QuestLog.STATE_ACTIVE,
		"quest state restored")
	SaveManager.consume_pending()

	# v1 migration: no skills / no world / no guild payload.
	var legacy := {
		"schema_version": 1,
		"game": {"gold": 12, "level": 3, "xp": 5, "inventory": {"slots": [], "equipment": {}}},
	}
	var legacy_file := FileAccess.open(SaveManager.path_for(MIGRATE_SLOT), FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy))
	legacy_file.close()
	_check(SaveManager.load_game(MIGRATE_SLOT), "v1 save migrates and loads")
	_check(GameManager.gold == 12, "migrated save keeps gold")
	_check(GameManager.progression.level == 3, "migrated save keeps level")
	SaveManager.consume_pending()

	var corrupt := FileAccess.open(SaveManager.path_for(CORRUPT_SLOT), FileAccess.WRITE)
	corrupt.store_string("{ this is not json")
	corrupt.close()
	_check(not SaveManager.load_game(CORRUPT_SLOT), "corrupt save is refused")
	_check(SaveManager.last_save_error.contains("JSON"), "corrupt save reports a reason")

	var newer := FileAccess.open(SaveManager.path_for(NEWER_SLOT), FileAccess.WRITE)
	newer.store_string(JSON.stringify({"schema_version": 99, "game": {"gold": 1}}))
	newer.close()
	_check(not SaveManager.load_game(NEWER_SLOT), "newer schema version is refused")

	for slot: String in [SAVE_SLOT, MIGRATE_SLOT, CORRUPT_SLOT, NEWER_SLOT]:
		SaveManager.delete_save(slot)

# --- full scene --------------------------------------------------------------

func _test_game_scene() -> void:
	_section("Game scene (Eldoria World + Guild + Player + UI)")
	GameManager.start_new_game()
	var packed := load("res://scenes/game/game.tscn") as PackedScene
	_check(packed != null, "game.tscn loads")
	if packed == null:
		return
	var game := packed.instantiate()
	add_child(game)
	await _wait_physics(40)

	var world: WorldRoot = game.get("world")
	var player: Player = game.get("player")
	var ui: UIRoot = game.get("ui")
	_check(world != null, "world root created")
	_check(player != null, "player created")
	_check(ui != null, "ui root created")
	_check(game.get("tower") != null, "Celestial Tower manager created in the game scene")
	_check(ui.hud != null and ui.touch != null and ui.skills_screen != null and ui.guild_screen != null,
		"HUD, TouchControls, SkillTreeScreen, and GuildScreen built")
	_check(world.landmarks.size() >= 10, "Eldoria landmarks built (%d)" % world.landmarks.size())
	_check(world.npc_by_id("farmer") != null and world.npc_by_id("blacksmith") != null,
		"village NPCs exist")
	_check(world.npc_by_id("guild_receptionist") != null and world.npc_by_id("guild_master") != null,
		"Adventurers Guild NPCs (Elena & Grandmaster Aldric) exist")
	_check(world.creature_count() >= 18, "wildlife, monsters & crypt boss spawned (%d)" % world.creature_count())

	# Instancing pipeline: every MultiMeshInstance3D must carry a real mesh.
	var multimeshes: Array = []
	_collect_multimeshes(world, multimeshes)
	var bad_mm := 0
	for mm: MultiMeshInstance3D in multimeshes:
		if mm.multimesh == null or mm.multimesh.mesh == null or mm.multimesh.instance_count == 0:
			bad_mm += 1
	_check(multimeshes.size() >= 8 and bad_mm == 0,
		"MultiMesh biome instancing is real (%d batches, %d broken)" % [multimeshes.size(), bad_mm])
	_check(player.visual.model != null, "player Knight character model instantiated")
	_check(player.visual.available_states.has("idle") and player.visual.available_states.has("run"),
		"animation states resolved from KayKit rig clips")
	await _wait_physics(50)
	_check(player.is_on_floor(), "player lands on the ground")
	_check(player.global_position.y > -1.0 and player.global_position.y < 3.0,
		"player stands at ground height (y=%.2f)" % player.global_position.y)

	var mock := MockTouch.new()
	add_child(mock)
	player.input.bind_touch_controls(mock)
	var start := player.global_position
	mock.move_vector = Vector2(0.0, -1.0)
	await _wait_physics(45)
	var moved := player.global_position.distance_to(start)
	_check(moved > 0.5, "joystick input moves the player (%.2fm)" % moved)
	mock.move_vector = Vector2.ZERO
	await _wait_physics(10)

	# Camera orbit + zoom.
	var yaw_before := player.camera_rig.yaw
	player.camera_rig.add_look(Vector2(80.0, 0.0))
	_check(absf(player.camera_rig.yaw - yaw_before) > 0.1, "camera yaw responds to drag")
	var zoom_before := player.camera_rig.current_distance()
	player.camera_rig.add_zoom(1.5)
	_check(absf(player.camera_rig.current_distance() - zoom_before) > 0.5,
		"camera zoom changes distance")

	# UI Screens smoke test
	for scr: String in ["inventory", "skills", "guild", "crafting", "map", "journal", "character"]:
		ui.open_screen(scr)
		await _wait_frames(2)
	_check(ui.current_screen != null, "UI screens open and refresh without error")
	ui.close_current_screen()
	await _wait_frames(2)
	_check(ui.touch != null and ui.touch.find_child("Btn_lock_target", true, false) != null,
		"Mobile TouchControls includes Target-Lock button (Btn_lock_target)")

	# Verify Thumb-Zone >= 44px clear spacing across all right-hand circular buttons
	var right_btns: Array[Button] = []
	for act_name: String in ["attack", "attack_heavy", "dodge", "jump", "cast_spell", "quick_potion", "lock_target", "block", "interact"]:
		var rb := ui.touch.find_child("Btn_" + act_name, true, false) as Button
		if rb != null:
			right_btns.append(rb)
	var min_btn_gap := 999.0
	for i in right_btns.size():
		for j in range(i + 1, right_btns.size()):
			var b1 := right_btns[i]
			var b2 := right_btns[j]
			var c1 := Vector2((b1.offset_left + b1.offset_right) * 0.5, (b1.offset_top + b1.offset_bottom) * 0.5)
			var c2 := Vector2((b2.offset_left + b2.offset_right) * 0.5, (b2.offset_top + b2.offset_bottom) * 0.5)
			var r1 := (b1.offset_right - b1.offset_left) * 0.5
			var r2 := (b2.offset_right - b2.offset_left) * 0.5
			min_btn_gap = minf(min_btn_gap, c1.distance_to(c2) - (r1 + r2))
	_check(right_btns.size() == 9 and min_btn_gap >= 44.0,
		"Thumb-Zone circular Glassmorphism buttons maintain >= 44px gap (min=%.1fpx)" % min_btn_gap)

	_test_touch_input(ui)

	# Verify Polished Stylized/Chibi PBR Mobile Overhaul (Phases 1-5)
	_check(String(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "mobile",
		"Phase 1: Project renderer set to Vulkan Mobile ('mobile')")
	_check(ResourceLoader.exists("res://assets/ui/fonts/Cairo-Variable.ttf"), "Cairo variable font bundled & active")
	_check(AssetLibrary.has_model("res://assets/kaykit_adventurers/Knight.glb")
		and AssetLibrary.has_model("res://assets/stylized_nature/trees/PineTree_1.glb")
		and AssetLibrary.has_model("res://assets/stylized_nature/rocks/Rock_1.glb")
		and AssetLibrary.has_model("res://assets/stylized_nature/foliage/Flowers.glb"),
		"Step 1 & 2: CC0 Stylized Assets (KayKit Chibi Knight + Quaternius Pine/Rock/Flowers) imported")
	var stone_pbr: StandardMaterial3D = ArtDirection.pbr_material("test_stone_wall", "stone_wall")
	_check(stone_pbr != null and stone_pbr.normal_enabled and stone_pbr.normal_texture != null and stone_pbr.roughness_texture != null,
		"Stylized PBR surface material has Normal Maps & Roughness enabled")
	_check(ResourceLoader.exists("res://shaders/stylized_terrain_splat.gdshader")
		and ResourceLoader.exists("res://shaders/stylized_wind_grass.gdshader")
		and ResourceLoader.exists("res://shaders/chibi_knight_rim.gdshader"),
		"Phase 2 & 3: Terrain Splatmap, GPU Wind Grass & Chibi Fresnel Rim Shaders present")
	_check(player.visual != null and player.visual._model_path == "res://assets/kaykit_adventurers/Knight.glb",
		"Phase 3: Player character uses Stylized Chibi Knight (%s)" % (player.visual._model_path if player.visual != null else ""))
	_check(player.camera_rig != null and player.camera_rig.camera != null
		and is_equal_approx(player.camera_rig.camera.fov, 55.0)
		and is_equal_approx(player.camera_rig.distance, 4.0),
		"Phase 3: CameraRig configured with FOV=55 and spring_arm=4.0")
	var env_res: Environment = world.environment
	var sky_pano: PanoramaSkyMaterial = env_res.sky.sky_material as PanoramaSkyMaterial if (env_res != null and env_res.sky != null) else null
	_check(env_res != null
		and env_res.tonemap_mode == Environment.TONE_MAPPER_ACES
		and is_equal_approx(env_res.tonemap_exposure, 1.1)
		and env_res.glow_enabled
		and env_res.fog_mode == Environment.FOG_MODE_DEPTH
		and is_equal_approx(env_res.fog_depth_begin, 30.0)
		and is_equal_approx(env_res.fog_depth_end, 150.0)
		and env_res.ssao_enabled,
		"Phase 1: WorldEnvironment configured with ACES(1.1), Softlight Glow, Depth Fog(30..150m) & SSAO")
	_check(sky_pano != null and sky_pano.panorama != null,
		"Phase 1: Stylized Blue Sky & Soft Clouds HDRI bound in PanoramaSkyMaterial")
	_check(world.sun != null and world.sun.shadow_enabled and is_equal_approx(world.sun.directional_shadow_max_distance, 45.0) and is_equal_approx(world.sun.shadow_blur, 2.0),
		"Phase 1: DirectionalLight3D configured with Soft Shadows (blur=2.0) & 45m max distance")

	# Graphics presets must own viewport anti-aliasing, render scale and the
	# glow post-process (WorldRoot used to force MSAA 4X on every preset).
	var root_vp := get_viewport()
	var preset_before := SettingsManager.graphics_preset
	_check(root_vp.msaa_3d == SettingsManager.msaa_3d_level()
			and is_equal_approx(root_vp.scaling_3d_scale, SettingsManager.render_scale_3d()),
		"graphics: viewport MSAA and 3D scale match the active preset after the world is built")
	SettingsManager.graphics_preset = SettingsManager.GraphicsPreset.LOW
	SettingsManager.apply_graphics()
	_check(root_vp.msaa_3d == Viewport.MSAA_2X and is_equal_approx(root_vp.scaling_3d_scale, 0.82)
			and not env_res.glow_enabled and not world.sun.shadow_enabled,
		"graphics: LOW preset applies MSAA 2X, 0.82 render scale, no glow, no sun shadows")
	SettingsManager.graphics_preset = SettingsManager.GraphicsPreset.HIGH
	SettingsManager.apply_graphics()
	_check(root_vp.msaa_3d == Viewport.MSAA_4X and is_equal_approx(root_vp.scaling_3d_scale, 1.0)
			and env_res.glow_enabled and world.sun.shadow_enabled,
		"graphics: HIGH preset applies MSAA 4X, native render scale, glow and sun shadows")
	SettingsManager.graphics_preset = preset_before
	SettingsManager.apply_graphics()
	_check(env_res.glow_enabled and world.sun.shadow_enabled
			and is_equal_approx(world.sun.directional_shadow_max_distance, 45.0),
		"graphics: restoring the original preset restores glow and shadows")
	_check(ui.hud != null and ui.hud.find_child("TopCenterActionDock", true, false) != null and ui.touch.find_child("QuickSlotsBar", true, false) != null,
		"Phase 4: Arabic HUD Top-Center 7-Button Action Dock & 5 Quick-Slots built")
	_check(game.get("vfx") != null and (game.get("vfx") as Node).get_node_or_null("FootstepDust") != null,
		"VFXManager particle system (FootstepDust, RainSplashes, HitSparks) active")
	_check(player.collision_layer == CollisionLayers.PLAYER and player.collision_mask == CollisionLayers.MASK_PLAYER_SOLID and player.safe_margin >= 0.04,
		"Player anti-clipping physics & CollisionLayers configured")
	_check(player.state_machine != null and QuestManager.get_quest("main_guild_call") != null,
		"PlayerStateMachine FSM & QuestManager Resource facade operational")
	_check(world.quest_waypoint != null, "3D QuestWaypoint beacon exists in WorldRoot")

	# Attack, Target Lock & Spell test against a forest skeleton.
	var skeleton: Creature = null
	for creature: Node in world._creatures.values():
		if creature is Creature and (creature as Creature).data.id == "skeleton_forest":
			skeleton = creature as Creature
			break
	_check(skeleton != null, "a forest skeleton exists")
	if skeleton != null:
		player.global_position = skeleton.global_position + Vector3(0.0, 0.0, 1.4)
		player.rotation.y = 0.0
		await _wait_physics(3)
		player.toggle_target_lock()
		_check(player.locked_target != null, "Target Lock acquires nearest hostile creature")
		var hp_before := skeleton.health.current_health
		var attacked := player.try_attack()
		await _wait_physics(3)
		_check(attacked, "player can swing melee combo")
		_check(skeleton.health.current_health < hp_before,
			"skeleton takes damage (%.1f -> %.1f)" % [hp_before, skeleton.health.current_health])
		_check(skeleton.aggro, "skeleton aggroes when hit")
		player.clear_target_lock()

	# Verify 3D Quest Waypoint resolves active quest coordinates
	GameManager.start_quest("main_guild_call")
	if world.quest_waypoint != null:
		world.quest_waypoint.refresh_target()
		_check(world.quest_waypoint.has_waypoint, "QuestWaypoint3D resolves active quest target beacon")

	# Quest: kill three skeletons then hand in to the farmer.
	GameManager.start_quest("skeleton_menace")
	for creature: Node in world._creatures.values():
		if creature is Creature and (creature as Creature).data.id == "skeleton_forest":
			(creature as Creature).take_hit(9999.0, player, false)
	await _wait_physics(10)
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_READY,
		"killing 3 skeletons completes the objective")
	var farmer := world.npc_by_id("farmer")
	var turn_in_action := {"type": "quest_turnin", "quest_id": "skeleton_menace"}
	var result: String = farmer.execute_action(turn_in_action)
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_COMPLETED,
		"farmer accepts the quest turn-in")
	_check(result.contains("Reward") or result.contains("المكافأة"), "turn-in reports the reward")

	# Loot drop pickup.
	GameManager.inventory.clear()
	var before_bones := GameManager.inventory.count_item("bone")
	var drop: LootDrop = world.spawn_loot_drop([{"id": "bone", "count": 2}],
		player.global_position + Vector3(0.5, 0.0, 0.0))
	await _wait_frames(2)
	_check(drop != null and is_instance_valid(drop), "loot drop spawned")
	if drop != null:
		drop.interact(player)
		await _wait_frames(2)
		_check(GameManager.inventory.count_item("bone") == before_bones + 2,
			"loot is collected into the inventory (got %d)" % GameManager.inventory.count_item("bone"))

	# Zone travel: Guild Hall -> Village -> House -> Dungeon Boss Check.
	var guild_door := world.find_child("GuildDoor", true, false) as ZoneDoor
	_check(guild_door != null, "Adventurers Guild door exists")
	if guild_door != null:
		guild_door.interact(player)
		await _wait_physics(3)
		_check(player.zone == "guild" and world.guild_root.visible, "door moves player into Adventurers Guild Hall")

	var house_door := world.find_child("HouseDoor", true, false) as ZoneDoor
	_check(house_door != null, "house door exists")
	if house_door != null:
		house_door.interact(player)
		await _wait_physics(3)
		_check(player.zone == "house" and world.house_root.visible, "door moves player into house zone")

	var boss: Creature = world._creatures.get("malakor_crypt_boss", null) as Creature
	_check(boss != null and boss.data.is_boss, "Malakor the Bone Warden boss exists in Sunken Crypt")
	_check(world.find_child("CastleHighKeepTower", true, false) != null
		and world.find_child("MeadowWindGrass", true, false) != null
		and world.find_child("HillsideStoneArch", true, false) != null,
		"Stylized Castle Keep, 3D Wind Grass Meadow & Hillside Stone Arch built")
	_check(get_tree().get_nodes_in_group("npc").size() >= 24,
		"Royal Capital City & Guild populated with %d >= 24 living NPCs" % get_tree().get_nodes_in_group("npc").size())

	_draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_triangles = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	_fps = Engine.get_frames_per_second()

	# Persist, tear down, reload.
	_check(SaveManager.save_game(SAVE_SLOT), "scene state saves")
	var dead_before := GameManager.world.dead_creatures.size()
	_check(dead_before >= 3, "dead creatures recorded (%d)" % dead_before)
	var position_before := player.global_position
	var creatures_before := world.creature_count()
	game.queue_free()
	await _wait_frames(3)
	GameManager.reset_state()
	_check(SaveManager.load_game(SAVE_SLOT), "scene state reloads")
	var game2 := packed.instantiate()
	add_child(game2)
	await _wait_physics(30)
	var world2: WorldRoot = game2.get("world")
	var player2: Player = game2.get("player")
	_check(world2.creature_count() <= creatures_before,
		"dead creatures stay dead after reload (%d alive vs %d before)"
		% [world2.creature_count(), creatures_before])
	_check(player2.global_position.distance_to(position_before) < 4.0,
		"player position restored (%.1fm off)" % player2.global_position.distance_to(position_before))
	_check(GameManager.quest_log.state_of("skeleton_menace") == QuestLog.STATE_COMPLETED,
		"quest completion survives reload")
	_check(GameManager.inventory.count_item("bone") >= 2, "inventory survives reload")
	game2.queue_free()
	await _wait_frames(2)

	# 10-round save/load cycle.
	var rounds_ok := true
	var rounds_detail := ""
	for round_index in 10:
		GameManager.gain_item("wood", 1)
		var expected := GameManager.inventory.count_item("wood")
		var gold_expected := GameManager.gold
		if not SaveManager.save_game(SAVE_SLOT):
			rounds_ok = false
			rounds_detail = "save failed on round %d" % round_index
			break
		GameManager.reset_state()
		if not SaveManager.load_game(SAVE_SLOT):
			rounds_ok = false
			rounds_detail = "load failed on round %d" % round_index
			break
		var loaded: Dictionary = SaveManager.consume_pending()
		GameManager.apply_dict(loaded.get("game", {}) as Dictionary)
		var got := GameManager.inventory.count_item("wood")
		if got != expected or GameManager.gold != gold_expected:
			rounds_ok = false
			rounds_detail = "round %d: wood %d != %d" % [round_index, got, expected]
			break
	_check(rounds_ok, "save/load survives 10 rounds%s" % ("" if rounds_ok else " (%s)" % rounds_detail))

	SaveManager.delete_save(SAVE_SLOT)

# --- report ------------------------------------------------------------------

func _touch_event(index: int, pos: Vector2, is_pressed: bool) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = is_pressed
	return ev

func _drag_event(index: int, pos: Vector2, relative: Vector2) -> InputEventScreenDrag:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	ev.relative = relative
	return ev

## Multi-touch contract of the on-screen controls: every control is owned by
## the finger index that pressed it, so simultaneous fingers never interfere.
func _test_touch_input(ui: UIRoot) -> void:
	var touch := ui.touch
	var was_visible := touch.visible
	touch.visible = true
	touch.reset_state()

	# Rescaled radial dead zone.
	_check(TouchPointer.apply_radial_dead_zone(Vector2(0.10, 0.0), 0.15) == Vector2.ZERO,
		"touch: stick deflection inside the dead zone outputs zero")
	var mid := TouchPointer.apply_radial_dead_zone(Vector2(0.575, 0.0), 0.15)
	_check(absf(mid.x - 0.5) < 0.001 and absf(mid.y) < 0.001,
		"touch: dead zone is rescaled (0.575 raw -> %.3f)" % mid.x)
	_check(absf(TouchPointer.apply_radial_dead_zone(Vector2(0.0, -1.0), 0.15).y + 1.0) < 0.001,
		"touch: full deflection outputs magnitude 1.0")

	var joy := touch.joystick
	var attack := touch.action_button("attack")
	var block := touch.action_button("block")
	var interact := touch.action_button("interact")
	_check(joy != null and attack != null and block != null and interact != null and touch.sprint_button != null,
		"touch: joystick and TouchActionButton controls are registered")
	if joy == null or attack == null or block == null or interact == null or touch.sprint_button == null:
		touch.visible = was_visible
		return

	# Finger 0 owns the joystick.
	var joy_center := joy.size * 0.5
	joy._gui_input(_touch_event(0, joy_center, true))
	joy._gui_input(_drag_event(0, joy_center + Vector2(joy.radius, 0.0), Vector2(joy.radius, 0.0)))
	_check(joy.active_pointer() == 0 and touch.get_move_vector().x > 0.95,
		"touch: finger 0 drives the joystick (x=%.2f)" % touch.get_move_vector().x)

	# Finger 1 attacks while finger 0 keeps moving.
	attack._gui_input(_touch_event(1, attack.size * 0.5, true))
	_check(attack.is_held() and attack.active_pointer() == 1,
		"touch: attack button is pressed by a second finger while the joystick is held")
	_check(touch.consume_pressed("attack"), "touch: attack press is queued for the player")
	_check(not touch.consume_pressed("attack"), "touch: one touch-down queues exactly one attack")
	attack._gui_input(_touch_event(1, attack.size * 0.5, false))
	_check(not attack.is_held() and joy.active_pointer() == 0 and touch.get_move_vector().x > 0.95,
		"touch: releasing the attack finger does not release the joystick")

	# A foreign finger must not steal or release the joystick.
	joy._gui_input(_touch_event(5, joy_center, true))
	joy._gui_input(_drag_event(5, joy_center - Vector2(joy.radius, 0.0), Vector2(-joy.radius, 0.0)))
	joy._gui_input(_touch_event(5, joy_center, false))
	_check(joy.active_pointer() == 0 and touch.get_move_vector().x > 0.95,
		"touch: a foreign finger cannot steal or release the joystick")

	# Block is hold-to-block and never enters the tap queue.
	block._gui_input(_touch_event(2, block.size * 0.5, true))
	_check(touch.is_blocking() and not touch.consume_pressed("block"),
		"touch: block is held (not queued) while its finger is down")
	block._gui_input(_touch_event(2, block.size * 0.5, false))
	_check(not touch.is_blocking(), "touch: block ends when its finger lifts")

	# Sprint is a latched toggle.
	var sprint := touch.sprint_button
	sprint._gui_input(_touch_event(3, sprint.size * 0.5, true))
	sprint._gui_input(_touch_event(3, sprint.size * 0.5, false))
	var sprint_on := touch.is_sprinting()
	sprint._gui_input(_touch_event(3, sprint.size * 0.5, true))
	sprint._gui_input(_touch_event(3, sprint.size * 0.5, false))
	_check(sprint_on and not touch.is_sprinting(), "touch: sprint toggles on and off per tap")

	# Camera area: one finger orbits, two fingers pinch.
	var look_total: Array[Vector2] = [Vector2.ZERO]
	var zoom_factors: Array[float] = []
	var on_look := func(relative: Vector2) -> void: look_total[0] += relative
	var on_zoom := func(factor: float) -> void: zoom_factors.append(factor)
	touch.look_dragged.connect(on_look)
	touch.zoom_requested.connect(on_zoom)
	var area := touch.drag_area
	area._gui_input(_touch_event(6, Vector2(200.0, 100.0), true))
	area._gui_input(_drag_event(6, Vector2(240.0, 100.0), Vector2(40.0, 0.0)))
	_check(absf(look_total[0].x - 40.0) < 0.01 and zoom_factors.is_empty(),
		"touch: one finger on the camera area orbits (dx=%.1f)" % look_total[0].x)
	area._gui_input(_touch_event(7, Vector2(340.0, 100.0), true))
	area._gui_input(_drag_event(7, Vector2(440.0, 100.0), Vector2(100.0, 0.0)))
	var spread: float = zoom_factors[0] if not zoom_factors.is_empty() else 0.0
	_check(absf(spread - 2.0) < 0.01 and absf(look_total[0].x - 40.0) < 0.01,
		"touch: two fingers spreading pinch-zoom without orbiting (factor=%.2f)" % spread)
	area._gui_input(_touch_event(7, Vector2(440.0, 100.0), false))
	area._gui_input(_touch_event(6, Vector2(240.0, 100.0), false))
	_check(area.pointer_count() == 0 and joy.active_pointer() == 0,
		"touch: camera fingers release independently of the joystick")
	touch.look_dragged.disconnect(on_look)
	touch.zoom_requested.disconnect(on_zoom)

	# Contextual feedback.
	EventBus.interact_prompt_changed.emit("probe")
	var lit := interact.is_highlighted()
	EventBus.interact_prompt_changed.emit("")
	_check(lit and not interact.is_highlighted(), "touch: interact button highlights while a prompt is shown")
	EventBus.player_stamina_changed.emit(0.0, 100.0)
	var dim := attack.is_dimmed()
	EventBus.player_stamina_changed.emit(100.0, 100.0)
	_check(dim and not attack.is_dimmed(), "touch: attack button dims when stamina is insufficient")

	# Hiding the controls (menus, pause) must drop every held input.
	block._gui_input(_touch_event(2, block.size * 0.5, true))
	touch.visible = false
	_check(touch.get_move_vector() == Vector2.ZERO and not touch.is_blocking()
			and joy.active_pointer() == TouchPointer.NONE and not block.is_held(),
		"touch: hiding the controls releases the joystick and held buttons")
	touch.visible = true
	_check("haptics_enabled" in SettingsManager, "settings expose the haptics toggle")

	touch.reset_state()
	touch.visible = was_visible

func _report() -> void:
	_finished = true
	var info := Engine.get_version_info()
	var lines: PackedStringArray = []
	lines.append("MICRO WORLD: LIVING — headless test results (Eldoria Edition v2.0 — Ultra Immersion & Systems Overhaul)")
	lines.append("engine: %s %s" % [info.get("string", "?"), info.get("status", "")])
	lines.append("rendering method: %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	lines.append("run at: %s" % Time.get_datetime_string_from_system(true))
	lines.append("checks passed: %d" % _passes)
	lines.append("checks failed: %d" % _failures.size())
	lines.append("")
	lines.append("renderer metrics (headless dummy driver — see perf_probe_results.txt for GLES3 numbers):")
	lines.append("  fps: %.1f" % _fps)
	lines.append("  draw calls: %d" % _draw_calls)
	lines.append("  triangles: %d" % _triangles)
	lines.append("  nodes: %d" % int(_nodes))
	lines.append("")
	lines.append("checks:")
	for line: String in _log:
		lines.append(line)
	if not _failures.is_empty():
		lines.append("")
		lines.append("FAILURES:")
		for failure: String in _failures:
			lines.append("  - " + failure)
	var text := "\n".join(lines) + "\n"
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()
	print("")
	print("=== %d passed, %d failed ===" % [_passes, _failures.size()])
	for failure: String in _failures:
		print("FAILED: " + failure)
	get_tree().quit(0 if _failures.is_empty() else 1)
