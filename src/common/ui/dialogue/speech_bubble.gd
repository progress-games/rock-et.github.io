extends Sprite2D

@export var text_lines: Array[Dialogue]
@export var flipped: bool = false
@export var delete_when_finished: bool = true

@onready var skip: TextureButton = $Skip
@onready var skip_progress: ColorRect = $Skip/Skip

const SKIP_DUR = 0.5
const CHOICE := preload("res://common/ui/dialogue/speech_choice.tscn")
const FLIPPED := preload("res://common/ui/dialogue/speech_bubble_flipped.png")

var holding: bool = false
var skipping: float = 0
var current_line: Dialogue
var current_idx: int = -1
var ellipses: DialogueOption

func _ready() -> void:
	skip.mouse_entered.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		skip.material.set_shader_parameter("width", 1)
	)
	
	skip.mouse_exited.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		skip.material.set_shader_parameter("width", 0)
	)
	
	skip.button_down.connect(func (): holding = true)
	skip.button_up.connect(func (): holding = false)
	
	GameManager.state_changed.connect(func (_s): skip_progress.material.set_shader_parameter("progress", 0))
	
	ellipses = DialogueOption.new()
	ellipses.player = "..."
	
	next_line()
	
	if flipped:
		$Label.position.x = -95
		texture = FLIPPED

func _process(delta: float) -> void:
	if !holding && skipping == 0: return
	
	if holding:
		skipping += delta
		if skipping > SKIP_DUR:
			if delete_when_finished:
				queue_free()
			else:
				reset_dialogue()
				hide()
	else:
		skipping = max(skipping - delta * 2, 0)
	
	skip_progress.material.set_shader_parameter("progress", skipping / SKIP_DUR)

func next_line(line: Dialogue = null) -> void:
	# if current_idx > -1: AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	if !line:
		current_idx += 1
		
		if current_idx == text_lines.size():
			if delete_when_finished:
				queue_free()
			else:
				reset_dialogue()
				hide()
			return
		
		current_line = text_lines[current_idx]
	else:
		current_line = line
	
	$Label.text = current_line.text
	
	for choice in $Choices.get_children():
		choice.queue_free()
	
	if current_line.options.size() == 0:
		current_line.options.append(ellipses)
	
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
