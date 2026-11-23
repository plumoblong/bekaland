extends Node
class_name Game

@onready var generation : Generation = get_node("Generation")
@onready var spawner : Spawner = get_node("Spawner")
@onready var water : Water = get_node("Water")
@onready var environment : WorldEnvironment = get_node("Environment")
@onready var player : Player = get_node("Player")
@onready var skybox : Skybox = get_node("Skybox")
@onready var light : DirectionalLight3D = get_node("Light")
@onready var player_obj : Node = get_node("PlayerObjects")
@onready var pickups : Node = get_node("Pickups")

@export var ray : TerrainRay
@export var sky_gradient : Gradient

var world_time : float = 0.25
var world_day : int = 0
signal day_ended

const WORLD_TIME_SCALE : float = 1440.0

var _current_fog_depth : float = 300.0
const FOG_DEPTH_RATIO : float = 0.5
const FOG_DEPTH_WATER : float = 0.25

var sky_color : Color

var current_dimension : WorldType = WorldType.ISLAND
var world_seed : int = 0
var _default_sky_gradient : Gradient
var _pending_player_pos : Variant = null
var _pending_player_rot : Variant = null
var _switching : bool = false

var _saved_inventories : Dictionary = {}

enum Placeables {
	NONE = 0,
	TORCH = 1,
	WOOD_WALL = 2,
	WORKBENCH = 3,
}

enum EntityType {
	CUSTOM,
	ANIMAL,
	ENEMY,
	CONTAINER,
	PICKUP
}

enum WorldType {
	ISLAND,
	CAVE,
	DREAM
}

@export var placeable_scenes : Array[PackedScene]

signal save_data_applied

func _ready() -> void:
	_G.game = self
	_F.config_entry_changed.connect(_on_config_entry_changed)
	
	_default_sky_gradient = sky_gradient
	
	if not _G.is_starting_new_game:
	
		var data : Dictionary = _F.load_world()
		if not data.is_empty():
			_apply_save_data(data)
	
	await _start_dimension()
	
	_F.update_config_entries()

func _on_config_entry_changed(entry : StringName, value) -> void:
	match entry:
		"render_distance":
			_current_fog_depth = value as float
		"shadows":
			light.shadow_enabled = value as bool

func get_dimension_key() -> String:
	return WorldType.keys()[current_dimension]

func _apply_save_data(data : Dictionary) -> void:
	world_time = float(data.get("world_time", world_time))
	world_day = int(data.get("world_day", 0))
	current_dimension = int(data.get("dimension", WorldType.ISLAND)) as WorldType
	world_seed = int(data.get("seed", 0))
	var p : Variant = data.get("player_pos")
	var pr : Variant = data.get("player_rot")
	if p is Array and p.size() == 3:
		_pending_player_pos = Vector3(p[0], p[1], p[2])
	if pr is Array and pr.size() == 3:
		_pending_player_rot = Vector3(pr[0], pr[1], pr[2])
	
	_saved_inventories = data.get("inventories", {})
	
	save_data_applied.emit()

func _start_dimension() -> void:
	var key : String = get_dimension_key()
	var dim : Dimension = generation.dimensions[current_dimension]
	
	if world_seed == 0:
		world_seed = randi()
	
	water.global_position.y = dim.sea_level if dim.has_water else -256.0
	water.visible = dim.has_water
	water.set_lava(dim.water_is_lava)
	sky_gradient = dim.sky_gradient if dim.sky_gradient else _default_sky_gradient
	
	generation.setup(dim, world_seed, _F.get_dimension_dir(key))
	
	# give the terrain collision a moment to build
	await get_tree().create_timer(0.1).timeout
	
	_load_placed(_F.load_objects(_F.get_dimension_dir(key)).get("placed", []))
	
	if _pending_player_pos != null:
		player.global_position = _pending_player_pos
		
		if _pending_player_rot != null:
			player.global_rotation = _pending_player_rot
		
		_pending_player_rot = null
		_pending_player_pos = null
	else:
		player.global_position = player.get_spawn_position()

func get_sea_level() -> float:
	return water.global_position.y

