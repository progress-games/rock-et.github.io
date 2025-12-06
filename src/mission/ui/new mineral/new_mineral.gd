extends Control

@export var mineral_colour: Color

func _ready() -> void:
	GameManager.player.mineral_discovered.connect(func (mineral):
		if SaveManager.loading_save: return
		visible = true
		GameManager.set_mouse_state.emit(Enums.MouseState.HOLDING)
		$MineralName.material = $MineralName.material.duplicate()
		$MineralName.material.set_shader_parameter("colour", GameManager.mineral_data[mineral].mid_colour)
		$NewMineralText.material = $NewMineralText.material.duplicate()
		$NewMineralText.material.set_shader_parameter("colour", GameManager.mineral_data[mineral].dark_colour)
		$NewMineral.texture = GameManager.mineral_data[mineral].texture
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.NEW_MINERAL)
		$MineralName.text = Enums.Mineral.find_key(mineral).to_lower()
	)
	
	GameManager.finished_holding.connect(func (): visible = false)


func _on_visibility_changed() -> void:
	if visible: 
		GameManager.pause.emit()
