extends Control

@export var show_close_tab: bool = true

@onready var close_tab: TextureButton = $CloseTab
@onready var reset: Button = $Reset
@onready var quit: TextureButton = $Settings/Quit

@onready var panels: Dictionary[String, MarginContainer] = {
	"sound": $Settings/MarginContainer/Sound,
	"display": $Settings/MarginContainer/Display,
	"input": $Settings/MarginContainer/Input,
	"gameplay": $Settings/MarginContainer/Gameplay
}
@onready var return_button: Button = $Return

var prev_state: Enums.State = Enums.State.HOME
const DEFAULT_THEME = preload("uid://cr6q3vlvjjgb7")

signal return_pressed

func _ready() -> void:
	quit.mouse_entered.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		quit.material.set_shader_parameter("width", 1))
	
	quit.mouse_exited.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		quit.material.set_shader_parameter("width", 0))
	
	quit.pressed.connect(func (): SaveManager.store_save(); get_tree().quit())
	reset.pressed.connect(Settings.reset_settings)
	
	close_tab.visible = show_close_tab
	return_button.visible = !show_close_tab
	quit.visible = show_close_tab
	return_button.pressed.connect(return_pressed.emit)

func change_panel(p: String) -> void:
	panels.values().map(func (x): x.hide())
	panels[p].show()
