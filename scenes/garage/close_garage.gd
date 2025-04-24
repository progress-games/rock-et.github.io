extends Button


func _on_pressed() -> void:
	GameManager.state_changed.emit(GameManager.State.UPGRADES)
