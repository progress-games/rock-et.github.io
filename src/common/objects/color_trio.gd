extends Resource
class_name ColorTrio

@export var colour_1: Color
@export var colour_2: Color
@export var colour_3: Color

func get_array() -> Array[Color]:
	return [colour_1, colour_2, colour_3]