func change_dimension(target : WorldType) -> void:
	if _switching or target == current_dimension:
		return
	_switching = true
	
	save_world()
	
	current_dimension = target
	_pending_player_pos = null

	for n : Node in $Animals.get_children(): n.queue_free()
	for n : Node in $Enemies.get_children(): n.queue_free()
	for n : Node in player_obj.get_children(): n.queue_free() # already saved above
	
	await generation.clear()
	await _start_dimension()
	
	_switching = false
	_G.loading_screen.dectivate()

func get_placeable(id : Placeables) -> Placeable:
	if id == Placeables.NONE:
		return null
	var p : Placeable = placeable_scenes[id - 1].instantiate()
	p.set_meta("placeable_id", id) # lets save_world() know what this object is
	p.set_meta("uid", "%08x%08x" % [randi(), randi()]) # stable id, saved with the object
	return p

func get_hour() -> int:
	var t : float = fposmod(_G.game.world_time + 0.25, 1.0)
	var total_minutes : int = roundi(t * 1440)
	return total_minutes / 60

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_scene"):
		save_world()
	
	_update_time(delta)
	_update_environment()
	
func _update_time(delta : float) -> void:
	world_time += (delta / WORLD_TIME_SCALE)
	if world_time > 1.0:
		world_time = 0.0
		world_day += 1
		day_ended.emit()
	
	sky_color = sky_gradient.sample(snappedf(world_time, 0.001))

func _update_environment() -> void:
	var env : Environment = environment.environment
	var in_water_mult : float = clampf(float(not player.is_submerged()), 0.1, 1.0)
	
	env.fog_light_color = sky_color
	light.light_energy = maxf(0.025, sky_color.v)
	
	#skybox.light.shadow_opacity = (sky_color.v * sky_color.v)
	skybox.stars.emitting = light.light_energy < 0.1
	
	var fog_level = clampf(sky_color.v, 0.25, 1.0) * in_water_mult
	env.fog_depth_end = _current_fog_depth * fog_level
	env.fog_depth_begin = env.fog_depth_end * FOG_DEPTH_RATIO * in_water_mult
	env.ambient_light_color = Color.from_hsv(sky_color.h, sky_color.s * 0.5, sky_color.v)

func _get_placed_data() -> Array:
	var out : Array = []
	for n : Node in player_obj.get_children():
		if n is Node3D and n.has_meta("placeable_id"):
			var n3 : Node3D = n
			out.append({
				"id": n3.get_meta("placeable_id"),
				"uid": n3.get_meta("uid", ""),
				"pos": n3.global_position,
				"rot": n3.global_rotation,
				"inv_id" : -1,
			})
	return out

func _load_placed(list : Array) -> void:
	for e : Dictionary in list:
		var p : Placeable = get_placeable(int(e["id"]) as Placeables)
		if p == null:
			continue
		if e.has("uid"):
			p.set_meta("uid", e["uid"]) # before add_child, so _ready() sees the saved uid
		player_obj.add_child(p)
		p.global_position = e["pos"]
		p.global_rotation = e["rot"]

func _notification(what : int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_world()

func _get_free_inv_id() -> int:
	return _saved_inventories.size()

func register_inventory(inv : Inventory, id : int = -1) -> void:
	var i : int = id if id > -1 else _get_free_inv_id()
	if _saved_inventories.has(i):
		push_error(inv, " cant be registered, id ", id, " is already in use")
		return
	_saved_inventories[i] = inv
	_F.save_inventory(inv, i)

func erase_inventory(id : int) -> void:
	if _saved_inventories.has(id):
		_saved_inventories.erase(id)
		_F.delete_inventory(id)

func get_inventory(id : int) -> Inventory:
	if _saved_inventories.has(id):
		return _saved_inventories[id]
	return null

func save_world(quiet : bool = false) -> void:
	if generation.terrain == null:
		return
	
	if not quiet: _G.set_alert("Saving World...")

	var dir : String = _F.get_dimension_dir(get_dimension_key())
	generation.save_terrain(dir)
	_F.save_objects(dir, {
		"foliage": generation.get_foliage_data(),
		"placed": _get_placed_data(),
	})

	var p : Vector3 = player.global_position
	var pr : Vector3 = player.global_rotation
	_F.save_world({
		"version": _G.VERSION,
		"dimension": current_dimension,
		"seed": world_seed,
		"world_time": world_time,
		"world_day": world_day,
		"player_pos": [p.x, p.y, p.z],
		"player_rot": [pr.x, pr.y, pr.z],
		"inventories" : {}
	})
	
