class_name JournalScreen
extends MenuScreen

var _selected: String = ""

func _ready() -> void:
	configure("Quest Journal")
	super._ready()

func refresh() -> void:
	clear_content()
	var active := GameManager.quest_log.tracked_quests()
	var completed := GameManager.quest_log.completed_quests()
	if active.is_empty() and completed.is_empty():
		content.add_child(UIFactory.label("No quests yet. Talk to the villagers.", 18, UIFactory.TEXT_DIM))
		return
	if not active.is_empty():
		content.add_child(UIFactory.label("Active", 19, UIFactory.GOLD))
		for quest_id: String in active:
			content.add_child(_quest_row(quest_id, false))
	if not completed.is_empty():
		content.add_child(UIFactory.hsep())
		content.add_child(UIFactory.label("Completed", 19, UIFactory.TEXT_DIM))
		for quest_id: String in completed:
			content.add_child(_quest_row(quest_id, true))

func _quest_row(quest_id: String, is_completed: bool) -> Control:
	var quest := QuestDB.get_quest(quest_id)
	if quest == null:
		return UIFactory.label(quest_id, 16)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var button := UIFactory.button(quest.title, 46)
	button.pressed.connect(func() -> void:
		_selected = quest_id if _selected != quest_id else ""
		refresh())
	row.add_child(button)
	if _selected == quest_id:
		row.add_child(UIFactory.wrapped_label(quest.description, 16, UIFactory.TEXT_DIM))
		for i: int in quest.objectives.size():
			var objective: Dictionary = quest.objectives[i]
			var progress := GameManager.quest_log.objective_progress(quest_id, i)
			var required := int(objective.get("required", 1))
			var done := progress >= required
			row.add_child(UIFactory.label("%s  %d/%d" % [String(objective.get("label", "")), progress, required],
				16, UIFactory.ACCENT if done else UIFactory.TEXT))
		row.add_child(UIFactory.label("Reward: %d XP, %d gold" % [quest.reward_xp, quest.reward_gold],
			15, UIFactory.GOLD))
		for item: Dictionary in quest.reward_items:
			var data := ItemDB.get_item(String(item.get("id", "")))
			row.add_child(UIFactory.label("   + %s x%d" % [data.display_name if data != null else "?",
				int(item.get("count", 1))], 15, UIFactory.TEXT_DIM))
		if is_completed:
			row.add_child(UIFactory.label("Completed", 15, UIFactory.ACCENT))
		elif GameManager.quest_log.can_turn_in(quest_id):
			row.add_child(UIFactory.label("Ready to turn in", 15, UIFactory.ACCENT))
	return row
