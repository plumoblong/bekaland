extends WorldDestroyable
class_name Placeable

#@export var rotate_to_normals : bool = false
@export var water_detect_offset : float = 0.0
@export var use_rotation_snap : bool = true
@export var rotation_snap : float = 90.0

signal is_in_water

func _ready() -> void:
	setup()

func place() -> void:
	if use_rotation_snap: rotation_degrees.y = snappedf(rotation_degrees.y, rotation_snap)
	if global_position.y < _G.game.get_sea_level() + water_detect_offset:
		is_in_water.emit()
