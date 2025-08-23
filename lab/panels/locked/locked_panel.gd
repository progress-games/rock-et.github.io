extends Node2D

@export var mineral: Enums.Mineral

func _ready() -> void:
	$Mineral.texture = GameManager.MINERAL_TEXTURES[mineral]
