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

var is_in_water : bool = false

var _water_detect_position : Vector3 = Vector3.ZERO

func disable_hitbox() -> void:
	if not hitbox:
		return
	hitbox.disabled = true

func enable_hitbox() -> void:
	if not hitbox:
		return
	hitbox.disabled = true

func is_submerged() -> bool:
	return _water_detect_position.y + submerge_offset < _G.game.SEA_LEVEL and is_in_water
