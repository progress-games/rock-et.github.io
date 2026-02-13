extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var hit_bar: ReferenceRect = $HitBar
@onready var combo_amount: Label = $Combo/HBoxContainer/ComboAmount
@onready var combo_rect: ReferenceRect = $Combo
@onready var combo_bar: TextureRect = $Combo/HBoxContainer/ComboBarContainer/ComboBar
@onready var hit_area: ColorRect = $HitArea

# corners
@onready var corners: Node2D = $Corners
@onready var top_left: Sprite2D = $Corners/TopLeft
@onready var bottom_left: Sprite2D = $Corners/BottomLeft
@onready var bottom_right: Sprite2D = $Corners/BottomRight
@onready var top_right: Sprite2D = $Corners/TopRight

@onready var hit_data := HitData.new()

const MISSION_PROGRESS_FLIPPED := preload("uid://b4ad3pys5nyjy")
const DASHES := preload("uid://c8a6gqo5c6piu")
const BLACKHOLE_BORDER := Color(0.18, 0.133, 0.184, 1.0)
const BLACKHOLE_INT := Color("2e222f84")

const EXPLOSION_BORDER := Color(0.682, 0.137, 0.204, 1.0)
const EXPLOSION_INT := Color(0.984, 0.42, 0.114, 0.51)
const EXPLOSION_DUR := 1
const EXPLOSION_FLASH := 0.3
const EXPLOSION_FLASH_FREQ := 3

# treats each rect as bigger by X on all sides
const RECT_PADDING := 5
const COMBO_GAP := 1.2

# hitbox multipliers
var mission_scale: Vector2

# multipliers x base size
var box_size: Vector2
var scale_tween: Tween
var using_hitbar: bool
var using_combo: bool
var combo := {
	"timer": Timer.new(),
	"amount": 0,
	"max": 0
}
var can_click: bool

## autoclicking will use this
var autoclick_timer: Timer

## all non-player effects use this
var duration_timer: Timer

## rotation effect used in blackhole and explosion
var shader_rotation: float

## if the hitbox is being used, eg corners and that.
var using_box: bool = true

## only updates size when this flag is true
var update_size: bool = false

## used because explosion was pissing me the fuck off
var has_triggered: int = 10

@export var mouse_ui: Dictionary[ReferenceRect, MouseUI]
@export var click_effect: ClickEffectManager.ClickType
@export var player_controlled: bool = false
@export var can_pop_powerups: bool
@export var can_spawn_lightning: bool

func _ready() -> void:
	GameManager.out_of_clicks.connect(func(): can_click = false)
	area_entered.connect(_on_body_entered)
	
	for r in mouse_ui: if r == null: mouse_ui.erase(r)
	
	monitoring = true
	monitorable = true
	
	new_mission()

func get_stat(stat_type: ClickEffectManager.StatType) -> float:
	return ClickEffectManager.stats[click_effect][stat_type]

func _set_size(s: float = 1.) -> void:
	if !using_box: push_error("not using a box")
	mission_scale = Vector2(
		StatManager.get_stat("hit_size").value * s,
		StatManager.get_stat("hit_size").value * s
	)
	box_size = collision_shape.shape.extents * mission_scale
	collision_shape.scale = mission_scale

func _new_autoclick_mission() -> void:
	autoclick_timer = Timer.new()
	autoclick_timer.wait_time = get_stat(ClickEffectManager.StatType.FREQUENCY)
	autoclick_timer.timeout.connect(_clicked)
	add_child(autoclick_timer)
	autoclick_timer.start()
	
	var m = ShaderMaterial.new()
	m.shader = MISSION_PROGRESS_FLIPPED 
	hit_area.material = m
	
	duration_timer = Timer.new()
	duration_timer.wait_time = get_stat(ClickEffectManager.StatType.DURATION)
	duration_timer.timeout.connect(queue_free)
	add_child(duration_timer)
	duration_timer.start()
	
	_set_size(get_stat(ClickEffectManager.StatType.SIZE))

func _new_blackhole_mission() -> void:
	using_box = false
	
	var m = ShaderMaterial.new()
	m.shader = DASHES
	m.set_shader_parameter("border_width", 0.1)
	m.set_shader_parameter("dash_count", 5)
	m.set_shader_parameter("gap_ratio", 0.48)
	m.set_shader_parameter("dash_color", BLACKHOLE_BORDER)
	m.set_shader_parameter("fill_color", BLACKHOLE_INT)
	hit_area.material = m
	
	hit_data.lightning_chance_multiplier = 0.
	corners.visible = false
	
	duration_timer = Timer.new()
	duration_timer.wait_time = get_stat(ClickEffectManager.StatType.DURATION)
	duration_timer.timeout.connect(queue_free)
	add_child(duration_timer)
	duration_timer.start()
	
	collision_shape.shape = CircleShape2D.new()
	mission_scale = Vector2(
		StatManager.get_stat("hit_size").value * get_stat(ClickEffectManager.StatType.SIZE),
		StatManager.get_stat("hit_size").value * get_stat(ClickEffectManager.StatType.SIZE)
	)
	collision_shape.scale = mission_scale

func _new_explosion_mission() -> void:
	rotation_degrees = [randi_range(-70, -20), randi_range(20, 70)].pick_random()
	
	duration_timer = Timer.new()
	duration_timer.wait_time = EXPLOSION_DUR
	duration_timer.timeout.connect(queue_free)
	add_child(duration_timer)
	duration_timer.start()
	
	corners.material = corners.material.duplicate()
	corners.material.set_shader_parameter("replacement_colors", [EXPLOSION_BORDER])
	
	hit_area.color = EXPLOSION_INT
	hit_data.damage_mult = get_stat(ClickEffectManager.StatType.DAMAGE)
	
	_set_size(get_stat(ClickEffectManager.StatType.SIZE))
	_update_size()

