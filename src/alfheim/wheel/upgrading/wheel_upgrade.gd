extends Object
class_name WheelUpgrade

var short_desc: String
var long_desc: String
var new_portion_1: WheelPortion
var new_portion_2: WheelPortion
var upgrade_func: Callable

func _init(args: Dictionary) -> void:
	short_desc = args.get("short_desc", "")
	long_desc = args.get("long_desc", "")
	upgrade_func = args.get("upgrade_func", func (): return)
	
	if args.has("portion_1"):
		var p_args = args.get("portion_1")
		var p = WheelPortion.new()
		p.amount = p_args.amount
		p.rarity = p_args.rarity
		p.outcome = p_args.outcome
		p.reward = p_args.reward
		new_portion_1 = p
	
	if args.has("portion_2"):
		var p_args = args.get("portion_2")
		var p = WheelPortion.new()
		p.amount = p_args.amount
		p.rarity = p_args.rarity
		p.outcome = p_args.outcome
		p.reward = p_args.reward
		new_portion_2 = p

func get_description() -> String:
	if long_desc != "":
		return long_desc
	
	var d = WheelPortion.Rarity.find_key(new_portion_1.rarity).to_lower().replace("_", " ")
	d += " " + WheelPortion.Outcome.find_key(new_portion_1.outcome).to_lower() + ":"
	d += new_portion_1.reward_text
	
	if new_portion_2 == null:
		return d
	
	d += "| " + WheelPortion.Rarity.find_key(new_portion_2.rarity).to_lower().replace("_", " ")
	d += " " + WheelPortion.Outcome.find_key(new_portion_2.outcome).to_lower() + ":"
	d += new_portion_2.reward_text
	
	return d
