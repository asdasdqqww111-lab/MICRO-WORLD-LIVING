class_name InventoryScreen
extends MenuScreen
## Grid inventory + equipment slots with tap-to-select and drag & drop.

signal item_used(item_id: String)

var selected_index: int = -1
var selected_equipment_slot: String = ""
var _grid: GridContainer
var _equipment_box: HBoxContainer
var _detail: VBoxContainer
var _gold_label: Label
var world: WorldRoot
var player: Player

func _ready() -> void:
	configure("Inventory")
	super._ready()

func refresh() -> void:
	clear_content()
	var header := HBoxContainer.new()
	content.add_child(header)
	_gold_label = UIFactory.label("Gold: %d" % GameManager.gold, 18, UIFactory.GOLD)
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_gold_label)
	content.add_child(UIFactory.label("Equipped", 17, UIFactory.TEXT_DIM))

	_equipment_box = HBoxContainer.new()
	_equipment_box.add_theme_constant_override("separation", 10)
	content.add_child(_equipment_box)
	for slot_name: String in Inventory.EQUIP_SLOTS:
		_equipment_box.add_child(_build_equipment_button(slot_name))

	content.add_child(UIFactory.hsep())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	content.add_child(body)

	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	body.add_child(_grid)
	for i: int in Inventory.SLOT_COUNT:
		_grid.add_child(_build_slot_button(i))

	_detail = VBoxContainer.new()
	_detail.custom_minimum_size = Vector2(300, 0)
	_detail.add_theme_constant_override("separation", 8)
	body.add_child(_detail)
	_rebuild_detail()

func _build_equipment_button(slot_name: String) -> Button:
	var item_id := GameManager.inventory.equipped(slot_name)
	var data := ItemDB.get_item(item_id)
	var text := "%s\n%s" % [slot_name.capitalize(), data.display_name if data != null else "—"]
	var b := UIFactory.button(text, 64)
	b.custom_minimum_size = Vector2(240, 64)
	b.toggle_mode = true
	b.button_pressed = selected_equipment_slot == slot_name
	b.pressed.connect(func() -> void:
		selected_equipment_slot = slot_name if selected_equipment_slot != slot_name else ""
		selected_index = -1
		refresh())
	if data != null:
		b.modulate = data.icon_color.lerp(Color.WHITE, 0.4)
	b.set_drag_forwarding(
		func(_pos: Vector2) -> Variant:
			return {"kind": "equipment", "slot": slot_name, "item_id": item_id},
		func(_pos: Vector2, data_in: Variant) -> bool:
			return data_in is Dictionary and String((data_in as Dictionary).get("kind", "")) == "inventory",
		func(_pos: Vector2, data_in: Variant) -> void:
			_drop_on_equipment(slot_name, data_in))
	return b

func _build_slot_button(index: int) -> Button:
	var entry: Dictionary = GameManager.inventory.slots[index]
	var data := ItemDB.get_item(String(entry.get("id", "")))
	var text := ""
	if data != null:
		text = data.icon_letter()
		if int(entry.get("count", 1)) > 1:
			text += "\n%d" % int(entry.get("count", 1))
	var b := UIFactory.button(text, 64)
	b.custom_minimum_size = Vector2(64, 64)
	b.toggle_mode = true
	b.button_pressed = index == selected_index
	if data != null:
		b.modulate = data.icon_color.lerp(Color.WHITE, 0.35)
	b.pressed.connect(func() -> void:
		selected_index = index if selected_index != index else -1
		selected_equipment_slot = ""
		refresh())
	b.set_drag_forwarding(
		func(_pos: Vector2) -> Variant:
			var slot_entry: Dictionary = GameManager.inventory.slots[index]
			if slot_entry.is_empty():
				return null
			var preview := UIFactory.label(text, 20)
			b.set_drag_preview(preview)
			return {"kind": "inventory", "index": index, "item_id": String(slot_entry.get("id", ""))},
		func(_pos: Vector2, data_in: Variant) -> bool:
			return data_in is Dictionary and (data_in as Dictionary).has("item_id"),
		func(_pos: Vector2, data_in: Variant) -> void:
			_handle_slot_drop(index, data_in))
	return b

