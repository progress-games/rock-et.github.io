extends Control
class_name Wheel

const LIGHT_TICK_SPEED := 25
const LIGHT_AMOUNT: int = 25
const WHEEL_WIDTH = 0.07
const PORTIONS := 7
const COLLECT_MINERAL = preload("uid://dekanujq3tcx0")
const LIGHT = preload("uid://daxnq814jfxne")
const REWARD_DISTANCE := 35 # how far the rewards are shown from the wheel centre

const DARK_TEXT = Color(0.18, 0.133, 0.184, 1.0)
const LIGHT_TEXT = Color(1.0, 1.0, 1.0, 1.0)

@export var win_colours: Dictionary[WheelPortion.Rarity, WheelColour]
@export var loss_colours: Dictionary[WheelPortion.Rarity, WheelColour]

var current_wheel: Array[WheelPortion]
@onready var wheel: ColorRect = $WheelBoard
@onready var borders: Line2D = $WheelBoard/Borders
@onready var wheel_tick: TextureRect = $WheelTick
@onready var reward_text: RichTextLabel = $Reward/MarginContainer/MarginContainer/Reward
@onready var reward_panel: NinePatchRect = $Reward/MarginContainer/RewardPanel
@onready var spins_left: NinePatchRect = $SpinsLeft
@onready var spins_left_label: Label = $SpinsLeft/Label
@onready var reward_hbox: HBoxContainer = $Reward
@onready var reroll: TextureButton = $Reroll
@onready var wheel_centre: Sprite2D = $WheelCentre

@onready var reward_labels: Array[RichTextLabel] = [
	$"Rewards/1", 
	$"Rewards/2", 
	$"Rewards/3", 
	$"Rewards/4", 
	$"Rewards/5", 
	$"Rewards/6", 
	$"Rewards/7", 
]

var lights: Array[WheelLight]
var current_portion: int
var angles: Array[float]
var remaining_spins: int = 10
var previous_rotation: float
var update_lights: bool = false
var daily_rerolls := 0

var mineral_to_delete := 0

var is_spinning := false

signal finished_spinning()

func _ready() -> void:
	previous_rotation = wheel.rotation
	
	GameManager.day_changed.connect(func (_d):
		daily_rerolls = int(ceil(StatManager.get_stat("wheel_reroll").value))
		reroll.visible = daily_rerolls > 0
		remaining_spins = int(ceil(StatManager.get_stat("daily_spins").value))
		spins_left_label.text = str(remaining_spins))
	
	reward_hbox.visible = false
	
	set_up_lights()

func set_up_lights() -> void:
	var wheel_radius = 1 - (WHEEL_WIDTH)
	for i in range(LIGHT_AMOUNT):
		var new_light = LIGHT.instantiate()
		var a =  2 * PI * (i + 1) / LIGHT_AMOUNT
		new_light.position = wheel.size / 2 + Vector2(
			cos(a) * wheel.size.x / 2. * wheel_radius ,
			sin(a) * wheel.size.y / 2. * wheel_radius
		)
		lights.append(new_light)
		wheel.add_child(new_light)

func pay_for_spin() -> bool:
	if remaining_spins <= 0 || is_spinning: 
		return false
	
	is_spinning = true
	
	var t2 = create_tween()
	t2.tween_property(spins_left, "position:y", spins_left.position.y + 10, 0.05)
	t2.tween_property(spins_left, "position:y", spins_left.position.y, 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	
	remaining_spins -= 1
	spins_left_label.text = str(remaining_spins)
	
	spin_wheel()
	return true

func spin_wheel() -> void:
	update_wheel_colours()
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.tween_property(wheel, "rotation", wheel.rotation + randf_range(3. * PI, 6. * PI), 2)
	t.finished.connect(payout)

func payout() -> void:
	reward_hbox.visible = true
	var portion = current_wheel[current_portion]
	
	light_animation(portion)
	
	if portion.outcome == WheelPortion.Outcome.LOSS:
		subtract_minerals(portion.amount)
	elif portion.reward == WheelPortion.Reward.SPINS:
		add_spins(portion.amount)
	else:
		spawn_minerals(portion.amount)
	
	is_spinning = false
	finished_spinning.emit()

func add_spins(a: int) -> void:
	var t = create_tween()
	t.tween_property(spins_left, "position:y", spins_left.position.y + 5, 0.04)
	t.tween_property(spins_left, "position:y", spins_left.position.y, 0.04)
	t.finished.connect(func ():
		remaining_spins += a
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SLIDER)
		spins_left_label.text = str(remaining_spins))

