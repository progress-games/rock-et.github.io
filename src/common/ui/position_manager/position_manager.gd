extends Node2D

const WHITE_OUTLINE = preload("uid://dstl4edni51y1")

@export var details: Array[DetailNode]
@export var listening_state: Enums.State
@export var speech_bubble: Node

@export var using_extra_help: bool = false
@export var help_button: TextureButton
@export var extra_help_speech: Node 

var temp_help_speech: Node
var conditionals: Array[DetailNode]
var speech = true

func _ready() -> void:
	GameManager.state_changed.connect(func (state): 
		if state == listening_state: 
			if temp_help_speech: temp_help_speech.queue_free()
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
	
	if using_extra_help:
		extra_help_speech.visibility_changed.connect(set_positions)
		extra_help_speech.visible = false
	
		var white_outline = ShaderMaterial.new()
		white_outline.shader = WHITE_OUTLINE
		help_button.material = white_outline.duplicate()
		
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(help_button.texture_normal.get_image(), 0.5)
		help_button.texture_click_mask = bitmap
		
		help_button.mouse_entered.connect(
			func ():
				GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
				help_button.material.set_shader_parameter("width", 1)
		)
		
		help_button.mouse_exited.connect(
			func ():
				GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
				help_button.material.set_shader_parameter("width", 0)
		)
		
		help_button.pressed.connect(
			func ():
				extra_help_speech.visible = true
				for n in details:
					get_node(n.node).visible = false
		)

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
