extends Node2D
class_name DialogueManager

# saved as dialogue read: N
# where N=0, read none, N=1, read first, etc.

const WHITE_OUTLINE = preload("uid://dstl4edni51y1")

## detail nodes hold dialogue, when to show them, etc.
@export var details: Array[DetailNode]

@export var state: Enums.State

var completed_reading: bool = false

func _ready() -> void:
	if state == Enums.State.CLICKY:
		ClickEffectManager.effect_upgraded.connect(func (_c): set_positions())
	
	for detail in details: 
		get_node(detail.speech_bubble).visible = false
		if detail.show_requirement == DetailNode.ShowRequirement.STAT_LEVEL:
			StatManager.get_stat(detail.stat_name).upgraded.connect(set_positions)
	
	GameManager.state_changed.connect(func (s): 
		if s == state: set_positions())
	
	SaveManager.loaded_save.connect(update_dialogue_progress, CONNECT_ONE_SHOT)

func update_dialogue_progress() -> void:
	var state_data = SaveManager.get_state_data(state)
	
	if state_data.dialogue_progress == -1:
		return
	
	completed_reading = state_data.dialogue_progress + 1 >= details.size()
	
	if completed_reading:
		set_detail_vis(0, details.size(), true)
		queue_free()
		return
	
	#set_detail_vis(0, state_data.dialogue_progress + 1, true)
	for i in range(state_data.dialogue_progress + 1): # +1 bc it's exclusive
		details[i].total_state_amount = max(details[i].total_state_amount, details[i].state_amount)
		details[i].force_read()
	
	details.map(
		func (d: DetailNode):
			if d.show_requirement == DetailNode.ShowRequirement.LISTENING_STATE:
				d.state_amount -= details[state_data.dialogue_progress].total_state_amount
	)
	
# for all the details past a given index, sets their visibility to be the given visibility
# and updates their position to be the latest
func set_detail_vis(from: int, to: int, vis: bool) -> void:
	for detail in details.slice(from, to):
		for node_path in detail.show_nodes:
			var node = get_node(node_path)
			node.visible = vis
	
		for node_path in detail.hide_nodes:
			var node = get_node(node_path)
			node.visible = !vis
		
		if vis:
			for node_path in detail.movements.keys():
				var node = get_node(node_path)
				node.position = detail.movements[node_path]

func read_speech(idx: int) -> void:
	completed_reading = idx + 1 >= details.size()
	SaveManager.read_dialogue.emit(state)
	set_positions()

func set_current_speech(idx: int) -> void:
	if !details[idx].is_ready() || completed_reading || details[idx].has_been_shown:
		return
	
	var speech: SpeechBubble = get_node(details[idx].speech_bubble)
	speech.visible = true
	details[idx].has_been_shown = true
	speech.tree_exited.connect(func (): 
		details[idx].has_been_read = true
		read_speech(idx)
	)

func set_positions() -> void:
	call_deferred("set_positions_deferred")

func set_positions_deferred() -> void:
	if is_queued_for_deletion():
		return
	
	for i in range(details.size()):
		var detail = details[i]
		if detail.has_been_read:
			set_detail_vis(0, i + 1, true) # show all nodes up to this point
		elif detail.is_ready():
			set_current_speech(i)
			set_detail_vis(0, details.size(), false) # hide all nodes for dialogue
			break # break so we don't accidentally show anything else
		else:
			set_detail_vis(i, details.size(), false) # hide all nodes from this point onwards
			break
	
	if completed_reading: 
		queue_free()
		return
