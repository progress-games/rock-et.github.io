extends Node2D

const BASE_DB := -10
const FADED_DB := -80

const PITCH_CHANGE_DUR = 1.;
const FADE_DUR = 1;

@export var music: Dictionary[Enums.Planet, AudioStreamMP3]
@export var background_eq: AudioEffectEQ

# states that we shouldnt play the music slightly muffled
@export var non_background_states: Array[Enums.State]
@export var mission_pitch: float
@export var fade_time: float 

var pitch_tween: Tween
var volume1_tween: Tween
var volume2_tween: Tween

@onready var main_music: AudioStreamPlayer = $Music
# yeah yeah yeah fuck you
@onready var ambience: AudioStreamPlayer2D = $"../Background/Dyrt/Ground/Ambience"

func _ready() -> void:
	AudioServer.add_bus_effect(1, background_eq)
	AudioServer.add_bus_effect(2, background_eq)
	
	GameManager.state_changed.connect(state_changed)
	GameManager.music_changed.connect(planet_changed)
	Settings.setting_updated.connect(volume_changed)

func get_vol(v: int, s: Settings.SettingType = Settings.SettingType.MUSIC_VOLUME) -> int:
	v -= 40 if s == Settings.SettingType.AMBIENCE_VOLUME else 50
	if v > 0: v = int(pow(v, 0.6))
	v += BASE_DB
	return v

func volume_changed(s, v) -> void:
	if s == Settings.SettingType.MUSIC_VOLUME: main_music.volume_db = get_vol(v)
	if s == Settings.SettingType.AMBIENCE_VOLUME: ambience.volume_db = get_vol(v, s)

func state_changed(s: Enums.State) -> void:
	AudioServer.set_bus_effect_enabled(1, 0, s not in non_background_states)
	AudioServer.set_bus_effect_enabled(2, 0, s not in non_background_states)
	
	if s == Enums.State.MISSION:
		if pitch_tween: pitch_tween.kill()
		pitch_tween = create_tween()
		pitch_tween.tween_property(main_music, "pitch_scale", mission_pitch, PITCH_CHANGE_DUR).set_trans(Tween.TRANS_LINEAR)
	elif main_music.pitch_scale > 1:
		if pitch_tween: pitch_tween.kill()
		pitch_tween = create_tween()
		pitch_tween.tween_property(main_music, "pitch_scale", 1, PITCH_CHANGE_DUR / 2).set_trans(Tween.TRANS_LINEAR)

func planet_changed(p: Enums.Planet) -> void:
	if volume1_tween: volume1_tween.kill()
	if volume2_tween: volume2_tween.kill()
	
	var off_music: AudioStreamPlayer = $Music2 if main_music == $Music else $Music
	off_music.stream = music[p]
	off_music.play()
	
	volume1_tween = create_tween()
	volume1_tween.tween_property(main_music, "volume_db", FADED_DB, FADE_DUR).set_trans(Tween.TRANS_LINEAR)
	volume1_tween.finished.connect(main_music.stop)
	
	volume2_tween = create_tween()
	volume2_tween.tween_property(off_music, "volume_db", 
		get_vol(Settings.get_setting(Settings.SettingType.MUSIC_VOLUME)), 
		FADE_DUR).set_trans(Tween.TRANS_LINEAR)
	
	main_music = off_music
