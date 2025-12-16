extends Button

func _on_pressed() -> void:
	print_debug('test')
	GameManager.endless = true
	get_tree().paused = false
	$"..".visible = false
	
