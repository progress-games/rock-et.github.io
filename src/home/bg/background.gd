extends Node2D

const positions := {
	Enums.Planet.DYRT: Vector2(0, -1980),
	Enums.Planet.KRUOS: Vector2(0, -309)
}

var home: Vector2
var target: Vector2
const SPEED := 3
const endless_bg := preload("res://home/bg/itch bg.png")

func _ready() -> void:
	home = position
	GameManager.boost.connect(func (amount):
		target.y += GameManager.DISTANCE * amount
	)
	
	GameManager.state_changed.connect(
		func (s):
			if s == Enums.State.MISSION:
				$Dyrt.stop()
			elif not $Dyrt.is_playing():
				$Dyrt.play("running_water")
				for n in $Dyrt/EndlessBG.get_children(): n.queue_free()
	)
	
	GameManager.planet_changed.connect(
		func (p: Enums.Planet):
			home = positions[p]
	)

func _process(delta: float) -> void:
	if GameManager.state == Enums.State.MISSION:
		target.y += delta * GameManager.player.get_stat("thruster_speed").value
	else:
		target = home
		
	position += (target - position) * delta * SPEED
	
	if GameManager.endless:
		var total_pos = position + Vector2(0, $Dyrt/EndlessBG.get_child_count() * 300)
		if total_pos.y > -10:
			var new_bg = Sprite2D.new()
			new_bg.texture = endless_bg
			new_bg.position = Vector2(0, -300 * ($Dyrt/EndlessBG.get_child_count() + 1))
			new_bg.centered = false
			add_child(new_bg)
	
	if $Kruos/KruosPassOver.global_position.y >= 0 and GameManager.planet != Enums.Planet.KRUOS:
		GameManager.planet_changed.emit(Enums.Planet.KRUOS)
	
