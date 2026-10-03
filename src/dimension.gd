extends Resource
class_name Dimension

## One of these per dimension (island.tres, cave.tres, dream.tres).
## Order in Generation.dimensions must match Game.WorldType: ISLAND, CAVE, DREAM.

@export var display_name : String = "Island"

@export_group("Terrain")
@export var use_generation : bool = true
@export var noise : FastNoiseLite
@export var selector_noise : FastNoiseLite
@export var control : Texture2D
@export var terrain_gradient : Gradient
@export var spawn_foliage : bool = true
@export var spawn_rocks : bool = false

@export_group("Look")
@export var sea_level : float = 3.5
@export var has_water : bool = true
@export var use_skybox : bool = true
## Leave empty to use the default sky gradient set on the Game node
@export var sky_gradient : Gradient
