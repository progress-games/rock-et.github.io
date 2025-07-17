extends Area2D

var sprites := {
	"default": preload("res://common/ui/mouse/default.png"),
	"disabled": preload("res://common/ui/mouse/disabled.png"),
	"hover": preload("res://common/ui/mouse/hover.png"),
	"new_mineral": preload("res://common/ui/mouse/new_mineral.png")
}

@onready var corners := {
	"top_left": $Corners/TopLeft,
	"top_right": $Corners/TopRight,
	"bottom_left": $Corners/BottomLeft,
	"bottom_right": $Corners/BottomRight
}

var state := GameManager.MouseState.DEFAULT
var prev_state := GameManager.MouseState.DEFAULT
var holding_progress: float = 0;
var scale_tween: Tween
var mission_scale: Vector2
var asteroids = []

const NEW_MINERAL_HOLD = 1;

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	GameManager.set_mouse_state.connect(set_state)
	set_state(state)

func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	
	if state == GameManager.MouseState.NEW_MINERAL and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		holding_progress += delta
		$ColorRect.material.set_shader_parameter("progress", holding_progress / NEW_MINERAL_HOLD)
		if holding_progress >= NEW_MINERAL_HOLD:
			set_state(prev_state)
			GameManager.hide_discovery.emit()
	else:
		holding_progress = max(0, holding_progress - delta * 3)
		$ColorRect.material.set_shader_parameter("progress", holding_progress / NEW_MINERAL_HOLD)
	
	if state == GameManager.MouseState.MISSION:
		_position_corners()

func _position_corners() -> void:
	position = get_global_mouse_position()
	var shape = $CollisionShape.shape.extents * scale
	var corner_scale = (shape.x / 3) / 32

	corners.get("top_left").global_position = position - shape
	corners.get("top_right").global_position = position + Vector2(shape.x, -shape.y)
	corners.get("bottom_left").global_position = position - Vector2(shape.x, -shape.y)
	corners.get("bottom_right").global_position = position + shape

func _on_body_entered(body: Node) -> void:
	if body.has_meta("asteroid"):
		asteroids.append(body)
	elif body.has_meta("mineral"):
		GameManager.collect_mineral.emit(body)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MINERAL_PICKUP)
		body.queue_free()

func _on_body_exited(body: Node) -> void:
	if body.has_meta("asteroid"):
		asteroids.erase(body)

func set_state(new_state: GameManager.MouseState) -> void:
	if state == GameManager.MouseState.HOVER:
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER_POP)
	
	prev_state = state
	state = new_state
	scale = Vector2(1, 1)
	$ColorRect.visible = false
	$CollisionShape.visible = false
	$Sprite.visible = true
	$Corners.visible = false
	
	match state:
		GameManager.MouseState.DEFAULT:
			$Sprite.texture = sprites.default
		GameManager.MouseState.HOVER:
			$Sprite.texture = sprites.hover
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER_POP)
		GameManager.MouseState.DISABLED:
			$Sprite.texture = sprites.disabled
		GameManager.MouseState.NEW_MINERAL:
			$Sprite.texture = sprites.new_mineral
			$ColorRect.visible = true
			$CollisionShape.visible = true
			holding_progress = 0
		GameManager.MouseState.MISSION:
			mission_scale = Vector2(
				GameManager.player.get_stat("hit_size").value,
				GameManager.player.get_stat("hit_size").value)
			scale = mission_scale
			$Corners.visible = true
			$Sprite.texture = sprites.new_mineral
			$CollisionShape.visible = true
			_position_corners()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is not InputEventMouseButton or !event.is_pressed() or event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if state == GameManager.MouseState.MISSION:
		scale_tween = create_tween()
		scale = mission_scale
		
		scale_tween.tween_property(self, "scale", scale * 0.8, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", scale, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		# hit_bar.progress = max(0, hit_bar.progress - 0.2)
		
		for asteroid in asteroids: 
			GameManager.mouse_clicked.emit(asteroid)
