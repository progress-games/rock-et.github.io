extends TextureButton

const BITE_INTERVAL := 1.

const BITES = preload("uid://bv4no0qahnuy5")
const SPLASH = preload("uid://bofuhpw2kdiff")

const FISH := [
	preload("uid://d3gw0wh3xmoy0"),
	preload("uid://c04n5fjkui85m"),
	preload("uid://bm6ahhjqr466n"),
	preload("uid://cvulcuupmwrx3"),
	preload("uid://blt50hpqt0dsu"),
	preload("uid://crqrg31pq65em")
	
]

var bite_shader: ShaderMaterial

func _ready() -> void:
	pressed.connect(jump)
	bite_shader = ShaderMaterial.new()
	bite_shader.shader = BITES

func jump() -> void:
	var pos = get_global_mouse_position()
	
	var new_splash = SPLASH.instantiate()
	add_child(new_splash)
	new_splash.global_position = pos
	new_splash.emitting = true
	new_splash.finished.connect(new_splash.queue_free)
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SPLASH)
	
	if randf() > 0.2:
		return
	
	var tex = TextureRect.new()
	tex.texture = FISH.pick_random()
	
	add_child(tex)
	tex.global_position = pos - Vector2(8, 0)
	tex.modulate = Color.TRANSPARENT
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var y = create_tween()
	y.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	y.tween_property(tex, "position:y", pos.y - 20, 0.5)
	
	var m = create_tween()
	m.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	m.tween_property(tex, "modulate", Color.WHITE, 0.5)
	
	tex.material = bite_shader.duplicate()
	tex.material.set_shader_parameter("bite_size", 0.4)
	
	var b = Timer.new()
	b.timeout.connect(
		func ():
			var bites = tex.get_meta("bites", [])
			bites.append([randf(), randf()])
			tex.material.set_shader_parameter("bites", bites)
			tex.set_meta("bites", bites)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BITE)
	)
	add_child(b)
	b.start(BITE_INTERVAL)
	
	var e = Timer.new()
	e.timeout.connect(
		func ():
			b.stop()
			b.queue_free()
			tex.queue_free()
			e.queue_free()
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.GULP)
	)
	add_child(e)
	e.start(2 * BITE_INTERVAL)
