extends WorldDestroyable
class_name ShrubFoliage
#var _mat : StandardMaterial3D

func _ready() -> void:
	setup()
	body.rotation_degrees.x = randf_range(-9.0, 9.0)
	body.rotation_degrees.y = randf_range(0.0, 360.0)
	body.rotation_degrees.z = randf_range(-9.0, 9.0)
	var s : float = randf_range(1.5, 4.5)
	body.scale = Vector3(s, randf_range(1.2, 2.0), s)
