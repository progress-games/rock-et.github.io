extends Node2D

const positions := {
	Enums.Planet.DYRT: Vector2(0, -1980),
	Enums.Planet.KRUOS: Vector2(0, 680)
}

var home: Vector2
var target: Vector2
const TRANSITION_SPEED := 40
const SPEED := 3
const PLANET_BUFFER := 30
const endless_bg := preload("uid://dt501pcvxbn2d")

var transitioning: bool = false

"""
so it should hit a point then go into a cutscene.
asteroids stop spawning, mouse goes to hold mode, rocket comes into vision

needs to be done (then this feature is done):
	smooth transition
	pull rocket into view 
"""

func _ready() -> void:
	home = position
	GameManager.boost.connect(func (amount):
		target.y += GameManager.DISTANCES[GameManager.planet] * amount
	)
	
	GameManager.state_changed.connect(
		func (s):
			if s == Enums.State.MISSION:
				target.y += 180
			else:
				for n in $Dyrt/EndlessBG.get_children(): 
					n.queue_free()
	)
	
	GameManager.planet_changed.connect(
		func (p: Enums.Planet):
			home = positions[p]
	)

func _process(delta: float) -> void:
	if GameManager.state == Enums.State.MISSION and not transitioning:
		target.y += delta * StatManager.get_stat("thruster_speed").value
	elif transitioning:
		target.y += delta * TRANSITION_SPEED
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
	
	if $Kruos/KruosPassOver.global_position.y >= -get_viewport_rect().size.y and not transitioning and GameManager.planet != Enums.Planet.KRUOS:
		transitioning = true
		GameManager.music_changed.emit(Enums.Planet.KRUOS)
	elif transitioning and position.y > positions[Enums.Planet.KRUOS].y - get_viewport_rect().size.y + PLANET_BUFFER:
		transitioning = false
		GameManager.planet_changed.emit(Enums.Planet.KRUOS)
		GameManager.state_changed.emit(Enums.State.HOME)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
