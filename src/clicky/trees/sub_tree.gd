extends Control
class_name SubTree

enum DependencyLine {
	ANGLED,
	STRAIGHT
}

# the next node will be at least $3 more expensive
const MIN_GROW := 3

@export var level_pricing: Array[int] = [
	24,
	28,
	36,
	42,
	52,
	60,
	72,
	84,
	98,
	114,
	242,
	320,
	500
]

@export var first: SkillNode
@export var final: Array[SkillNode]

## some nodes are not "final" nodes, however they are the last in a line, noted for flood pricing 
@export var end_points: Array[SkillNode]

@export var dependency_lines: DependencyLine
@export var sub_tree_name: ClickEffectManager.ClickType

@onready var nodes: Array[Node]

func _ready() -> void:
	nodes = get_children()
	for i in range(get_child_count()):
		get_child(i).id = i
	flood_price()

func get_min_y() -> float:
	return get_children().reduce(func (a, x): return min(x.position.y, a), INF)

func get_max_y() -> float:
	return get_children().reduce(func (a, x): return max(x.position.y, a), -INF)

func get_max_x() -> float:
	return get_children().reduce(func (a, x): return max(x.position.x, a), -INF)

func scale_prices(amt: float) -> void:
	nodes.map(func (x: SkillNode): x.set_base_price(x.base_price * amt))

func unlock_nodes(ids: Dictionary) -> void:
	for id in ids.keys():
		for i in range(ids[id]):
			get_child(int(id)).unlock()

func get_nodes() -> Dictionary:
	var n = {}
	for child in get_children():
		n.set(child.id, child.level)
	return n

func _get_levels(n: SkillNode, l: int = 0) -> int:
	l += 1
	if n.dependencies.size() == 0:
		return l
	
	return n.dependencies.reduce(func (a, x): return max(a, _get_levels(x, l)), -1)

# base price is going to be either the maximum price of a predecessor, or the pre-existing price
func flood_price_aux(n: SkillNode, l: int) -> float:
	n.set_base_price(
		min(
			n.dependencies.reduce(
				func (a, x):
					return max(a, flood_price_aux(x, l - 1) + MIN_GROW),
				level_pricing[l] * n.base_price_mult
			),
			n.base_price
		)
	)
	
	return n.base_price * pow(n.price_scaling, n.levels - 1)

func flood_price() -> void:
	var levels = end_points.reduce(func (a, x): return max(a, _get_levels(x)), -1)
	end_points.map(func (n): flood_price_aux(n, levels - 1))
