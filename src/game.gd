extends Node
class_name Game

@onready var generation : Generation = get_node("Generation")
@onready var spawner : Spawner = get_node("Spawner")
@onready var water : Node3D = get_node("Water")
@onready var environment : WorldEnvironment = get_node("Environment")
@onready var player : Player = get_node("Player")
@onready var skybox : Skybox = get_node("Skybox")
@onready var light : DirectionalLight3D = get_node("Light")
@onready var player_obj : Node = get_node("PlayerObjects")
@onready var pickups : Node = get_node("Pickups")
@export var ray : TerrainRay

var world_time : float = 0.25
var world_day : int = 0
const WORLD_TIME_SCALE : float = 1440.0

@export var sky_gradient : Gradient

const FOG_DEPTH : float = 600.0
const FOG_DEPTH_RATIO : float = 0.5
const FOG_DEPTH_WATER : float = 0.25

var sky_color : Color

# ---- dimensions / saving ----
var current_dimension : WorldType = WorldType.ISLAND
var world_seed : int = 0                   # shared by every dimension
var _default_sky_gradient : Gradient
var _pending_player_pos : Variant = null   # Vector3 when loading a save
var _switching : bool = false

signal day_ended

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

func _ready() -> void:
	_G.game = self
	_default_sky_gradient = sky_gradient
	
	var data : Dictionary = _F.load_world()
	if not data.is_empty():
		_apply_save_data(data)
	
	await _start_dimension()

func get_dimension_key() -> String:
	return WorldType.keys()[current_dimension]

func _apply_save_data(data : Dictionary) -> void:
	world_time = float(data.get("world_time", world_time))
	world_day = int(data.get("world_day", 0))
	current_dimension = int(data.get("dimension", WorldType.ISLAND)) as WorldType
	world_seed = int(data.get("seed", 0))
	var p : Variant = data.get("player_pos")
	if p is Array and p.size() == 3:
		_pending_player_pos = Vector3(p[0], p[1], p[2])

## Builds (or loads) the terrain of current_dimension
func _start_dimension() -> void:
	var key : String = get_dimension_key()
	var dim : Dimension = generation.dimensions[current_dimension]
	
	if world_seed == 0:
		world_seed = randi()
	
	# per-dimension look
	water.global_position.y = dim.sea_level if dim.has_water else -256.0
	water.visible = dim.has_water
	sky_gradient = dim.sky_gradient if dim.sky_gradient else _default_sky_gradient
	
	generation.setup(dim, world_seed, _F.get_dimension_dir(key))
	
	# give the terrain collision a moment to build
	await get_tree().create_timer(0.25).timeout
	
	_load_placed(_F.load_objects(_F.get_dimension_dir(key)).get("placed", []))
	
	if _pending_player_pos != null:
		player.global_position = _pending_player_pos
		_pending_player_pos = null
	else:
		player.global_position = player.get_spawn_position()

func get_sea_level() -> float:
	return water.global_position.y

func change_dimension(target : WorldType) -> void:
	if _switching or target == current_dimension:
		return
	_switching = true
	
	save_world() # saves the dimension we're leaving
	
	current_dimension = target
	_pending_player_pos = null
	
	# Things that belong to the old dimension
	for n : Node in $Animals.get_children(): n.queue_free()
	for n : Node in $Enemies.get_children(): n.queue_free()
	for n : Node in player_obj.get_children(): n.queue_free() # already saved above
	
	await generation.clear()
	await _start_dimension()
	
	_switching = false

func get_placeable(id : Placeables) -> Placeable:
	if id == Placeables.NONE:
		return null
	var p : Placeable = placeable_scenes[id - 1].instantiate()
	p.set_meta("placeable_id", id) # lets save_world() know what this object is
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
	env.fog_depth_end = FOG_DEPTH * fog_level
	env.fog_depth_begin = env.fog_depth_end * FOG_DEPTH_RATIO * in_water_mult
	env.ambient_light_color = Color.from_hsv(sky_color.h, sky_color.s * 0.5, sky_color.v)

func _get_placed_data() -> Array:
	var out : Array = []
	for n : Node in player_obj.get_children():
		if n is Node3D and n.has_meta("placeable_id"):
			var n3 : Node3D = n
			out.append({
				"id": n3.get_meta("placeable_id"),
				"pos": n3.global_position,
				"rot": n3.global_rotation,
			})
	return out

func _load_placed(list : Array) -> void:
	for e : Dictionary in list:
		var p : Placeable = get_placeable(int(e["id"]) as Placeables)
		if p == null:
			continue
		player_obj.add_child(p)
		p.global_position = e["pos"]
		p.global_rotation = e["rot"]

func _notification(what : int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_world() # autosave when the window is closed

func save_world() -> void:
	if generation.terrain == null:
		return # mid dimension-switch / still loading, nothing valid to save
	
	_G.set_alert("Saving World...", Color.YELLOW)
	
	# terrain + trees + placed objects of the current dimension
	var dir : String = _F.get_dimension_dir(get_dimension_key())
	generation.save_terrain(dir)
	_F.save_objects(dir, {
		"foliage": generation.get_foliage_data(),
		"placed": _get_placed_data(),
	})
	
	# everything else
	var p : Vector3 = player.global_position
	_F.save_world({
		"version": _G.VERSION,
		"dimension": current_dimension,
		"seed": world_seed,
		"world_time": world_time,
		"world_day": world_day,
		"player_pos": [p.x, p.y, p.z],
	})
	
	_G.set_alert("World Saved!", Color.GREEN)
