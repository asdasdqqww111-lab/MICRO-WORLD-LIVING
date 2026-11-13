class_name JournalScreen
extends MenuScreen
## Quest & Contract Journal with Main / Side / Guild / Completed filters.

var _filter: String = "all"

func _ready() -> void:
	configure("Quest Journal", "journal")
	super._ready()

func refresh() -> void:
	clear_content()
	var ar := Localization.is_arabic()
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)
	var tab_defs := [
		["all", "النشطة" if ar else "Active"],
		["available", "المتاحة في المدينة" if ar else "Available in City"],
		["main", "القصة الرئيسية" if ar else "Main Story"],
		["guild", "عقود النقابة" if ar else "Guild Contracts"],
		["done", "المكتملة" if ar else "Completed"],
	]
	for pair: Array in tab_defs:
		var k := String(pair[0])
		var b := UIFactory.button(String(pair[1]), 38)
		b.toggle_mode = true
		b.button_pressed = (_filter == k)
		b.pressed.connect(func() -> void:
			_filter = k
			refresh())
		tabs.add_child(b)

	content.add_child(UIFactory.hsep())

	var shown := 0
	if _filter == "available":
		for q_var: Variant in QuestDB.all_quests():
			var q := q_var as QuestData
			if q == null:
				continue
			if GameManager.quest_log.state_of(q.id) != QuestLog.STATE_NOT_STARTED:
				continue
			if q.is_guild_contract and not GameManager.guild.meets_rank(q.required_guild_rank):
				continue
			shown += 1
			content.add_child(_available_quest_card(q))
	else:
		var list: Array = GameManager.quest_log.completed_quests() if _filter == "done" else GameManager.quest_log.tracked_quests()
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
		content.add_child(UIFactory.label(
			"لا توجد مهام مطابقة حالياً — افتح تبويب «المتاحة في المدينة» لتصفّح 24 مهمة وتتبّع مانحيها!" if ar else
			"No matching quests yet — check 'Available in City' to browse all 24 quests!",
			16, UIFactory.TEXT_DIM))

func _available_quest_card(quest: QuestData) -> Control:
	var ar := Localization.is_arabic()
	var card := UIFactory.card_panel(UIFactory.GOLD)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	card.add_child(row)
	var tag := ("[رئيسية] " if quest.is_main_quest else ("[نقابة %s] " % quest.required_guild_rank if quest.is_guild_contract else "[مدينة إلدوريا] ")) if ar else ("[MAIN] " if quest.is_main_quest else ("[GUILD %s] " % quest.required_guild_rank if quest.is_guild_contract else "[CITY] "))
	var top := HBoxContainer.new()
	var title_lbl := UIFactory.label(tag + Localization.quest_title(quest), 17, UIFactory.GOLD)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_lbl)
	var giver_nm := Localization.npc_name(quest.giver_npc, quest.giver_npc.capitalize())
	var accept_btn := UIFactory.button("قبول وتتبّع ◆" if ar else "Accept & Track ◆", 34)
	accept_btn.pressed.connect(func() -> void:
		if GameManager.start_quest(quest.id):
			var wp := get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
			if wp != null:
				wp.focus_quest(quest.id)
			EventBus.notify.emit(("بدأت المهمة: %s" if ar else "Quest started: %s") % Localization.quest_title(quest))
			refresh())
	top.add_child(accept_btn)
	row.add_child(top)
	row.add_child(UIFactory.wrapped_label(Localization.quest_desc(quest), 14, UIFactory.TEXT_DIM))
	row.add_child(UIFactory.label(
		("مانح المهمة: %s  ·  المكافآت: %d خبرة · %d ذهب" if ar else "Quest Giver: %s  ·  Rewards: %d XP · %d Gold") % [giver_nm, quest.reward_xp, quest.reward_gold],
		13, UIFactory.ACCENT))
	return card

func _quest_card(quest: QuestData, is_completed: bool) -> Control:
	var ar := Localization.is_arabic()
	var card := UIFactory.card_panel(UIFactory.ACCENT if is_completed else UIFactory.GOLD)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	card.add_child(row)

	var tag := ("[رئيسية] " if quest.is_main_quest else ("[نقابة] " if quest.is_guild_contract else "[جانبية] ")) if ar else ("[MAIN] " if quest.is_main_quest else ("[GUILD] " if quest.is_guild_contract else "[SIDE] "))
	var top := HBoxContainer.new()
	var t_lbl := UIFactory.label(tag + Localization.quest_title(quest), 18, UIFactory.GOLD)
	t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t_lbl)
	if not is_completed:
		var track_btn := UIFactory.button("تتبّع ◆" if ar else "Track ◆", 32)
		track_btn.pressed.connect(func() -> void:
			var wp := get_tree().get_first_node_in_group("quest_waypoint") as QuestWaypoint3D
			if wp != null:
				wp.focus_quest(quest.id)
			EventBus.notify.emit(("تم تحديد الهدف على الخريطة: %s" if ar else "Tracking quest: %s") % Localization.quest_title(quest)))
		top.add_child(track_btn)
	row.add_child(top)
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
