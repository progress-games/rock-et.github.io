extends Sprite2D

@export var text_lines: Array[Dialogue]
@export var flipped: bool = false

const CHOICE := preload("res://common/ui/dialogue/speech_choice.tscn")
const FLIPPED := preload("res://common/ui/dialogue/speech_bubble_flipped.png")

var current_line: Dialogue
var current_idx: int = -1

func _ready() -> void:
	next_line()
	
	if flipped:
		$Label.position.x = -95
		texture = FLIPPED

func next_line(line: Dialogue = null) -> void:
	if !line:
		current_idx += 1
		
		if current_idx == text_lines.size():
			queue_free()
			return
		
		current_line = text_lines[current_idx]
	else:
		current_line = line
	
	$Label.text = current_line.text
	
	for choice in $Choices.get_children():
		choice.queue_free()
	
	for choice in current_line.options:
		var new_choice = CHOICE.instantiate()
		new_choice.choice = choice
		new_choice.chosen.connect(next_line)
		$Choices.add_child(new_choice)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and current_line.options.size() == 0:
		next_line()
	
func reset_dialogue() -> void:
	current_idx = -1
	next_line()
