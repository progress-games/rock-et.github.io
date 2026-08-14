extends Resource
class_name WheelColour

enum TextColour {
	LIGHT,
	DARK
}

@export var outline: Color
@export var shadow: Color
@export var mid: Color
@export var highlight: Color
@export var text_colour: TextColour

func get_text_colour() -> Color:
	return [Color(1.0, 1.0, 1.0, 1.0), Color(0.18, 0.133, 0.184, 1.0)].get(text_colour)
