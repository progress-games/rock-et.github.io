extends NinePatchRect

var progress := 0.0
var colour: String
var width: float

const EDGE_WIDTH = 2

func _process(delta: float) -> void:
	progress = min(progress + 0.005, 1)
	size.x = width * progress
	var new_colour = GameManager.player.get_colour(progress * 100)
	if new_colour != colour:
		colour = new_colour
		texture = load("res://mission/mouse/bar_" + colour + ".png")
