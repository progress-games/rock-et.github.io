extends Button

func _on_pressed() -> void:
	GameManager.add_mineral.emit(GameManager.Mineral.AMETHYST, 10)
