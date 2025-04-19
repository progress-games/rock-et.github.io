extends Area2D

var sprites = {
	"hover": preload("res://assets/ship hover.png"),
	"base": preload("res://assets/ship.png")
}
@onready var sprite: Sprite2D = $Sprite2D

func _on_mouse_entered() -> void:
	sprite.texture = sprites.hover

func _on_mouse_exited() -> void:
	sprite.texture = sprites.base

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		GameManager.state_changed.emit(GameManager.State.MISSION)
