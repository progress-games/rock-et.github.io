extends Object
class_name Stat

var level: int
var cost: float
var display_cost: String
var method: Callable
var value: Variant
var name: String

func _init(args: Dictionary) -> void:
	level = args.get("level", 0)
	cost = args.get("cost", 10)
	method = args.get("method")
	value = args.get("value")
	name = args.get("name", "UNASSIGNED NAME")
	display_cost = CustomMath.format_number_short(round(cost))

func upgrade() -> void:
	method.call(self)
	cost = round(cost)
	display_cost = CustomMath.format_number_short(round(cost))
