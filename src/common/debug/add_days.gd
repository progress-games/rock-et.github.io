extends Button

@export var day: int

func _ready() -> void:
	text = "load day " + str(day)

func _on_pressed() -> void:
	SaveManager.load_save("day" + str(day))
