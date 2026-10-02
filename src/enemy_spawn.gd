extends Node
class_name Spawner

const ENEMIES : Array[PackedScene] = [
	preload("res://scene/ghoul.tscn")
]

const ANIMALS : Array[PackedScene] = [
	preload("res://scene/pig.tscn")
]

@export var animals_node : Node
@export var enemies_node : Node

@export var animal_spawn_timer : Timer

@export var animal_spawn_time_max : float = 8.0
@export var animal_spawn_time_min : float = 4.0

@export var animal_spawn_hour_max : float = 16.0
@export var animal_spawn_hour_min : float = 8.0

var _animals_can_spawn : bool = false

const ANIMAL_SPAWN_RANGE : float = 400.0
const ANIMAL_LIMIT : int = 10
const ENEMY_LIMIT : int = 10

var _game : Game

const VEC_ARRAY : PackedVector2Array = [
	Vector2(-0.447, 0.894),
	Vector2(0.894, -0.447),
	Vector2(-0.707,  -0.707),
	Vector2(0.243, -0.970),
	Vector2(-0.997,  0.078),
	Vector2(0.554, 0.832),
	Vector2(-0.164, -0.986),
	Vector2(0.933, 0.359),
]

var _current_vec : int = 0

func _ready() -> void:
	animal_spawn_timer.timeout.connect(_spawn_animal)
	_game = get_parent()

func _process(_delta: float) -> void:
	_animals_can_spawn = _game.get_hour() in range(animal_spawn_hour_min, animal_spawn_hour_max)
	if _animals_can_spawn:
		_update_animal_spawns()

func _update_animal_spawns() -> void:
	if animal_spawn_timer.is_stopped():
		animal_spawn_timer.start()

func _get_vector() -> Vector2:
	if _current_vec > 6:
		_current_vec = 0
	else:
		_current_vec += 1
		
	return VEC_ARRAY[_current_vec] 

func _get_spawn_pos(offset : Vector3, mult : float = 1.0) -> Vector3:
	var pos : Vector2 = _get_vector()
	var r : float = randf_range(mult * 0.75, mult)
	var o : Vector2 = Vector2(offset.x, offset.z)
	var final : Vector3 = _game.ray.sample_position(pos * r + o)
	print(final, " pig position")
	return final

func _spawn_animal() -> void:
	var pos : Vector3 = _get_spawn_pos(_game.player.global_position, ANIMAL_SPAWN_RANGE)
	
	if animals_node.get_child_count() < ANIMAL_LIMIT:
		var animal_scene : PackedScene = ANIMALS.pick_random()
		var animal : Animal = animal_scene.instantiate()
		animals_node.add_child(animal)
		animal.global_position = pos
	
	if _animals_can_spawn:
		var t : float = _get_animal_spawn_time()
		animal_spawn_timer.start(t)

func _get_animal_spawn_time() -> float:
	return randf_range(animal_spawn_time_min, animal_spawn_time_max) * animals_node.get_child_count()
