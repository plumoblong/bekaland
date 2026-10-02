extends Node
class_name Game

@onready var generation : Generation = get_node("TerrainGeneration")
@onready var spawner : Spawner = get_node("Spawner")
@onready var water : Node3D = get_node("Water")
@onready var environment : WorldEnvironment = get_node("Environment")
@onready var player : Player = get_node("Player")
@onready var skybox : Skybox = get_node("Skybox")
@onready var light : DirectionalLight3D = get_node("Light")
@onready var player_obj : Node = get_node("PlayerObjects")
@onready var pickups : Node = get_node("Pickups")
@export var ray : TerrainRay

const SEA_LEVEL : float = 3.5

var world_time : float = 0.25
var world_day : int = 0
const WORLD_TIME_SCALE : float = 1440.0

@export var sky_gradient : Gradient

const FOG_DEPTH : float = 600.0
const FOG_DEPTH_RATIO : float = 0.5
const FOG_DEPTH_WATER : float = 0.25

var sky_color : Color

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
	water.global_position.y = SEA_LEVEL
	generation.setup()

func get_placeable(id : Placeables) -> Placeable:
	return null if id == Placeables.NONE else placeable_scenes[id - 1].instantiate()

func get_hour() -> int:
	var t : float = fposmod(_G.game.world_time + 0.25, 1.0)
	var total_minutes : int = roundi(t * 1440)
	return total_minutes / 60

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_scene"):
		save_terrain()
	
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

func save_terrain() -> void:
	_G.set_alert("Saving World...", Color.YELLOW)
	_G.set_alert("World Saved!", Color.GREEN)
