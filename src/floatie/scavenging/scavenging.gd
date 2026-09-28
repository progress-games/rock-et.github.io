extends Control

const PRICE_OFF_HOVER := 105
const PRICE_ON_HOVER := 170

const BASE_PERCENT_POS := 162
const PERCENT_WIDTH := BASE_PERCENT_POS - 46

@onready var scavenge: TextureButton = $Scavenge
#@onready var progress: Panel = $Progress
#@onready var progress_bar: Panel = $Progress/Progress
#@onready var percent: Label = $Progress/Percent

@onready var rock_breaking: Control = $RockBreaking

var scavenges_left := 1
var scavenge_timer := -1.
var scavenging := false

func _ready() -> void:
	scavenge.mouse_entered.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		scavenge.material.set_shader_parameter("width", 1))
	
	scavenge.mouse_exited.connect(
		func ():
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
			scavenge.material.set_shader_parameter("width", 0)
	)
	
	scavenge.pressed.connect(start_scavenge)
	
	GameManager.day_changed.connect(
		func (_d):
			scavenge.disabled = false
			scavenges_left = int(ceil(StatManager.get_stat("daily_scavenges").value))
	)
	
	StatManager.get_stat("daily_scavenges").upgraded.connect(
		func ():
			scavenge.disabled = false
			scavenges_left += 1
	)

func start_scavenge() -> void:
	if scavenges_left <= 0: return
	
	rock_breaking.reset()
	scavenges_left -= 1
	scavenge.disabled = scavenges_left <= 1
	
	#scavenge.hide()
	#progress.show()
	#scavenge_timer = StatManager.get_stat("scavenge_duration").value
	#scavenging = true
	#scavenges_left -= 1
	#AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SCAVENGING)
	#
	#if scavenges_left <= 0: scavenge.disabled = true

func end_scavenge() -> void:
	scavenge.show()
	#progress.hide()
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.FINISHED_SCAVENGE)
	
	#reward.load_reward(choose_reward())
	scavenging = false

#func _process(delta: float) -> void:
	#if scavenge_timer <= 0 && scavenging:
		#end_scavenge()
	#elif scavenge_timer > 0 && scavenging:
		#scavenge_timer -= delta
		#var p = (1 - (scavenge_timer / StatManager.get_stat("scavenge_duration").value))
		#progress_bar.material.set_shader_parameter("progress", p * 1.2 - 0.1)
		#percent.text = str(round(1000 * p) / 10.) + "%"
		#percent.position.y = BASE_PERCENT_POS - p * PERCENT_WIDTH
