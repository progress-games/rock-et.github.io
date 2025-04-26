extends Label

func _ready() -> void:
	GameManager.add_mineral.connect(_add_mineral)
	_add_mineral()

func _add_mineral(_mineral: GameManager.Mineral = GameManager.Mineral.AMETHYST, _amount: int = 0) -> void:
	text = str(GameManager.player.get_mineral(GameManager.Mineral.AMETHYST))
