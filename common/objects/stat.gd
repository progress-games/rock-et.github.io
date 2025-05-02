extends Object
class_name Stat

var level: int
var cost: Dictionary
var display_cost: String
var method: Callable
var value: Variant
var name: String

func _init(args: Dictionary) -> void:
	level = args.get("level")
	cost = args.get("cost")
	method = args.get("method")
	value = args.get("value")
	name = args.get("name")
	display_cost = CustomMath.format_number_short(round(cost.amount))

func upgrade() -> void:
	method.call(self)
	cost.amount = round(cost.amount)
	display_cost = CustomMath.format_number_short(round(cost.amount))
