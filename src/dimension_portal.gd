extends Area3D
class_name DimensionPortal

@export var target : Game.WorldType = Game.WorldType.CAVE

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body : Node3D) -> void:
	if body is Player:
		_G.game.change_dimension(target)
