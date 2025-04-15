extends Object
class_name Stat

var level: int
var cost: float
var method: Callable
var value: Variant
var name: String

func _init(args: Dictionary) -> void:
	level = args.get("level", 0)
	cost = args.get("cost", 10)
	method = args.get("method")
	value = args.get("value")
	name = args.get("name", "UNASSIGNED NAME")

func upgrade() -> void:
	method.call(self)
