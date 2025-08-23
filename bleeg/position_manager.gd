extends Node2D

func _ready() -> void:
	GameManager.state_changed.connect(func (state): 
		if state == Enums.State.BLEEG: 
			set_positions())
	$SpeechBubble.tree_exited.connect(set_positions)

func set_positions() -> void:
	GameManager.show_inventory.emit()
	if GameManager.player.minerals[Enums.Mineral.CORUNDUM] == 0 and get_node_or_null("SpeechBubble"):
		$SpeechBubble.visible = true
		$SpeechBubble.reset_dialogue()
		$Progress.visible = false
		GameManager.hide_inventory.emit()
	else:
		$Progress.visible = true


func _on_close_garage_pressed() -> void:
	GameManager.show_inventory.emit()
