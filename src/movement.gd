extends Node
class_name Movement

var _parent : CharacterEntity

@export var move_speed : float = 20.0
@export var jump_speed : float = 7.0
@export var water_margin : float = 0.5
@export var friction : float = 150.0       # how fast you slow down when no input
@export var accel : float = 0.8       # how fast you slow down when no input
@export var air_control_mult : float = 50.0 # optional: less control in air
@export var slope_snap : float = 0.25

const GRAVITY : float = 25.0
const FALLING_MULT : float = 1.7

var movement_mult : float
var wish_dir : Vector2

func _ready() -> void:
	assert(get_parent() is CharacterEntity)
	_parent = get_parent()
	_parent.floor_snap_length = slope_snap
	_parent.floor_constant_speed = false

func jump(strength: float = -1.0) -> void:
	if not _parent.is_on_floor(): return
	var water_mult : float = 1.3 if _parent.is_in_water else 1.0
	var spd: float = jump_speed if strength == -1.0 else strength
	_parent.velocity += get_surface_normal() * spd * water_mult
	
func get_surface_normal() -> Vector3:
	return _G.game.generation.terrain.data.get_normal(_parent.global_position)

func update(delta : float) -> void:
	if not _G.game: return
	
	movement_mult = 1.0 if not _parent.is_in_water else 0.5
	
	if not _parent.is_on_floor():
		var mult : float = FALLING_MULT if _parent.velocity.y < 0.0 else 1.0
		_parent.velocity.y -= (GRAVITY * mult * delta) * movement_mult
	
	var direction : Vector3 = (_parent.transform.basis * Vector3(wish_dir.x, 0.0, wish_dir.y)).normalized()
	var target_speed : float = move_speed * movement_mult
	
	var current_accel : float = friction * accel
	if not _parent.is_on_floor():
		current_accel = air_control_mult
	
	# isolate horizontal velocity
	var horizontal_vel : Vector3 = Vector3(_parent.velocity.x, 0.0, _parent.velocity.z)
	
	if direction:
		var target_vel : Vector3 = direction * target_speed	
		horizontal_vel = horizontal_vel.move_toward(target_vel, current_accel * target_speed * delta)
	else:
		horizontal_vel = horizontal_vel.move_toward(Vector3.ZERO, friction * delta)
	
	_parent.velocity.x = horizontal_vel.x
	_parent.velocity.z = horizontal_vel.z

	_parent.move_and_slide()
	
func is_moving() -> bool:
	return wish_dir != Vector2.ZERO
