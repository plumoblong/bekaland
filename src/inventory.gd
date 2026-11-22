extends Resource
class_name Inventory

@export var slots: Array[InventorySlot] = []
@export var capacity: int = 30

signal inventory_change 

func clear() -> void:
	slots = []
	inventory_change.emit()

func setup() -> void:
	for i : int in range(capacity - slots.size()):
		var s : InventorySlot = _G.DUMMY_SLOT.duplicate()
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

func add_item(slot : InventorySlot) -> bool:
	if slot.is_empty():
		print(slot.get_string(), " is empty i cannot accept it")
		return false

	for i : int in slots.size():
		if slots[i].is_empty() or slots[i].item == slot.item:
			if not slots[i].is_full():
				slots[i].add(slot)
				print(slot.get_string(), " has been accepted as ", i)
	
	inventory_change.emit()
	return true
	
func remove_item(item : Item, count : int = 1) -> bool:
	if item == null or count <= 0:
		return false
	if get_total_count(item) < count:
		return false

	var remaining : int = count
	# Walk backwards so the hotbar slots (the first 6) are drained last
	for i : int in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var slot : InventorySlot = slots[i]
		if slot.item != item:
			continue
		var taken : int = mini(slot.quantity, remaining)
		slot.quantity -= taken
		remaining -= taken
		if slot.quantity <= 0:
			slots[i] = _G.DUMMY_SLOT.duplicate()

	inventory_change.emit()
	return true
	
func is_full() -> bool:
	for slot : InventorySlot in slots:
		if slot.is_empty():
			return false
	return true
