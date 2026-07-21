extends Control
class_name GameComplete

var clicked = {
	"feedback": false,
	"steam": false
}

@onready var completed_days: Label = $Calendar/Day
@onready var endless: TextureButton = $Endless

@onready var wishlist: TextureButton = $Wishlist
@onready var feedback: TextureButton = $Feedback

@onready var feedback_pipe: Sprite2D = $FeedbackPipe
@onready var wishlist_pipe: Sprite2D = $WishlistPipe

const YES_WISHLIST = preload("uid://kahylbfhbpr0")
const YES_FEEDBACK = preload("uid://bcdeoxggytvtc")

func _ready() -> void:
	visibility_changed.connect(reveal)
	
	wishlist.mouse_entered.connect(func (): hover(wishlist))
	wishlist.mouse_exited.connect(func (): off_hover(wishlist))
	wishlist.pressed.connect(func (): 
		wishlist_pipe.texture = YES_WISHLIST
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MINERAL_DEPOSIT)
		OS.shell_open("https://store.steampowered.com/app/4214860/rocket/"))
	
	feedback.mouse_entered.connect(func (): hover(feedback))
	feedback.mouse_exited.connect(func (): off_hover(feedback))
	feedback.pressed.connect(func (): 
		feedback_pipe.texture = YES_FEEDBACK
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MINERAL_DEPOSIT)
		OS.shell_open(GameManager.FEEDBACK_LINK))
	
	endless.mouse_entered.connect(func (): hover(endless))
	endless.mouse_exited.connect(func (): off_hover(endless))
	endless.pressed.connect(init_endless)

func reveal() -> void:
	completed_days.text = str(GameManager.day)

func hover(b: TextureButton) -> void:
	b.material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover(b: TextureButton) -> void:
	b.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func init_endless() -> void:
	if feedback_pipe.texture != YES_FEEDBACK || wishlist_pipe.texture != YES_WISHLIST: return
	GameManager.planet_changed.emit(Enums.Planet.DYRT)
	GameManager.endless = true
	get_tree().paused = false
	hide()
	
