extends Resource
class_name DetailNode

@export var node: NodePath
@export var mineral: Enums.Mineral
@export var amount: int
@export var stat_name: String = "fuel_capacity"
@export var stat_req: int

## each node is moved to given location when revealed
@export var movements: Dictionary[NodePath, Vector2]
