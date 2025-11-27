extends Control

const DEFAULT_INTERVAL = 0.5

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
	$Next/Dismiss.mouse_exited.connect(func (): $Next/Dismiss.material.set_shader_parameter("width", 0))
	$Next/Dismiss.mouse_entered.connect(func (): $Next/Dismiss.material.set_shader_parameter("width", 1))
	
	interval_timer.wait_time = DEFAULT_INTERVAL
	interval_timer.one_shot = false
	interval_timer.timeout.connect(reveal_row)

func add_mineral(mineral: Enums.Mineral, amount: int) -> void:
	if amount <= 0: return
	
	if !mission_stats.get(mineral) and amount != 0:
		mission_stats[mineral] = amount
		
		var texture_rect = TextureRect.new()
		texture_rect.texture = GameManager.mineral_data[mineral].texture
		
		var amount_label = Label.new()
		amount_label.text = str(amount)
		amount_label.add_theme_font_override("font", load("res://common/fonts/BitPap.ttf"))
		
		var hbox = HBoxContainer.new()
		minerals.add_child(hbox)
		hbox.add_child(amount_label)
		hbox.add_child(texture_rect)
		hbox.set_meta("mineral", mineral)
		hbox.visible = false
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		return
	
	mission_stats[mineral] += amount
	
	for node in minerals.get_children():
		if node.get_meta("mineral") == mineral:
			(node.get_child(0) as Label).text = str(mission_stats[mineral])

func reveal_row() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER_POP)
	
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
	add_child(interval_timer)
	interval_timer.start()
