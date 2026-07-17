extends Control

@export var tips: Array[Tip]

const DEFAULT_INTERVAL = 0.5
const DEFAULT_THEME = preload("uid://cr6q3vlvjjgb7")
const BIT_PAP = preload("uid://cmwv2cvr5llki")
const NEW = "f9c22b"

var mission_stats: Dictionary[Enums.Mineral, Variant] = {}
var interval_timer: Timer = Timer.new()
@onready var minerals := $VBoxContainer/MineralContainer/Minerals/Minerals

@onready var tip_text: RichTextLabel = $Tip
@onready var mute_blue: TextureButton = $MuteBlue

func _ready() -> void:
	GameManager.add_mineral.connect(add_mineral)
	for node in minerals.get_children(): 
		node.queue_free()
	$Next/Dismiss.pressed.connect(func ():
		GameManager.pause_locked = false
		GameManager.play.emit()
		GameManager.day_changed.emit(GameManager.day + 1)
		GameManager.state_changed.emit(Enums.State.HOME)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.LAND)
		GameManager.show_inventory.emit()
		get_parent().queue_free())
	$Next/Calendar/Day.text = str(GameManager.day)
	$Next/Dismiss.visible = false
	$Next/Calendar.visible = false
	$Next/Dismiss.mouse_exited.connect(func (): 
		$Next/Dismiss.material.set_shader_parameter("width", 0)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
	$Next/Dismiss.mouse_entered.connect(func (): 
		$Next/Dismiss.material.set_shader_parameter("width", 1)
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER))
	
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	
	interval_timer.wait_time = DEFAULT_INTERVAL
	interval_timer.one_shot = false
	interval_timer.timeout.connect(reveal_row)
	mute_blue.visible = StatManager.get_stat("blue_portion").level > 1

func add_mineral(mineral: Enums.Mineral, amount: int) -> void:
	if amount <= 0: return
	
	if !mission_stats.get(mineral) and amount != 0:
		mission_stats[mineral] = amount
		
		var amount_label = RichTextLabel.new()
		amount_label.bbcode_enabled = true
		amount_label.fit_content = true
		amount_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		amount_label.add_theme_font_override("normal_font", BIT_PAP)
		amount_label.set_meta("mineral", mineral)
		
		minerals.add_child(amount_label)
		
		return
	
	mission_stats[mineral] += amount
	
	for node in minerals.get_children():
		if node.get_meta("mineral") == mineral:
			node.text = "[img]res://common/minerals/" + Enums.Mineral.find_key(mineral).to_lower() + ".png[/img] "
			node.text += str(Math.format_number_short(mission_stats[mineral]))
			

func reveal_row() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.POP)
	
	for node in minerals.get_children():
		if !node.visible:
			node.visible = true
			return
	
	if !$Next/Calendar.visible:
		$Next/Calendar.visible = true
	else:
		$Next/Dismiss.visible = true
		interval_timer.stop()
		interval_timer.queue_free()

func play() -> void:
	GameManager.state = Enums.State.HOME
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	for node in minerals.get_children():
		var t = node.text.replace("AMOUNT", str(mission_stats[node.get_meta("mineral")]))
		node.text = t
	add_child(interval_timer)
	interval_timer.start()
	choose_tip()

func choose_tip() -> void:
	var unlocked_tips = tips.filter(func (t: Tip):
		return ((t.requirement == Tip.RequirementType.STATE && \
		GameManager.player.has_discovered_state(t.state_req)) || \
		(t.requirement == Tip.RequirementType.MINERAL && \
		GameManager.player.has_discovered_mineral(t.mineral_req)))
	)
	
	var filtered_tips: Dictionary[Tip.TipType, Array] = {
		Tip.TipType.SERIOUS: unlocked_tips.filter(func (t: Tip): return t.tip_type == Tip.TipType.SERIOUS),
		Tip.TipType.JOKE: unlocked_tips.filter(func (t: Tip): return t.tip_type == Tip.TipType.JOKE)
	}
	
	filtered_tips.values().map(func (a: Array[Tip]):
		a.sort_custom(func (x:Tip, y:Tip):
			return x.shown < y.shown)
			)
	
	var next_a: Tip = filtered_tips[Tip.TipType.SERIOUS].front()
	var next_b: Tip = filtered_tips[Tip.TipType.JOKE].front()
	var next: Tip
	
	if next_a.shown > Tip.SHOULD_BE_SHOWN and next_a.shown == next_b.shown:
		next = ([next_a, next_b]).pick_random()
	elif next_a.shown > Tip.SHOULD_BE_SHOWN and next_a.shown > next_b.shown: 
		next = next_b
	else: 
		next = next_a
	
	next.shown += 1
	tip_text.text = "[wave amplitude=40.0 freq=7.0]tip: " + next.text
	
