extends Node2D

var sprites := {
	"default": preload("res://common/ui/mouse/default.png"),
	"disabled": preload("res://common/ui/mouse/disabled.png"),
	"hover": preload("res://common/ui/mouse/hover.png")
}

@onready var hit_box: HitBox = $HitBox
@onready var color_rect: ColorRect = $ColorRect
@onready var sprite: Sprite2D = $Sprite

@export var offsets: Dictionary[Enums.MouseState, Vector2]

var state := Enums.MouseState.DEFAULT
var prev_state := Enums.MouseState.DEFAULT

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	GameManager.set_mouse_state.connect(set_state)
	set_state(state)

func _process(_dt: float) -> void:
	global_position = get_global_mouse_position()

func set_state(new_state: Enums.MouseState) -> void:
	if GameManager.state == Enums.State.MISSION and new_state != Enums.MouseState.MISSION:
		return
	
	prev_state = state
	state = new_state
	sprite.visible = true
	color_rect.visible = false
	hit_box.visible = false
	
	sprite.offset = offsets.get(state, Vector2.ZERO)
	
	if prev_state == Enums.MouseState.MISSION:
		hit_box.mission_ended()
	
	match state:
		Enums.MouseState.DEFAULT:
			sprite.texture = sprites.default
		Enums.MouseState.HOVER:
			sprite.texture = sprites.hover
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		Enums.MouseState.DISABLED:
			sprite.texture = sprites.disabled
		Enums.MouseState.MISSION:
			sprite.visible = false
			hit_box.visible = true
			hit_box.new_mission()
