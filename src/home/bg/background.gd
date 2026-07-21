extends Node2D

const positions := {
	Enums.Planet.DYRT: Vector2(0, -1980),
	Enums.Planet.KRUOS: Vector2(0, 680)
}

const BLIZZARD_AUDIO := preload("uid://gci72p7bd82e")

@onready var blur: ColorRect = $StateButtons/Blur
@onready var snow: CPUParticles2D = $Kruos/Snow
@onready var lines: CPUParticles2D = $Kruos/Lines
@onready var kruos_blizzard: Sprite2D = $Kruos/KruosBlizzard
@onready var clouds: CPUParticles2D = $Kruos/Clouds

var home: Vector2
var target: Vector2
const TRANSITION_SPEED := 40
const SPEED := 3
const PLANET_BUFFER := 30
const endless_bg := preload("uid://dt501pcvxbn2d")

var transitioning: bool = false
var blizzard_audio: AudioStreamPlayer

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
				hide_blizzard()
				end_blizzard_audio()
	)
	
	GameManager.planet_changed.connect(
		func (p: Enums.Planet):
			home = positions[p]
	)
	
	GameManager.blizzard_started.connect(
		func ():
			kruos_blizzard.show()
			snow.emitting = true
			lines.emitting = true
			clouds.emitting = true
			snow.show()
			lines.show()
			clouds.show()
			blur.show()
			start_blizzard_audio()
	)

func start_blizzard_audio() -> void:
	blizzard_audio = AudioStreamPlayer.new()
	blizzard_audio.stream = BLIZZARD_AUDIO
	blizzard_audio.volume_db = -80
	blizzard_audio.bus = "Ambience"
	blizzard_audio.autoplay = true
	add_child(blizzard_audio)
	
	var t = create_tween()
	t.tween_property(blizzard_audio, "volume_db", -15, 0.5)

func end_blizzard_audio() -> void:
	if !blizzard_audio: return
	
	var t = create_tween()
	t.tween_property(blizzard_audio, "volume_db", -40, 1)
	blizzard_audio.queue_free()

func hide_blizzard() -> void:
	var t = Timer.new()
	t.wait_time = 0.2
	t.one_shot = true
	t.timeout.connect(
		func ():
			kruos_blizzard.hide()
			snow.emitting = false
			lines.emitting = false
			clouds.emitting = false
			snow.hide()
			lines.hide()
			clouds.hide()
			blur.hide()
	)
	add_child(t)
	t.start()

func _process(delta: float) -> void:
	if GameManager.state == Enums.State.MISSION and not transitioning:
		target.y += StatManager.get_stat("thruster_speed").value * delta + \
			(GameManager.powerup_modifiers[Powerup.PowerupType.SPEED_BOOST]) * delta
	elif transitioning:
		target.y += delta * TRANSITION_SPEED
	else:
		target = home
	
	position += (target - position) * delta * SPEED
	
	if !GameManager.endless:
		if $Kruos/KruosPassOver.global_position.y >= -get_viewport_rect().size.y and not transitioning and GameManager.planet != Enums.Planet.KRUOS:
			transitioning = true
			GameManager.music_changed.emit(Enums.Planet.KRUOS)
		elif transitioning and position.y > positions[Enums.Planet.KRUOS].y - get_viewport_rect().size.y + PLANET_BUFFER:
			transitioning = false
			GameManager.planet_changed.emit(Enums.Planet.KRUOS)
			GameManager.state_changed.emit(Enums.State.HOME)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	else:
		$Kruos.visible = false
