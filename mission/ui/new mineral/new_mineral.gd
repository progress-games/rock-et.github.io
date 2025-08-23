extends Control

@export var mineral_colour: Color

func _ready() -> void:
	GameManager.player.mineral_discovered.connect(func (mineral):
		visible = true
		GameManager.set_mouse_state.emit(Enums.MouseState.NEW_MINERAL)
		$MineralName.material = $MineralName.material.duplicate()
		$MineralName.material.set_shader_parameter("colour", GameManager.MINERAL_COLOURS[mineral].primary)
		$NewMineralText.material = $NewMineralText.material.duplicate()
		$NewMineralText.material.set_shader_parameter("colour", GameManager.MINERAL_COLOURS[mineral].secondary)
		$NewMineral.texture = GameManager.MINERAL_TEXTURES.get(mineral)
		# AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.NEW_MINERAL)
		$MineralName.text = Enums.Mineral.find_key(mineral).to_lower()
	)
	
	GameManager.hide_discovery.connect(func (): visible = false)


func _on_visibility_changed() -> void:
	if visible: 
		GameManager.pause.emit()
