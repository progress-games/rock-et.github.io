extends TextureButton

@onready var ship: Sprite2D = $Ship
@onready var embark: TextureButton = $"../../StateButtons/Embark"

var hit_tween: Tween
var hits := 5

func _ready() -> void:
	mouse_entered.connect(func (): GameManager.set_mouse_state.emit(Enums.MouseState.SHOVEL))
	mouse_exited.connect(func (): GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
	pressed.connect(func (): hit())
	
	embark.call_deferred("hide")

func hit() -> void:
	scale = Vector2.ONE * 0.7
	
	if hit_tween != null: hit_tween.kill()
	
	hit_tween = create_tween()
	hit_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	hit_tween.tween_property(self, "scale", Vector2.ONE, 0.5)
	hits -= 1
	
	if hits <= 0:
		finish()
		disabled = true

func embark_pos() -> Vector2:
	return embark.global_position + embark.size / 2.

func finish() -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(ship, "global_position", embark_pos() - Vector2(0, 15), 0.5)
	t.tween_property(ship, "rotation", 0, 0.5)
	t.tween_property(ship, "global_position", embark_pos(), 0.5)
	
	t.finished.connect(
		func ():
			embark.show()
			queue_free()
	)
