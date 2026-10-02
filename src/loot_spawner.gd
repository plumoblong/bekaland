extends Node3D
class_name ItemPickupSpawner

func create(slot : InventorySlot, direction : Vector3 = Vector3.UP) -> void:
	if slot == null: 
		return
	
	if slot.is_empty():
		return
		
	var p : ItemPickup = LootSpawner.PICKUP_SCENE.instantiate()
	
	_G.game.pickups.add_child(p)
	p.global_position = global_position
	p.setup(slot.duplicate(), direction)
