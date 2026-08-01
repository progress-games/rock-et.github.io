extends Camera2D

# yeah yeah yeah tell it to the next guy
@onready var opening: Node2D = $"../Background/Opening"

@onready var day_count := $Calendar/DayCount

var tweened_home := false
var collect_mineral := preload("res://common/ui/collect_mineral/collect_mineral.tscn")
const SPEED := 1.5
@onready var game_complete: GameComplete = $GameComplete
@onready var endless_bg: Sprite2D = $EndlessBg

func _ready() -> void:
	GameManager.state_changed.connect(update_facing)
	GameManager.collect_mineral.connect(_collect_mineral)
	GameManager.day_changed.connect(func (_d): day_count.text = str(GameManager.day))
	GameManager.planet_changed.connect(func (p): 
		if p == Enums.Planet.KRUOS and GameManager.demo_mode:
			$Calendar.visible = false
			$Feedback.visible = false
			GameManager.clear_inventory.emit()
			GameManager.hide_inventory.emit()
			game_complete.show())
	update_facing(GameManager.state)
	global_position = opening.global_position + Vector2(160, 90)

func update_facing(new_facing: Enums.State) -> void:
	if game_complete.visible: return
	
	if new_facing == Enums.State.HOME && !tweened_home:
		var t = create_tween()
		t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		t.tween_property(self, "position:y", 90, 3)
		
		var t2 = Timer.new()
		t2.wait_time = 2
		t2.timeout.connect(func (): 
			GameManager.state_changed.connect(func (s):
				$Calendar.visible = s == Enums.State.HOME
				$Feedback.visible = s == Enums.State.HOME
			)
			t2.queue_free()
		)
		add_child(t2)
		t2.start()
	
	day_count.text = str(GameManager.day)

func _process(_d: float) -> void:
	endless_bg.visible = GameManager.endless
	
	"""
	if $"../Background".position.y >= -180 and !GameManager.endless:
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		$GameComplete.visible = true
		$GameComplete/Days.text = $GameComplete/Days.text.replace("DAYS", str(GameManager.day))
		get_tree().paused = true
	"""

func _collect_mineral(_mineral: Mineral) -> void:
	var new_mineral = collect_mineral.instantiate()
	new_mineral.position = _mineral.global_position - position
	new_mineral.texture = _mineral.mineral_tex
	new_mineral.target = $Inventory.position
	new_mineral.rotation = _mineral.rotation
	new_mineral.value = _mineral.value
	new_mineral.mineral = _mineral.mineral
	
	add_child(new_mineral)
	GameManager.show_mineral.emit(_mineral.mineral)
