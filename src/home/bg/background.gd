extends Node2D

const BLIZZARD_AUDIO := preload("uid://gci72p7bd82e")

@export var state_positions: Dictionary[Enums.State, Vector2] = {}
@export var planet_positions: Dictionary[Enums.Planet, Vector2] = {}
@export var transition_positions: Dictionary[Enums.Planet, Vector2] = {}

@onready var blur: ColorRect = $Kruos/StateButtons/Blur
@onready var snow: CPUParticles2D = $Kruos/Kruos/Snow
@onready var lines: CPUParticles2D = $Kruos/Kruos/Lines
@onready var kruos_blizzard: Sprite2D = $Kruos/Kruos/KruosBlizzard
@onready var clouds: CPUParticles2D = $Kruos/Kruos/Clouds

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
	GameManager.boost.connect(func (amount):
		target.y += GameManager.DISTANCES[GameManager.planet] * amount
	)
	
	GameManager.state_changed.connect(
		func (s):
			if s == Enums.State.MISSION:
				target = planet_positions[GameManager.planet] + state_positions[s]
				hide_blizzard()
				end_blizzard_audio()
			elif s == Enums.State.HOME:
				target = planet_positions[GameManager.planet] + state_positions[s]
	)
	
	GameManager.planet_changed.connect(
		func (p: Enums.Planet):
			target = planet_positions[p]
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
			(GameManager.current_click_boost) * delta
	elif transitioning:
		target.y += delta * TRANSITION_SPEED
	
	position += (target - position) * delta * SPEED
	
	if !GameManager.endless && GameManager.state == Enums.State.MISSION:
		check_for_transition()
	elif GameManager.endless:
		$Kruos.visible = false

func check_for_transition() -> void:
	var next_planet = GameManager.planet + 1
	var pos = transition_positions[GameManager.planet + 1]
	if position.y > pos.y && !transitioning:
		transitioning = true
		GameManager.music_changed.emit(next_planet)
	elif transitioning && position.y > planet_positions[GameManager.planet + 1].y:
		transitioning = false
		GameManager.planet_changed.emit(next_planet)
		GameManager.state_changed.emit(Enums.State.HOME)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
