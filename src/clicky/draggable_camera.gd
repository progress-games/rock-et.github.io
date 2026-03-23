extends Camera2D

var anchor: Vector2
var anchor_offset: Vector2
var dragging := false

func _process(delta: float) -> void:
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		dragging = false
	
	if dragging:
		position = anchor + (anchor_offset - get_local_mouse_position())
		position = Vector2(int(position.x), int(position.y))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		dragging = true
		anchor = position
		anchor_offset = get_local_mouse_position()
	#elif event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP):
		#var mouse_world_before := get_global_mouse_position()
		#zoom *= 0.9 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 1.1
		#var mouse_world_after := get_global_mouse_position()
		#position += mouse_world_before - mouse_world_after
		
