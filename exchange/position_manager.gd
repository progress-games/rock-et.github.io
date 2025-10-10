extends Node2D
#janky solution lol

var jack_timer: float

func _ready() -> void:
	GameManager.state_changed.connect(func (state): 
		if state == Enums.State.EXCHANGE: 
			set_positions())
	$"../SpeechBubble".tree_exited.connect(set_positions)
	$"../Jack/AnimationPlayer".animation_finished.connect(func (n): if n == "jack look": jack_timer = randf_range(10, 50))
	

func set_positions() -> void:
	if get_node_or_null("../SpeechBubble"):
		$"../SpeechBubble".visible = true
		$"../SpeechBubble".reset_dialogue()
		$"../Graph".visible = false
		$"../Stats".visible = false
		$"../TransferInfo".visible = false
		$"../Exchange".visible = false
		GameManager.hide_inventory.emit()
	else:
		$"../Jack/AnimationPlayer".play("jack_down")
		$"../Graph".visible = true
		$"../Stats".visible = true
		$"../TransferInfo".visible = true
		$"../Exchange".visible = true
		GameManager.show_inventory.emit()
		jack_timer = randf_range(10, 50)

func _process(delta: float) -> void:
	jack_timer -= delta
	if jack_timer <= 0 and !get_node_or_null("../SpeechBubble"):
		$"../Jack/AnimationPlayer".play("jack look")

func _on_close_garage_pressed() -> void:
	GameManager.show_inventory.emit()
