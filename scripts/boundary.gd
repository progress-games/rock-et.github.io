extends Area2D

@onready var collision_shape = $CollisionShape2D
var tracked_bodies: Array[RigidBody2D] = []

func _physics_process(delta: float) -> void:
	for body in tracked_bodies:
		if body.has_meta("locked_in"):
			continue
		if body_fully_inside(body):
			body.set_meta("locked_in", true)
			body.collision_mask = 2

func _ready() -> void:
	update_shape_to_viewport()
	get_viewport().connect("size_changed", Callable(self, "update_shape_to_viewport"))

func update_shape_to_viewport() -> void:
	var size = get_viewport_rect().size
	var shape = RectangleShape2D.new()
	shape.extents = size / 2
	collision_shape.shape = shape
	collision_shape.position = GameManager.location

func body_fully_inside(body: RigidBody2D) -> bool:
	var body_shape = body.collision_shape.shape
	var area_shape = collision_shape.shape
	
	var body_transform = body.get_global_transform()
	var area_transform = collision_shape.get_global_transform()
	
	var body_rect = Rect2(
		body_transform.origin - body_shape.extents,
		body_shape.extents * 2
	)
	
	var area_rect = Rect2(
		area_transform.origin - area_shape.extents,
		area_shape.extents * 2
	)
	
	return area_rect.encloses(body_rect)

func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and not tracked_bodies.has(body):
		tracked_bodies.append(body)

func _on_body_exited(body: Node2D) -> void:
	tracked_bodies.erase(body)
