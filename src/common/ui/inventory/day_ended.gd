extends Control

const SHOW_INTERVAL := 0.3
const ADD_INTERVAL := 0.3
const MINERAL = preload("uid://b2slpdh803g43")
const CHANGES = {1: 0, 10: 1, 100: 2, 1000: 3, 10000: 4}

@onready var bars: HBoxContainer = $Bars
@onready var bg: ColorRect = $BG
@onready var amounts: VBoxContainer = $Amounts
@onready var amounts_text: RichTextLabel = $Amounts/MarginContainer/MarginContainer2/RichTextLabel

@onready var day: Label = $Next/Calendar/Day
@onready var dismiss: TextureButton = $Next/Dismiss
@onready var calendar: TextureRect = $Next/Calendar

# values that are now being shown in the rich text label
var consolidated_values: Dictionary[Enums.Mineral, int]

# the amount of minerals we've spawned
var created_values: Dictionary[Enums.Mineral, int]

var minerals: Dictionary[Enums.Mineral, AtlasTexture]
var mineral_order: Dictionary[Enums.Mineral, int]

var played_deposit_sfx: int = 0

func _ready() -> void:
	for mineral in Enums.Mineral.keys():
		if !GameManager.mineral_data[Enums.Mineral[mineral]].droppable: continue
		var tex = AtlasTexture.new()
		tex.atlas = load("res://mission/mineral/assets/" + mineral.to_lower() + ".png")
		minerals.set(Enums.Mineral[mineral], tex)
	
	GameManager.state_changed.connect(func (s): if s == Enums.State.MISSION: new_mission())
	GameManager.mission_ended.connect(day_ended)
	
	dismiss.pressed.connect(new_day)
	
	dismiss.mouse_exited.connect(func (): 
		dismiss.material.set_shader_parameter("width", 0)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
	
	dismiss.mouse_entered.connect(func (): 
		dismiss.material.set_shader_parameter("width", 1)
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER))

func new_mission() -> void:
	day.text = str(GameManager.day)
	bg.hide()
	
	dismiss.hide()
	calendar.hide()
	amounts.hide()
	
	consolidated_values.clear()

func new_day() -> void:
	GameManager.pause_locked = false
	GameManager.play.emit()
	GameManager.state = Enums.State.MISSION
	GameManager.state_changed.emit(Enums.State.HOME)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.LAND)

func write_values() -> void:
	amounts.visible = amounts.visible || consolidated_values.size() > 0
	
	var s = ""
	
	for m in consolidated_values.keys():
		s += "+ " + Math.format_number_short(consolidated_values[m]) + \
			" [img]res://common/minerals/" + Enums.Mineral.find_key(m).to_lower() + ".png[br]"
	
	s = s.trim_suffix("[br]")
	
	amounts_text.text = s

func day_ended() -> void:
	bg.show()
	amounts_text.text = ""
	consolidated_values.clear()
	
	GameManager.state = Enums.State.HOME
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	
	var idx = 0
	
	var max_minerals = 0
	for mineral in bars.bar_amounts.keys():
		consolidated_values.set(mineral, 0)
		created_values.set(mineral, 0)
		
		mineral_order.set(mineral, idx)
		idx += 1
		
		max_minerals = max(bars.bar_amounts[mineral], max_minerals)
		
		var t = create_tween()
		t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		t.tween_method(consolidate.bind(mineral), 0, bars.bar_amounts[mineral], 1.5)
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MULTIPLE_PICKUP)
	played_deposit_sfx = 1
	
	if max_minerals > 100:
		played_deposit_sfx = 2
		var d = create_tween()
		d.tween_interval(0.05)
		d.finished.connect(AudioManager.create_audio.bind(SoundEffect.SOUND_EFFECT_TYPE.MULTIPLE_PICKUP))
	
	if max_minerals > 1000:
		played_deposit_sfx = 3
		var d2 = create_tween()
		d2.tween_interval(0.1)
		d2.finished.connect(AudioManager.create_audio.bind(SoundEffect.SOUND_EFFECT_TYPE.MULTIPLE_PICKUP))
	
	var x = create_tween()
	x.tween_interval(2.)
	x.finished.connect(calendar.show)
	
	var x2 = create_tween()
	x2.tween_interval(2.5)
	x2.finished.connect(dismiss.show)

func consolidate(new_val: int, m: Enums.Mineral) -> void:
	var diff = new_val - created_values[m]
	if diff < 1:
		return
	
	var change = _calc_change(diff)
	bars.add_mineral(m, -diff)
	
	created_values.set(m, new_val)
	
	for value in change.keys():
		var amount = change[value]
		for i in range(amount):
			spawn_mineral(m, value)

func spawn_mineral(m: Enums.Mineral, val: int) -> void:
	var pos = bars.get_mineral_position(m) + \
		Vector2(
			randi_range(-5, 15),
			randi_range(-15, 15)
		)
	bars.add_mineral(m, -val)
	
	var new_mineral = Sprite2D.new()
	new_mineral.position = pos
	
	var atlas = AtlasTexture.new()
	atlas.atlas = minerals.get(m)
	atlas.set_region(Rect2(
		CHANGES[val] * 24,
		0,
		24,
		20
	))
	
	new_mineral.texture = atlas
	
	add_child(new_mineral)
	
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(
		new_mineral, 
		"position", 
		amounts_text.global_position + Vector2(0, mineral_order[m] * 25), 
		.6
	)
	t.finished.connect(
		func ():
			new_mineral.queue_free()
			consolidated_values[m] += val
			write_values()
			amounts.show()
			
			if played_deposit_sfx > 0:
				played_deposit_sfx -= 1
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MULTIPLE_DEPOSIT)
	)

func _calc_change(amount: int) -> Dictionary[int, int]:
	var values: Array[int] = [1, 10, 100, 1000, 10000]
	var change: Dictionary[int, int] = {1: 0, 10: 0, 100: 0, 1000: 0, 10000: 0}
	
	_calc_chance_aux(amount, values, change)
	return change

func _calc_chance_aux(n: int, values: Array[int], change: Dictionary[int, int]) -> Dictionary[int, int]:
	var back = values.back()
	
	if len(values) == 1:
		change[back] += n
		return change
	
	if n == back:
		change[back] += 1
		return change
	
	if n > back:
		change[back] += n / back
		n /= back
		values.pop_back()
		return _calc_chance_aux(n, values, change)
	
	if n < back:
		values.pop_back()
		return _calc_chance_aux(n, values, change)

	push_error("change not calculated correctly")
	return change
