extends Node
class_name Generation

const TERRAIN_TEXTURE : Terrain3DTextureAsset = preload("res://data/texture/grass.tres")
const TERRAIN_SCALE : float = 16.0

const TERRAIN_SIZE : float = 512.0

var _grass_mesh : PackedScene = load("res://scene/long_grass.tscn")
var _shrub_mesh : PackedScene = load("res://scene/shrub.tscn")
var _tree_mesh : PackedScene = load("res://scene/tree.tscn")
var _flower_mesh : PackedScene = load("res://scene/flower.tscn")
var _pebble_mesh : PackedScene = load("res://scene/small_rock.tscn")
var _struct_cave_entrance : PackedScene = load("res://scene/cave_entrance.tscn")

## Save-file name -> scene. Add new foliage types here.
var FOLIAGE_SCENES : Dictionary = {
	"tree": _tree_mesh,
	"grass": _grass_mesh,
	"shrub": _shrub_mesh,
	"flower": _flower_mesh,
	"small_rock": _pebble_mesh,
	"cave_entrance" : _struct_cave_entrance,
}

const GRASS_THRES : float = 18.0
const CACTUS_THRES_MAX : float = 11.5
const CACTUS_THRES_MIN : float = 6.5
const SHRUB_THRES : float = 7.8
const TREE_THRES : float = 40.0

var terrain : Terrain3D
var foliage_root : Node3D # all trees/grass/shrubs live here, NOT under the terrain

var foliage_count : int = 0

var _game : Game

## Index must match Game.WorldType (ISLAND, CAVE, DREAM)
@export var dimensions : Array[Dimension]

@export var bumpiness : float = 0.4

var dimension : Dimension
var _seed : int = 0
var _rng : RandomNumberGenerator = RandomNumberGenerator.new()

#signal generation_complete

func setup(dim : Dimension, world_seed : int, save_dir : String) -> void:
	_game = get_parent()
	dimension = dim
	_seed = world_seed
	_rng.seed = world_seed # same seed -> same foliage every time
	foliage_count = 0
	
	dimension.noise.frequency = 0.1 * bumpiness
	dimension.selector_noise.frequency = 0.06 * bumpiness
	dimension.noise.seed = _seed
	dimension.selector_noise.seed = _seed
	_game.skybox.visible = dimension.use_skybox
	
	terrain = _create_terrain()
	
	# top_level = ignores any parent transform, so positions here are world positions
	foliage_root = Node3D.new()
	foliage_root.name = "Foliage"
	foliage_root.top_level = true
	add_child(foliage_root)
	
	terrain.region_size = int(TERRAIN_SIZE) / 2
	terrain.vertex_spacing = TERRAIN_SCALE
	
	if _F.has_terrain(save_dir):
		# Load edited terrain from disk
		terrain.data_directory = save_dir
	else:
		_setup_terrain_noise()
	
	_setup_terrain_assets()
	
	if dimension.spawn_foliage:
		var saved : Dictionary = _F.load_objects(save_dir)
		if saved.has("foliage"):
			_load_foliage(saved["foliage"]) # exact trees from the save
		else:
			_create_structures()            # first time in this dimension:
			_create_foliage()               # structures first, so they always get their spot
	
	_G.loading_screen.dectivate()
	_G.override_max_fps(false)

func save_terrain(save_dir : String) -> void:
	if not terrain: return
	DirAccess.make_dir_recursive_absolute(save_dir)
	terrain.data.save_directory(save_dir)

## Every foliage node that still exists (chopped trees are gone, so they stay gone)
func get_foliage_data() -> Array:
	var out : Array = []
	if not foliage_root: return out
	for n : Node in foliage_root.get_children():
		if n is Node3D and n.has_meta("foliage_type"):
			out.append([n.get_meta("foliage_type"), (n as Node3D).position])
	return out

func _load_foliage(list : Array) -> void:
	for entry : Array in list:
		var type : String = entry[0]
		if not FOLIAGE_SCENES.has(type):
			continue
		var n : Node3D = FOLIAGE_SCENES[type].instantiate()
		n.set_meta("foliage_type", type)
		n.position = entry[1]
		foliage_count += 1
		foliage_root.add_child(n)

func clear() -> void:
	if foliage_root:
		foliage_root.queue_free()
		foliage_root = null
	if terrain:
		terrain.queue_free()
		terrain = null
	await get_tree().process_frame

func _create_terrain() -> Terrain3D:
	var t : Terrain3D = Terrain3D.new()
	
	t.name = "Terrain3D"
	t.add_to_group(_G.GROUP_CAN_PLACE)
	get_parent().add_child(t, true)
	
	# Set material and assets
	t.material.world_background = Terrain3DMaterial.NONE
	t.material.texture_filtering = Terrain3DMaterial.NEAREST
	t.material.auto_shader = false
	t.collision_layer = 0xFFFFFF
	t.collision_mask = 0xFFFFFF
	
	return t
	
