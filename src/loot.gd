extends Resource
class_name Loot

@export var item : Item

@export var count_max : int = 5
@export var count_min : int = 2

func get_slot() -> InventorySlot:
	var s : InventorySlot = InventorySlot.new()
	s.item = item
	s.quantity = randi_range(count_min, count_max)
	return s if not s.is_empty() else null
