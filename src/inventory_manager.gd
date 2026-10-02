extends Node
class_name InventoryManager

@export var inventory : Inventory
@export var inventory_ui : InventoryUI
@export var hotbar_ui : InventoryUI
@export var ui : UI

const DUMMY_SLOT : InventorySlot = preload("res://data/item/dummy_slot.tres")

signal hotbar_slot_selected(slot_id : int)

var _inventory_opened : bool = false

func _ready() -> void:
	inventory.setup()
	if hotbar_ui and inventory_ui:
		hotbar_ui.set_inventory(inventory)
		inventory_ui.set_inventory(inventory)
	if not ui:
		process_mode = Node.PROCESS_MODE_DISABLED
		
#func set_inv() -> void:
	#hotbar_ui.set_inventory(inventory)
	#inventory_ui.set_inventory(inventory)

func select_slot(new_slot : int = 0) -> void:
	hotbar_ui.set_selected(new_slot)
	hotbar_slot_selected.emit(new_slot)

#func _fill_inventory() -> void:
	#for x : int in inventory.capacity:
		#var s : InventorySlot = DUMMY_SLOT.duplicate()
		#s.quantity = randi_range(0, 99)
		#inventory.slots.append(s)

func _process(_delta: float) -> void:
	inventory_ui.visible = _inventory_opened and ui.ui_visible
	hotbar_ui.visible = ui.ui_visible

func open_inventory_ui() -> void:
	if not inventory or not ui: return
	_inventory_opened = true
	hotbar_ui.set_hotbar_slot(false)
	ui.crosshair.hide()
	ui.set_mouse(false)
	
func close_inventory_ui() -> void:
	if not inventory or not ui: return
	_inventory_opened = false
	hotbar_ui.set_hotbar_slot(true)
	ui.crosshair.show()
	ui.set_mouse(true)
