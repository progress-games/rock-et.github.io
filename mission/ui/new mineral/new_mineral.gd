extends Control

@export var mineral: GameManager.Mineral
@export var mineral_colour: Color

func _ready() -> void:
	$MineralName.material = $MineralName.material.duplicate()
	$MineralName.material.set_shader_parameter("colour", mineral_colour)

	GameManager.player.mineral_discovered.connect(func (mineral):
		visible = true
		mineral = mineral
		mineral_colour = Color("a884f3")
		GameManager.set_mouse_state.emit(GameManager.MouseState.NEW_MINERAL)
	)
	
	GameManager.hide_discovery.connect(func (): visible = false)


func _on_visibility_changed() -> void:
	if visible: 
		GameManager.pause.emit()
