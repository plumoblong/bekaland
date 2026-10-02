extends Control

@onready var logo : Label = get_node("Main/Logo")
@onready var main_screen : Control = get_node("Main")
var screen : int = 0

var GAME_SCENE : PackedScene = preload("res://scene/game.tscn")

func _process(_delta: float) -> void:
	var logoscale : float = 1.0 + sin(_G.time * 5) * 0.25
	if Engine.get_physics_frames() % 4 == 0:
		logo.offset_transform_scale.x = logoscale
		logo.offset_transform_scale.y = logoscale
	
	main_screen.visible = screen == 0

func _on_start_pressed() -> void:
	_G.loading_screen.activate("Generating...")
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_packed(GAME_SCENE)
