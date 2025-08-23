extends Button

@export var amount: int

func _on_pressed() -> void:
	GameManager.add_mineral.emit(Enums.Mineral.CORUNDUM, amount)
