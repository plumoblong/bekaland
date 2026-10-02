extends WorldDestroyable
class_name GrassFoliage

func _ready() -> void:
	setup()
	body.rotation_degrees.x = randf_range(-4.0, 4.0)
	body.rotation_degrees.y = randf_range(0.0, 360.0)
	body.rotation_degrees.z = randf_range(-4.0, 4.0)
	var s : float = randf_range(1.5, 4.0)
	body.scale = Vector3(s, randf_range(1.0, 1.5), s)
