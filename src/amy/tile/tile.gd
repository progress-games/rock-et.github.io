extends TextureButton
class_name DroneTile

enum State {
	HIDDEN,
	SHOWN,
	UNLOCKED
}

const DAMAGE = preload("uid://bau682i5cceb2")
const MINIMUM_SIZE = Vector2(22, 22)

var drone_effect: DroneEnums.DroneEffect
var unlocked := false
var shown := false

var rotate := false
var selected_rotation := 0.

@onready var symbol: TextureRect = $Symbol
@onready var huh: Label = $Huh

func _ready() -> void:
	custom_minimum_size = MINIMUM_SIZE
	material = material.duplicate()
	mouse_entered.connect(hover)
	mouse_exited.connect(off_hover)

func hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	material.set_shader_parameter("width", 1)

func off_hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	if !rotate:
		material.set_shader_parameter("width", 0)

func select() -> void:
	material.set_shader_parameter("dash_width", 0.167)
	material.set_shader_parameter("width", 1)
	rotate = true

func deselect() -> void:
	rotate = false
	material.set_shader_parameter("dash_width", 1.)
	material.set_shader_parameter("width", 0)
	material.set_shader_parameter("rotation", 0)

func _process(delta: float) -> void:
	if !rotate: return
	selected_rotation += delta * 1.2
	material.set_shader_parameter("rotation", selected_rotation)

func set_state(state: State) -> void:
	if drone_effect == DroneEnums.DroneEffect.EMPTY_TILE:
		return
	
	match state:
		State.HIDDEN:
			modulate = Color(1, 1, 1, 0.3)
			symbol.hide()
			huh.show()
		State.SHOWN:
			shown = true
			modulate = Color(1, 1, 1, 0.5)
			huh.hide()
			symbol.show()
		State.UNLOCKED:
			shown = true
			unlocked = true
			modulate = Color(1, 1, 1)
			custom_minimum_size = MINIMUM_SIZE * 3
			huh.hide()
			symbol.show()
			var t = create_tween()
			t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			t.tween_property(self, "custom_minimum_size", MINIMUM_SIZE, 1)

func set_effect(new_effect: DroneEnums.DroneEffect) -> void:
	drone_effect = new_effect
	set_meta("effect", drone_effect)
	
	if drone_effect == DroneEnums.DroneEffect.EMPTY_TILE:
		symbol.hide()
		huh.hide()
		disabled = true
		texture_normal = null
		return
	
	if DroneManager.drone_effects.has(new_effect):
		symbol.texture = DroneManager.drone_effects.get(new_effect).texture
	set_state(State.HIDDEN)
