extends Control

enum Focus {
	SCAVENGING,
	UPGRADING
}

@onready var scavenging: TextureButton = $Tabs/Scavenging
@onready var upgrading: TextureButton = $Tabs/Upgrading

@onready var upgrading_panel: Control = $Upgrading
@onready var scavenging_panel: Control = $Scavenging


func _ready() -> void:
	scavenging.mouse_entered.connect(func (): hover(scavenging))
	scavenging.mouse_exited.connect(func (): off_hover(scavenging))
	scavenging.pressed.connect(func (): set_focus(Focus.SCAVENGING))
	upgrading.mouse_entered.connect(func (): hover(upgrading))
	upgrading.mouse_exited.connect(func (): off_hover(upgrading))
	upgrading.pressed.connect(func (): set_focus(Focus.UPGRADING))

func hover(b: TextureButton) -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	b.material.set_shader_parameter("width", 1)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover(b: TextureButton) -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	b.material.set_shader_parameter("width", 0)

func set_focus(f: Focus) -> void:
	scavenging_panel.visible = f == Focus.SCAVENGING
	upgrading_panel.visible = f == Focus.UPGRADING
