extends ReferenceRect

var progress := 0.0
var colour: String

const colour_tex := {
	"red": preload("res://mission/mouse/bar_red.png"),
	"orange": preload("res://mission/mouse/bar_orange.png"),
	"green": preload("res://mission/mouse/bar_green.png"),
	"blue": preload("res://mission/mouse/bar_blue.png")
}

const EDGE_WIDTH = 2

func _ready() -> void:
	GameManager.asteroid_broke.connect(func ():
		progress = min(progress + StatManager.get_stat("rock_boost").value, 1))
	GameManager.state_changed.connect(func (s): 
		if s == Enums.State.MISSION: 
			progress = 1.0
	)

func _process(_d: float) -> void:
	#if GameManager.state != Enums.State.MISSION: 
		#return
	if GameManager.state != Enums.State.MISSION:
		return
	progress = min(progress + StatManager.get_stat("bar_replenish").value, 1)
	$NinePatchRect.size.x = size.x * progress
	var new_colour = StatManager.get_colour(progress * 100)
	if new_colour != colour:
		colour = new_colour
		$NinePatchRect.texture = colour_tex[colour]