func subtract_minerals(amount: int) -> void:
	var mineral = Enums.Mineral.DIAMOND
	GameManager.show_mineral.emit(mineral)
	
	mineral_to_delete = min(amount, GameManager.player.get_mineral(mineral))
	
	var t = Timer.new()
	t.wait_time = 0.05
	t.timeout.connect(func (): 
		if mineral_to_delete > 0:
			mineral_to_delete -= 1
			GameManager.add_mineral.emit(mineral, -1)
		else:
			t.queue_free())
	
	add_child(t)
	t.start()

func spawn_minerals(amount: int) -> void:
	var mineral = Enums.Mineral.DIAMOND
	GameManager.show_mineral.emit(mineral)
	
	for _i in range(amount):
		var m = COLLECT_MINERAL.instantiate()
		m.target = Vector2(0, 0)
		m.position = reward_panel.global_position + Vector2(randi_range(-30, 30), randi_range(-30, 30))
		m.value = 1
		m.mineral = mineral
		m.texture = GameManager.mineral_data[mineral].texture
		add_child(m)

func light_tick() -> int:
	@warning_ignore("integer_division")
	return (Time.get_ticks_msec() % (lights.size() * LIGHT_TICK_SPEED)) / LIGHT_TICK_SPEED

func light_animation(portion: WheelPortion) -> void:
	if portion.outcome == WheelPortion.Outcome.LOSS:
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BAD)
		if portion.rarity == WheelPortion.Rarity.ULTRA_RARE:
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.REALLY_BAD)
		return
	
	var rarity = portion.rarity
	var t = Timer.new()
	var t2 = Timer.new()
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.GOOD)
	
	match rarity:
		WheelPortion.Rarity.COMMON:
			t.wait_time = 0.01
			t.timeout.connect(
				func ():
					var i = light_tick()
					lights[i].pulse()
					update_lights = true
			)
			add_child(t)
			t.start()
		WheelPortion.Rarity.UNCOMMON:
			t.wait_time = 0.01
			t.timeout.connect(
				func ():
					var i = light_tick()
					lights[i].pulse()
					@warning_ignore("integer_division")
					lights[(i + LIGHT_AMOUNT / 2) % LIGHT_AMOUNT].pulse()
					update_lights = true
			)
			add_child(t)
			t.start()
		WheelPortion.Rarity.RARE:
			t.wait_time = 0.01
			t.timeout.connect(
				func ():
					var i = light_tick()
					lights[i].pulse()
					@warning_ignore("integer_division")
					lights[(i + LIGHT_AMOUNT / 3) % LIGHT_AMOUNT].pulse()
					@warning_ignore("integer_division")
					lights[abs(i - LIGHT_AMOUNT / 3) % LIGHT_AMOUNT].pulse()
					update_lights = true
			)
			add_child(t)
			t.start()
		WheelPortion.Rarity.ULTRA_RARE:
			t.wait_time = 0.01
			t.timeout.connect(
				func ():
					var i = light_tick()
					lights[i].pulse()
					@warning_ignore("integer_division")
					lights[(i + LIGHT_AMOUNT / 4) % LIGHT_AMOUNT].pulse()
					@warning_ignore("integer_division")
					lights[(i + LIGHT_AMOUNT / 2) % LIGHT_AMOUNT].pulse()
					@warning_ignore("integer_division")
					lights[abs(i - LIGHT_AMOUNT / 4) % LIGHT_AMOUNT].pulse()
					update_lights = true
			)
			add_child(t)
			t.start()
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.REALLY_GOOD)
	
	t2.wait_time = 1.5
	t2.timeout.connect(
		func ():
			t.queue_free()
			t2.queue_free()
	)
	add_child(t2)
	t2.start()
	pass

func _process(_d: float) -> void:
	if previous_rotation != wheel.rotation:
		update_reward_labels()
		previous_rotation = wheel.rotation
	
	if update_lights:
		lights.map(func (x): x.update())
		update_lights = lights.any(func (x): return x.needs_update())
	
	if is_spinning:
		var tick_rotation = PI / 2
		change_current_portion(get_hovering_portion(tick_rotation))

"""
angles should be a list of the angle each portion is in, eg
[0, PI, 7PI/4]
we then rotate each point by the wheel (modded for simplicity)
let's say the wheel is rotated PI/4
[PI/4, 5PI/4, 9PI/4]
then we figure out the range of each angle
[[PI/4 - 5PI/4], [5PI/4-2PI], [2PI-PI/4]] (loops around)
"""
func get_hovering_portion(checking_rotation: float) -> int:
	var modded_rotation = fmod(wheel.rotation, 2 * PI)
	var prev_angle: float = modded_rotation
	
	for i in range(angles.size()):
		var angle = angles[i] + modded_rotation
		if angle > 2 * PI && checking_rotation >= 0 && checking_rotation <= angle - 2 * PI:
			return i
		elif checking_rotation >= prev_angle && checking_rotation <= angle:
			return i
	
	return -1

