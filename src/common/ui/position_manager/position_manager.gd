extends Node2D

@export var details: Array[DetailNode]
@export var listening_state: Enums.State
@export var speech_bubble: Node

var conditionals: Array[DetailNode]
var speech = true

func _ready() -> void:
	GameManager.state_changed.connect(func (state): 
		if state == listening_state: 
			set_positions())
	
	# we still need speech if we previously needed it AND we haven't just read the dialogue
	# sorry future orlando
	GameManager.read_state_dialogue.connect(func (s):
		var s_ = speech
		speech = speech and s != listening_state
		if s_ != speech: speech_bubble.queue_free())
	
	for n in details:
		get_node(n.node).visible = false
	
	speech_bubble.tree_exited.connect(func (): speech = false; set_positions())
	conditionals = details.filter(func (x): return x.amount > 0 or x.stat_name != "")

func set_positions() -> void:
	if speech:
		speech_bubble.visible = true
		speech_bubble.reset_dialogue()
		for n in details:
			get_node(n.node).visible = false
		GameManager.hide_inventory.emit()
	else:
		GameManager.read_state_dialogue.emit(listening_state)
		GameManager.show_inventory.emit()
		
		for n in details:
			get_node(n.node).visible = true
		
		for n in conditionals:
			var node = get_node(n.node)
			var met = (n.amount > 0 and GameManager.player.get_mineral(n.mineral) >= n.amount) or \
				StatManager.get_stat(n.stat_name).level >= n.stat_req
			if met:
				node.visible = true
				for m in n.movements.keys():
					get_node(m).position = n.movements[m]
			else: node.visible = false
