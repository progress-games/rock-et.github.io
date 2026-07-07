extends Object
class_name Potion

var potion_name: String
var description: String
var cost: int
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
	texture = load("res://merchant/potions/" + potion_name + ".png")
