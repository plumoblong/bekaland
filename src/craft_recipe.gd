extends Resource
class_name CraftingRecipe

enum Station {
	NONE,
	WORKBENCH,
	FURNACE,
	ANVIL
}

@export var inputs : Dictionary[Item, int]
@export var required_station : Station = Station.NONE

@export var output : InventorySlot

func can_craft(inventory : Inventory, stations : Array[Station]) -> bool:
	
	if inputs.is_empty() or output.is_empty():
		return false
	
	for i in inputs:
		var c : int = inventory.get_total_count(i)
		if c < inputs[i]:
			return false
	
	return true
