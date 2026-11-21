extends Node
class_name CraftingManager

@export var recipes : Array[CraftingRecipe]
@export var inventory : Inventory
@export var crafting_ui : CraftingUI

var _current_stations : Array[CraftingRecipe.Station] = []

func get_aviable_recipes() -> Array[CraftingRecipe]:
	var a : Array[CraftingRecipe] = []
	
	for i : CraftingRecipe in recipes: 
		if i.can_craft(inventory, _current_stations):
			a.append(i)
			
	return a

func add_station(station : CraftingRecipe.Station) -> void:
	if not (station in _current_stations): _current_stations.append(station)

func remove_station(station : CraftingRecipe.Station) -> void:
	_current_stations = _current_stations.filter(func(s): return s != station)

func request_crafting_ui() -> void:
	crafting_ui.set_parameters(get_aviable_recipes(), inventory, _current_stations)
