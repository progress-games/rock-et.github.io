extends Node2D

const WHITE_OUTLINE = preload("uid://dstl4edni51y1")

@export var details: Array[DetailNode]
@export var listening_state: Enums.State
@export var speech_bubbles: Array[Node]
@export var zen_mode_speech_bubbles: Array[Node]

var conditionals: Array[DetailNode]
var speech = true
var next_day_required: bool = true
var current_speech_bubble: Node

func _ready() -> void:
	if GameManager.zen_mode:
		speech_bubbles.map(func (x): x.queue_free())
		speech_bubbles = zen_mode_speech_bubbles
	GameManager.state_changed.connect(set_positions)
	GameManager.day_changed.connect(update_speech)
	
	# we still need speech if we previously needed it AND we haven't just read the dialogue
	# sorry future orlando (FUCK YOU PAST ORLANDO!) (chill out past orlando)
	GameManager.read_state_dialogue.connect(func (s):
		if s == listening_state:
			speech = false
	)
	
	conditionals = details.filter(func (x): return x.amount > 0 or x.stat_name != "")
	details = details.filter(func (x): return x.amount == 0 and x.stat_name == "")
	conditionals.map(
		func (n):
			if n.stat_name != "":
				StatManager.get_stat(n.stat_name).upgraded.connect(set_positions)
	)
	
	speech_bubbles.map(func (x): x.hide())
	set_current_speech()

func update_speech(d: int) -> void:
	if current_speech_bubble: return
	
	match d:
		4, 5, 6, 7:
			speech = true
			set_current_speech()
		8:
			speech_bubbles.map(func (x): x.queue_free())
			speech = false
			GameManager.read_state_dialogue.emit(listening_state)
			set_positions()

func set_current_speech() -> void:
	for n in details: get_node(n.node).hide()
	current_speech_bubble = speech_bubbles.pop_front()
	current_speech_bubble.visible = true
	
	current_speech_bubble.tree_exited.connect(func (): 
		speech = false
		set_positions()
	)

func set_positions(s: Enums.State = listening_state) -> void:
	if s != listening_state: return
	
	if speech:
		current_speech_bubble.reset_dialogue()
		for n in details:
			get_node(n.node).visible = false
		GameManager.hide_inventory.emit()
	else:
		GameManager.show_inventory.emit()
		
		for n in details:
			get_node(n.node).visible = true
			for m in n.movements.keys():
				get_node(m).position = n.movements[m]
		
		for n in conditionals:
			var node = get_node(n.node)
			var met = GameManager.player.get_mineral(n.mineral) >= n.amount \
				if n.amount > 0 else \
				StatManager.get_stat(n.stat_name).level >= n.stat_req
			
			if met:
				node.visible = true
				for m in n.movements.keys():
					get_node(m).position = n.movements[m]
			else: node.visible = false
