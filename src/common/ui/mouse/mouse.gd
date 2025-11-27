extends Node2D

var sprites := {
	"default": preload("res://common/ui/mouse/default.png"),
	"disabled": preload("res://common/ui/mouse/disabled.png"),
	"hover": preload("res://common/ui/mouse/hover.png"),
	"new_mineral": preload("res://common/ui/mouse/new_mineral.png")
}

var state := Enums.MouseState.DEFAULT
var prev_state := Enums.MouseState.DEFAULT
var holding_progress: float = 0;

const NEW_MINERAL_HOLD = 1;

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	GameManager.set_mouse_state.connect(set_state)
	set_state(state)

func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	
	if state == Enums.MouseState.HOLDING and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		holding_progress += delta
		$ColorRect.material.set_shader_parameter("progress", holding_progress / NEW_MINERAL_HOLD)
		if holding_progress >= NEW_MINERAL_HOLD:
			set_state(prev_state)
			GameManager.finished_holding.emit()
	else:
		holding_progress = max(0, holding_progress - delta * 3)
		$ColorRect.material.set_shader_parameter("progress", holding_progress / NEW_MINERAL_HOLD)

func set_state(new_state: Enums.MouseState) -> void:
	# cant leave holding unless fully held
	if state == Enums.MouseState.HOLDING and holding_progress < NEW_MINERAL_HOLD:
		return
	
	prev_state = state
	state = new_state
	$Sprite.visible = true
	$ColorRect.visible = false
	$HitBox.visible = false
	
	if GameManager.state == Enums.State.MISSION and state != Enums.MouseState.HOLDING:
		state = Enums.MouseState.MISSION
	
	match state:
		Enums.MouseState.DEFAULT:
			$Sprite.texture = sprites.default
		Enums.MouseState.HOVER:
			$Sprite.texture = sprites.hover
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER_POP)
		Enums.MouseState.DISABLED:
			$Sprite.texture = sprites.disabled
		Enums.MouseState.HOLDING:
			$Sprite.texture = sprites.new_mineral
			$ColorRect.visible = true
			holding_progress = 0
		Enums.MouseState.MISSION:
			$Sprite.visible = false
			$HitBox.new_mission()
