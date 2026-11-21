extends Control
class_name CraftingUI

const SLOT_UI : PackedScene = preload("res://scene/crafting_slot_ui.tscn")

@export var recipe_container : VBoxContainer
@export var container : VBoxContainer
#@export var craft_button : Button

#var selected_slot : CraftingSlotUI = null
#
#var _last_selected : int = -1

signal requested_crafting(recipe : CraftingRecipe)
signal request_close

var _recipes : Array[CraftingRecipe] = []
var _inv : Inventory = null
var _stations : Array[CraftingRecipe.Station]

func set_parameters(recipes : Array[CraftingRecipe], inv : Inventory, stations : Array[CraftingRecipe.Station]) -> void:
	_recipes = recipes
	_inv = inv
	_stations = stations
	if _recipes.is_empty():
		request_close.emit()
		return
	update_recipes()

func update_recipes() -> void:
	
	for c in recipe_container.get_children():
		c.queue_free()
	
	if _recipes.is_empty():
		return
	
	for i : CraftingRecipe in _recipes:
		var s : CraftingSlotUI = SLOT_UI.instantiate()
		recipe_container.add_child(s)
		s.set_recipe(i, _inv, _stations)
		s.selected.connect(_on_slot_selected)
	
func _on_slot_selected(slot : CraftingSlotUI) -> void:
	requested_crafting.emit(slot.get_recipe())
	update_recipes()
	
func _process(_delta: float) -> void:
	container.visible = not (_F.is_screenshoting and _F.get_config_entry("hide_ui_when_screenshot"))

func _get_output_name(slot : CraftingSlotUI) -> String:
	var s : InventorySlot = slot.get_recipe().output
	if s.item:
		return s.item.name
	return "#INVALID_ITEM"
