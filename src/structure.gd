extends Node3D
class_name Structure

@export var random_rotation_step : float = 90.0

func _ready() -> void:
	rotation_degrees.y = snappedf(randf_range(0.0, 360.0), random_rotation_step)
