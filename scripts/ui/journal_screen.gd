class_name JournalScreen
extends MenuScreen
## Quest & Contract Journal with Main / Side / Guild / Completed filters.

var _filter: String = "all"

func _ready() -> void:
	configure("Quest Journal", "journal")
	super._ready()

func refresh() -> void:
	clear_content()
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)
	for pair: Array in [["all", "All Active"], ["main", "Main Story"], ["guild", "Guild Contracts"], ["done", "Completed"]]:
		var k := String(pair[0])
		var b := UIFactory.button(String(pair[1]), 38)
		b.toggle_mode = true
		b.button_pressed = (_filter == k)
		b.pressed.connect(func() -> void:
			_filter = k
			refresh())
		tabs.add_child(b)

	content.add_child(UIFactory.hsep())

	var list: Array = GameManager.quest_log.completed_quests() if _filter == "done" else GameManager.quest_log.tracked_quests()
	var shown := 0
	for quest_id: String in list:
		var q := QuestDB.get_quest(quest_id)
		if q == null:
			continue
		if _filter == "main" and not q.is_main_quest:
			continue
		if _filter == "guild" and not q.is_guild_contract:
			continue
		shown += 1
		content.add_child(_quest_card(q, _filter == "done"))

	if shown == 0:
		content.add_child(UIFactory.label("No matching quests yet — speak with Elder Theron, Villagers, or the Adventurers Guild!", 16, UIFactory.TEXT_DIM))

func _quest_card(quest: QuestData, is_completed: bool) -> Control:
	var ar := Localization.is_arabic()
	var card := UIFactory.card_panel(UIFactory.ACCENT if is_completed else UIFactory.GOLD)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	card.add_child(row)

	var tag := ("[رئيسية] " if quest.is_main_quest else ("[نقابة] " if quest.is_guild_contract else "[جانبية] ")) if ar else ("[MAIN] " if quest.is_main_quest else ("[GUILD] " if quest.is_guild_contract else "[SIDE] "))
	row.add_child(UIFactory.label(tag + Localization.quest_title(quest), 18, UIFactory.GOLD))
	row.add_child(UIFactory.wrapped_label(Localization.quest_desc(quest), 14, UIFactory.TEXT_DIM))

	for i: int in quest.objectives.size():
		var obj: Dictionary = quest.objectives[i]
		var prog := GameManager.quest_log.objective_progress(quest.id, i)
		var req := int(obj.get("required", 1))
		var done := is_completed or prog >= req
		var olabel := Localization.quest_obj_label(quest, i, String(obj.get("label", "Objective")))
		row.add_child(UIFactory.label("  %s %s (%d/%d)" % ["✔" if done else "○", olabel, prog, req],
			15, UIFactory.ACCENT if done else UIFactory.TEXT))

	row.add_child(UIFactory.label(("المكافآت: %d خبرة · %d ذهب · +%d سمعة نقابة" if ar else "Rewards: %d XP · %d Gold · +%d Guild Rep") % [quest.reward_xp, quest.reward_gold, quest.reward_reputation], 14, UIFactory.GOLD))
	return card
