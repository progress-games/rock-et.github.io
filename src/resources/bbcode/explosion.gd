@tool
extends RichTextEffect
class_name RichTextExplosion

# Syntax: [explosion size=5.0 freq=5.0]text here[/explosion]

var bbcode = "explosion"

func _process_custom_fx(char_fx):
	var size = char_fx.env.get("size")
	var freq = char_fx.env.get("freq")
	
	# gets progression of current period: 0 to freq
	var iterations = floor(char_fx.elapsed_time / freq)
	var progression = char_fx.elapsed_time - (freq * iterations)
	var shaking = freq - 0.75
	var explosion = 0.25
	var pause = 0.15
	
	if progression < shaking:
		var amplitude = (size / 4.) * (progression / shaking)
		char_fx.offset = Vector2(randf(), randf()) * amplitude * randf()
	else:
		var rng = RandomNumberGenerator.new()
		rng.seed = char_fx.glyph_index * (iterations + 1)
		
		var target = Vector2(
			rng.randf_range(-1., 1.) * size,
			rng.randf_range(-1., 1.) * size
		)
		if progression < shaking + explosion:
			var t = (progression - shaking) / explosion
			t = 1.0 - pow(1.0 - t, 3.0) # ease out cubic

			char_fx.offset = target * t
		elif progression < shaking + explosion + pause:
			char_fx.offset = target
		else:
			var t = (progression - shaking - explosion) / (freq - explosion - shaking)
			char_fx.offset = target * (1.0 - t)
	
	return true
	
	