const LUT_SIZE: int = 128

static func _build_position_lut() -> PackedVector3Array:
	var lut := PackedVector3Array()
	var lut_max : int = int(TERRAIN_SIZE) / 2
	var lut_min : int = -int(TERRAIN_SIZE) / 2
	var step: float = (lut_max - lut_min) / float(LUT_SIZE - 1)
	for i in range(LUT_SIZE):
		var v: float = lut_min + i * step
		lut.append(Vector3(v, 0.0, v))
	return lut
	
#func _build_height_lut(input : PackedVector3Array) -> void:
	#for i : Vector3 in input:
		#var h : float = terrain.data.get_height(i * TERRAIN_SCALE)
		#height_positions.append(Vector3(i.x * TERRAIN_SCALE, h, i.y * TERRAIN_SCALE))

#func find_closest(target: Vector3) -> Vector3:
	#var closest: Vector3 = height_positions[0]
	#var closest_dist_sq: float = target.distance_squared_to(closest)
#
	#for point in height_positions:
		#var dist_sq: float = target.distance_squared_to(point)
		#if dist_sq < closest_dist_sq:
			#closest_dist_sq = dist_sq
			#closest = point
#
	#return closest
	
func _setup_terrain_assets() -> void:
	if not terrain: return
	
	terrain.assets = Terrain3DAssets.new()
	terrain.assets.set_texture(0, TERRAIN_TEXTURE)
	
func _create_foliage() -> void:
	if dimension.foliage == null:
		return

	var scale : int = int(TERRAIN_SCALE) / 2
	var half_x : int = TERRAIN_SIZE * scale
	var half_z : int = TERRAIN_SIZE * scale

	for rule : FoliageRule in dimension.foliage.rules:
		for x : int in range(-half_x, half_x, rule.step):
			for z : int in range(-half_z, half_z, rule.step):
				var pos : Vector3 = Vector3(
					x + _rng.randf_range(rule.jitter_min, rule.jitter_max), 0.0,
					z + _rng.randf_range(rule.jitter_min, rule.jitter_max)
				)
				var height : float = terrain.data.get_height(pos)
				if not rule.accepts_height(height):
					continue
				if _rng.randf() >= rule.chance:
					continue
				_spawn(rule.spawn_id, pos, height)

## Spawns every StructureRule: at least min_instances (when a valid spot exists), at most max_instances.
func _create_structures() -> void:
	if dimension.foliage == null:
		return

	var scale : int = int(TERRAIN_SCALE) / 2
	var half_x : int = TERRAIN_SIZE * scale
	var half_z : int = TERRAIN_SIZE * scale

	for rule : StructureRule in dimension.foliage.structures:
		# preferred = passed height AND the chance roll; fallback = passed height only
		var preferred : Array[Vector3] = []
		var fallback : Array[Vector3] = []

		for x : int in range(-half_x, half_x, rule.step):
			for z : int in range(-half_z, half_z, rule.step):
				var pos : Vector3 = Vector3(
					x + _rng.randf_range(rule.jitter_min, rule.jitter_max), 0.0,
					z + _rng.randf_range(rule.jitter_min, rule.jitter_max)
				)
				var height : float = terrain.data.get_height(pos)
				if not rule.accepts_height(height):
					continue
				var p : Vector3 = Vector3(pos.x, height, pos.z)
				if _rng.randf() < rule.chance:
					preferred.append(p)
				else:
					fallback.append(p)

		# Last resort: the grid found nothing, so probe random points across the map
		if preferred.is_empty() and fallback.is_empty():
			for i : int in 5000:
				var pos : Vector3 = Vector3(
					_rng.randf_range(-half_x, half_x), 0.0, _rng.randf_range(-half_z, half_z)
				)
				var height : float = terrain.data.get_height(pos)
				if rule.accepts_height(height):
					fallback.append(Vector3(pos.x, height, pos.z))
					break

		_shuffle_seeded(preferred)
		_shuffle_seeded(fallback)
		var pool : Array[Vector3] = preferred + fallback

		var target : int = rule.roll_count(_rng)
		var placed : Array[Vector3] = []

		# Pass 1: respect min_spacing
		for p : Vector3 in pool:
			if placed.size() >= target:
				break
			if _too_close(p, placed, rule.min_spacing):
				continue
			placed.append(p)

		# Pass 2: spacing blocked the guaranteed minimum, so relax it
		if placed.size() < rule.min_instances:
			for p : Vector3 in pool:
				if placed.size() >= rule.min_instances:
					break
				if not placed.has(p):
					placed.append(p)

		if placed.is_empty():
			push_warning("No valid spot for structure '%s' (check its height range)" % rule.spawn_id)
			continue

		for p : Vector3 in placed:
			_spawn(rule.spawn_id, p, p.y)

