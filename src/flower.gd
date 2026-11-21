extends WorldDestroyable
class_name FoliageFlower

@export var gradient_color : Gradient

func _ready() -> void:
	setup()
	var g : float = randf()
	var c : Color = gradient_color.sample(g)
	
	$Body/Node3D/Head.modulate = c
	$Body/Node3D/Head2.modulate = c
	
	$Body/Node3D.rotation_degrees.x = randf_range(-5.0, 5.0)
	$Body/Node3D.rotation_degrees.y = randf() * 360.0
	$Body/Node3D.rotation_degrees.z = randf_range(-5.0, 5.0)
