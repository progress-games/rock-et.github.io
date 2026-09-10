extends Resource
class_name DroneEffect

@export var texture: CompressedTexture2D
@export var name: String
@export var description: String
@export var value: float
@export var display_type: Stat.DisplayType = Stat.DisplayType.BASIC
@export var effect: DroneEnums.DroneEffect

var level: int = 0

signal upgraded

func upgrade() -> void:
	level += 1

func get_description() -> String:
	return description.replace("[VALUE]", str(value))
