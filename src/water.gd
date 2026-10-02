extends Node3D
class_name Water

@onready var mesh : MeshInstance3D = get_node("MeshInstance3D")

func _process(delta: float) -> void:
	mesh.material_override.uv1_offset += Vector3(delta, delta, delta) * 0.04

func _on_body_entered(body: Node3D) -> void:
	#print(body)
	if body is not CharacterEntity:
		return
	body.is_in_water = true
	body._water_detect_position = body.global_position

func _on_body_exited(body: Node3D) -> void:
	#print(body)
	if body is not CharacterEntity:
		return
	body.is_in_water = false
