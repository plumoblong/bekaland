extends RayCast3D
class_name TerrainRay

@onready var _debug_sprite : Sprite3D = get_node("Sprite3D")

func sample_position(pos : Vector2 = Vector2.ZERO) -> Vector3:
	set_global_position(Vector3(pos.x, 128.0, pos.y))
	force_raycast_update()
	return _get_point()
	
func _process(delta: float) -> void:
	_debug_sprite.visible = _G.debug_mode
	_debug_sprite.position = lerp(_debug_sprite.position, global_position, delta * 4.0)

func _get_point() -> Vector3:
	return get_collision_point() + Vector3.UP
	
