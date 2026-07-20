extends Area2D
class_name HitBox

@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var hit_bar: ReferenceRect = $HitBar
@onready var combo_amount: Label = $Combo/HBoxContainer/ComboAmount
@onready var combo_rect: ReferenceRect = $Combo
@onready var combo_bar: TextureRect = $Combo/HBoxContainer/ComboBarContainer/ComboBar
@onready var hit_area: ColorRect = $HitArea
@onready var powerups: ReferenceRect = $Powerups

# corners
@onready var corners: Node2D = $Corners
@onready var top_left: Sprite2D = $Corners/TopLeft
@onready var bottom_left: Sprite2D = $Corners/BottomLeft
@onready var bottom_right: Sprite2D = $Corners/BottomRight
@onready var top_right: Sprite2D = $Corners/TopRight

@onready var hit_data := HitData.new()
@onready var autoclick_tex: TextureRect = $Autoclick/HBoxContainer/TextureRect
@onready var autoclick_rect: ReferenceRect = $Autoclick

const MISSION_PROGRESS_FLIPPED := preload("uid://b4ad3pys5nyjy")
const DASHES := preload("uid://c8a6gqo5c6piu")
const BLACKHOLE_BORDER := Color(0.18, 0.133, 0.184, 1.0)
const BLACKHOLE_INT := Color("2e222f84")
const BLACKHOLE_INTERVAL := 3.0

const EXPLOSION_BORDER := Color(0.682, 0.137, 0.204, 1.0)
const EXPLOSION_INT := Color(0.984, 0.42, 0.114, 0.51)
const EXPLOSION_DUR := 1
const EXPLOSION_FLASH := 0.3
const EXPLOSION_FLASH_FREQ := 3

# treats each rect as bigger by X on all sides
const RECT_PADDING := 5
const COMBO_GAP := 1.2

# base
var base: Vector2

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

## was calling new_mission multiple times for some reason
var in_mission: bool = false

## autoclicking will use this
var autoclick_timer: Timer

## player's holding interval
var holding_interval: float = 1.

## autoclick speed
var autoclick_speed: float = -1.

## all non-player effects use this
var duration_timer: Timer

## rotation effect used in blackhole and explosion
var shader_rotation: float

## if the hitbox is being used, eg corners and that.
var using_box: bool = true

## if using autoclick stat
var using_autoclick: bool = false

## only updates size when this flag is true
var update_size: bool = false

## used because explosion was pissing me the fuck off
var has_triggered: int = 10

## mineral collection update freq (every N frames)
const COLLECT_FREQ := 1
var collect_curr := 0

@export var ui: Dictionary[ReferenceRect, MouseUI]
@export var click_effect: ClickEffectManager.ClickType
@export var player_controlled: bool = false
@export var can_pop_powerups: bool
@export var can_spawn_lightning: bool

func _ready() -> void:
	GameManager.out_of_clicks.connect(func(): can_click = false)
	
	monitoring = true
	monitorable = true
	
	new_mission()
	mission_ended()

func get_stat(stat_type: ClickEffectManager.StatType) -> float:
	return ClickEffectManager.stats[click_effect][stat_type]

func _set_size(s) -> void:
	if !using_box: push_error("not using a box")
	mission_scale = Vector2(s, s)
	base = mission_scale
	box_size = collision_shape.shape.extents * mission_scale

func _new_autoclick_mission() -> void:
	autoclick_timer = Timer.new()
	autoclick_timer.wait_time = 1. / get_stat(ClickEffectManager.StatType.FREQUENCY)
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
	base = mission_scale
	collision_shape.scale = mission_scale

