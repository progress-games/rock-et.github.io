extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

@export var state: Enums.State
@export var sound_effect: SoundEffect.SOUND_EFFECT_TYPE
@export var mineral: Enums.Mineral

func _ready() -> void:
	visible = false
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	
	GameManager.day_changed.connect(func (day): 
		if day >= GameManager.day_requirement[state]: 
			visible = true
	)

func _on_mouse_entered() -> void:
	sprite.material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func _on_mouse_exited() -> void:
	sprite.material.set_shader_parameter("width", 0)
	if GameManager.state != state:
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		GameManager.show_mineral.emit(mineral)
		GameManager.state_changed.emit(state)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		AudioManager.create_audio(sound_effect)
