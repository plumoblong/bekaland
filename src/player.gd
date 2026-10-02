extends CharacterEntity
class_name Player

@onready var ui : UI = get_node("UI")

@onready var head : Node3D = get_node("Head")
@onready var camera : Camera3D = get_node("Head/Camera3D")

@onready var ray : RayCast3D = get_node("Head/Camera3D/Ray")
@onready var placeable_ghost : MeshInstance3D = get_node("Ghost")
@onready var pickup_spawner : ItemPickupSpawner = get_node("PickupSpawner")

@onready var body_sprite : Node3D = get_node("Body")
@onready var head_sprite : Sprite3D = get_node("Body/Head")

@onready var timer_suffocation : Timer = get_node("SuffocationTimer")
@onready var timer_respawn : Timer = get_node("RespawnTimer")

const MOUSE_SENSITIVITY : float = 0.002

const SUFFOCATION_THRES : float = 0.01
const SUFFOCATION_TIME : float = 1.0
const SUFFOCATION_DAMAGE : float = 0.1
 
const CAMERA_BOB_SPEED : float = 7.0
const CAMERA_BOB_HEIGHT : float = 0.25

const CAMERA_FOV_NORMAL : float = 80.0
const CAMERA_FOV_ZOOM : float = 30.0

var _camera_movement_mult : float = 0.0
var _camera_can_move_mult : float = 0.0

const RESPAWN_TIME : float = 10.0

var oxygen : float = 1.0

var can_control : bool = false 

var selected_hotbar : int = 0

var last_health : float = 0.0

var _current_damage : float = 0.1

var held_item : InventorySlot

var _ray_point : Vector3 = Vector3.ZERO
var _ray_norm : Vector3 = Vector3.ZERO

var _spawn_position : Vector2 = Vector2.ZERO
const _SPAWN_RADIUS : float = 4.0

func _ready() -> void:
	ui.set_mouse(true)
	ui.pulse(Color(0.0, 0.0, 0.0, 1.0), 1.0)
	inv_manager.select_slot(selected_hotbar)
	await get_tree().create_timer(0.1).timeout
	health.respawn()
	
func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		if can_control:
			var s : float = MOUSE_SENSITIVITY * (camera.fov / CAMERA_FOV_NORMAL)
			rotate_y(-event.screen_relative.x * s)
			head.rotate_x(-event.screen_relative.y * s)
			head.rotation_degrees.x = clampf(head.rotation_degrees.x, -90.0, 90.0)


func _physics_process(delta: float) -> void:
	head_sprite.rotation_degrees.x = head.rotation_degrees.x
	movement.move_speed = 8.0 + health.get_ratio() * 12.0
	movement.update(delta)
	
	if can_control and health.alive:
		movement.wish_dir = Input.get_vector("left", "right", "forward", "back")
		if Input.is_action_pressed("jump"):
			movement.jump()
		
		_handle_drop()
		
		if ray.is_colliding():
			
			_ray_point = ray.get_collision_point()
			_ray_norm = ray.get_collision_normal()
			
			_update_ghost()
			
			if Input.is_action_just_pressed("place"):
				_handle_placing()
			elif Input.is_action_pressed("attack"):
				_handle_attack()
				
		#else:
			#placeable_ghost.hide()
	else:
		movement.wish_dir = Vector2.ZERO
		#placeable_ghost.hide()
	
	if Input.is_action_just_pressed("screenshot"):
		_F.screenshot()
	

func _process(delta: float) -> void:
	if health.alive:
		_update_camera(delta)
		
		_handle_inventory()
		_update_effects(delta)

func _handle_placing() -> void:
	held_item.place_item(_ray_point, placeable_ghost.rotation)

func _update_ghost() -> void:
	if not ray.get_collider() is Terrain3D:
		#placeable_ghost.hide()
		return
		
	if held_item.is_empty(): 
		#placeable_ghost.hide()
		return
		
	var i : Item = held_item.item
	if i.placeable_id == Game.Placeables.NONE:
		#placeable_ghost.hide()
		return
	
	#placeable_ghost.show()
	placeable_ghost.global_position = _ray_point + i.place_ghost_offset
	placeable_ghost.rotation = _ray_norm if i.place_snap_to_normal else rotation
	placeable_ghost.scale = i.place_ghost_size

func _handle_attack() -> void:
	var obj : Node3D = ray.get_collider()
	
	#print(obj)
	
	if obj == null or obj == self: 
		return
	
	#var pos : Vector3 = ray.get_collision_point()
	#var norm : Vector3 = ray.get_collision_normal()
	_check_damageable_object(obj)
			
func _check_damageable_object(obj : Node) -> void:
	if obj.is_in_group(_G.GROUP_DESTROYABLE):
		_set_ui_last_health(obj.health)
		obj.damage(_current_damage)
		
	elif obj.is_in_group(_G.GROUP_ENTITY):
		_set_ui_last_health(obj.health)
		obj.health.hurt(_current_damage)
		
