extends Node
class_name InventoryManager

@export var inventory : Inventory
@export var inventory_ui : InventoryUI
@export var hotbar_ui : InventoryUI
@export var crafting_ui : CraftingUI
@export var crafting_manager : CraftingManager
@export var ui : UI

signal hotbar_slot_selected(slot_id : int)

var inventory_opened : bool = false
var container_opened : bool = false
var crafting_opened : bool = false

var _last_selected : int = 0 

var active : bool = true

func _ready() -> void:
	var i : Inventory = inventory.duplicate()
	inventory = i
	inventory.setup()
	if hotbar_ui and inventory_ui:
		hotbar_ui.set_inventory(inventory)
		inventory_ui.set_inventory(inventory)
	if not ui:
		process_mode = Node.PROCESS_MODE_DISABLED
	
	if crafting_ui:
		crafting_ui.requested_crafting.connect(_on_crafting_requested)
		crafting_ui.request_close.connect(_close_crafting)
		
func _on_save_data_applied() -> void:
	inventory = _G.game.get_inventory(0)
	inventory.setup()
	
func _close_crafting() -> void:
	await get_tree().create_timer(0.1).timeout
	close_inventory_ui()

func select_slot(new_slot : int = 0) -> void:
	hotbar_ui.set_selected(new_slot)
	hotbar_slot_selected.emit(new_slot)
	_last_selected = new_slot

#func _fill_inventory() -> void:
	#for x : int in inventory.capacity:
		#var s : InventorySlot = DUMMY_SLOT.duplicate()
		#s.quantity = randi_range(0, 99)
		#inventory.slots.append(s)

func _process(_delta: float) -> void:
	inventory_ui.visible = inventory_opened or container_opened and ui.ui_visible and active
	hotbar_ui.visible = ui.ui_visible and active
	crafting_ui.visible = crafting_opened and ui.ui_visible and active
	
func open_inventory_ui() -> void:
	if not inventory or not ui: return
	inventory_opened = true
	container_opened = false
	crafting_opened = false
	hotbar_ui.set_hotbar_slot(false)
	ui.crosshair.hide()
	ui.set_mouse(false)
	
func close_inventory_ui() -> void:
	if not inventory or not ui: return
	inventory_opened = false
	container_opened = false
	crafting_opened = false
	hotbar_ui.set_hotbar_slot(true)
	ui.crosshair.show()
	ui.set_mouse(true)
	select_slot(_last_selected)
	
func open_crafting_ui() -> void:
	var r : Array[CraftingRecipe] = crafting_manager.get_aviable_recipes()
	if r.is_empty():
		_G.set_alert("No recipes aviable.")
		return
	inventory_opened = false
	container_opened = false
	crafting_opened = true
	crafting_manager.request_crafting_ui()
	hotbar_ui.set_hotbar_slot(false)
	ui.crosshair.hide()
	ui.set_mouse(false)

func open_container_ui(container : Inventory) -> void:
	if not container or not ui: return
	inventory_opened = false
	container_opened = true
	crafting_opened = false
	inventory_ui.set_inventory(inventory)
	hotbar_ui.set_hotbar_slot(false)
	ui.crosshair.hide()
	ui.set_mouse(false)

func is_ui_open() -> bool:
	return inventory_opened or container_opened or crafting_opened

func _on_crafting_requested(recipe : CraftingRecipe) -> void:
	var out : InventorySlot = recipe.output.duplicate()
	if not out:
		_G.set_alert("Recipe is invalid!")
		return
	
	for i : InventorySlot in recipe.inputs:
		inventory.remove_item(i.item, i.quantity)
	
	inventory.add_item(out)
	
	crafting_manager.request_crafting_ui()
	
	inventory_ui._refresh()
	hotbar_ui._refresh()
	
	crafting_ui.update_recipes()
