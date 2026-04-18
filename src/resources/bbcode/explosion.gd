@tool
extends RichTextEffect
class_name RichTextExplosion

# explosion duration
const EXPLOSION: float = 0.25

# pause after explosion
const PAUSE: float = 0.15

# duration for letters to move back to original colour
const RECOUP: float = 0.35

# Syntax: [explosion size=5.0 freq=5.0]{text}[/explosion]

var bbcode = "explosion"

func _process_custom_fx(char_fx):
	var size = char_fx.env.get("size")
	var freq = char_fx.env.get("freq")
	
	# gets progression of current period: 0 to freq
	var iterations = floor(char_fx.elapsed_time / freq)
	
	# gets progression of current iteration
	var progression = char_fx.elapsed_time - (freq * iterations)
	var shaking = freq - (EXPLOSION + PAUSE + RECOUP)
	
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
		if progression < shaking + EXPLOSION:
			var t = (progression - shaking) / EXPLOSION
			t = 1.0 - pow(1.0 - t, 3.0) # ease out cubic

			char_fx.offset = target * t
		elif progression < shaking + EXPLOSION + PAUSE:
			char_fx.offset = target
		else:
			var t = (progression - shaking - EXPLOSION) / (freq - EXPLOSION - shaking)
			char_fx.offset = target * (1.0 - t)
	
	return true
	
	
