extends Area2D

const COMBO_GAP := 1.2

var asteroids = []
var powerups = []

# hitbox multipliers
var mission_scale: Vector2

# multipliers x base size
var box_size: Vector2
var scale_tween: Tween
var using_hitbar: bool
var using_combo: bool
var combo := {
	"timer": 0,
	"amount": 0,
	"max": 0
}
var can_click: bool

const HIT_BAR_GAP := 5;
const HIT_BAR_HEIGHT := 8
const HIT_BAR_SIZE := 20;

# treats each rect as bigger by X on all sides
const RECT_PADDING := 5

@export var mouse_ui: Dictionary[ReferenceRect, MouseUI]

func _ready() -> void:
	GameManager.asteroid_broke.connect(func (): 
		if not using_combo: return
		combo.timer = min(COMBO_GAP, combo.timer + COMBO_GAP)
		combo.amount = min(combo.max, combo.amount + 1)
		GameManager.player.combo_amount = combo.amount
		$Combo/HBoxContainer/ComboAmount.text = "MAX" if combo.amount == combo.max else str(combo.amount) + "x"
	)
	
	GameManager.out_of_clicks.connect(func(): can_click = false)
	
	area_entered.connect(_on_body_entered)
	area_exited.connect(_on_body_exited)

func new_mission() -> void:
	mission_scale = Vector2(
		StatManager.get_stat("hit_size").value,
		StatManager.get_stat("hit_size").value)
	box_size = $CollisionShape.shape.extents * mission_scale
	$CollisionShape.scale = mission_scale
	
	visible = true
	using_hitbar = GameManager.player.has_discovered_state(Enums.State.SCIENTIST) and !GameManager.player.scientist_disabled
	using_combo = GameManager.player.equipped_items.has("combo")
	if using_combo: 
		combo.max = GameManager.player.equipped_items["combo"].get_value("max_combo")
	else:
		GameManager.player.combo_amount = 0
	
	$HitBar.visible = using_hitbar
	$Combo.visible = using_combo
	can_click = true
	
	for rect in mouse_ui.keys():
		update_position(rect, mouse_ui[rect])

func update_position(rect: ReferenceRect, pos_details: MouseUI) -> void:
	match [pos_details.position, pos_details.align]:
		# above, left
		[MouseUI.Pos.ABOVE, MouseUI.Align.LEFT]:
			rect.set_size(Vector2(
				box_size.x * 2 + RECT_PADDING * 2,
				pos_details.size.y
			))
			rect.set_position(position - Vector2(
				box_size.x,
				box_size.y + rect.size.y + RECT_PADDING 
			))
		# above, centre
		[MouseUI.Pos.ABOVE, MouseUI.Align.CENTRE]:
			rect.set_size(Vector2(
				box_size.x * 2 + RECT_PADDING * 2,
				pos_details.size.y
			))
			rect.set_position(position - Vector2(
				rect.size.x / 2,
				box_size.y + rect.size.y + RECT_PADDING 
			))
		# right, centre
		[MouseUI.Pos.RIGHT, MouseUI.Align.CENTRE]:
			rect.set_size(Vector2(
				pos_details.size.x,
				box_size.y * 2 + RECT_PADDING * 2
			))
			rect.set_position(position + Vector2(
				box_size.x + RECT_PADDING,
				- (rect.size.y / 2)
			))
		_:
			pass

func _process(delta: float) -> void:
	var shape = $CollisionShape.shape.extents * $CollisionShape.scale

	$Corners/TopLeft.position = -shape + Vector2(-1, -1)
	$Corners/TopRight.position = Vector2(shape.x, -shape.y) + Vector2(1, -1)
	$Corners/BottomLeft.position = -Vector2(shape.x, -shape.y) + Vector2(-1, 1)
	$Corners/BottomRight.position = shape + Vector2(1, 1)
	
	$ColorRect.position = position - shape
	$ColorRect.size = shape * 2
	
	for rect in mouse_ui.keys():
		var ui = mouse_ui[rect]
		if ui.update_rate > 0:
			ui.current_frame += 1
			if ui.update_rate == ui.current_frame:
				update_position(rect, mouse_ui[rect])
	
	"""
	if !using_hitbar:
		using_hitbar = GameManager.player.has_discovered_state(Enums.State.SCIENTIST) and !GameManager.player.scientist_disabled
		$HitBar.visible = using_hitbar
	"""
	if using_combo:
		$Combo.visible = using_combo and combo.timer > 0
		if using_combo and combo.timer > 0 and !GameManager.paused:
			combo.timer -= delta
			$Combo/HBoxContainer/ComboBarContainer/ComboBar.material.set_shader_parameter("progress", combo.timer / COMBO_GAP)
		else:
			combo.timer = 0
			combo.amount = 0
			GameManager.player.combo_amount = 0

func _on_body_entered(body: Node) -> void:
	if body.has_meta("asteroid"):
		asteroids.append(body)
	elif body.has_meta("mineral"):
		GameManager.collect_mineral.emit(body)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MINERAL_PICKUP)
		body.queue_free()
	elif body.has_meta("powerup"):
		powerups.append(body)

func _on_body_exited(body: Node) -> void:
	if body.has_meta("asteroid"):
		asteroids.erase(body)
	elif body.has_meta("powerup"):
		powerups.erase(body)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if can_click and event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		scale_tween = create_tween()
		$CollisionShape.scale = mission_scale
		
		scale_tween.tween_property($CollisionShape, "scale", mission_scale * 0.7, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property($CollisionShape, "scale", mission_scale, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		if using_hitbar:
			$HitBar.progress = max(0, $HitBar.progress - 0.2)
			GameManager.player.hit_strength = $HitBar.colour
		
		for asteroid in asteroids: 
			GameManager.asteroid_hit.emit(asteroid as Asteroid)
		
		for powerup in powerups:
			GameManager.powerup_hit.emit(powerup as Powerup)
