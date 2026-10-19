extends Node2D

var jack_timer: float
@onready var speech_bubble = $"../../SpeechBubble"
@onready var animation_player = $"../AnimationPlayer"

@onready var speech_bubble_topaz: SpeechBubble = $"../../SpeechBubbleTopaz"

func _ready() -> void:
	animation_player.animation_finished.connect(func (n): if n == "jack look": jack_timer = randf_range(10, 50))
	speech_bubble.tree_exited.connect(func (): 
		animation_player.play("jack_down")
		jack_timer = randf_range(10, 50))
	
	speech_bubble_topaz.visibility_changed.connect(
		func ():
			if speech_bubble_topaz.visible:
				animation_player.play("jack look")
	)

func _process(delta: float) -> void:
	jack_timer -= delta
	if jack_timer <= 0 and !get_node_or_null("../../SpeechBubble"):
		animation_player.play("jack look")
