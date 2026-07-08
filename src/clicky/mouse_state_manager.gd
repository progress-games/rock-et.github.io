extends SubViewportContainer

var hovering := false

func _ready() -> void:
	mouse_entered.connect(
		func ():
			hovering = true
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER_DRAG)
	)
	mouse_exited.connect(
		func ():
			hovering = false
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	)

func _input(e: InputEvent) -> void:
	if hovering and e is InputEventMouseButton and e.is_pressed() and e.button_index == MOUSE_BUTTON_RIGHT:
		GameManager.set_mouse_state.emit(Enums.MouseState.DRAG)
	elif hovering and e is InputEventMouseButton and e.is_released() and e.button_index == MOUSE_BUTTON_RIGHT:
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER_DRAG)
