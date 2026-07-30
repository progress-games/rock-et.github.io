extends Object
class_name Potion

var potion_name: String
var description: String
var cost: int
var value: float
var texture: CompressedTexture2D

"""
How an potion is defined:
var item = Potion({
	"name": "asteroid_storm",
	"description": "spawn 100 asteroids",
	"cost": 17
	})"""
func _init(args: Dictionary) -> void:
	potion_name = args.get("name", "unnamed")
	description = args.get("description", "")
	cost = args.get("cost", 0)
	value = args.get("value", 1.)
	texture = load("res://merchant/potions/" + potion_name + ".png")

func get_description(multiplier: float = 1.) -> String:
	var t = "[color=#2e222f]" + potion_name.replace("_", " ") + "[/color]: "
	t += description
	
	var v = str(int(ceil(value)))
	if multiplier > 1 && potion_name == "supernova":
		t += " [color=#91db69](" + str(snappedf(multiplier, 0.1)) + "x size)" 
	elif multiplier > 1:
		t = t.replace("[value]", v + "[color=#91db69](" + \
			str(snappedf(value * multiplier, 0.1)) + ")[/color]")
	else:
		t = t.replace("[value]", v)
	
	return t
