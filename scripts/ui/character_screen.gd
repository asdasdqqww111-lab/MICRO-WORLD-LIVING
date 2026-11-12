class_name CharacterScreen
extends MenuScreen
## Hero Attributes, Guild Standing & Quick Skill Tree Launcher.

signal open_skill_tree_requested()

func _ready() -> void:
	configure("Hero Overview", "character")
	super._ready()

func refresh() -> void:
	clear_content()
	var prog := GameManager.progression
	var g := GameManager.guild

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	content.add_child(top)

	var stat_card := UIFactory.card_panel()
	stat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stat_card)
	var sbox := VBoxContainer.new()
	sbox.add_theme_constant_override("separation", 6)
	stat_card.add_child(sbox)
	var cdef := HeroClassDB.get_class_def(GameManager.hero_class)
	var glyph := String(cdef.get("glyph", "⚔"))
	var ar := Localization.is_arabic()
	var hdr := ("%s %s (%s) — المستوى %d" % [glyph, GameManager.hero_name, Localization.class_title(GameManager.hero_class), prog.level]) if ar else ("%s %s · %s — Level %d" % [glyph, GameManager.hero_name, Localization.class_title(GameManager.hero_class), prog.level])
	sbox.add_child(UIFactory.label(hdr, 21, UIFactory.GOLD))
	sbox.add_child(UIFactory.label("XP %d / %d   ·   %s: %d" % [prog.xp, prog.xp_to_next(), Localization.tr_key("skill_points"), GameManager.skills.points], 15, UIFactory.ACCENT))
	sbox.add_child(UIFactory.hsep())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 6)
	sbox.add_child(grid)
	var rows := [
		["Melee Attack", "%.1f" % GameManager.attack_power()],
		["Defense", "%.1f" % GameManager.defense_power()],
		["Spell Power", "%.1f" % GameManager.spell_power()],
		["Agility", "%.1f" % GameManager.stats.agility],
		["Crit Chance", "%.0f%%" % (GameManager.crit_chance() * 100.0)],
		["Block Mitigation", "%.0f%%" % (GameManager.skills.block_mitigation() * 100.0)],
		["Max Health", "%.0f" % GameManager.max_health()],
		["Max Mana", "%.0f" % GameManager.max_mana()],
		["Max Stamina", "%.0f" % GameManager.max_stamina()],
		["Guild Standing", "%s (%d Rep)" % [g.current_rank(), g.reputation]],
	]
	for row: Array in rows:
		grid.add_child(UIFactory.label(String(row[0]), 16, UIFactory.TEXT_DIM))
		grid.add_child(UIFactory.label(String(row[1]), 16, UIFactory.TEXT))

	var open_tree_btn := UIFactory.button("✦ Open Interactive 24-Node Skill Tree", 48)
	open_tree_btn.pressed.connect(func() -> void: open_skill_tree_requested.emit())
	content.add_child(open_tree_btn)
