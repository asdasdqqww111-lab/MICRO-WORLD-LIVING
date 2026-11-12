extends Node
## Global signal hub (autoload: EventBus).
## Preserves 100% of original v0.1 signals + adds v1.0 RPG, Guild, Crafting,
## Magic, Boss, World Map & Localization signals.

# --- Player progression & vitals ---------------------------------------------
signal player_health_changed(current: float, maximum: float)
signal player_stamina_changed(current: float, maximum: float)
signal player_mana_changed(current: float, maximum: float)
signal player_xp_changed(level: int, xp: int, xp_to_next: int)
signal player_level_up(level: int)
signal player_gold_changed(gold: int)
signal player_died()

# --- Inventory / equipment / crafting / skills -------------------------------
signal inventory_changed()
signal equipment_changed()
signal item_picked_up(item_id: String, amount: int)
signal item_crafted(recipe_id: String, item_id: String)
signal skill_tree_changed()

# --- Combat & Bosses ---------------------------------------------------------
signal damage_dealt(target: Node, amount: float, is_crit: bool)
signal creature_died(creature_id: String, uid: String, position: Vector3)
signal creature_aggro(creature: Node)
signal boss_health_changed(boss_name: String, current: float, maximum: float, phase: int, visible_bar: bool)
signal target_locked_changed(target: Node)
signal hero_class_changed(class_id: String)

# --- Quests & Adventurers Guild ----------------------------------------------
signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_ready_to_turn_in(quest_id: String)
signal quest_completed(quest_id: String)
signal guild_updated()
signal guild_board_opened()

# --- World & Atmosphere ------------------------------------------------------
signal time_changed(hour: int, minute: int, day: int)
signal hour_changed(hour: int)
signal day_started(day: int)
signal weather_changed(weather: String)
signal raid_started(day: int)
signal raid_cleared(day: int)
signal market_updated(day: int)
signal zone_entered(zone_id: String)

# --- UI / interaction / localization -----------------------------------------
signal notify(text: String)
signal interact_prompt_changed(text: String)
signal dialog_requested(npc: Node)
signal shop_requested(npc: Node)
signal crafting_opened(station_type: String)
signal screen_changed(screen_name: String)
signal pause_toggled(paused: bool)
signal graphics_settings_changed()
signal language_changed(lang_code: String)

# --- Persistence -------------------------------------------------------------
signal game_saved(slot: String)
signal game_loaded(slot: String)