## adding PI because it was reflected for some reason
func update_reward_labels() -> void:
	var modded_rotation = fmod(wheel.rotation, 2 * PI)
	var prev_angle = modded_rotation
	
	for i in range(angles.size()):
		var next_angle = angles[i] + modded_rotation
		var angle = prev_angle + PI + (next_angle - prev_angle) / 2.
		var portion = current_wheel[i]
		var label = reward_labels[i]
		label.global_position = wheel_centre.global_position + Vector2(
			REWARD_DISTANCE * cos(angle),
			REWARD_DISTANCE * sin(angle)
		) - (label.pivot_offset_ratio * label.size)
		label.text = portion.small_reward_text
		
		if portion.outcome == WheelPortion.Outcome.WIN:
			label.add_theme_color_override("default_color", win_colours[portion.rarity].get_text_colour())
		else:
			label.add_theme_color_override("default_color", loss_colours[portion.rarity].get_text_colour())
		
		prev_angle = next_angle

func change_current_portion(i: int) -> void:
	if current_portion == i || !get_parent().visible: return
	
	current_portion = i
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.WHEEL)
	if is_spinning:
		var t = create_tween()
		var f = randf_range(-PI/6, -PI/4)
		t.tween_property(wheel_tick, "rotation", f, 0.05)
		t.tween_property(wheel_tick, "rotation", -f * 0.5, 0.3)
		t.tween_property(wheel_tick, "rotation", f * 0.25, 0.3)
		t.tween_property(wheel_tick, "rotation", 0, 0.3)
	
	var portion = current_wheel[i]
	var colour_dict = win_colours if portion.outcome == WheelPortion.Outcome.WIN else loss_colours
	
	reward_panel.material.set_shader_parameter("replacement_colors", [
		colour_dict[portion.rarity].outline,
		colour_dict[portion.rarity].shadow,
		colour_dict[portion.rarity].mid,
		colour_dict[portion.rarity].highlight
	])
	
	reward_text.text = portion.reward_text

func get_portion(all_portions, rarity_chances, outcome_chances) -> WheelPortion:
	var rng = RandomNumberGenerator.new()
	
	var rarities = WheelPortion.Rarity.values()
	var r = rarities.get(rng.rand_weighted(rarity_chances.values()))
	
	var outcomes = WheelPortion.Outcome.values()
	var o = outcomes.get(rng.rand_weighted(outcome_chances.values()))
	
	var valid_portions = all_portions[o].values().any(func (x): return x.size() > 0)
	if !valid_portions: o = WheelPortion.Outcome.WIN
	
	while true:
		if all_portions[o][r].size() == 0:
			r += 1
		else:
			return all_portions[o][r].pick_random()
	
	return all_portions[o][r]

func generate_new_wheel(
		all_portions: Dictionary[WheelPortion.Outcome, Dictionary], 
		rarities: Dictionary[WheelPortion.Rarity, float], \
		outcomes: Dictionary[WheelPortion.Outcome, float]) -> void:
	current_wheel.clear()
	borders.clear_points()
	angles.clear()
	
	for i in range(PORTIONS):
		current_wheel.append(get_portion(all_portions, rarities, outcomes))
	
	# get portion total
	var total_portion = current_wheel.reduce(
		func (acc, x): return acc + x.portion_size, 0.)
	
	# draw lines
	var a = 0.
	var wheel_radius = 1 - (WHEEL_WIDTH * 2)
	for portion in current_wheel:
		a += portion.portion_size
		var angle = (a / float(total_portion)) * 2 * PI + PI
		borders.add_point(wheel.size / 2.)
		borders.add_point(wheel.size / 2. + Vector2(
			cos(angle) * wheel.size.x / 2. * wheel_radius,
			sin(angle) * wheel.size.y / 2. * wheel_radius
		))
		angles.append(angle - PI)
	
	wheel.material.set_shader_parameter(
		"portions", 
		current_wheel.map(func (p): return p.portion_size / float(total_portion))
	)
	
	update_wheel_colours()
	update_reward_labels()

func update_wheel_colours(hovering_index: int = -1) -> void:
	var colours = current_wheel.map(func (p): 
		if p.outcome == WheelPortion.Outcome.WIN: 
			return win_colours[p.rarity].mid
		else: 
			return loss_colours[p.rarity].mid
		)
	
	if hovering_index >= 0:
		colours[hovering_index] = Color.WHITE
		
	wheel.material.set_shader_parameter(
		"portion_colours", 
		colours
	)
