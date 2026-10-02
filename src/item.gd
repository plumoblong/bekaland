extends Resource
class_name Item

@export var name : String = "Dummy"
@export var icon : Texture2D = preload("res://texture/morph_0.png")

@export var max_stack : int = 99

@export_category("meta")
@export var emits_light : bool = false

@export_category("placeable")

@export var placeable_id : Game.Placeables = Game.Placeables.NONE

@export var place_ghost_size : Vector3 = Vector3.ONE
@export var place_ghost_offset : Vector3 = Vector3.ZERO 
@export var place_snap_to_normal : bool = false

@export_category("consumable")

@export var consumable : bool = false

@export var consumable_poison_chance : float = 0.0
@export var consumable_heal_value : float = 0.1
