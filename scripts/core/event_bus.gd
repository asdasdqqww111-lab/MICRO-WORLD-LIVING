extends Node
## Global signal hub (autoload: EventBus).
##
## Every subsystem talks through here instead of holding references to each
## other.  Keeps the world, UI, quests, combat and save layers decoupled.

# --- Player progression ------------------------------------------------------
signal player_health_changed(current: float, maximum: float)
signal player_stamina_changed(current: float, maximum: float)
signal player_xp_changed(level: int, xp: int, xp_to_next: int)
signal player_level_up(level: int)
signal player_gold_changed(gold: int)
signal player_died()

# --- Inventory / items -------------------------------------------------------
signal inventory_changed()
signal equipment_changed()
signal item_picked_up(item_id: String, amount: int)

# --- Combat ------------------------------------------------------------------
signal damage_dealt(target: Node, amount: float, is_crit: bool)
signal creature_died(creature_id: String, uid: String, position: Vector3)
signal creature_aggro(creature: Node)

# --- Quests ------------------------------------------------------------------
signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_ready_to_turn_in(quest_id: String)
signal quest_completed(quest_id: String)

# --- World -------------------------------------------------------------------
signal time_changed(hour: int, minute: int, day: int)
signal day_started(day: int)
signal weather_changed(weather: String)
signal raid_started(day: int)
signal raid_cleared(day: int)
signal market_updated(day: int)

# --- UI / interaction --------------------------------------------------------
signal notify(text: String)
signal interact_prompt_changed(text: String)
signal dialog_requested(npc: Node)
signal shop_requested(npc: Node)
signal screen_changed(screen_name: String)
signal pause_toggled(paused: bool)
signal graphics_settings_changed()

# --- Persistence -------------------------------------------------------------
signal game_saved(slot: String)
signal game_loaded(slot: String)
