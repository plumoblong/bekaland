extends Resource
class_name LootTable

## All Loot resources and their percentage change to spawn
@export var table : Dictionary[Loot, float] = {}
@export var loot_chance_percent : float = 1.0

#func _get_loot_array() -> Array[InventorySlot]:
	#
	#var final : Array[InventorySlot]
	#
	#for i : int in range(table.size()):
		#var l : Loot = Global.choose_from_chance(table)
		#var s : InventorySlot = l.get_slot()
		#if s:
			#final.append(s)
		#
	#return final

func get_loot() -> InventorySlot:
	
	var f : Array[InventorySlot] = []
	
	for i : Loot in table:
		if randf() <= table[i] * loot_chance_percent:
			var s : InventorySlot = i.get_slot()
			f.append(s)
	
	if f.is_empty():
		return null
	
	return f.pick_random()
