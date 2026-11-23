extends Entrance
class_name CaveEntrance

@onready var rocks : Node3D = get_node("Rocks")

func _process(_delta) -> void:
	interactable.set_enabled(rocks.get_child_count() <= 1)
