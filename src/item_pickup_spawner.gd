extends Node3D
class_name LootSpawner

@export var loot : LootTable

@export var random_velocity_range : float = 0.25
@export var random_position_radius : float = 0.5

const PICKUP_SCENE : PackedScene = preload("res://scene/item_pickup.tscn")

func create(direction : Vector3 = Vector3.UP) -> void:
	var s : InventorySlot = loot.get_loot()
	if s == null: 
		return
		
	var p : ItemPickup = PICKUP_SCENE.instantiate()
	
	var v : Vector3 = Vector3(randf() - 0.5, randf() * 0.5, randf() - 0.5).normalized()
	var d : Vector3 = direction * v
	
	_G.game.pickups.add_child(p)
	p.global_position = global_position + (v * random_position_radius)
	p.setup(s, d)

func get_direction_to_player() -> Vector3:
	return global_position.direction_to(_G.game.player.global_position * Vector3(-1.0, 1.0, -1.0))
