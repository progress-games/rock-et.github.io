extends Node2D
## Audio manager node. Inteded to be globally loaded as a 2D Scene. Handles [method create_2d_audio_at_location()] and [method create_audio()] to handle the playback and culling of simultaneous sound effects.
##
## To properly use, define [enum SoundEffect.SOUND_EFFECT_TYPE] for each unique sound effect, create a Node2D scene for this AudioManager script add those SoundEffect resources to this globally loaded script's [member sound_effects], and setup your individual SoundEffect resources. Then, use [method create_2d_audio_at_location()] and [method create_audio()] to play those sound effects either at a specific location or globally.
## 
## See https://github.com/Aarimous/AudioManager for more information.
##
## @tutorial: https://www.youtube.com/watch?v=Egf2jgET3nQ

var sound_effect_dict: Dictionary = {} ## Loads all registered SoundEffects on ready as a reference.

@export var sound_effects: Array[SoundEffect] ## Stores all possible SoundEffects that can be played.
var muted: Array[SoundEffect.SOUND_EFFECT_TYPE] = []

signal sfx_muted(sfx: SoundEffect.SOUND_EFFECT_TYPE, m: bool)

func _ready() -> void:
	for sound_effect: SoundEffect in sound_effects:
		sound_effect.unmuted_limit = sound_effect.limit
		sound_effect_dict[sound_effect.type] = sound_effect

## Creates a sound effect if the limit has not been reached. Pass [param type] for the SoundEffect to be queued.
func create_audio(type: SoundEffect.SOUND_EFFECT_TYPE) -> void:
	if !is_inside_tree(): return
	if SaveManager.loading_save: return
	if muted.has(type): return
	if sound_effect_dict.has(type):
		var sound_effect: SoundEffect = sound_effect_dict[type]
		if sound_effect.has_open_limit():
			sound_effect.change_audio_count(1)
			var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
			add_child(new_audio)
			new_audio.set_meta("sfx_type", type)
			new_audio.stream = sound_effect.sound_effect
			
			
			var v = Settings.get_setting(Settings.SettingType.SFX_VOLUME)
			v -= 40
			if v > 0: v = pow(v, 0.6)
			v += sound_effect.volume
			
			new_audio.volume_db = v
			
			new_audio.pitch_scale = sound_effect.pitch_scale
			new_audio.pitch_scale += randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness )
			new_audio.finished.connect(sound_effect.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)
			new_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", type)

func toggle_mute_audio(sfx: SoundEffect.SOUND_EFFECT_TYPE) -> void:
	sfx_muted.emit(sfx, !muted.has(sfx))
	if muted.has(sfx): muted.erase(sfx)
	else: muted.append(sfx)

func stop_audio(sfx: SoundEffect.SOUND_EFFECT_TYPE) -> void:
	get_children().map(func (x: AudioStreamPlayer): 
		if x.has_meta("sfx_type") and x.get_meta("sfx_type") == sfx: 
			x.stop())
