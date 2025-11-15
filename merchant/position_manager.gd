extends Node2D
#janky solution lol SHOULD DEF CHANGE BUT CBF!

@onready var items_and_that: Array = [
	$"../Price",
	$"../Stall",
	$"../Items",
	$"../DescriptionPanel",
	$"../DescriptionText",
	$"../RollButton"
]

func _ready() -> void:
	GameManager.state_changed.connect(func (state): 
		if state == Enums.State.MERCHANT: 
			set_positions())
	for item in items_and_that: 
		item.visible = false
	$"../SpeechBubble".tree_exited.connect(set_positions)

func set_positions() -> void:
	if get_node_or_null("../SpeechBubble"):
		$"../SpeechBubble".visible = true
		$"../SpeechBubble".reset_dialogue()
		for item in items_and_that: 
			item.visible = false
		GameManager.hide_inventory.emit()
	else:
		for item in items_and_that: 
			item.visible = true
		GameManager.show_inventory.emit()

func _on_close_garage_pressed() -> void:
	GameManager.show_inventory.emit()
