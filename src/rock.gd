extends WorldDestroyable
class_name FoliageRock

@onready var rock_mesh: MeshInstance3D = $Body/MeshInstance3D

func _ready() -> void:
	setup()
	
	rock_mesh.scale.x = randf_range(1.0, 1.6)
	rock_mesh.scale.z = randf_range(1.0, 1.6)
	rock_mesh.scale.y = randf_range(1.3, 1.5)
	
	rock_mesh.rotation_degrees = Vector3(randf_range(0.0, 360.0), randf_range(0.0, 30.0), randf_range(0.0, 360.0))
