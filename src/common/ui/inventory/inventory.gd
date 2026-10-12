extends Control

enum State {
	DISPLAY,
	INTERACTIVE,
	MISSION
}

@onready var states: Dictionary[State, Control] = {
	State.DISPLAY: $Display,
	State.INTERACTIVE: $Interactive,
	State.MISSION: $Mission
}

func _ready() -> void:
	GameManager.show_inventory.connect(show)
	GameManager.hide_inventory.connect(hide)
	GameManager.state_changed.connect(update_state)

func disable_state(c: Control) -> void:
	c.hide()

func enable_state(c: Control) -> void:
	c.show()

func update_state(s: Enums.State) -> void:
	states.values().map(disable_state)
	
	if s == Enums.State.HOME:
		enable_state(states[State.INTERACTIVE])
	elif s == Enums.State.MISSION:
		enable_state(states[State.MISSION])
	else:
		enable_state(states[State.DISPLAY])