func _drop_on_equipment(slot_name: String, data_in: Variant) -> void:
	if not (data_in is Dictionary):
		return
	var source: Dictionary = data_in
	if String(source.get("kind", "")) != "inventory":
		return
	var item_id := String(source.get("item_id", ""))
	var item := ItemDB.get_item(item_id)
	if item == null or item.equip_slot != slot_name:
		EventBus.notify.emit("That does not fit there")
		return
	GameManager.inventory.equip(item_id)
	refresh()

func _handle_slot_drop(target_index: int, data_in: Variant) -> void:
	if not (data_in is Dictionary):
		return
	var source: Dictionary = data_in
	match String(source.get("kind", "")):
		"inventory":
			var from_index := int(source.get("index", -1))
			if from_index < 0 or from_index == target_index:
				return
			GameManager.inventory.swap_slots(from_index, target_index)
		"equipment":
			var slot_name := String(source.get("slot", ""))
			if String(source.get("item_id", "")).is_empty():
				return
			if not GameManager.inventory.move_equipment_to_bag(slot_name):
				EventBus.notify.emit("Inventory full")
				return
	refresh()

func _rebuild_detail() -> void:
	for child: Node in _detail.get_children():
		child.queue_free()
	var item_id := ""
	if selected_index >= 0:
		var entry: Dictionary = GameManager.inventory.slots[selected_index]
		item_id = String(entry.get("id", ""))
	elif not selected_equipment_slot.is_empty():
		item_id = GameManager.inventory.equipped(selected_equipment_slot)
	if item_id.is_empty():
		_detail.add_child(UIFactory.label("Select an item", 17, UIFactory.TEXT_DIM))
		return
	var item := ItemDB.get_item(item_id)
	if item == null:
		return
	_detail.add_child(UIFactory.label(item.display_name, 21, UIFactory.GOLD))
	_detail.add_child(UIFactory.wrapped_label(item.description, 15, UIFactory.TEXT_DIM))
	if item.attack_bonus > 0.0:
		_detail.add_child(UIFactory.label("Attack +%.1f" % item.attack_bonus, 16, UIFactory.ACCENT))
	if item.defense_bonus > 0.0:
		_detail.add_child(UIFactory.label("Defense +%.1f" % item.defense_bonus, 16, UIFactory.ACCENT))
	if item.heal_amount > 0.0:
		_detail.add_child(UIFactory.label("Heals %.0f" % item.heal_amount, 16, Color(0.9, 0.55, 0.5)))
	_detail.add_child(UIFactory.label("Value: %d gold" % item.value, 15, UIFactory.TEXT_DIM))

	if not selected_equipment_slot.is_empty():
		var unequip := UIFactory.button("Unequip")
		unequip.pressed.connect(func() -> void:
			GameManager.inventory.unequip(selected_equipment_slot)
			refresh())
		_detail.add_child(unequip)
		return
	if item.is_equippable():
		var equip := UIFactory.button("Equip")
		equip.pressed.connect(func() -> void:
			GameManager.inventory.equip(item_id)
			selected_index = -1
			refresh())
		_detail.add_child(equip)
	if item.is_consumable():
		var use := UIFactory.button("Use")
		use.pressed.connect(func() -> void:
			item_used.emit(item_id)
			refresh())
		_detail.add_child(use)
	var drop := UIFactory.button("Drop")
	drop.pressed.connect(func() -> void:
		if GameManager.inventory.remove_item(item_id, 1):
			if world != null and player != null:
				var forward := -player.global_transform.basis.z
				world.spawn_loot_drop([{"id": item_id, "count": 1}],
					player.global_position + forward * 1.2)
			refresh())
	_detail.add_child(drop)
