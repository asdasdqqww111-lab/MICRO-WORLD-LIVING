class_name GuildScreen
extends MenuScreen
## Adventurers Guild Ledger & Quest Board Screen (Section 13):
##   - Adventurer Registration, Rank Badge (F -> E -> D -> C -> B -> A -> S),
##     Reputation Progress Bar, Rank-Up Promotions & Guild Perks
##   - Official Guild Contract Board across Hunting, Gathering, Exploration,
##     Escort, and Dungeon Boss missions!

func _ready() -> void:
	configure("Adventurers Guild", "guild")
	super._ready()
	EventBus.guild_updated.connect(func() -> void:
		if visible:
			refresh())
	EventBus.quest_updated.connect(func(_q: String) -> void:
		if visible:
			refresh())

func refresh() -> void:
	clear_content()
	var g := GameManager.guild
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 14)
	content.add_child(split)

	# Left Column: Adventurer Rank Card
	var left_card := UIFactory.card_panel(UIFactory.GOLD)
	left_card.custom_minimum_size = Vector2(310, 0)
	split.add_child(left_card)
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 8)
	left_card.add_child(lbox)

	lbox.add_child(UIFactory.label("★ ELDORIA GUILD CARD", 19, UIFactory.GOLD))
	lbox.add_child(UIFactory.label("Rank: %s" % g.current_rank(), 26, Color(0.48, 0.82, 1.0)))
	lbox.add_child(UIFactory.label(g.rank_title(), 16, UIFactory.TEXT))
	lbox.add_child(UIFactory.hsep())

	lbox.add_child(UIFactory.label("%s: %d" % [Localization.tr_key("reputation"), g.reputation], 16, UIFactory.ACCENT))
	lbox.add_child(UIFactory.label("Contracts Completed: %d" % g.contracts_completed, 15, UIFactory.TEXT_DIM))
	var disc_pct := int(round((1.0 - g.shop_discount_multiplier()) * 100.0))
	lbox.add_child(UIFactory.label("Merchant Discount: %d%%" % disc_pct, 15, UIFactory.TEXT_DIM))

	var nxt := g.next_rank()
	if not g.registered:
		lbox.add_child(UIFactory.wrapped_label("Register as an official Rank F Adventurer to accept Guild contracts and earn promotions up to Rank S!", 14, UIFactory.TEXT_DIM))
		var reg_btn := UIFactory.button(Localization.tr_key("register_guild"), 46)
		reg_btn.pressed.connect(func() -> void:
			GameManager.register_in_guild()
			refresh())
		lbox.add_child(reg_btn)
	elif not nxt.is_empty():
		var req: Dictionary = GuildSystem.RANK_REQUIREMENTS[nxt]
		var req_rep := int(req["rep"])
		var req_lv := int(req["level"])
		var rep_bar := UIFactory.progress_bar(Color(0.40, 0.76, 1.0), 14)
		rep_bar.max_value = float(req_rep)
		rep_bar.value = clampf(float(g.reputation), 0.0, float(req_rep))
		lbox.add_child(rep_bar)
		lbox.add_child(UIFactory.label("Next Rank %s: %d/%d Rep · Lv %d" % [nxt, g.reputation, req_rep, req_lv], 14, UIFactory.TEXT_DIM))
		var prom_btn := UIFactory.button("Promote to Rank %s!" % nxt, 46)
		prom_btn.disabled = not g.can_promote(GameManager.progression.level)
		prom_btn.pressed.connect(func() -> void:
			GameManager.promote_guild_rank()
			refresh())
		lbox.add_child(prom_btn)
	else:
		lbox.add_child(UIFactory.label("★ Grand Legend Rank S Achieved!", 16, UIFactory.GOLD))

	# Right Column: Official Quest Board Contracts
	var right_box := VBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.add_theme_constant_override("separation", 8)
	split.add_child(right_box)

	right_box.add_child(UIFactory.label("📜 Official Guild Contracts (Ranks F – S)", 19, UIFactory.GOLD))
	for contract: QuestData in g.available_contracts():
		right_box.add_child(_build_contract_card(contract))

func _build_contract_card(q: QuestData) -> Control:
	var st := GameManager.quest_log.state_of(q.id)
	var unlocked := GameManager.guild.meets_rank(q.required_guild_rank)
	var border := UIFactory.ACCENT if st == QuestLog.STATE_READY else (UIFactory.GOLD if st == QuestLog.STATE_ACTIVE else UIFactory.BORDER_GOLD)
	var card := UIFactory.card_panel(border)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)

	info.add_child(UIFactory.label("%s  ·  [%s]" % [q.title, q.contract_category.capitalize()], 17,
		UIFactory.GOLD if unlocked else UIFactory.TEXT_DIM))
	info.add_child(UIFactory.wrapped_label(q.description, 14, UIFactory.TEXT_DIM))
	info.add_child(UIFactory.label("Rewards: %d Gold · %d XP · +%d Guild Rep" % [q.reward_gold, q.reward_xp, q.reward_reputation],
		14, UIFactory.ACCENT))

	if st == QuestLog.STATE_COMPLETED:
		var done_lbl := UIFactory.label("✔ Completed", 16, UIFactory.ACCENT)
		row.add_child(done_lbl)
	elif st == QuestLog.STATE_READY:
		var turn_btn := UIFactory.button("Claim Reward", 44)
		turn_btn.custom_minimum_size = Vector2(145, 44)
		turn_btn.pressed.connect(func() -> void:
			GameManager.turn_in_quest(q.id)
			refresh())
		row.add_child(turn_btn)
	elif st == QuestLog.STATE_ACTIVE:
		var prog_parts: PackedStringArray = []
		for i: int in q.objectives.size():
			var obj: Dictionary = q.objectives[i]
			prog_parts.append("%d/%d" % [GameManager.quest_log.objective_progress(q.id, i), int(obj.get("required", 1))])
		row.add_child(UIFactory.label("Active (%s)" % ", ".join(prog_parts), 15, UIFactory.GOLD))
	else:
		var acc_btn := UIFactory.button("Accept" if unlocked else ("Rank " + q.required_guild_rank), 44)
		acc_btn.custom_minimum_size = Vector2(130, 44)
		acc_btn.disabled = not unlocked
		acc_btn.pressed.connect(func() -> void:
			GameManager.start_quest(q.id)
			refresh())
		row.add_child(acc_btn)
	return card
