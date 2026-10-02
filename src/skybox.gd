extends Node3D
class_name Skybox

@export var game : Game

@onready var stars : GPUParticles3D = get_node("Stars")
@onready var moon : MeshInstance3D = get_node("Moon")

var moon_phase : int = 0

const _MOON_PHASE_ADD_CHANCES : Array[int] = [
	1, 1, 1, 2, 2, 3, 3, 4, 5
]

func _ready() -> void:
	game.day_ended.connect(_update_moon)

func _process(_delta: float) -> void:
		
	rotation_degrees.x = game.world_time * 360.0 - 15.0
	global_position = game.player.global_position

func _update_moon() -> void:
	moon_phase += _MOON_PHASE_ADD_CHANCES.pick_random()
	if moon_phase > 4:
		moon_phase -= 5
	moon.material_override.uv1_offset.x = float(moon_phase) * 0.2
