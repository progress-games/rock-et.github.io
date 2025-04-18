extends StaticBody2D

enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@export var direction: Direction
@onready var collision_shape = $CollisionShape2D

func _ready() -> void:
	align_to_edge()
	get_viewport().connect("size_changed", Callable(self, "align_to_edge"))

func align_to_edge() -> void:
	var size = get_viewport_rect().size
	var shape = RectangleShape2D.new()
	
	match direction:
		Direction.NORTH:
			shape.extents = Vector2(size.x / 2, 5)
			collision_shape.position = Vector2(size.x / 2, -1)
		Direction.EAST:
			shape.extents = Vector2(5, size.y / 2)
			collision_shape.position = Vector2(size.x + 1, size.y / 2)
		Direction.SOUTH:
			shape.extents = Vector2(size.x / 2, 5)
			collision_shape.position = Vector2(size.x / 2, size.y + 1)
		Direction.WEST:
			shape.extents = Vector2(5, size.y / 2)
			collision_shape.position = Vector2(-1, size.y / 2)
	
	collision_shape.shape = shape
