class_name Inventory
extends RefCounted
## Slot based inventory + 3 equipment slots. Pure data: no node dependencies so
## it can be unit tested headless.

signal changed()
signal equipment_changed()

const SLOT_COUNT := 20
const EQUIP_SLOTS: Array[String] = ["weapon", "armor", "helmet"]

var slots: Array[Dictionary] = []
var equipment: Dictionary = {}

func _init() -> void:
	clear()

func clear() -> void:
	slots.clear()
	for _i: int in SLOT_COUNT:
		slots.append({})
	equipment.clear()
	for slot_name: String in EQUIP_SLOTS:
		equipment[slot_name] = ""

func add_item(item_id: String, amount: int = 1) -> int:
	var data := ItemDB.get_item(item_id)
	if data == null or amount <= 0:
		push_warning("Inventory.add_item: unknown item '%s'" % item_id)
		return amount
	var remaining := amount
	if data.is_stackable():
		for i: int in slots.size():
			if remaining <= 0:
				break
			var entry: Dictionary = slots[i]
			if entry.is_empty() or String(entry.get("id", "")) != item_id:
				continue
			var have := int(entry.get("count", 0))
			if have >= data.max_stack:
				continue
			var space := data.max_stack - have
			var moved := mini(space, remaining)
			entry["count"] = have + moved
			slots[i] = entry
			remaining -= moved
	while remaining > 0:
		var empty_index := _first_empty_slot()
		if empty_index < 0:
			break
		var chunk := mini(data.max_stack, remaining) if data.is_stackable() else 1
		slots[empty_index] = {"id": item_id, "count": chunk}
		remaining -= chunk
	if remaining != amount:
		changed.emit()
	return remaining

func remove_item(item_id: String, amount: int = 1) -> bool:
	if count_item(item_id) < amount:
		return false
	var remaining := amount
	for i: int in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var entry: Dictionary = slots[i]
		if entry.is_empty() or String(entry.get("id", "")) != item_id:
			continue
		var have := int(entry.get("count", 0))
		var taken := mini(have, remaining)
		have -= taken
		remaining -= taken
		if have <= 0:
			slots[i] = {}
		else:
			entry["count"] = have
			slots[i] = entry
	if remaining == 0:
		changed.emit()
	return remaining == 0

func count_item(item_id: String) -> int:
	var total := 0
	for entry: Dictionary in slots:
		if not entry.is_empty() and String(entry.get("id", "")) == item_id:
			total += int(entry.get("count", 0))
	return total

func used_slots() -> int:
	var used := 0
	for entry: Dictionary in slots:
		if not entry.is_empty():
			used += 1
	return used

func is_full() -> bool:
	return _first_empty_slot() < 0

func _first_empty_slot() -> int:
	for i: int in slots.size():
		if slots[i].is_empty():
			return i
	return -1

func equip(item_id: String) -> bool:
	var data := ItemDB.get_item(item_id)
	if data == null or not data.is_equippable():
		return false
	if count_item(item_id) <= 0:
		return false
	var slot_name := data.equip_slot
	var previous := String(equipment.get(slot_name, ""))
	if not remove_item(item_id, 1):
		return false
	if not previous.is_empty() and add_item(previous, 1) > 0:
		# No room for the swapped-out gear: roll back.
		add_item(item_id, 1)
		return false
	equipment[slot_name] = item_id
	changed.emit()
	equipment_changed.emit()
	return true

func unequip(slot_name: String) -> bool:
	if not EQUIP_SLOTS.has(slot_name):
		return false
	var item_id := String(equipment.get(slot_name, ""))
	if item_id.is_empty():
		return false
	if add_item(item_id, 1) > 0:
		return false
	equipment[slot_name] = ""
	changed.emit()
	equipment_changed.emit()
	return true

func equipped(slot_name: String) -> String:
	return String(equipment.get(slot_name, ""))

func total_attack_bonus() -> float:
	var total := 0.0
	for slot_name: String in EQUIP_SLOTS:
		var data := ItemDB.get_item(equipped(slot_name))
		if data != null:
			total += data.attack_bonus
	return total

func total_defense_bonus() -> float:
	var total := 0.0
	for slot_name: String in EQUIP_SLOTS:
		var data := ItemDB.get_item(equipped(slot_name))
		if data != null:
			total += data.defense_bonus
	return total

func swap_slots(a: int, b: int) -> bool:
	if a == b or a < 0 or b < 0 or a >= slots.size() or b >= slots.size():
		return false
	var tmp: Dictionary = slots[a]
	slots[a] = slots[b]
	slots[b] = tmp
	changed.emit()
	return true

## Moves an equipped item back into the bags (fails when the bags are full).
func move_equipment_to_bag(slot_name: String) -> bool:
	var item_id := equipped(slot_name)
	if item_id.is_empty():
		return false
	if add_item(item_id, 1) > 0:
		return false
	equipment[slot_name] = ""
	changed.emit()
	equipment_changed.emit()
	return true

func consume(item_id: String, amount: int = 1) -> bool:
	return remove_item(item_id, amount)

func to_dict() -> Dictionary:
	return {
		"slots": slots.duplicate(true),
		"equipment": equipment.duplicate(true),
	}

func from_dict(data: Dictionary) -> void:
	clear()
	var raw_slots: Array = data.get("slots", [])
	for i: int in mini(raw_slots.size(), SLOT_COUNT):
		var entry: Variant = raw_slots[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var item_id := String((entry as Dictionary).get("id", ""))
		var count := int((entry as Dictionary).get("count", 0))
		if item_id.is_empty() or count <= 0 or not ItemDB.has(item_id):
			continue
		slots[i] = {"id": item_id, "count": count}
	var raw_equipment: Dictionary = data.get("equipment", {})
	for slot_name: String in EQUIP_SLOTS:
		var item_id := String(raw_equipment.get(slot_name, ""))
		equipment[slot_name] = item_id if ItemDB.has(item_id) else ""
	changed.emit()
	equipment_changed.emit()
