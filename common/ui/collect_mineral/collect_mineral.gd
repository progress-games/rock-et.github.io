extends Sprite2D

var target: Vector2
const SPEED := 3
var pos_tween: Tween
var rot_tween: Tween
var mineral: GameManager.Mineral
var value: int

func _ready() -> void:
	var speed = position.distance_to(target) / 300
	
	pos_tween = create_tween()
	pos_tween.tween_property(self, "position", target, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	pos_tween.tween_callback(_end)
	
	rot_tween = create_tween()
	rot_tween.tween_property(self, "rotation", 0, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
func _end() -> void:
	GameManager.add_mineral.emit(mineral, value)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MINERAL_DEPOSIT)
	queue_free()
