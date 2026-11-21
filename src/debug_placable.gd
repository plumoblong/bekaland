extends Placeable
class_name DebugPlaceable

const SCENE : PackedScene = preload("res://scene/ancestor.tscn")

func place() -> void:
	var s : Node3D = SCENE.instantiate()
	s.global_position = global_position + Vector3.UP
	get_parent().add_child(s)
	
