extends Control

const LIGHT_TICK_SPEED := 25
const LIGHT_AMOUNT = 25
const WHEEL_WIDTH = 0.07
const PORTIONS := 7
const COLLECT_MINERAL = preload("uid://dekanujq3tcx0")
const LIGHT = preload("uid://daxnq814jfxne")

@export var outcome_colours: Dictionary[WheelPortion.Outcome, WheelColour]

var current_wheel: Array[WheelPortion]
@onready var wheel: ColorRect = $Wheel
@onready var borders: Line2D = $Wheel/Borders
@onready var wheel_tick: TextureRect = $WheelTick
@onready var reward_text: RichTextLabel = $Reward/MarginContainer/MarginContainer/Reward
@onready var reward_panel: NinePatchRect = $Reward/MarginContainer/RewardPanel
@onready var spin_arrow: TextureButton = $SpinArrow
@onready var spins_left: NinePatchRect = $SpinsLeft
@onready var spins_left_label: Label = $SpinsLeft/Label
@onready var reward_hbox: HBoxContainer = $Reward

var lights: Array[WheelLight]
var current_portion: WheelPortion
var angles: Array[float]
var remaining_spins: int = 10
var previous_rotation: float
var update_lights: bool = false

func _ready() -> void:
	previous_rotation = wheel.rotation
	generate_new_wheel()
	
	GameManager.day_changed.connect(func (_d): 
		remaining_spins = int(ceil(StatManager.get_stat("daily_spins").value))
		spins_left_label.text = str(remaining_spins))
	
	spin_arrow.mouse_entered.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		spin_arrow.material.set_shader_parameter("width", 1))
	
	spin_arrow.mouse_exited.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		spin_arrow.material.set_shader_parameter("width", 0))
	
	spin_arrow.pressed.connect(pay_for_spin)
	reward_hbox.visible = false
	
	set_up_lights()

func pay_for_spin() -> void:
	if remaining_spins <= 0: return
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(spin_arrow, "rotation", spin_arrow.rotation + 2 * PI, 0.75)
	
	var t2 = create_tween()
	t2.tween_property(spins_left, "position:y", spins_left.position.y + 10, 0.05)
	t2.tween_property(spins_left, "position:y", spins_left.position.y, 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	
	remaining_spins -= 1
	spins_left_label.text = str(remaining_spins)
	
	spin_wheel()

func spin_wheel() -> void:
	generate_new_wheel()
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.tween_property(wheel, "rotation", wheel.rotation + randf_range(3. * PI, 6. * PI), 2)
	t.finished.connect(payout)

func payout() -> void:
	reward_hbox.visible = true
	
	if current_portion.is_good_outcome():
		light_animation(current_portion.outcome)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.GOOD)
		if current_portion.outcome == WheelPortion.Outcome.INSANELY_GOOD:
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.REALLY_GOOD)
	elif current_portion.is_bad_outcome():
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BAD)
		if current_portion.outcome == WheelPortion.Outcome.SUICIDAL:
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.REALLY_BAD)
	
	for i in range(current_portion.rewards.size()):
		var reward = current_portion.rewards[i]
		if reward.effect == WheelReward.Effect.NOTHING:
			break
		
		if reward.effect == WheelReward.Effect.SPINS:
			if reward.operation == WheelReward.Operation.ADD:
				var t = create_tween()
				for _i in range(reward.amount):
					t.tween_property(spins_left, "position:y", spins_left.position.y + 5, 0.04)
					t.tween_property(spins_left, "position:y", spins_left.position.y, 0.04).finished.connect(func ():
						remaining_spins += 1
						AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SLIDER)
						spins_left_label.text = str(remaining_spins))
			else:
				var t = create_tween()
				for _i in range(min(remaining_spins, reward.amount)):
					t.tween_property(spins_left, "position:y", spins_left.position.y + 5, 0.04)
					t.tween_property(spins_left, "position:y", spins_left.position.y, 0.04).finished.connect(func ():
						remaining_spins -= 1
						AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SLIDER)
						spins_left_label.text = str(remaining_spins))
			continue
		
		var mineral = Enums.Mineral.get(WheelReward.Effect.find_key(reward.effect))
		reward.normalise_amount()
		
		if reward.operation == WheelReward.Operation.ADD:
			spawn_minerals(int(ceil(reward.amount)), mineral, i, current_portion.rewards.size())
		
		if reward.operation == WheelReward.Operation.MULT:
			var curr = GameManager.player.get_mineral(mineral)
			var new_amt = int(abs(ceil(curr * (reward.amount - 1))))
			if reward.amount > 1:
				spawn_minerals(max(1, new_amt), mineral, i, current_portion.rewards.size())
			else:
				subtract_minerals(mineral, max(1, new_amt))
		
		if reward.operation == WheelReward.Operation.SUBTRACT:
			subtract_minerals(mineral, reward.amount)

