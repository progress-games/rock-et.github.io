extends Node2D

@export var mineral: GameManager.Mineral

func _ready() -> void:
	$Mineral.texture = GameManager.MINERAL_TEXTURES[mineral]
