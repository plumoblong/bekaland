extends CharacterEntity
class_name ItemPickup

@onready var light : OmniLight3D = get_node("Light")
@onready var debug : Label3D = get_node("Debug")
@onready var sprites : Node3D = get_node("Sprites")

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
	
	_setup_sprites(slot.item.icon, not slot.item.emits_light, slot.quantity)
	light.visible = slot.item.emits_light
	light.light_color = slot.item.light_emit_color
	
	await get_tree().create_timer(PICKUP_COOLDOWN).timeout
	
	add_to_group(_G.GROUP_PICKUP)

func _setup_sprites(texture : Texture2D, shaded : bool = true, count : int = 1) -> void:
	for i : int in sprites.get_child_count():
		var s : Sprite3D = sprites.get_child(i)
		var p : float = 0.8 if i == 0 else 0.64 #sprite pixel size coefficient
		s.texture = texture
		s.pixel_size = p / texture.get_height()
		s.shaded = shaded
		if i == 0:
			s.show()
		else:
			if count >= i * 10:
				s.show()
			else:
				s.hide()

func _physics_process(delta: float) -> void:
	_vel_mult = lerpf(_vel_mult, 0.0, DRAG * delta)
	_submerge_mult = 0.3 if is_submerged() else 1.0
	
	if not is_on_floor():
		_off.y -= GRAVITY * delta
	
	velocity = ((_dir * _vel_mult) + _off ) * _submerge_mult
	
	rotation_degrees.y += delta * 50.0
	
	move_and_slide()
	_update_debug()

func _update_debug() -> void:
	debug.visible = _G.debug_mode
	if _G.debug_mode:
		if slot and slot.item:
			debug.text = "Item: " + str(slot.item.name) + " x" + str(slot.quantity) + "\nVelocity: " + str(velocity) + "\nDir: " + str(_dir)

func pickup(inv : Inventory) -> void:
	inv.add_item(slot)
	queue_free.call_deferred()
