extends Object
class_name Stat

var level: int
var cost: Dictionary
var upgrade_method: Callable
var update_display: Callable
var value: Variant
var name: String
var max: int
var display_value: String
var display_cost: String
var display_name: String
var tooltip: String

# for displaying value of next level
var next_level: Stat
var next_level_required: bool

func _init(args: Dictionary) -> void:
	level = args.get("level", 1)
	cost = args.get("cost", {"amount": 0, "mineral": GameManager.Mineral.AMETHYST})
	upgrade_method = args.get("upgrade_method", func(u): pass)
	update_display = args.get("update_display", func (u): u.display_value = str(u.value))
	value = args.get("value", 0)
	name = args.get("name", "")
	max = args.get("max", 9999)
	next_level_required = args.get("next_level_required", true)
	tooltip = args.get("tooltip", "")
	
	display_value = ""
	display_cost = CustomMath.format_number_short(round(cost.amount))
	display_name = args.get("display_name", name.replace("_", " "))
	update_display.call(self)
	
	if next_level_required:
		next_level = Stat.new({
			"name": name,
			"level": level,
			"max": max,
			"cost": {
				"amount": cost.amount, 
				"mineral": cost.mineral
			}, 
			"upgrade_method": upgrade_method,
			"update_display": update_display,
			"value": value,
			"next_level_required": false
		})
		next_level.upgrade()

func upgrade() -> void:
	if level >= max:
		display_value = "MAX"
		return
	
	level += 1
	upgrade_method.call(self)
	update_display.call(self)
	
	if next_level_required:
		next_level.upgrade()
		
	cost.amount = round(cost.amount)
	display_cost = CustomMath.format_number_short(round(cost.amount))

func is_max() -> bool:
	return level >= max
