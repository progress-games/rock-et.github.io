extends Object
class_name Stat

var level: int
var cost: Dictionary
var display_cost: String
var method: Callable
var value: Variant
var name: String
var max: int

func _init(args: Dictionary) -> void:
	level = args.get("level")
	cost = args.get("cost")
	method = args.get("method")
	value = args.get("value")
	name = args.get("name")
	max = args.get("max", 9999)
	display_cost = CustomMath.format_number_short(round(cost.amount))

func upgrade() -> void:
	if level >= max:
		return
	level += 1
	method.call(self)
	cost.amount = round(cost.amount)
	display_cost = CustomMath.format_number_short(round(cost.amount))

func is_max() -> bool:
	return level >= max
