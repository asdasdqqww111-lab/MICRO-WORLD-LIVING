class_name CharacterScreen
extends MenuScreen
## Character sheet + the 3-node skill tree.

func _ready() -> void:
	configure("Character")
	super._ready()

func refresh() -> void:
	clear_content()
	var progression := GameManager.progression
	content.add_child(UIFactory.label("Level %d" % progression.level, 22, UIFactory.GOLD))
	content.add_child(UIFactory.label("XP %d / %d" % [progression.xp, progression.xp_to_next()],
		16, UIFactory.TEXT_DIM))
	content.add_child(UIFactory.hsep())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	var rows := [
		["Attack", "%.1f" % GameManager.attack_power()],
		["Defense", "%.1f" % GameManager.defense_power()],
		["Agility", "%.1f" % GameManager.stats.agility],
		["Crit chance", "%.0f%%" % (GameManager.crit_chance() * 100.0)],
		["Max health", "%.0f" % GameManager.max_health()],
		["Gold", "%d" % GameManager.gold],
	]
	for row: Array in rows:
		grid.add_child(UIFactory.label(String(row[0]), 17, UIFactory.TEXT_DIM))
		grid.add_child(UIFactory.label(String(row[1]), 17, UIFactory.TEXT))

	content.add_child(UIFactory.hsep())
	content.add_child(UIFactory.label("Skills — points available: %d" % GameManager.skills.points,
		19, UIFactory.ACCENT))
	for skill: SkillData in SkillDB.all_skills():
		content.add_child(_skill_row(skill))

func _skill_row(skill: SkillData) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rank := GameManager.skills.rank_of(skill.id)
	info.add_child(UIFactory.label("%s  (%d/%d)" % [skill.title, rank, skill.max_rank], 18))
	info.add_child(UIFactory.wrapped_label(skill.description, 15, UIFactory.TEXT_DIM))
	row.add_child(info)
	var button := UIFactory.button("Rank up")
	button.custom_minimum_size = Vector2(150, 48)
	button.disabled = not GameManager.skills.can_upgrade(skill.id)
	button.pressed.connect(func() -> void:
		if GameManager.upgrade_skill(skill.id):
			refresh())
	row.add_child(button)
	return row
