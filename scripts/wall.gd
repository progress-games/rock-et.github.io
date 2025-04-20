extends StaticBody2D

enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@export var direction: Direction
@onready var collision_shape = $CollisionShape2D

func _process(delta: float) -> void:
	global_position.y -= delta * GameManager.player.get_stat("rocket_speed").value

func _ready() -> void:
	align_to_edge()
	get_viewport().connect("size_changed", Callable(self, "align_to_edge"))

func align_to_edge() -> void:
	var size = get_viewport_rect().size
	var shape = RectangleShape2D.new()
	var indent = 5
	
	match direction:
		Direction.NORTH:
			shape.extents = Vector2(size.x / 2, 1)
			collision_shape.position = GameManager.location - Vector2(0, size.y / 2 + indent)
		Direction.EAST:
			shape.extents = Vector2(1, size.y / 2)
			collision_shape.position = GameManager.location + Vector2(size.x / 2 + indent, 0)
		Direction.SOUTH:
			shape.extents = Vector2(size.x / 2, 1)
			collision_shape.position = GameManager.location + Vector2(0, size.y / 2 + indent)
		Direction.WEST:
			shape.extents = Vector2(1, size.y / 2)
			collision_shape.position = GameManager.location - Vector2(size.x / 2 + indent, 0)
	
	collision_shape.shape = shape
