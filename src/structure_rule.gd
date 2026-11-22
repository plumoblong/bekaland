extends FoliageRule
class_name StructureRule

## A FoliageRule for rare, important things (ruins, camps, portals...).
## Placed by Generation._create_structures(), which guarantees at least
## `min_instances` get spawned whenever any valid spot exists.

@export_group("Instances")
## Always try to spawn at least this many (guaranteed if a valid spot exists)
@export_range(1, 100) var min_instances : int = 1
## Never spawn more than this many
@export_range(1, 100) var max_instances : int = 1
## Minimum distance between two instances of this structure (world units)
@export var min_spacing : float = 0.0


func roll_count(rng : RandomNumberGenerator) -> int:
	return rng.randi_range(min_instances, maxi(min_instances, max_instances))
