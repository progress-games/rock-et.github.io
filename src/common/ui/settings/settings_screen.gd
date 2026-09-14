extends Control

@onready var quit: TextureButton = $Quit
@onready var close_tab: TextureButton = $CloseTab
@onready var reset: Button = $Reset

@onready var panels: Dictionary[String, MarginContainer] = {
	"sound": $Settings/MarginContainer/Sound,
	"display": $Settings/MarginContainer/Display,
	"input": $Settings/MarginContainer/Input,
	"gameplay": $Settings/MarginContainer/Gameplay
}

var prev_state: Enums.State = Enums.State.HOME

func _ready() -> void:
	quit.mouse_entered.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		quit.material.set_shader_parameter("width", 1))
	
	quit.mouse_exited.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		quit.material.set_shader_parameter("width", 0))
	
	quit.pressed.connect(get_tree().quit)
	reset.pressed.connect(Settings.reset_settings)

func change_panel(p: String) -> void:
	panels.values().map(func (x): x.hide())
	panels[p].show()
