extends Node2D

enum PanelFocus {
	TOPAZ,
	KYANITE
}

const LIGHTNING_PANEL = preload("uid://qr1jpc5o752g")
const STRENGTH_PANEL = preload("uid://kwjm251d3cmd")
const UNLOCKED_KYANITE = preload("uid://ccyoq45doduqy")

@onready var topaz: TextureButton = $Topaz
@onready var kyanite: TextureButton = $Kyanite
@onready var current_panel: Sprite2D =  $Panel

func _ready() -> void:
	select_panel(PanelFocus.TOPAZ)
	GameManager.clear_inventory.emit()
	
	topaz.mouse_entered.connect(func (): on_hover(topaz))
	topaz.mouse_exited.connect(func (): off_hover(topaz))
	topaz.pressed.connect(func (): select_panel(PanelFocus.TOPAZ))
	
	kyanite.mouse_entered.connect(func (): on_hover(kyanite))
	kyanite.mouse_exited.connect(func (): off_hover(kyanite))
	
	GameManager.player.mineral_discovered.connect(
		func (m: Enums.Mineral):
			if m == Enums.Mineral.KYANITE:
				select_panel(PanelFocus.KYANITE)
				kyanite.pressed.connect(func (): select_panel(PanelFocus.KYANITE))
				kyanite.texture_normal = UNLOCKED_KYANITE
				kyanite.material.set_shader_parameter("width", 1)
				kyanite.material.set_shader_parameter("color", Color(0.984, 1.0, 0.525, 1.0))
				kyanite.mouse_entered.connect(func (): 
					kyanite.material.set_shader_parameter("color", Color(1, 1, 1)), CONNECT_ONE_SHOT)
	)

func on_hover(b: TextureButton) -> void:
	b.material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover(b: TextureButton) -> void:
	b.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func select_panel(p: PanelFocus) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	
	var new_panel = (LIGHTNING_PANEL if p == PanelFocus.KYANITE else STRENGTH_PANEL).instantiate()
	new_panel.position = current_panel.position
	current_panel.queue_free()
	add_child(new_panel)
	current_panel = new_panel
	
	GameManager.clear_inventory.emit()
	GameManager.show_mineral.emit(Enums.Mineral.KYANITE if p == PanelFocus.KYANITE else Enums.Mineral.TOPAZ)
	
	var t = create_tween()
	t.tween_property(current_panel, "scale", Vector2.ONE * 1.1, 0.1)
	t.tween_property(current_panel, "scale", Vector2.ONE * 0.9, 0.08)
	t.tween_property(current_panel, "scale", Vector2.ONE, 0.025)
	
	
