extends WorldDestroyable
class_name Placeable

#@export var rotate_to_normals : bool = false
@export var water_detect_offset : float = 0.0
@export var rotation_snap : float = 90.0

signal is_in_water

func place() -> void:
	rotation_degrees.y = snappedf(rotation_degrees.y, rotation_snap)
	if global_position.y < _G.game.SEA_LEVEL + water_detect_offset:
		is_in_water.emit()
