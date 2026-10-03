extends CharacterBody3D
class_name CharacterEntity

@export var entity_type : Game.EntityType = Game.EntityType.CUSTOM
@export var health : Health
@export var sprite : Sprite3D
@export var movement : Movement
@export var inv_manager : InventoryManager
@export var loot_spawner : LootSpawner
@export var hitbox : CollisionShape3D

@export var submerge_offset : float = 1.0
#@export var in_water_offset : float = 1.0

var _is_in_water : bool = false
var _is_in_lava : bool = false

func disable_hitbox() -> void:
	if not hitbox:
		return
	hitbox.disabled = true

func enable_hitbox() -> void:
	if not hitbox:
		return
	hitbox.disabled = true

func in_water() -> bool:
	return _is_in_water
	
func in_lava() -> bool:
	return _is_in_lava
	
func is_in_liquid() -> bool:
	return _is_in_lava or _is_in_water

func is_submerged() -> bool:
	return global_position.y + submerge_offset < _G.game.get_sea_level() and in_water() or in_lava()
