extends Entrance
class_name CaveEntrance

@onready var rocks : Node3D = get_node("Rocks")

func _ready() -> void:
	interactable.set_enabled(false)

func _on_child_exiting_tree(_node: Node) -> void:
	if rocks.get_child_count() <= 1:
		interactable.set_enabled(true)
