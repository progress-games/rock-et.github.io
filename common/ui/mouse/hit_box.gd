extends Area2D

var asteroids = []
var mission_scale: Vector2
var scale_tween: Tween
var using_hitbar: bool

const HIT_BAR_GAP := 5;
const HIT_BAR_HEIGHT := 8
const HIT_BAR_SIZE := 20;

func new_mission() -> void:
	mission_scale = Vector2(
		GameManager.player.get_stat("hit_size").value,
		GameManager.player.get_stat("hit_size").value)
	
	$CollisionShape.scale = mission_scale
	
	visible = true
	
	using_hitbar = GameManager.player.has_discovered_state(Enums.State.SCIENTIST)
	
	if !using_hitbar:
		$HitBar.visible = false

func _process(delta: float) -> void:
	var shape = $CollisionShape.shape.extents * $CollisionShape.scale

	$Corners/TopLeft.position = -shape + Vector2(-1, -1)
	$Corners/TopRight.position = Vector2(shape.x, -shape.y) + Vector2(1, -1)
	$Corners/BottomLeft.position = -Vector2(shape.x, -shape.y) + Vector2(-1, 1)
	$Corners/BottomRight.position = shape + Vector2(1, 1)
	
	$ColorRect.position = position - shape
	$ColorRect.size = shape * 2
	
	if using_hitbar:
		$HitBar.width = shape.x * 2 + HIT_BAR_SIZE + 2
		$HitBar.position = position - Vector2(
			$HitBar.width / 2, 
			shape.y + HIT_BAR_GAP + HIT_BAR_HEIGHT + 1
		)
	else:
		using_hitbar = GameManager.player.has_discovered_state(Enums.State.SCIENTIST)
		$HitBar.visible = using_hitbar

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

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		scale_tween = create_tween()
		$CollisionShape.scale = mission_scale
		
		scale_tween.tween_property($CollisionShape, "scale", mission_scale * 0.8, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property($CollisionShape, "scale", mission_scale, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		if using_hitbar:
			$HitBar.progress = max(0, $HitBar.progress - 0.2)
			GameManager.player.hit_strength = $HitBar.colour
		
		for asteroid in asteroids: 
			GameManager.mouse_clicked.emit(asteroid)
