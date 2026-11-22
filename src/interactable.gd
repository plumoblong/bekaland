extends Area3D
class_name Interactable

@export var interact_id : String = "enter_cave"
@export var interact_string : String = "Enter the caves"

var enabled : bool = false

func _ready() -> void:
	collision_layer = 512
	collision_mask = 512
	add_to_group(_G.GROUP_INTERACT)

func set_enabled(value : bool) -> void:
	
	enabled = value
	
	monitorable = enabled
	monitoring = enabled
