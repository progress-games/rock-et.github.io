@tool
extends RichTextEffect
class_name RichTextFloat

# Syntax [float dist=5.0 speed=1.0]{text}[/float]

var bbcode = "float"

func _process_custom_fx(char_fx):
	var speed = char_fx.env.get("speed", 1.0)
	var distance = char_fx.env.get("dist", 5.0)
	var seed = float(char_fx.glyph_index) * 12.9898 # deterministic per glyph
	
	var t = char_fx.elapsed_time * speed
	
	# Create smooth pseudo-random motion using sin/cos
	var x = sin(t + seed) 
	var y = cos(t * 0.8 + seed * 1.3)
	
	char_fx.offset = Vector2(x, y) * distance
	
	return true
