extends Resource
class_name FoliageRule

## One placement rule: "scatter <spawn_id> on a grid, where terrain height is in range".

## Passed as the first argument to _spawn() ("tree", "grass", "shrub", "cactus"...)
@export var spawn_id : String = "tree"

@export_group("Height")
## Spawn only where terrain height is strictly above this
@export var min_height : float = -64.0
## Spawn only where terrain height is strictly below this
@export var max_height : float = 256.0

@export_group("Placement")
## Grid spacing in world units
@export var step : int = 32
## Random offset added to each grid cell (x and z)
@export var jitter_min : float = 4.0
@export var jitter_max : float = 64.0
## Probability (0-1) that a valid cell actually spawns
@export_range(0.0, 1.0) var chance : float = 1.0

func accepts_height(height : float) -> bool:
	return height > min_height and height < max_height
