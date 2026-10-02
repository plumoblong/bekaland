extends Resource
class_name LootTable

@export var table : Dictionary[Loot, int] = {}
@export var loot_chance_percent : float = 1.0

func _get_loot_array() -> Array[InventorySlot]:
	
	var final : Array[InventorySlot]
	
	for i : int in range(table.size()):
		var l : Loot = Global.choose_from_chance(table)
		var s : InventorySlot = l.get_slot()
		if s:
			final.append(s)
		
	return final

func get_loot() -> InventorySlot:
	var a : Array[InventorySlot] = _get_loot_array()
	var c : bool = false if a.is_empty() else randf() > 1.0 - loot_chance_percent
	if not c:
		return null
	var s : InventorySlot = a.pick_random()
	return s
