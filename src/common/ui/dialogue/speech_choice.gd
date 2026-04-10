extends Button

@export var choice: DialogueOption

signal chosen(response: Dialogue)

func _ready() -> void:
	mouse_entered.connect(func (): 
		$Outline.visible = true
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER))
	mouse_exited.connect(func (): 
		$Outline.visible = false
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
	$MarginContainer/Label.text = choice.player
	pressed.connect(func (): chosen.emit(choice.response))
