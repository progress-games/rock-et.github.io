extends Control

const DEFAULT_INTERVAL = 0.5
const DEFAULT_THEME = preload("uid://cr6q3vlvjjgb7")
const BIT_PAP = preload("uid://cmwv2cvr5llki")
const NEW = "f9c22b"

# discovered[Enums.EnumType.MINERAL][mineral] = true
@onready var d: Array = GameManager.player.discovered[Enums.EnumType.MINERAL].keys().filter(
	func (k):
		return GameManager.player.discovered[Enums.EnumType.MINERAL][k]
)
var mission_stats: Dictionary[Enums.Mineral, Variant] = {}
var interval_timer: Timer = Timer.new()
@onready var minerals := $VBoxContainer/MineralContainer/Minerals/Minerals

func _ready() -> void:
	GameManager.add_mineral.connect(add_mineral)
	for node in minerals.get_children(): 
		node.queue_free()
	$Next/Dismiss.pressed.connect(GameManager.play.emit)
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
	
	interval_timer.wait_time = DEFAULT_INTERVAL
	interval_timer.one_shot = false
	interval_timer.timeout.connect(reveal_row)

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
			node.text += str(mission_stats[mineral])
			if !(mineral in d): node.text += "[color=#f9c22b][wave amp=25.0 freq=5.0 connected=1] new!"
			

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

func play() -> void:
	for node in minerals.get_children():
		var t = node.text.replace("AMOUNT", str(mission_stats[node.get_meta("mineral")]))
		node.text = t
	add_child(interval_timer)
	interval_timer.start()
