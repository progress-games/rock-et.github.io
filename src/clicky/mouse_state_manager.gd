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