func subtract_minerals(mineral: Enums.Mineral, new_amt: int) -> void:
	GameManager.show_mineral.emit(mineral)
	
	var t = Timer.new()
	t.wait_time = 0.01
	t.timeout.connect(func (): 
		if GameManager.player.get_mineral(mineral) > 0:
			GameManager.add_mineral.emit(mineral, -1))
	
	var t2 = Timer.new()
	t2.wait_time = 0.01 * new_amt
	t2.one_shot = true
	t2.timeout.connect(func (): t.queue_free())
	
	add_child(t2)
	add_child(t)
	t2.start()
	t.start()

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

func light_tick() -> int:
	return (Time.get_ticks_msec() % (lights.size() * LIGHT_TICK_SPEED)) / LIGHT_TICK_SPEED

func light_animation(outcome: WheelPortion.Outcome) -> void:
	var t = Timer.new()
	var t2 = Timer.new()
	
	match outcome:
		WheelPortion.Outcome.DECENT:
			t.wait_time = 0.01
			t.timeout.connect(
				func ():
					var i = light_tick()
					lights[i].pulse()
					update_lights = true
			)
			add_child(t)
			t.start()
		WheelPortion.Outcome.GOOD:
			t.wait_time = 0.01
			t.timeout.connect(
				func ():
					var i = light_tick()
					lights[i].pulse()
					lights[(i + LIGHT_AMOUNT / 2) % LIGHT_AMOUNT].pulse()
					update_lights = true
			)
			add_child(t)
			t.start()
		WheelPortion.Outcome.REALLY_GOOD:
			t.wait_time = 0.01
			t.timeout.connect(
				func ():
					var i = light_tick()
					lights[i].pulse()
					lights[(i + LIGHT_AMOUNT / 3) % LIGHT_AMOUNT].pulse()
					lights[abs(i - LIGHT_AMOUNT / 3) % LIGHT_AMOUNT].pulse()
					update_lights = true
			)
			add_child(t)
			t.start()
		WheelPortion.Outcome.INSANELY_GOOD:
			t.wait_time = 0.01
			t.timeout.connect(
				func ():
					var i = light_tick()
					lights[i].pulse()
					lights[(i + LIGHT_AMOUNT / 4) % LIGHT_AMOUNT].pulse()
					lights[(i + LIGHT_AMOUNT / 2) % LIGHT_AMOUNT].pulse()
					lights[abs(i - LIGHT_AMOUNT / 4) % LIGHT_AMOUNT].pulse()
					update_lights = true
			)
			add_child(t)
			t.start()
	
	t2.wait_time = 1.5
	t2.timeout.connect(
		func ():
			t.queue_free()
			t2.queue_free()
	)
	add_child(t2)
	t2.start()
	pass

