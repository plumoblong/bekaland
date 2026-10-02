extends CharacterEntity
class_name ItemPickup

@onready var light : OmniLight3D = get_node("Light")
@onready var debug : Label3D = get_node("Debug")

var slot : InventorySlot

const GRAVITY : float = 15.0
const SPEED : float = 20.0
const FALLING_MULT : float = 1.4
const DRAG : float = 4.0

const PICKUP_COOLDOWN : float = 0.1

const ANIM_SPEED : float = 2.0

var _dir : Vector3
var _off : Vector3
var _vel_mult : float = 1.5
var _submerge_mult : float = 1.0

func setup(inventory_slot : InventorySlot, init_vel : Vector3 = Vector3.UP) -> void:
	
	if inventory_slot == null or inventory_slot.is_empty(): 
		return
	
	_dir = init_vel * SPEED
	slot = inventory_slot
	
	sprite.texture = slot.item.icon
	sprite.shaded = not slot.item.emits_light
	light.visible = slot.item.emits_light
	
	await get_tree().create_timer(PICKUP_COOLDOWN).timeout
	
	add_to_group(_G.GROUP_PICKUP)

func _physics_process(delta: float) -> void:
	_vel_mult = lerpf(_vel_mult, 0.0, DRAG * delta)
	_submerge_mult = 0.3 if is_submerged() else 1.0
	
	if not is_on_floor():
		_off.y -= GRAVITY * delta
	
	velocity = ((_dir * _vel_mult) + _off ) * _submerge_mult
	
	move_and_slide()
	_update_debug()

func _process(_delta: float) -> void:
	#sprite.pixel_size = 0.02 + abs(sin(_G.time * ANIM_SPEED)) * 0.01
	var o : float = global_position.x + global_position.z
	sprite.offset.y = sin(o + _G.time * ANIM_SPEED) * 4.0

func _update_debug() -> void:
	debug.visible = _G.debug_mode
	if _G.debug_mode:
		if slot and slot.item:
			debug.text = "Item: " + str(slot.item.name) + " x" + str(slot.quantity) + "\nVelocity: " + str(velocity) + "\nDir: " + str(_dir)

func pickup(inv : Inventory) -> void:
	inv.add_item(slot)
	queue_free.call_deferred()
