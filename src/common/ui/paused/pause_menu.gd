extends Control

@onready var resume: Button = $VBoxContainer/HBoxContainer/Resume
@onready var settings: Button = $VBoxContainer/HBoxContainer/Settings
@onready var abort: Button = $VBoxContainer/HBoxContainer/Abort

@onready var quit: TextureButton = $VBoxContainer/Quit

@onready var settings_panel: Control = $Settings

func _ready() -> void:
	resume.pressed.connect(
		func ():
			GameManager.play.emit()
			hide()
			position.x = -160
	)
	
	abort.pressed.connect(
		func ():
			GameManager.play.emit()
			hide()
			GameManager.mission_aborted.emit()
	)
	
	settings.pressed.connect(
		func ():
			var t = create_tween()
			t.tween_property(self, "position:x", position.x - 320, 0.2)
	)
	
	settings_panel.return_pressed.connect(
		func ():
			var t = create_tween()
			t.tween_property(self, "position:x", position.x + 320, 0.2)
	)
	
	quit.pressed.connect(func (): SaveManager.store_save(); get_tree().quit())
