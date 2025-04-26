extends Area2D

@onready var corners := {
	"top_left": $TopLeft,
	"top_right": $TopRight,
	"bottom_left": $BottomLeft,
	"bottom_right": $BottomRight
}
@onready var collision_shape := $CollisionShape2D
var scale_tween: Tween
var base_scale: Vector2

var rocks = []

func _ready() -> void:
	base_scale = Vector2(GameManager.player.get_stat("hit_size").value,
		GameManager.player.get_stat("hit_size").value)
	scale = base_scale
	
	_position_self()

func _process(delta: float) -> void:
	_position_self()

func _position_self() -> void:
	position = get_global_mouse_position()
	var shape = collision_shape.shape.extents * scale
	var corner_scale = (shape.x / 3) / 32

	corners.get("top_left").global_position = position - shape
	corners.get("top_right").global_position = position + Vector2(shape.x, -shape.y)
	corners.get("bottom_left").global_position = position - Vector2(shape.x, -shape.y)
	corners.get("bottom_right").global_position = position + shape

func _on_body_entered(body: Node2D) -> void:
	if body.has_meta("rock"):
		rocks.append(body)
	elif body.has_meta("mineral"):
		GameManager.add_mineral.emit(GameManager.Mineral.AMETHYST, 1 * GameManager.player.get_stat("mineral_value").value)
		body.queue_free()

func _on_body_exited(body: Node2D) -> void:
	if body.has_meta("rock"):
		rocks.erase(body)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		scale_tween = create_tween()
		scale = base_scale
		
		scale_tween.tween_property(self, "scale", scale * 0.8, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", scale, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
		for rock in rocks: 
			rock.hit(0.5)