func _new_player_mission() -> void:
	_set_size()
	
	using_hitbar = GameManager.player.has_discovered_state(Enums.State.SCIENTIST) and !GameManager.player.scientist_disabled
	hit_bar.visible = using_hitbar
	
	using_combo = GameManager.player.equipped_items.has("combo")
	GameManager.player.combo_amount = 0
	combo_rect.visible = using_combo
	
	for rect in mouse_ui.keys():
		update_position(rect, mouse_ui[rect])
	
	# all combo logic is contained :thumbsup:
	if !using_combo:
		return
	
	combo.max = GameManager.player.equipped_items["combo"].get_value("max_combo")
	combo.timer = Timer.new()
	add_child(combo.timer)
	
	combo.timer.timeout.connect(
		func ():
			combo.amount = 0
			GameManager.player.combo_amount = 0
	)
	
	GameManager.asteroid_broke.connect(func (): 
		combo.timer.start(min(COMBO_GAP, combo.timer.time_left + COMBO_GAP))
		combo.amount = min(combo.max, combo.amount + 1)
		GameManager.player.combo_amount = combo.amount
		combo_amount.text = "MAX" if combo.amount == combo.max else str(combo.amount) + "x"
	)

func new_mission() -> void:
	visible = true
	can_click = true
	mouse_ui.keys().map(func (x): x.visible = false)
	
	if player_controlled:
		_new_player_mission()
		_update_size()
		return
	
	match click_effect:
		ClickEffectManager.ClickType.AUTOCLICK_AREA:
			_new_autoclick_mission()
		ClickEffectManager.ClickType.BLACKHOLE:
			_new_blackhole_mission()
		ClickEffectManager.ClickType.EXPLOSION:
			_new_explosion_mission()
	
	_update_size()

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

func _update_size() -> void:
	if using_box:
		var shape = collision_shape.shape.extents * collision_shape.scale
		
		top_left.position = -shape + Vector2(-1, -1)
		top_right.position = Vector2(shape.x, -shape.y) + Vector2(1, -1)
		bottom_left.position = -Vector2(shape.x, -shape.y) + Vector2(-1, 1)
		bottom_right.position = shape + Vector2(1, 1)
		
		hit_area.position = -shape
		hit_area.size = shape * 2
	else:
		var r = collision_shape.shape.radius * collision_shape.scale * 1.1
		
		hit_area.position = -r
		hit_area.size = r * 2

func _process(_d: float) -> void:
	if update_size:
		_update_size()
	
	if player_controlled:
		_process_player()
		return
	
	match click_effect:
		ClickEffectManager.ClickType.EXPLOSION:
			if has_triggered == 0:
				_clicked()
				has_triggered -= 1
			else: 
				has_triggered -= 1
			if duration_timer.time_left < EXPLOSION_FLASH:
				if int(duration_timer.time_left * 100) % EXPLOSION_FLASH_FREQ == 0:
					visible = not visible
		ClickEffectManager.ClickType.AUTOCLICK_AREA:
			hit_area.material.set_shader_parameter("progress", duration_timer.time_left / duration_timer.wait_time)
		ClickEffectManager.ClickType.BLACKHOLE:
			hit_area.material.set_shader_parameter("progress", duration_timer.time_left / duration_timer.wait_time)
			shader_rotation += 0.03
			hit_area.material.set_shader_parameter("rotation", shader_rotation)
			var pull = get_stat(ClickEffectManager.StatType.PULL)
			var bodies = get_overlapping_bodies().filter(func (x): return x.has_meta("asteroid"))
			for asteroid in bodies:
				asteroid.linear_velocity = asteroid.linear_velocity.lerp(
					(global_position - asteroid.global_position),
					pull)
				asteroid.linear_velocity *= (1 + pull * 2.5)

func _process_player() -> void:
	for rect in mouse_ui.keys():
		var ui = mouse_ui[rect]
		if ui.update_rate > 0:
			ui.current_frame += 1
			if ui.update_rate == ui.current_frame:
				update_position(rect, mouse_ui[rect])
	
	if using_combo:
		combo_rect.visible = using_combo and combo.timer.time_left > 0
		combo_bar.material.set_shader_parameter("progress", combo.timer.time_left / COMBO_GAP)

func _on_body_entered(body: Node) -> void:
	if body.has_meta("mineral"):
		GameManager.collect_mineral.emit(body)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MINERAL_PICKUP)
		body.queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player_controlled and can_click and event is InputEventMouseButton \
	and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_clicked()

func _clicked() -> void:
	scale_tween = create_tween()
	collision_shape.scale = mission_scale
	update_size = true
	
	scale_tween.tween_property(collision_shape, "scale", mission_scale * 0.7, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(collision_shape, "scale", mission_scale, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	scale_tween.finished.connect(func (): update_size = false)
	
	if using_hitbar:
		hit_bar.progress = max(0, hit_bar.progress - 0.2)
		GameManager.player.hit_strength = hit_bar.colour
	
	var bodies = get_overlapping_bodies()
	if can_pop_powerups:
		bodies.append_array(get_overlapping_areas())
	
	for body in bodies:
		if body.has_meta("asteroid"):
			GameManager.asteroid_hit.emit(body, hit_data)
		if body.has_meta("powerup") and can_pop_powerups:
			GameManager.powerup_hit.emit(body)
