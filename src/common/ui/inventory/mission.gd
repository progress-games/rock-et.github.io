extends HBoxContainer

const MAX_HEIGHT := 178

const BAR_WIDTH := 4
const BAR_COLOUR := Color(0.18, 0.133, 0.184, 1.0)

var bar_amounts: Dictionary[Enums.Mineral, int]
var bars: Dictionary[Enums.Mineral, ColorRect]

func _ready() -> void:
	GameManager.state_changed.connect(
		func (s):
			if s != Enums.State.MISSION:
				hide()
			else:
				show()
				new_mission()
	)
	
	GameManager.add_mineral.connect(add_mineral)

func new_mission() -> void:
	bars.values().map(func (x): x.queue_free())
	bars.clear()
	bar_amounts.clear()

func create_bar(m: Enums.Mineral) -> void:
	bar_amounts.set(m, 0)
	
	var new_bar = ColorRect.new()
	new_bar.custom_minimum_size.x = 4
	new_bar.color = BAR_COLOUR
	new_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	var fill = ColorRect.new()
	fill.color = GameManager.mineral_data[m].light_colour
	
	new_bar.add_child(fill)
	
	fill.set_anchor_and_offset(SIDE_LEFT, 0, 1)
	fill.set_anchor_and_offset(SIDE_RIGHT, 1, -1)
	fill.set_anchor_and_offset(SIDE_TOP, 0, 1)
	fill.set_anchor_and_offset(SIDE_BOTTOM, 1, -1)
	
	add_child(new_bar)
	bars.set(m, new_bar)

func add_mineral(m: Enums.Mineral, a: int) -> void:
	if !bar_amounts.has(m):
		create_bar(m)
	
	bar_amounts[m] += a
	bars[m].custom_minimum_size.y = MAX_HEIGHT * log(bar_amounts[m]) / 5 / log(10)
	
	if bar_amounts[m] <= 0:
		bars[m].hide()

func get_mineral_position(m: Enums.Mineral) -> Vector2:
	return bars[m].global_position + bars[m].custom_minimum_size
