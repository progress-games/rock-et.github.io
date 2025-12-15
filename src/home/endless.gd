extends Button

func _pressed() -> void:
	GameManager.endless = true
	get_tree().paused = false
