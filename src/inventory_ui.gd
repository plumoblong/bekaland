extends Control
class_name InventoryUI

var inventory: Inventory
@export var slot_scene: PackedScene  # drag InventorySlotUI.tscn here

@export var grid: GridContainer

@export var start_grid : int = 6
@export var end_grid : int = 0
@export var hotbar : bool = false

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
	inventory = new_inventory
	_build_slots()

func _build_slots() -> void:
	for child in grid.get_children():
		child.queue_free()
	slot_nodes.clear()
	
	var end : int = inventory.capacity if end_grid < 1 else end_grid
	
	for i in range(start_grid, end):
		var slot_ui: InventorySlotUI = slot_scene.instantiate()
		grid.add_child(slot_ui)
		slot_ui.slot_id = i
		slot_ui.hotbar_slot = hotbar
		slot_ui.set_slot(inventory.slots[slot_ui.slot_id])
		slot_nodes.append(slot_ui)

func _refresh() -> void:
	for i in slot_nodes:
		i._refresh()
	
func _process(_delta: float) -> void:
	grid.visible = not _F.is_screenshoting
	#debug.text = "Hotbar: " + str(hotbar) + "; " + "Anchor: " + str(grid.get_anchor(SIDE_TOP))
	#debug.visible = _G.debug_mode
	#if slot_nodes.is_empty():
		#return
	#debug.position = slot_nodes[0].global_position - Vector2(0.0, 32.0)
