extends Control
class_name HotbarUI

var inventory: Inventory
@export var slot_scene: PackedScene  # drag InventorySlotUI.tscn here

@export var grid: GridContainer

var slot_nodes: Array[InventorySlotUI] = []

func set_selected(slot : int = 0) -> void:
	for i : int in slot_nodes.size():
		slot_nodes[i].selected = false
		if i == slot: 
			slot_nodes[i].selected = true

func set_hotbar_slot(is_hotbar : bool = false) -> void:
	set_selected(-1)
	for i : int in slot_nodes.size():
		slot_nodes[i].hotbar_slot = is_hotbar
		
func set_inventory(new_inventory: Inventory) -> void:
	if inventory and inventory.inventory_changed.is_connected(_refresh):
		inventory.inventory_changed.disconnect(_refresh)
	inventory = new_inventory
	inventory.inventory_changed.connect(_refresh)
	_build_slots()
	_refresh()

func _build_slots() -> void:
	for child in grid.get_children():
		child.queue_free()
	slot_nodes.clear()
	
	for i in range(0, 6):
		var slot_ui: InventorySlotUI = slot_scene.instantiate()
		slot_ui.slot_id = i
		slot_ui.hotbar_slot = true
		grid.add_child(slot_ui)
		slot_nodes.append(slot_ui)

func _refresh() -> void:
	for i in range(slot_nodes.size()):
		var data_slot: InventorySlot = inventory.slots[slot_nodes[i].slot_id] if slot_nodes[i].slot_id < inventory.slots.size() else null
		slot_nodes[i].set_slot(data_slot)
		slot_nodes[i].inventory_id = i
		print(slot_nodes[i].slot_id, " set to ", i)
