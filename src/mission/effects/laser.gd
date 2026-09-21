extends Area2D

const LASER_DURATION = 1
const LASER_DAMAGE = 7

func _ready() -> void:
	var m = create_tween()
	m.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	m.tween_property(self, "modulate", Color.TRANSPARENT, LASER_DURATION)
	m.finished.connect(queue_free)
	
	var s = create_tween()
	s.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	s.tween_property(self, "scale:x", 0.5, LASER_DURATION)

func _process(delta: float) -> void:
	var asteroids = get_overlapping_areas().filter(func (x): return x.has_meta("asteroid"))
	for asteroid in asteroids:
		asteroid.hit(LASER_DAMAGE * delta, [false, false, false, false, false, true].pick_random())
	
