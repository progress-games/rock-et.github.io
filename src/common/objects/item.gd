extends Object
class_name Item

"""
How an item is defined:
var item = Item({
	"name": "pickaxe",
	"description": "[gold_chance] chance to drop [gold_amount] gold",
	"values": {
		"gold_chance": {
			"value": 0.1,
			"type": "percentage",
			"improves": true,
			"upgrade": func (x): return x + 0.1
			}, 
		"gold_amount": {
			"value": 1,
			"type": "multiplier",
			"improves": true,
			"upgrade": func (x): return x * 2
			}
		},
	"cost": 17,
	"cost_scaling": 1.2
	})

handling pricing is done uniformly across all items
"""

const GREEN := "#91db69"
const RED := "#ea4f36"
const NAME := "#2e222f"
const DESC := "#6e2727"
const UPGRADE_ORDER: Array[Array] = [
	[],
	[[0]],
	[[0], [1], [0, 1], [0], [0], [1], [1], [0, 1], [1], [0, 1], [0], [0], [0, 1], [1], [1], [0]],
	[[0], [1], [2], [0, 1], [0, 2], [2], [1, 2], [0], [1], [2], [0, 1, 2], [1, 2]]
]


var name: String
var values: Dictionary = {}
var cost: float
var description: String
var upgrade_method: Callable
var cost_scaling: float
var level: int = 1

# for displaying the next level item
var next_level: Item
var first_level: bool

func _init(args: Dictionary) -> void:
	name = args.get("name")
	description = args.get("description")
	cost = args.get("cost")
	first_level = args.get("first_level", true)
	values = args.get("values") as Dictionary
	cost_scaling = args.get("cost_scaling")
	
	if first_level:
		args["first_level"] = false
		next_level = Item.new(args.duplicate(true))
		next_level.upgrade()

func get_description(get_next: bool = false) -> String:
	var display_desc = insert_colour(name.replace("_", " ") + ": ", NAME) + description
	var desc_values = next_level.values if get_next else values

	for n in desc_values.keys():
		var val = desc_values[n]
		var printed_val = ""
		if val.type == "percentage": 
			printed_val = str(round(val.value * 1000) / 10) + "%"
		elif val.type == "multiplier":
			printed_val = str(round(val.value * 10) / 10) + "x"
		elif val.type == "duration":
			printed_val = str(round(val.value * 10) / 10) + "s"
		else:
			printed_val = str(val.value)
		
		if get_next and val.value != values[n].value:
			printed_val = insert_colour(printed_val, GREEN if val.improves else RED)
		
		display_desc = display_desc.replace("[" + n + "]", printed_val)
	
	return display_desc

func insert_colour(string: String, colour: String) -> String:
	return "[color=" + colour + "]" + string + "[/color]"

func n_choose_k(n: int, k: int) -> int:
	return factorial(n) / (factorial(k) * factorial(n - k))

func factorial(n: int) -> int:
	var arr = []
	for i in range(n, 1): arr.append(i)
	return arr.reduce(func (acc, x): acc * x, 1)

func get_cost() -> String:
	return CustomMath.format_number_short(cost)

func get_value(val: String) -> Variant:
	return values.get(val).value

func upgrade() -> void:
	# get the things that need to be upgraded
	var u = UPGRADE_ORDER[values.size()][(level - 1) % UPGRADE_ORDER[values.size()].size()]
	
	for upgrade_i in u:
		var val = values[values.keys()[upgrade_i]]
		val.value = val.upgrade.call(val.value)
	
	cost *= cost_scaling
	level += 1
	
	if first_level:
		next_level.upgrade()
