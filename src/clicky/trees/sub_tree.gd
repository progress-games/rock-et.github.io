extends Control
class_name SubTree

enum DependencyLine {
	ANGLED,
	STRAIGHT
}

@export var level_pricing: Array[int] = [
	40,
	65,
	75,
	90,
	110,
	135,
	230,
	300,
	380,
	470,
	570,
	680
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
	get_children().map(func (x): x.base_price *= amt; x.current_price = x.base_price)

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

func flood_price() -> void:
	var levels = end_points.reduce(func (a, x): return max(a, _get_levels(x)), -1)
	end_points.map(func (x): flood_price_aux(x, levels))

func flood_price_aux(node: SkillNode, level: int) -> void:
	node.set_base_price(level_pricing[level - 1])
	node.dependencies.map(func (x): flood_price_aux(x, level - 1))
