extends TextureRect

const BASE_W := 320
const BASE_H := 180

func _ready():
	var win_size = get_window().size
	var scale_x = win_size.x / BASE_W
	var scale_y = win_size.y / BASE_H
	
	# Integer scale to preserve pixel perfection
	var int_scale = floor(min(scale_x, scale_y))
	
	if int_scale < 1:
		int_scale = 1  # Prevent weird shrinking
	
	# If integer scale leaves black bars, allow fractional scaling (last resort)
	var final_scale = max(int_scale, min(scale_x, scale_y))

	scale = Vector2(final_scale, final_scale)

	# Center the SubViewport texture
	position = (Vector2(win_size) - texture.get_size() * scale) / 2
