extends Control
class_name GameStart

func _ready() -> void:
	_F.setup()
	_G.set_init_flags()

	await get_tree().create_timer(2.0).timeout
	
	get_tree().change_scene_to_file("res://scene/menu.tscn")
