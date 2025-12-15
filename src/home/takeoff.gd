extends Node2D

var flying: bool = false
var transparency: float = 0

func _ready() -> void:
	$Takeoff.visible = false
	
	GameManager.state_changed.connect(func (s):
		if s == Enums.State.MISSION:
			$Embark.visible = false
			$Takeoff.visible = true
			$Takeoff.play("takeoff")
			flying = true
			transparency = 0
		elif flying:
			$Takeoff.play_backwards("takeoff")
			$Embark.visible = false
			flying = false)
	
	$Takeoff.animation_finished.connect(
		func ():
			if $Takeoff.animation == "takeoff" and flying:
				$Takeoff.play("flying")
			else:
				$Takeoff.visible = false
				$Embark.visible = true
	)

func _process(delta: float) -> void:
	if flying and transparency < 1:
		transparency += 0.015
		$Takeoff.modulate = Color(1, 1, 1, 1 - transparency)
	elif !flying:
		transparency -= 0.05
		$Takeoff.modulate = Color(1, 1, 1, 1 - transparency)
