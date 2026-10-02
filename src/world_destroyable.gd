extends StaticBody3D
class_name WorldDestroyable

@export var health : Health
#@export var drops : LootTable
@export var hitbox : CollisionShape3D
@export var body : Node3D
@export var loot_spawner : LootSpawner
@export var item_spawner : ItemPickupSpawner
@export var item_spawner_slot : InventorySlot 
@export var material : Mat = Mat.NONE


@export var shake_strength : float = 0.25
@export var shake_duration : float = 0.25

enum Mat {
	NONE,
	WOOD,
	ROCK,
	METAL,
}

const SHAKE_FRAMERATE : float = 25.0

func setup() -> void:
	
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_die)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	
	add_to_group(_G.GROUP_DESTROYABLE)

func damage(value : float = 0.1) -> void:
	health.hurt(value)
	
func _on_damaged(_value : float, _type : Health.DamageType) -> void:
	_shake_booty()

func _on_die() -> void:
	_G.game.player.ui.set_last_health(0.0)
	
	hitbox.disabled = true
	
	if loot_spawner:
		var dir : Vector3 = loot_spawner.get_direction_to_player()
		loot_spawner.create(dir)
	
	elif item_spawner:
		item_spawner.create(item_spawner_slot, Vector3.UP * 0.35)
		
	await get_tree().create_timer(shake_duration).timeout
		
	queue_free.call_deferred()
		

func _shake_booty() -> void:
	var elapsed : float = 0.0
	var framerate : float = 1.0 / SHAKE_FRAMERATE
	while elapsed < shake_duration:
		var t : float = elapsed / shake_duration
		var falloff : float = 1.0 - t
		var offset := Vector3(
			randf_range(-1.0, 1.0),
			0.0,
			randf_range(-1.0, 1.0)
		) * shake_strength * falloff
		body.position = offset
		await get_tree().create_timer(framerate).timeout
		elapsed += framerate
	body.position = Vector3.ZERO
