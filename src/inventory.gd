extends Resource
class_name Inventory

@export var slots: Array[InventorySlot] = []
@export var capacity: int = 30

const DUMMY_SLOT : InventorySlot = preload("res://data/item/dummy_slot.tres")

signal inventory_change 

func clear() -> void:
	slots = []
	inventory_change.emit()

func setup() -> void:
	for i : int in range(capacity - slots.size()):
		var s : InventorySlot = DUMMY_SLOT.duplicate()
		slots.append(s)
		
func get_total_count(item: Item) -> int:
	var total = 0
	for slot in slots:
		if slot.item == item:
			total += slot.quantity
	return total

func get_hotbar_item(hotbar_slot : int = 0) -> InventorySlot:
	var h : int = clampi(hotbar_slot, 0, 5)
	return slots[h]

func add_item(slot : InventorySlot) -> void:
	if slot.is_empty():
		print(slot.get_string(), " is empty i cannot accept it")
		return

	for i : int in slots.size():
		if slots[i].is_empty() or slots[i].item == slot.item:
			if not slots[i].is_full():
				slots[i].add(slot)
				print(slot.get_string(), " has been accepted as ", i)
				inventory_change.emit()
