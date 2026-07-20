extends Control

enum Focus {
	BAR,
	WHEEL
}

@export var selected_positions: Dictionary[Focus, Vector2]

@onready var selected_focus: Control = $Bar
@onready var bar: Control = $Bar
@onready var wheel: Control = $Wheel
@onready var bar_tab: TextureButton = $Tabs/Bar
@onready var wheel_tab: TextureButton = $Tabs/Wheel
@onready var tabs: Control = $Tabs
@onready var selected: Sprite2D = $Tabs/Selected

func _ready() -> void:
	bar_tab.mouse_entered.connect(func (): on_hover(bar_tab))
	bar_tab.mouse_exited.connect(func (): off_hover(bar_tab))
	bar_tab.pressed.connect(func (): update_focus(Focus.BAR))
	
	wheel_tab.mouse_entered.connect(func (): on_hover(wheel_tab))
	wheel_tab.mouse_exited.connect(func (): off_hover(wheel_tab))
	wheel_tab.pressed.connect(func (): update_focus(Focus.WHEEL))
	
	tabs.visibility_changed.connect(func (): update_focus(Focus.WHEEL), CONNECT_ONE_SHOT)

func on_hover(b: TextureButton) -> void:
	b.material.set_shader_parameter("width", 1)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func off_hover(b: TextureButton) -> void:
	b.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func update_focus(f: Focus) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.POP)
	
	selected_focus.visible = false
	
	selected_focus = bar if f == Focus.BAR else wheel
	selected_focus.visible = true
	
	var t = create_tween()
	t.tween_property(selected_focus, "scale", Vector2.ONE * 1.15, 0.1)
	t.tween_property(selected_focus, "scale", Vector2.ONE * 0.9, 0.1)
	t.tween_property(selected_focus, "scale", Vector2.ONE, 0.1)
	
	selected.position = selected_positions[f]
	
