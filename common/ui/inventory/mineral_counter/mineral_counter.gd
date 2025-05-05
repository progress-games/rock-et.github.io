extends Node2D

const GAP := 2

@export var mineral: GameManager.Mineral

func _ready() -> void:
	$Mineral.texture = GameManager.MINERAL_TEXTURES.get(mineral)
	GameManager.add_mineral.connect(update_text)

func update_text(_mineral: GameManager.Mineral, _amt) -> void:
	if _mineral == mineral:
		$Score.text = CustomMath.format_number_short(GameManager.player.get_mineral(mineral))
	
func get_width() -> float:
	return $Mineral.texture.get_size().x + GAP + $Score.get_minimum_size().x
