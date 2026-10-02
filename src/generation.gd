extends Node
class_name Generation

const TERRAIN_TEXTURE : Terrain3DTextureAsset = preload("res://data/texture/grass.tres")
const TERRAIN_SCALE : float = 16.0
const TERRAIN_HEIGHT : float = 150.0
const TERRAIN_SIZE : float = 512.0

const GRASS_MESH : PackedScene = preload("res://scene/long_grass.tscn")
const SHRUB_MESH : PackedScene = preload("res://scene/shrub.tscn")
const TREE_MESH : PackedScene = preload("res://scene/tree.tscn")
const CACTUS_MESH : PackedScene = preload("res://scene/cactus.tscn")

const GRASS_THRES : float = 18.0
const CACTUS_THRES_MAX : float = 11.5
const CACTUS_THRES_MIN : float = 6.5
const SHRUB_THRES : float = 7.8
const TREE_THRES : float = 40.0

var terrain : Terrain3D

var foliage_count : int = 0

var _game : Game

@export var noise : FastNoiseLite
@export var selector_noise : FastNoiseLite

@export var bumpiness : float = 0.4

@export var terrain_gradient : Gradient

@export var control : Texture2D

var _seed : int = 0

#signal generation_complete

func setup() -> void:
	
	_game = get_parent()
	
	if _seed == 0:
		_seed = randi()
	
	noise.frequency = 0.1 * bumpiness
	selector_noise.frequency = 0.06 * bumpiness
	
	noise.seed = _seed
	selector_noise.seed = _seed
	
	terrain = _create_terrain()
	
	_setup_terrain_noise()
	_setup_terrain_assets()
	_create_foliage()
	
	#_build_height_lut(_build_position_lut())
	
	_G.loading_screen.dectivate()
	
	await get_tree().create_timer(0.25).timeout
	
	print("wassup")
	_game.player.global_position = _game.player.get_spawn_position()

func _create_terrain() -> Terrain3D:
	var t : Terrain3D = Terrain3D.new()
	
	t.name = "Terrain3D"
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
	var scale : int = int(TERRAIN_SCALE) / 2
	var half_x : int = TERRAIN_SIZE * scale
	var half_z : int = TERRAIN_SIZE * scale
	var parent_xform : Transform3D = terrain.global_transform

	# --- Trees ---
	var tree_step : int = 32
	for x : int in range(-half_x, half_x, tree_step):
		for z : int in range(-half_z, half_z, tree_step):
			var pos : Vector3 = Vector3(
				x + randf_range(10.0, 48.0), 0.0, z + randf_range(10.0, 48.0)
			)
			var height : float = terrain.data.get_height(pos)
			if height > TREE_THRES:
				_spawn(TREE_MESH, pos, height, parent_xform)
			#if height > CACTUS_THRES_MIN:
				#if height < CACTUS_THRES_MAX and randf() < 0.5:
					#_spawn(CACTUS_MESH, pos, height, parent_xform)

	# --- Grass & shrubs ---
	var grass_step : int = 32
	for x : int in range(-half_x, half_x, grass_step):
		for z : int in range(-half_z, half_z, grass_step):
			var pos : Vector3 = Vector3(
				x + randf_range(4.0, 64.0), 0.0, z + randf_range(4.0, 64.0)
			)
			var height : float = terrain.data.get_height(pos)
			if height > GRASS_THRES:
				_spawn(GRASS_MESH, pos, height, parent_xform)
			elif height < SHRUB_THRES and randf() < 0.3:
				_spawn(SHRUB_MESH, pos, height, parent_xform)

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
	
func _spawn(scene: PackedScene, pos: Vector3, height: float, parent_xform: Transform3D) -> void:
	var n : Node3D = scene.instantiate()
	# local position instead of global_position: skips a transform-hierarchy
	# recompute since we already have the parent's world transform
	foliage_count += 1
	n.position = parent_xform.affine_inverse() * Vector3(pos.x, height, pos.z)
	terrain.add_child(n)

func _setup_terrain_noise() -> void:
	if not terrain: return
	
	var img : Image = _get_noise()
	
	terrain.region_size = int(TERRAIN_SIZE) / 2
	terrain.vertex_spacing = TERRAIN_SCALE
	
	var color_map : Image = _get_color_map(img)
	
	terrain.data.import_images([img, null, color_map], Vector3(-TERRAIN_SIZE, 0, -TERRAIN_SIZE) * 0.5 * terrain.vertex_spacing, -40.0, TERRAIN_HEIGHT)

func _get_selector_noise() -> Image:
	
	var img: Image = Image.create_empty(int(TERRAIN_SIZE), int(TERRAIN_SIZE), false, Image.FORMAT_RF)
	var control_img : Image = control.get_image()
	
	control_img.resize(int(TERRAIN_SIZE), int(TERRAIN_SIZE), Image.INTERPOLATE_BILINEAR)
	
	for x : int in img.get_width():
		for y : int in img.get_height():
			var control_pixel : Color = control_img.get_pixel(x, y)
			var noise_data : float = selector_noise.get_noise_2d(x, y)
			var noise_color : Color = Color(noise_data, noise_data, noise_data, 1.0)
			var color : Color = control_pixel - noise_color
			img.set_pixel(x, y, color)
			
	return img

func _get_color_map(from_noise : Image) -> Image:
	
	var img: Image = Image.create_empty(int(TERRAIN_SIZE), int(TERRAIN_SIZE), false, Image.FORMAT_RGB8)
	
	for x : int in img.get_width():
		for y : int in img.get_height():
			var noise_data : float = from_noise.get_pixel(x, y).r
			var color : Color = terrain_gradient.sample(noise_data)
			img.set_pixel(x, y, color)
			
	return img

func _get_noise() -> Image:
	var img: Image = Image.create_empty(int(TERRAIN_SIZE), int(TERRAIN_SIZE), false, Image.FORMAT_RF)
	var control_img : Image = _get_selector_noise()
	
	for x : int in img.get_width():
		for y : int in img.get_height():
			var control_pixel : Color = control_img.get_pixel(x, y)
			var noise_data : float = (noise.get_noise_2d(x, y) + 1.0) * 0.5
			var color : Color = Color(noise_data, noise_data, noise_data, 1.0)
			img.set_pixel(x, y, color * control_pixel)
			
	return img
