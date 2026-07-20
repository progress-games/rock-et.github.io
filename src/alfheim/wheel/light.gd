extends Sprite2D
class_name WheelLight

const FADE_OUT = 0.1

@onready var glow: Sprite2D = $Glow

func pulse() -> void:
	glow.modulate.a = 1

# returns if it needs to update again
func update() -> void:
	glow.modulate.a = max(0, glow.modulate.a - FADE_OUT)

func needs_update() -> bool:
	return glow.modulate.a != 0
