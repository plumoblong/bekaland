extends Placeable
class_name Torch

@onready var fire : AnimatedSprite3D = get_node("Body/Fire")
@onready var light : OmniLight3D = get_node("Body/OmniLight3D")

func _ready() -> void:
	setup()
	
	fire.frame = randi_range(0, 29)
	fire.play("default")

func extinguish() -> void:
	fire.hide()
	light.hide()
