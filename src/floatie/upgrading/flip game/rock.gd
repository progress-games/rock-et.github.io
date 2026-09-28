extends TextureButton
class_name FlipRock

const ROCKS = [
	preload("uid://bth0wmhvyokb6"),
	preload("uid://d0omnmaxy07x4"),
	preload("uid://dogf8qc1g87mk")
	
]

var has_nothing: bool = false
var drone_type: DroneEnums.DroneType
var scale_tween: Tween

var max_hits: float = 5.
var hits: float = max_hits

@onready var drone: TextureRect = $Drone
@onready var reward: GPUParticles2D = $Drone/Reward

func _ready() -> void:
	material = material.duplicate()
	texture_normal = ROCKS.pick_random()
	mouse_entered.connect(hover)
	mouse_exited.connect(off_hover)
	
	drone.visible = !has_nothing
	drone.modulate = Color(1, 1, 1, 0.3)
	reward.emitting = false
	if !has_nothing:
		drone.texture = DroneManager.get_drone_sprite(drone_type)

func hover() -> void:
	material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.PICKAXE)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover() -> void:
	material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func hit(damage: float) -> void:
	if hits <= 0:
		return
	
	scale = Vector2.ONE * 1.5
	
	if scale_tween != null:
		scale_tween.kill()
	
	scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.5)
	hits -= snappedf(damage, .1)
	
	material.set_shader_parameter("progress", hits / max_hits)
	
	if hits <= 0.:
		break_rock()

func break_rock() -> void:
	var t = create_tween()
	t.tween_property(self, "self_modulate", Color.TRANSPARENT, 0.3)
	material.set_shader_parameter("modulate", Color.TRANSPARENT)
	drone.visible = !has_nothing
	reward.emitting = !has_nothing
	drone.modulate = Color.WHITE
	drone.tooltip_text = DroneEnums.DroneType.find_key(drone_type).to_lower()
