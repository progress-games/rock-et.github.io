extends Button

@export var amount: int
@export var mineral: Enums.Mineral

func _on_pressed() -> void:
	GameManager.add_mineral.emit(mineral, amount)
