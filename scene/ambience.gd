extends Node
class_name AmbienceSFX

var game : Game

@export var overall_volume : float = 0.25

@export var night_volume_curve : Curve
@onready var night_stream : AudioStreamPlayer = get_node("Night")

func _ready() -> void:
	game = get_parent().get_parent()
	night_stream.play()

func _process(_delta: float) -> void:
	if not game: return
	night_stream.volume_linear = night_volume_curve.sample(game.world_time) * overall_volume
	
