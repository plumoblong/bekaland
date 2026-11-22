extends Resource
class_name Foliage

## A set of placement rules for one dimension. Assign to Dimension.foliage.

@export var rules : Array[FoliageRule] = []
## Rare, capped, guaranteed spawns (see StructureRule)
@export var structures : Array[StructureRule] = []
