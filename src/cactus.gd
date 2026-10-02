extends WorldDestroyable
class_name CactusFoliage

func _ready() -> void:
	setup()
	body.rotation_degrees.x = randf_range(-7.0, 7.0)
	body.rotation_degrees.y = randf_range(0.0, 360.0)
	body.rotation_degrees.z = randf_range(-7.0, 7.0)
	
	var s : float = randf_range(1.5, 2.3)
	body.scale = Vector3(s, randf_range(1.4, 2.5), s)
	
