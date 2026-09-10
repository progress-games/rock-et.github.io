extends Control

@onready var click_boost: UpgradeButton = $"../BaseUpgrades/Wall/Freeze/ClickBoost"
@onready var freeze_chance: UpgradeButton = $"../BaseUpgrades/Wall/Freeze/FreezeChance"
@onready var freeze_dur: UpgradeButton = $"../BaseUpgrades/Wall/Freeze/FreezeDur"
@onready var locked_tab: TextureButton = $"../BaseUpgrades/Tabs/LockedTab"
@onready var shards_arrow: TextureRect = $ShardsArrow

@onready var dialogue: Array[Label] = [
	$Intro, 
	$Freeze, 
	$Blackhole, 
	$ClickBoost, 
	$Important, 
	$Shards
]
@onready var speech_bubble: SpeechBubble = $"../SpeechBubble"
@onready var next: Button = $Next

var current_idx := -1

func _ready() -> void:
	#GameManager.add_mineral.emit(Enums.Mineral.LARIMAR, 100000)
	
	if GameManager.tutorial_progress.has(Enums.Tutorial.EGG): queue_free()
	
	hide()
	speech_bubble.tree_exited.connect(func(): 
		var t = Timer.new()
		t.timeout.connect(
			func (): next_line(); show(); t.queue_free()
		)
		add_child(t)
		t.start(1.)
	)
	next.pressed.connect(next_line)

func next_line() -> void:
	next.hide()
	dialogue[max(current_idx, 0)].visible = false
	current_idx += 1
	
	if current_idx == dialogue.size() - 1:
		next.text = "done"
		next.pressed.disconnect(next_line)
		next.pressed.connect(queue_free)
	
	if current_idx == 3:
		click_boost.z_index = 7
	else:
		click_boost.z_index = 0
	
	if current_idx == 1:
		freeze_chance.z_index = 7
		freeze_dur.z_index = 7
	else:
		freeze_chance.z_index = 0
		freeze_dur.z_index = 0
	
	if current_idx == 5:
		locked_tab.z_index = 7
		shards_arrow.show()
	else:
		locked_tab.z_index = 0
	
	var label = dialogue[current_idx]
	label.visible = true
	
	var text = label.text
	label.text = ""
	
	var t = create_tween()
	t.tween_property(label, "text", text, text.length() * 0.03)
	t.finished.connect(
		func ():
			var n = Timer.new()
			n.timeout.connect(func (): next.show(); n.queue_free())
			add_child(n)
			n.start(0.2)
	)
