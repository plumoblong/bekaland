extends CharacterBody3D
class_name Enemy

@export var movement : Movement

func _physics_process(delta: float) -> void:
	movement.update(delta)
	movement.wish_dir = Vector2(0.0, -1.0)
	look_at(_G.player.global_position)
	rotation_degrees.x = 0.0
