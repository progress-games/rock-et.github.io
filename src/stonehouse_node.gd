extends TextureButton
class_name StonehouseNode

const UNLOCK_SIZE := Vector2(16, 16)
const BASE_SIZE := Vector2(12, 12)

const PRICES := [
	1
]

"""
each node has a price which we'll set manually
each node has a bounce effect type and stat type
each bounce effect has stats plus an "unlock" stat which uses the bigger icon
each bounce effect has a colour for the circle


so each node just needs to know:
	bounce effect
	stat type
	price

then it'll be able to choose the correct sprite, colour, desc, etc from that


"""

@export var effect_type: BounceEffectManager.BounceEffect
@export var stat_type: BounceEffectManager.StatType
@export var depth: int
@export var amount: float

var price: int:
	get():
		return PRICES[depth]

@export var dependencies: Array[StonehouseNode]
var next_nodes: Array[StonehouseNode]

var unlocked: bool = false

@onready var glow: Sprite2D = $Glow

signal node_unlocked

func _ready() -> void:
	dependencies.map(func (node): node.next_nodes.append(self))
	
	if stat_type == BounceEffectManager.StatType.UNLOCK:
		texture_normal = BounceEffectManager.get_unlock_sprite(effect_type)
		size = UNLOCK_SIZE
		glow.modulate.a += 0.1
	else:
		texture_normal = BounceEffectManager.get_stat_sprite(stat_type)
		size = BASE_SIZE
		
	material = material.duplicate()
	material.set_shader_parameter("replacement_colors", [BounceEffectManager.get_colour(effect_type)])

func _on_mouse_entered() -> void:
	material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	unlock()

func _on_mouse_exited() -> void:
	material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func unlock() -> void:
	unlocked = true
	BounceEffectManager.upgrade_stat(effect_type, stat_type, amount)
	node_unlocked.emit()
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "rotation_degrees", [-1, 1].pick_random() * 45, 0.05)
	t.tween_property(self, "rotation_degrees", 0, 0.3)
	
	var s = create_tween()
	s.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	s.tween_property(self, "scale", Vector2.ONE * 1.4, 0.05)
	s.tween_property(self, "scale", Vector2.ONE, 0.3)