func _too_close(p : Vector3, others : Array[Vector3], min_dist : float) -> bool:
	if min_dist <= 0.0:
		return false
	var p2 : Vector2 = Vector2(p.x, p.z)
	for o : Vector3 in others:
		if p2.distance_to(Vector2(o.x, o.z)) < min_dist:
			return true
	return false

## Fisher-Yates using the world-seeded RNG (Array.shuffle() uses the global RNG, which isn't deterministic per seed)
func _shuffle_seeded(arr : Array) -> void:
	for i : int in range(arr.size() - 1, 0, -1):
		var j : int = _rng.randi_range(0, i)
		var tmp : Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func get_random_point_in_range(start_pos : Vector2, range_min : float = 4.0, range_max : float = 6.0) -> Vector3:
	var scale : int = int(TERRAIN_SCALE) / 2
	var half_x : int = TERRAIN_SIZE * scale
	var half_z : int = TERRAIN_SIZE * scale
	var step : int = 64
	
	# Snap start_pos to the grid so it lines up with the step size
	var start_x : int = int(round(start_pos.x / step)) * step
	var start_z : int = int(round(start_pos.y / step)) * step
	
	var max_radius : int = int(max(half_x, half_z) / step) + 1
	
	for radius : int in range(max_radius + 1):
		for x_offset : int in range(-radius, radius + 1):
			for z_offset : int in range(-radius, radius + 1):
				# Only check the outer ring of this radius — 
				# smaller radii were already fully checked in previous iterations
				if max(abs(x_offset), abs(z_offset)) != radius:
					continue
				
				var x : int = start_x + x_offset * step
				var z : int = start_z + z_offset * step
				
				if x < -half_x or x > half_x or z < -half_z or z > half_z:
					continue
				
				var pos : Vector3 = Vector3(x, 0.0, z)
				var height : float = terrain.data.get_height(pos)
				if height in range(range_min, range_max):
					return Vector3(x, height, z)
	
	return Vector3.ZERO
	
func _spawn(type: String, pos: Vector3, height: float) -> void:
	var n : Node3D = FOLIAGE_SCENES[type].instantiate()
	n.set_meta("foliage_type", type)
	foliage_count += 1
	n.position = Vector3(pos.x, height, pos.z) # foliage_root is at the world origin
	foliage_root.add_child(n)

func _setup_terrain_noise() -> void:
	if not terrain: return
	
	var img : Image = _get_noise()
	
	var color_map : Image = _get_color_map(img)
	
	var offset : float = -40.0 * dimension.terrain_max_height / 150.0
	
	terrain.data.import_images([img, null, color_map], Vector3(-TERRAIN_SIZE, 0, -TERRAIN_SIZE) * 0.5 * terrain.vertex_spacing, offset, dimension.terrain_max_height)

func _get_selector_noise() -> Image:
	
	var img: Image = Image.create_empty(int(TERRAIN_SIZE), int(TERRAIN_SIZE), false, Image.FORMAT_RF)
	var control_img : Image = dimension.control.get_image()
	
	control_img.resize(int(TERRAIN_SIZE), int(TERRAIN_SIZE), Image.INTERPOLATE_BILINEAR)
	
	for x : int in img.get_width():
		for y : int in img.get_height():
			var control_pixel : Color = control_img.get_pixel(x, y)
			var noise_data : float = dimension.selector_noise.get_noise_2d(x, y)
			var noise_color : Color = Color(noise_data, noise_data, noise_data, 1.0)
			var color : Color = control_pixel - noise_color
			img.set_pixel(x, y, color)
			
	return img

func _get_color_map(from_noise : Image) -> Image:
	
	var img: Image = Image.create_empty(int(TERRAIN_SIZE), int(TERRAIN_SIZE), false, Image.FORMAT_RGB8)
	
	for x : int in img.get_width():
		for y : int in img.get_height():
			var noise_data : float = from_noise.get_pixel(x, y).r
			var color : Color = dimension.terrain_gradient.sample(noise_data)
			img.set_pixel(x, y, color)
			
	return img

func _get_noise() -> Image:
	var img: Image = Image.create_empty(int(TERRAIN_SIZE), int(TERRAIN_SIZE), false, Image.FORMAT_RF)
	var control_img : Image = _get_selector_noise()
	
	for x : int in img.get_width():
		for y : int in img.get_height():
			var control_pixel : Color = control_img.get_pixel(x, y)
			var noise_data : float = (dimension.noise.get_noise_2d(x, y) + 1.0) * 0.5
			var color : Color = Color(noise_data, noise_data, noise_data, 1.0)
			img.set_pixel(x, y, color * control_pixel)
			
	return img
