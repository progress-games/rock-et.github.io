extends Node2D

const BAR_PANEL_ULTRA := Vector2(0, 1)
const SPEECH_BUBBLE := Vector2(124, 38)

func _ready() -> void:
	GameManager.state_changed.connect(func (state): 
		if state == Enums.State.SCIENTIST: 
			set_positions())
	$SpeechBubble.tree_exited.connect(set_positions)

func set_positions() -> void:
	GameManager.show_inventory.emit()
	if GameManager.player.minerals[Enums.Mineral.OLIVINE] == 0 and get_node_or_null("SpeechBubble"):
		$SpeechBubble.position = SPEECH_BUBBLE
		$SpeechBubble.reset_dialogue()
		GameManager.hide_inventory.emit()
	elif GameManager.player.minerals[Enums.Mineral.OLIVINE] > 100 or $BarUpgrades.position == BAR_PANEL_ULTRA:
		$BarUpgrades.position = BAR_PANEL_ULTRA
		$UltraUpgrades.visible = true
	else:
		$BarUpgrades.visible = true


func _on_close_garage_pressed() -> void:
	GameManager.show_inventory.emit()
