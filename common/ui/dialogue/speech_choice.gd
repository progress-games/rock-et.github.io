extends Button

@export var choice: DialogueOption

signal chosen(response: Dialogue)

func _ready() -> void:
	mouse_entered.connect(func (): $Outline.visible = true)
	mouse_exited.connect(func (): $Outline.visible = false)
	$MarginContainer/Label.text = choice.player
	pressed.connect(func (): chosen.emit(choice.response))
