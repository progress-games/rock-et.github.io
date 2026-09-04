extends Control

var timer_1 := 50.
var timer_2 := 100.

@onready var animation_player: AnimationPlayer = $Skiier/AnimationPlayer
@onready var animation_player2: AnimationPlayer = $Skiier2/AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(func (_s): animation_player.play("RESET"))
	animation_player2.animation_finished.connect(func (_s): animation_player2.play("RESET"))

func _process(delta: float) -> void:
	timer_1 -= delta
	timer_2 -= delta
	
	if timer_1 <= 0:
		animation_player.play("go down the mountain")
		timer_1 = randi_range(40, 120)
	if timer_2 <= 0:
		animation_player2.play("go down the mountain")
		timer_2 = randi_range(40, 120)
