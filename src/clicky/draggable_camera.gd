extends Camera2D

@onready var pick_three: Control = $ColorRect/PickThree

var min_x := -10
var max_x := 10
var min_y := -10
var max_y := 10

var anchor: Vector2
var anchor_offset: Vector2
var dragging := false
var dragging_enabled := false

func _ready() -> void:
	GameManager.state_changed.connect(
		func (s: Enums.State):
			dragging_enabled = s == Enums.State.CLICKY
	)


func _process(_d: float) -> void:
	#if !dragging_enabled: return
	if dragging && !(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and !pick_three.visible):
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER_DRAG)
	dragging = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and !pick_three.visible
	
	if dragging:
		position = anchor + (anchor_offset - get_local_mouse_position())
		position = Vector2(
			clamp(int(position.x), min_x, max_x), 
			clamp(int(position.y), min_y, max_y))

func _input(event: InputEvent) -> void:
	#if !dragging_enabled: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		dragging = true
		anchor = position
		anchor_offset = get_local_mouse_position()
		GameManager.set_mouse_state.emit(Enums.MouseState.DRAG)
	#elif event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP):
		#var mouse_world_before := get_global_mouse_position()
		#zoom *= 0.9 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 1.1
		#var mouse_world_after := get_global_mouse_position()
		#position += mouse_world_before - mouse_world_after
		
