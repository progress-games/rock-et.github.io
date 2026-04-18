extends TextureButton

@export var state: Enums.State

func _ready() -> void:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(texture_normal.get_image(), 0.5)
	texture_click_mask = bitmap

func _on_pressed() -> void:
	if GameManager.state == Enums.State.MISSION: return 
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SWOOSH)
	
	GameManager.state_changed.emit(state)
	GameManager.show_inventory.emit()
	SaveManager.store_save()

func _on_mouse_entered() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func _on_mouse_exited() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
