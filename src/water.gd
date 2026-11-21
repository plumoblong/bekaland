extends Node3D
class_name Water

@onready var mesh : MeshInstance3D = get_node("MeshInstance3D")

@export var is_lava : bool = false

const WATER_MAT : StandardMaterial3D = preload("res://material/water.tres")
const LAVA_MAT : StandardMaterial3D = preload("res://material/lava.tres")

func _process(delta: float) -> void:
	mesh.material_override.uv1_offset += Vector3(delta, delta, delta) * 0.04

func _on_body_entered(body: Node3D) -> void:
	#print(body)
	if body is not CharacterEntity:
		return
	body._is_in_water = not is_lava
	body._is_in_lava = is_lava
	body.movement.movement_mult = 0.2 if is_lava else 0.5
	 
func _on_body_exited(body: Node3D) -> void:
	#print(body)
	if body is not CharacterEntity:
		return
	body._is_in_water = false
	body._is_in_lava = false
	body.movement.movement_mult = 1.0

func set_lava(a : bool) -> void:
	if a == is_lava: 
		return
	is_lava = a
	if is_lava:
		mesh.material_override = LAVA_MAT
	else:
		mesh.material_override = WATER_MAT
