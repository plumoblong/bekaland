extends Node
class_name Health

var value : float = 1.0
@export var max_health : float = 1.0

@export var natural_heal : bool = false
@export var natural_heal_rate : int = 60 # every x frames add natural_heal_value to value
@export var natural_heal_value : float = 1.0
@export var invincibility_time : float = 0.5

const NATURAL_HEAL_COOLDOWN : float = 30.0

var can_natural_heal : bool = false
var invincible : bool = false

@export var alive : bool = true

signal damaged(value : float, type : DamageType)
signal died
signal respawned

enum DamageType {
	GENERIC,
	OXYGEN
}

func _ready() -> void:
	if not natural_heal:
		process_mode = Node.PROCESS_MODE_DISABLED
	value = max_health

func hurt(damage : float = 0.0, type : DamageType = DamageType.GENERIC) -> void:
	if invincible: return
	value -= damage
	damaged.emit(damage, type)
	if value < 0.01:
		die()
		return
	start_invincibility()
	reset_natural_heal()
	
func reset_natural_heal(time : float = -1.0) -> void:
	can_natural_heal = false
	var t : float = NATURAL_HEAL_COOLDOWN if time == -1.0 else time
	await get_tree().create_timer(t).timeout
	can_natural_heal = true

func start_invincibility(time : float = -1.0) -> void:
	invincible = true
	var t : float = invincibility_time if time == -1.0 else time
	await get_tree().create_timer(t).timeout
	invincible = false

func is_full() -> bool:
	return value >= max_health

func _update_natural_heal() -> void:
	if not alive:
		return
		
	if Engine.get_physics_frames() % natural_heal_rate == 0:
		
		if not can_natural_heal:
			return 
		if is_full():
			return
			
		value += natural_heal_value * 0.01

func die() -> void:
	if alive:
		alive = false
		value = 0.0
		died.emit()

func respawn() -> void:
	if not alive:
		alive = true
		value = max_health
		respawned.emit()

func get_ratio() -> float:
	return value / max_health

func _process(_delta: float) -> void:
	value = clampf(value, 0.0, max_health)

func _physics_process(_delta: float) -> void:
	if natural_heal: _update_natural_heal()
