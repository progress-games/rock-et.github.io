extends Node2D
class_name DialogueManager

# saved as dialogue read: N
# where N=0, read none, N=1, read first, etc.

const WHITE_OUTLINE = preload("uid://dstl4edni51y1")

## detail nodes hold dialogue, when to show them, etc.
@export var details: Array[DetailNode]

# used exclusively for the scientist lol
@export var zen_mode_details: Array[DetailNode]

var completed_reading: bool = false

func _ready() -> void:
	if GameManager.zen_mode:
		details.map(func (x): get_node(x.speech_bubble).queue_free())
		details = zen_mode_details
	elif zen_mode_details.size() > 0:
		zen_mode_details.map(func (x): get_node(x.speech_bubble).queue_free())
	
	GameManager.state_changed.connect(func (_s): set_positions())
	ClickEffectManager.effect_upgraded.connect(func (_c): set_positions())
	StatManager.stat_upgraded.connect(func (_s): set_positions())
	
	for detail in details: get_node(detail.speech_bubble).visible = false
	
	set_detail_vis(0, details.size(), false)

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
		
		for node_path in detail.movements.keys():
			var node = get_node(node_path)
			node.position = detail.movements[node_path]

func read_speech(idx: int) -> void:
	completed_reading = idx >= details.size()
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
