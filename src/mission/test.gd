extends Area2D

func _ready() -> void:
	tree_exited.connect(func (): print_stack())
