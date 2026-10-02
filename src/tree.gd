extends WorldDestroyable
class_name TreeFoliage

@onready var leaf : MeshInstance3D = get_node("Body/Leaf")

func _ready() -> void:
	setup()
	rotation_degrees.x = randf_range(-7.0, 7.0)
	rotation_degrees.y = randf_range(0.0, 360.0)
	rotation_degrees.z = randf_range(-7.0, 7.0)
	leaf.rotation_degrees.z = randf_range(-10.0, 10.0)
	leaf.rotation_degrees.x = randf_range(-10.0, 10.0)
	#var s : float = randf_range(2.0, 3.5)
	#leaf.scale = Vector3(s, randf_range(1.5, 2.5), s)
	#leaf.global_position.y += randf_range(-1.0, 1.0)