func _set_ui_last_health(h : Health) -> void:
	if h == null:
		ui.set_last_health(0.0)
		return
	if h.invincible: return
	var r : float = max(0.0, (h.value - _current_damage) / h.max_health)
	ui.set_last_health(r)
	
func _update_camera(delta : float) -> void:
	var fov : float = CAMERA_FOV_ZOOM if Input.is_action_pressed("zoom") else CAMERA_FOV_NORMAL
	camera.fov = fov
	
	var b : float = (CAMERA_BOB_SPEED * (movement.move_speed / 20.0)) * movement.movement_mult
	
	_camera_can_move_mult = float(movement.is_moving() and is_on_floor()) * CAMERA_BOB_HEIGHT
	_camera_movement_mult = lerpf(_camera_movement_mult, _camera_can_move_mult, delta * 8.0)
	
	var form : float = abs(sin(_G.time * b))
	
	camera.position.y = form * _camera_movement_mult

func _handle_drop() -> void:
	if held_item.is_empty():
		return
	
	if Input.is_action_just_pressed("drop_item"):
		var d : Vector3 = -head.global_transform.basis.z + Vector3(0.0, 0.30, 0.0)
		var v : float = (1.0 + velocity.length())
		pickup_spawner.create(held_item, (d * v).normalized() * 1.5)
		held_item.set_empty()

func _handle_inventory() -> void:
	if Input.is_action_just_pressed("inventory"):
		if inv_manager.inventory_ui.visible:
			inv_manager.close_inventory_ui()
			inv_manager.select_slot(selected_hotbar)
		else:
			inv_manager.open_inventory_ui()

	if not inv_manager.inventory_ui.visible:
		if Input.is_action_just_pressed("scroll_down"):
			if selected_hotbar > 4:
				selected_hotbar = 0
			else:
				selected_hotbar += 1
			inv_manager.select_slot(selected_hotbar)
		
		elif Input.is_action_just_pressed("scroll_up"):
			if selected_hotbar < 1:
				selected_hotbar = 5
			else:
				selected_hotbar -= 1
			inv_manager.select_slot(selected_hotbar)
			held_item = inv_manager.inventory.get_hotbar_item(selected_hotbar)
		
		if Input.is_key_pressed(KEY_1):
			selected_hotbar = 0
			inv_manager.select_slot(selected_hotbar)
		elif Input.is_key_pressed(KEY_2):
			selected_hotbar = 1
			inv_manager.select_slot(selected_hotbar)
		elif Input.is_key_pressed(KEY_3):
			selected_hotbar = 2
			inv_manager.select_slot(selected_hotbar)
		elif Input.is_key_pressed(KEY_4):
			selected_hotbar = 3
			inv_manager.select_slot(selected_hotbar)
		elif Input.is_key_pressed(KEY_5):
			selected_hotbar = 4
			inv_manager.select_slot(selected_hotbar)
		elif Input.is_key_pressed(KEY_6):
			selected_hotbar = 5
			inv_manager.select_slot(selected_hotbar)

func _update_effects(delta : float) -> void:
	#oxygen mechanic
	if is_submerged():
		if oxygen > 0.0:
			oxygen -= delta * 0.15
	else:
		if oxygen < 1.0:
			oxygen += delta * (1.0 - oxygen)
			
	if oxygen < SUFFOCATION_THRES:
		if timer_suffocation.is_stopped():
			timer_suffocation.start(SUFFOCATION_TIME)

func _suffocate() -> void:
	if oxygen < SUFFOCATION_THRES:
		health.hurt(SUFFOCATION_DAMAGE)
		timer_suffocation.start(SUFFOCATION_TIME)

func _reset_status() -> void:
	oxygen = 1.0
	timer_suffocation.stop()
	
func _on_health_damaged(value: float, _type: Health.DamageType) -> void:
	if not health.alive: return
	var time : float = clampf(value * 3.0, 0.3, 0.75)
	ui.pulse(Color.RED, time)

func _on_health_died() -> void:
	body_sprite.hide()
	ui.set_mouse(false)
	inv_manager.hotbar_ui.hide()
	timer_respawn.start(RESPAWN_TIME)
	_reset_status()
	ui.pulse(Color.RED, 2.0)
	inv_manager.close_inventory_ui()

func _on_health_respawned() -> void:
	body_sprite.show()
	global_position = get_spawn_position()
	inv_manager.hotbar_ui.show()
	ui.set_mouse(true)

func _on_respawn_timer_timeout() -> void:
	health.respawn()

func _on_pickup_query_body_entered(body: Node3D) -> void:
	print(body.get_groups())
	if body.is_in_group(_G.GROUP_PICKUP):
		body.pickup(inv_manager.inventory)
		
	_on_inventory_manager_hotbar_slot_selected(selected_hotbar)
	
func _on_inventory_manager_hotbar_slot_selected(slot_id: int) -> void:
	held_item = inv_manager.inventory.get_hotbar_item(slot_id)

func get_spawn_position() -> Vector3:
	return _G.game.ray.sample_position(_spawn_position + Vector2(randf() - 0.5, randf() - 0.5).normalized() * _SPAWN_RADIUS) + Vector3.UP
