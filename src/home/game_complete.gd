extends Control
class_name GameComplete

var clicked = {
	"feedback": false,
	"steam": false
}

@onready var completed_days: RichTextLabel = $RichTextLabel
@onready var endless: Button = $Endless/Endless

func _ready() -> void:
	visibility_changed.connect(reveal)

func reveal() -> void:
	completed_days.text.replace("DAYS", str(GameManager.day))

func link_clicked(s) -> void:
	clicked.set(s, true)
	endless.disabled = !clicked.values().all(func (x): return x)

func hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func init_endless() -> void:
	GameManager.planet_changed.emit(Enums.Planet.DYRT)
	GameManager.endless = true
	get_tree().paused = false
	hide()
