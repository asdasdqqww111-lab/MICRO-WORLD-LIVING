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
		["الهجوم القريب" if ar else "Melee Attack", "%.1f" % GameManager.attack_power()],
		["الدفاع" if ar else "Defense", "%.1f" % GameManager.defense_power()],
		["القوة السحرية" if ar else "Spell Power", "%.1f" % GameManager.spell_power()],
		["الرشاقة" if ar else "Agility", "%.1f" % GameManager.stats.agility],
		["فرصة الضربة الحرجة" if ar else "Crit Chance", "%.0f%%" % (GameManager.crit_chance() * 100.0)],
		["تخفيف الضرر بالترس" if ar else "Block Mitigation", "%.0f%%" % (GameManager.skills.block_mitigation() * 100.0)],
		["الصحة القصوى" if ar else "Max Health", "%.0f" % GameManager.max_health()],
		["المانا القصوى" if ar else "Max Mana", "%.0f" % GameManager.max_mana()],
		["النشاط الأقصى" if ar else "Max Stamina", "%.0f" % GameManager.max_stamina()],
		["رتبة النقابة" if ar else "Guild Standing", ("%s (%d سمعة)" if ar else "%s (%d Rep)") % [g.current_rank() if g.registered else ("غير مسجّل" if ar else "Unregistered"), g.reputation]],
	]
	for row: Array in rows:
		grid.add_child(UIFactory.label(String(row[0]), 16, UIFactory.TEXT_DIM))
		grid.add_child(UIFactory.label(String(row[1]), 16, UIFactory.TEXT))

	var open_tree_btn := UIFactory.button("✦ فتح شجرة المهارات التفاعلية (36 مهارة)" if ar else "✦ Open Interactive 36-Node Skill Tree", 48)
	open_tree_btn.pressed.connect(func() -> void: open_skill_tree_requested.emit())
	content.add_child(open_tree_btn)
