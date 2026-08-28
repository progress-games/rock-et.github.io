extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var button: Button = $Face/Button

var pop_up_timer: Timer

func _ready() -> void:
	pop_up_timer = Timer.new()
	pop_up_timer.one_shot = true
	pop_up_timer.timeout.connect(pop_up)
	add_child(pop_up_timer)
	pop_up_timer.start(6)
	
	button.pressed.connect(func (): 
		animation_player.play("aah!")
		animation_player.animation_finished.connect(
			func (_a): 
				animation_player.play("RESET"),
				CONNECT_ONE_SHOT))

func pop_up() -> void:
	animation_player.play("pop_up")
	animation_player.animation_finished.connect(
		func (_a): pop_up_timer.start(randi_range(100, 180)), CONNECT_ONE_SHOT)
