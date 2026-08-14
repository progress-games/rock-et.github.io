extends Control

@onready var window: OptionButton = $VBoxContainer/MarginContainer/OptionButton

func _ready() -> void:
	window.item_selected.connect(func (i: int):
		if i == 0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	)
	window.select(0)