# takes in i and s so it knows how far along the rewards panel to spawn the minerals
func spawn_minerals(amount: int, mineral: Enums.Mineral, i: int, s: int) -> void:
	GameManager.show_mineral.emit(mineral)
	
	for _i in range(amount):
		var m = COLLECT_MINERAL.instantiate()
		m.target = Vector2(0, 0)
		m.position = reward_panel.global_position + \
			((2 * i) + 1) * (reward_panel.size / (2 * s)) + \
			Vector2(randi_range(-30, 30), randi_range(-30, 30))
		m.value = 1
		m.mineral = mineral
		m.texture = GameManager.mineral_data[mineral].texture
		add_child(m)

"""
angles should be a list of the angle each portion is in, eg
[0, PI, 7PI/4]
we then rotate each point by the wheel (modded for simplicity)
let's say the wheel is rotated PI/4
[PI/4, 5PI/4, 9PI/4]
then we figure out the range of each angle
[[PI/4 - 5PI/4], [5PI/4-2PI], [2PI-PI/4]] (loops around)
"""
func _process(_d: float) -> void:
	if update_lights:
		lights.map(func (x): x.update())
		update_lights = lights.any(func (x): return x.needs_update())
	
	if wheel.rotation == previous_rotation: return
	previous_rotation = wheel.rotation
	var modded_rotation = fmod(wheel.rotation, 2 * PI)
	var checking_rotation: = PI / 2
	var prev_angle: float = modded_rotation

	for i in range(angles.size()):
		var angle = angles[i] + modded_rotation
		if angle > 2 * PI && checking_rotation >= 0 && checking_rotation <= angle - 2 * PI:
			change_current_portion(current_wheel[i])
			break
		elif checking_rotation >= prev_angle && checking_rotation <= angle:
			change_current_portion(current_wheel[i])
			break

func change_current_portion(portion: WheelPortion) -> void:
	if current_portion && portion.outcome == current_portion.outcome: return
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.WHEEL)
	current_portion = portion
	reward_panel.material.set_shader_parameter("replacement_colors", [
		outcome_colours[portion.outcome].outline,
		outcome_colours[portion.outcome].shadow,
		outcome_colours[portion.outcome].mid,
		outcome_colours[portion.outcome].highlight
	])
	
	reward_text.text = "  ".join(portion.rewards.map(func (x): return x.description))
	
	var t = create_tween()
	var f = randf_range(-PI/6, -PI/4)
	t.tween_property(wheel_tick, "rotation", f, 0.05)
	t.tween_property(wheel_tick, "rotation", -f * 0.5, 0.3)
	t.tween_property(wheel_tick, "rotation", f * 0.25, 0.3)
	t.tween_property(wheel_tick, "rotation", 0, 0.3)

func generate_portion(outcome: WheelPortion.Outcome) -> WheelPortion:
	var portion = WheelPortion.new()
	portion.outcome = outcome
	portion.colour = outcome_colours[outcome].mid
	portion.generate_rewards()
	return portion

func generate_new_wheel() -> void:
	current_wheel.clear()
	borders.clear_points()
	angles.clear()
	
	var wheel_level = StatManager.get_stat("wheel_level").value
	var m = 4 - (wheel_level / 4)
	var sd = (wheel_level / 5) + 1.5
	
	# generate portions
	for i in range(PORTIONS):
		var outcome = int(clamp(round(randfn(m, sd)), 0, outcome_colours.size() - 1)) 
		current_wheel.append(generate_portion(outcome))
	
	# merge portions of same type
	var reduced_wheel: Dictionary[WheelPortion.Outcome, WheelPortion] = {}
	for portion in current_wheel:
		if !reduced_wheel.has(portion.outcome):
			var s = current_wheel.reduce(func (acc, x):
					return acc + x.portion_size if x.outcome == portion.outcome else acc, 0)
			portion.portion_size = s
			reduced_wheel.set(
				portion.outcome, 
				portion
			)
	
	# get portion total
	var total_portion = reduced_wheel.values().reduce(
		func (acc, x): return acc + x.portion_size, 0)
	
	current_wheel = reduced_wheel.values()
	
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
	
	wheel.material.set_shader_parameter(
		"portion_colours", 
		current_wheel.map(func (p): return p.colour)
	)
	
