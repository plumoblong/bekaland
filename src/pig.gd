extends CharacterEntity
class_name Animal

@export_subgroup("scale randomizing")
@export var randomize_scale : bool = true
@export var scale_max : float = 1.3
@export var scale_min : float = 0.9

@export_subgroup("movement")

@export var scared_move_speed : float = 15.0

@export var wander_timer : Timer

@export_subgroup("timer randomizing")

@export var wandering_time_max : float = 5.0
@export var wandering_time_min : float = 3.0

@export var pondering_time_max : float = 2.0
@export var pondering_time_min : float = 1.0

@export var scare_time : float = 4.0

var _is_scared : bool = false
var _is_wandering : bool = false

const DESPAWN_RANGE : float = 500.0
var _distance_to_player : float
var _normal_move_speed : float

func _ready() -> void:
	_normal_move_speed = movement.move_speed
	
	wander_timer.timeout.connect(_wander_timeout)
	wander_timer.start(1.0)
	
	add_to_group(_G.GROUP_ENTITY)
	
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	
	if not randomize_scale: 
		return
		
	scale = Vector3.ONE * randf_range(scale_min, scale_max)

func _physics_process(delta: float) -> void:
	_distance_to_player = global_position.distance_to(_G.game.player.global_position)
	
	if _distance_to_player > DESPAWN_RANGE:
		_despawn()
	 
	var is_moving : bool = _is_wandering if not _is_scared else true
	
	movement.wish_dir = Vector2(0.0, -1.0 * float(is_moving))
	movement.move_speed = scared_move_speed if _is_scared else _normal_move_speed
	movement.update(delta)

func _on_damaged(_value : float, _type : Health.DamageType) -> void:
	sprite.damage_anim(health.invincibility_time * 0.2)
	movement.jump(1.5)
	scare()
	
func _on_died() -> void:
	_G.game.player.ui.set_last_health(0.0)
	if loot_spawner:
		loot_spawner.create(velocity.normalized() * Vector3(-2.0, 1.0, -2.0))
		
	disable_hitbox()
	await get_tree().create_timer(1.0).timeout
	queue_free.call_deferred()

func _despawn() -> void:
	queue_free.call_deferred()

func scare() -> void:
	_is_scared = true
	_rotate_random()
	await get_tree().create_timer(scare_time).timeout
	_is_scared = false

func _wander_timeout() -> void:
	_is_wandering = false
	_rotate_random()
	await get_tree().create_timer(randf_range(pondering_time_min, pondering_time_max)).timeout
	_is_wandering = true
	wander_timer.start(randf_range(wandering_time_min, wandering_time_max))

func _rotate_random() -> void:
	rotate_y(deg_to_rad(randf_range(-180.0, 180.0)))
