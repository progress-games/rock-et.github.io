extends TextureRect

func _ready() -> void:
	if GameManager.zen_mode:
		queue_free()
