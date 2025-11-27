extends Button

@export var amount: int
@export var mineral: Enums.Mineral

func _ready() -> void:
	text = "add " + str(amount) + " " + Enums.Mineral.find_key(mineral)

func _on_pressed() -> void:
	GameManager.add_mineral.emit(mineral, amount)
