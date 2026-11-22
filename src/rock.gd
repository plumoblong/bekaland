extends WorldDestroyable
class_name FoliageRock

@onready var rock_mesh: MeshInstance3D = $Body/MeshInstance3D
@export var not_for_generation : bool = false
@export var for_scale : Vector3 = Vector3.ONE

func _ready() -> void:
	setup()
	
	rock_mesh.scale.x = randf_range(1.0, 1.6) * for_scale.x
	rock_mesh.scale.z = randf_range(1.0, 1.6) * for_scale.z
	rock_mesh.scale.y = randf_range(0.9, 1.2) * for_scale.y
	
	if not_for_generation: 
		global_position.y -= randf()
		return
	rock_mesh.rotation_degrees = Vector3(randf_range(0.0, 360.0), randf_range(0.0, 30.0), randf_range(0.0, 360.0))
