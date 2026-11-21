extends Label
class_name AlertPopup

var _life : float = 1.0

@export var speed : float = 0.2
@export var color : Color = Color.WHITE

func use_alert() -> void:
	_life = 1.0
	show()

func _physics_process(delta: float) -> void:
	_life -= delta * speed
	modulate = Color(color.r, color.g, color.b, maxf(0.0, color.a * _life))
	if _life < 0.2:
		hide()
