extends Control

@onready var quit: TextureButton = $Quit
@onready var close_tab: TextureButton = $CloseTab

@onready var panels: Dictionary[String, MarginContainer] = {
	"sound": $Settings/MarginContainer/Sound,
	"display": $Settings/MarginContainer/Display,
	"input": $Settings/MarginContainer/Input
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

func change_panel(p: String) -> void:
	panels.values().map(func (x): x.hide())
	panels[p].show()

#func change_day(dir: int = 0) -> void:
	#AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	#
	#var d = DirAccess.open("user://")
	#var files = d.get_files()
	#var saves = []
	#for f in files:
		#if !f.contains("day"): continue
		#var s = f.trim_suffix(".save")
		#if SaveManager.save_exists(s):
			#saves.append(int(s))
	#
	#saves.sort()
	#
	#var i = saves.find(day)
	#if i == -1:
		#day = saves.front() if dir > 0 else saves.back()
	#else:
		#day = saves[(i + dir) % saves.size()]
	
#func load_save() -> void:
	#AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	#
	#SaveManager.loading_save = true
	#SaveManager.loading_save = false
#
#func on_hover(_b: String = "") -> void:
	#GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	#AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
#
#func off_hover(_b: String = "") -> void:
	#GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		
