extends Label

func _ready() -> void:
	GameManager.add_point.connect(_add_point)
	_add_point()

func _add_point(_amount: int = 0) -> void:
	text = str(GameManager.player.points)
