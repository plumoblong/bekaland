extends Resource
class_name CraftingRecipe

enum Station {
	NONE,
	WORKBENCH,
	FURNACE,
	ANVIL
}

@export var inputs : Array[InventorySlot]
@export var required_station : Station = Station.NONE

@export var output : InventorySlot

func can_craft(inventory : Inventory, stations : Array[Station]) -> bool:
	
	if inputs.is_empty() or output.is_empty():
		return false
		
	if not inventory:
		return false
	
	if not _check_stations(stations):
		return false
	
	for i in inputs:
		var c : int = inventory.get_total_count(i.item)
		if c < i.quantity:
			return false
	
	return true

func _check_stations(stations : Array[Station]) -> bool:
	return required_station == Station.NONE or required_station in stations
