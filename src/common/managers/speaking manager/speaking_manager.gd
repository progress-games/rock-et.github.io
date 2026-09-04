extends Node

const TALKING_INTERVAL := 0.1
const PITCH_SCALE := 1.3

enum Person {
	JACK,
	LISHAN,
	AYI,
	BLEEG,
	
	CLICKY,
	SHIKOBA,
	EGG,
	ELF
}

@export var dialogue: Array[AudioStream]

@export var effects: Dictionary[Person, DialogueEffects]

var currently_playing: AudioStreamPlayer2D
var playing_timer: Timer
var muted: bool = false

func _ready() -> void:
	Settings.setting_updated.connect(
		func (s, v):
			if s == Settings.SettingType.MUTE_DIALOGUE:
				muted = v
	)

func start_talking(person: Person) -> void:
	if SaveManager.loading_save || muted: return
	currently_playing = AudioStreamPlayer2D.new()
	currently_playing.bus = &"Dialogue"
	currently_playing.pitch_scale = effects.get(person).speed
	
	var v = Settings.get_setting(Settings.SettingType.SFX_VOLUME)
	if v > 0: v = pow(v, 0.6)
	currently_playing.volume_db = v + 5
	
	add_child(currently_playing)
	
	var pitch_shift: AudioEffectPitchShift = AudioServer.get_bus_effect(3, 0)
	pitch_shift.pitch_scale = effects.get(person).pitch
	
	currently_playing.stream = dialogue.pick_random()
	currently_playing.play()
	
	if playing_timer != null:
		playing_timer.stop()
	playing_timer = Timer.new()
	playing_timer.timeout.connect(
		func ():
			currently_playing.stream = dialogue.pick_random()
			currently_playing.play()
	)
	add_child(playing_timer)
	playing_timer.start(effects.get(person).interval)

func stop_talking() -> void:
	if playing_timer != null:
		playing_timer.stop()
		playing_timer.queue_free()
	
	if currently_playing != null:
		currently_playing.queue_free()
