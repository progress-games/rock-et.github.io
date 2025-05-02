extends Node2D

@export var mineral: GameManager.Mineral
@export var mineral_texture: Texture2D

func _ready() -> void:
	GameManager.add_mineral.connect(
		func (_mineral, _amt):
			$Score.text = str(GameManager.player.get_mineral(mineral))
	)
