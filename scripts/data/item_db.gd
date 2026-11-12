class_name ItemDB
extends RefCounted
## Loads every ItemData resource in resources/items/ exactly once.

const ITEM_DIR := "res://resources/items"

static var _items: Dictionary = {}
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_load_dir()

static func _load_dir() -> void:
	_items.clear()
	var dir := DirAccess.open(ITEM_DIR)
	if dir == null:
		push_warning("ItemDB: missing " + ITEM_DIR)
		return
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res: Resource = ResourceLoader.load(ITEM_DIR + "/" + file_name)
		if res is ItemData:
			var item: ItemData = res
			if item.id.is_empty():
				item.id = file_name.get_basename()
			_items[item.id] = item
		else:
			push_warning("ItemDB: %s is not an ItemData" % file_name)

static func reload() -> void:
	_loaded = false
	ensure_loaded()

static func get_item(item_id: String) -> ItemData:
	ensure_loaded()
	return _items.get(item_id, null) as ItemData

static func has(item_id: String) -> bool:
	ensure_loaded()
	return _items.has(item_id)

static func all_items() -> Array:
	ensure_loaded()
	return _items.values()

static func count() -> int:
	ensure_loaded()
	return _items.size()