func update_blackhole_scale(f: float = 1.) -> void:
	collision_shape.shape = CircleShape2D.new()
	mission_scale = Vector2(
		StatManager.get_stat("hit_size").value * get_stat(ClickEffectManager.StatType.SIZE) * f,
		StatManager.get_stat("hit_size").value * get_stat(ClickEffectManager.StatType.SIZE) * f
	)
	base = mission_scale
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
	_set_size(StatManager.get_stat("hit_size").value * DrinksManager.get_stat(DrinkModifier.ModifyingStat.HIT_SIZE))
	
	powerups.visible = GameManager.planet == Enums.Planet.KRUOS
	
	using_hitbar = GameManager.player.has_discovered_state(Enums.State.SCIENTIST) and !GameManager.player.scientist_disabled
	hit_bar.visible = using_hitbar
	
	using_combo = GameManager.player.equipped_items.has("combo")
	GameManager.player.combo_amount = 0
	combo_rect.visible = using_combo
	
	using_autoclick = GameManager.planet == Enums.Planet.DYRT
	autoclick_rect.visible = using_autoclick
	
	var cs = StatManager.get_stat("click_speed")
	autoclick_speed = cs.value if cs.level > 1 else INF
	autoclick_rect.visible = cs.level > 1
	
	var i = DrinksManager.get_stat(DrinkModifier.ModifyingStat.INITIAL_AUTOCLICK)
	if i > 0:
		autoclick_speed = 0.2
		autoclick_rect.visible = true
		
		var t = Timer.new()
		t.one_shot = true
		t.wait_time = i
		t.timeout.connect(func (): autoclick_speed = INF; autoclick_rect.visible = false)
		add_child(t)
		t.start()
	
	for rect in ui.keys():
		update_position(rect, ui[rect])
	
	# all combo logic is contained :thumbsup:
	if !using_combo:
		return
	
	combo.max = GameManager.player.equipped_items["combo"].get_value("max_combo")
	combo.timer = Timer.new()
	combo.timer.one_shot = true
	add_child(combo.timer)
	
	combo.timer.timeout.connect(
		func ():
			combo.amount = 0
			GameManager.player.combo_amount = 0
	)
	
	if !GameManager.asteroid_broke.is_connected(tick_combo):
		GameManager.asteroid_broke.connect(tick_combo)

func tick_combo() -> void:
	combo.timer.start(min(COMBO_GAP, combo.timer.time_left + COMBO_GAP))
	combo.amount = min(combo.max, combo.amount + 1)
	GameManager.player.combo_amount = combo.amount
	combo_amount.text = "MAX" if combo.amount == combo.max else str(combo.amount) + "x"

func mission_ended() -> void:
	in_mission = false

func new_mission() -> void:
	if in_mission: return
	
	in_mission = true
	visible = true
	can_click = true
	ui.keys().map(func (x): x.visible = false)
	
	if player_controlled:
		_new_player_mission()
		_update_size()
		return
	
	match click_effect:
		ClickEffectManager.ClickType.AUTOCLICK:
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
		# centre, centre
		[MouseUI.Pos.CENTRE, MouseUI.Align.CENTRE]:
			rect.set_size(Vector2(
				pos_details.size.x,
				box_size.y * 2 + RECT_PADDING * 2
			))
			rect.set_position(position + Vector2(
				rect.size.x + box_size.x,
				- (rect.size.y / 2)
			))
		_:
			pass

func _update_size(s: float = 1.) -> void:
	if using_box:
		var shape = collision_shape.shape.extents * mission_scale
		collision_shape.scale = mission_scale
		
		if player_controlled:
			shape *= s * (GameManager.powerup_modifiers[Powerup.PowerupType.SIZE_UP] + 1)
			collision_shape.scale *= s * (GameManager.powerup_modifiers[Powerup.PowerupType.SIZE_UP] + 1)
		
		top_left.position = -shape + Vector2(-1, -1)
		top_right.position = Vector2(shape.x, -shape.y) + Vector2(1, -1)
		bottom_left.position = -Vector2(shape.x, -shape.y) + Vector2(-1, 1)
		bottom_right.position = shape + Vector2(1, 1)
		
		hit_area.position = -shape
		hit_area.size = shape * 2
	else:
		var r = s * collision_shape.shape.radius * collision_shape.scale * 1.1
		
		hit_area.position = -r
		hit_area.size = r * 2

func _process(dt: float) -> void:
	if update_size or GameManager.powerup_modifiers[Powerup.PowerupType.SIZE_UP] > 0:
		_update_size()
	
	if player_controlled:
		_process_player(dt)
		return
	
	match click_effect:
		ClickEffectManager.ClickType.EXPLOSION:
			if has_triggered == 0:
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.EXPLOSION)
				_clicked()
				has_triggered -= 1
			else: 
				has_triggered -= 1
			if duration_timer.time_left < EXPLOSION_FLASH:
				if int(duration_timer.time_left * 100) % EXPLOSION_FLASH_FREQ == 0:
					visible = not visible
		ClickEffectManager.ClickType.AUTOCLICK:
			hit_area.material.set_shader_parameter("progress", duration_timer.time_left / duration_timer.wait_time)
		ClickEffectManager.ClickType.BLACKHOLE:
			update_blackhole()

func update_blackhole() -> void:
	hit_area.material.set_shader_parameter("progress", duration_timer.time_left / duration_timer.wait_time)
	shader_rotation += 0.03
	hit_area.material.set_shader_parameter("rotation", shader_rotation)
	
	var pull = get_stat(ClickEffectManager.StatType.PULL)
	var time = Time.get_ticks_msec() / 1000.
	var wave = ((sin(time * BLACKHOLE_INTERVAL) + 1.0) / 2.0) + pull / 15.
	
	var bodies = get_overlapping_bodies().filter(func (x): return x.has_meta("asteroid"))
	
	for asteroid in bodies:
		var to_center = global_position - asteroid.global_position
		var distance = to_center.length()
		
		if distance == 0: continue
		
		var dir = to_center.normalized()
		
		var force = dir * pull * wave * 10.
		
		asteroid.apply_central_force(force)

func _process_player(dt) -> void:
	for rect in ui.keys():
		var ui_box = ui[rect]
		if ui_box.update_rate > 0:
			ui_box.current_frame += 1
			if ui_box.current_frame >= ui_box.update_rate:
				ui_box.current_frame = 0
				update_position(rect, ui[rect])
	
	if using_combo:
		combo_rect.visible = using_combo and combo.timer.time_left > 0
		combo_bar.material.set_shader_parameter("progress", combo.timer.time_left / COMBO_GAP)
	
	if GameManager.powerup_modifiers[Powerup.PowerupType.AUTOCLICK] > 0:
		holding_interval -= GameManager.powerup_modifiers[Powerup.PowerupType.AUTOCLICK] * dt
		
		if holding_interval <= 0:
			_clicked(true)
			holding_interval = 1.
	
	if in_mission and using_autoclick:
		autoclick_tex.material.set_shader_parameter("progress", (1. - autoclick_speed))
		autoclick_speed -= dt * StatManager.get_stat("click_speed").value
		if autoclick_speed <= 0:
			_clicked(true)
			autoclick_speed = 1.
	
	if in_mission:
		if collect_curr == 0:
			collect_curr = COLLECT_FREQ
			var areas = get_overlapping_areas()
			for area in areas:
				if area.has_meta("mineral"):
					GameManager.collect_mineral.emit(area)
					AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MINERAL_PICKUP)
					area.queue_free()
		else:
			collect_curr -= 1
		

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player_controlled and can_click and event is InputEventMouseButton \
	and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:# \
	#and GameManager.planet == Enums.Planet.KRUOS:
		if GameManager.powerup_modifiers[Powerup.PowerupType.DOUBLE_CLICK] > 0:
			var bodies = get_overlapping_bodies()
			for i in range(GameManager.powerup_modifiers[Powerup.PowerupType.DOUBLE_CLICK]):
				for body in bodies:
					if body.has_meta("asteroid"):
						GameManager.asteroid_hit.emit(body, hit_data)
			GameManager.powerup_modifiers[Powerup.PowerupType.DOUBLE_CLICK] = 0
		
		_clicked()

func _clicked(autoclick: bool = false) -> void:
	scale_tween = create_tween()
	collision_shape.scale = mission_scale
	update_size = true
	
	scale_tween.tween_property(self, "mission_scale", base * 0.7, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "mission_scale", base, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	scale_tween.finished.connect(func (): update_size = false)
	
	# using autoclick to indicate two things here don't @ me
	if using_hitbar and (!autoclick or !GameManager.player.hit_strength):
		hit_bar.progress = max(0, hit_bar.progress - 0.17)
		GameManager.player.hit_strength = hit_bar.colour
	
	var bodies = get_overlapping_bodies()
	
	# if autoclick, it goes forever lol
	if can_pop_powerups and !autoclick:
		bodies.append_array(get_overlapping_areas())
	
	for body in bodies:
		if body.has_meta("asteroid"):
			GameManager.asteroid_hit.emit(body, hit_data)
		if body.has_meta("powerup") and can_pop_powerups:
			GameManager.powerup_hit.emit(body)
