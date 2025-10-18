extends Node2D

@export var rates: Dictionary[Enums.Mineral, ExchangeRate]
@export var origin: Vector2
@export var y_height: int
@export var x_width: int

const DEFAULT_TRANSFER := 100
const TRANSFER_AMOUNTS := [100, 500, 2500, 10000, 50000, 1000000]
const GREEN := Color("91db69")
const RED := Color("ae2334")

# temporary day counter for testing
var day = 0

var transfer_amount: int = 100
var transfer_mults: Array
var selected_mineral: Enums.Mineral = Enums.Mineral.AMETHYST
var unlocked_minerals: Array[Enums.Mineral] = [Enums.Mineral.AMETHYST]

func _ready() -> void:
	transfer_mults = TRANSFER_AMOUNTS.map(func (x): return x / DEFAULT_TRANSFER)
	GameManager.player.mineral_discovered.connect(func (m: Enums.Mineral): 
		if !unlocked_minerals.has(m) and m != Enums.Mineral.GOLD: unlocked_minerals.append(m); change_mineral())
	GameManager.day_changed.connect(new_day)
	for rate in rates.values(): rate.set_up()
	$Exchange/NextMineral.material = $Exchange/NextMineral.material.duplicate()
	$Exchange/PrevMineral.material = $Exchange/PrevMineral.material.duplicate()
	
	change_transfer()

func new_day(day: int) -> void:
	for rate in rates.values():
		rate.get_exchange(day)
	
	generate_points()

## generates the graph for the selected mineral
func generate_points() -> void:
	var selected_rate = rates[selected_mineral]
	var transfer_mult: int = transfer_mults[TRANSFER_AMOUNTS.find(transfer_amount)]
	var current = selected_rate.target.current * transfer_mult
	var all_rates = selected_rate.past_rates.map(func (x): return x * transfer_mult)
	var _min = all_rates.min() - (10 * (transfer_mult / 4))
	var _max = all_rates.max() + (10 * (transfer_mult / 4))
	var interval = (_max - _min) / 4
	var point_positions = []
	
	# set texts
	$TransferInfo/GoldPanel/Amount.text = Math.format_number_short(int(current))
	$Stats/MaxMin/Max.text = Math.format_number_short(int(selected_rate.stats.max))
	$Stats/MaxMin/Min.text = Math.format_number_short(int(selected_rate.stats.min))
	$Stats/Average/Centering/AverageNum.text = Math.format_number_short(int(selected_rate.stats.average))
	
	# set y axis values
	var lbl = _min
	for i in range(5):
		(get_node("Graph/Exchange/" + str(i)) as Label).text = Math.format_number_short(int(lbl))
		lbl += interval
	
	for i in range(10):
		var d = max(GameManager.day - 9 + i, i + 1)
		
		# set x axis values
		(get_node("Graph/Days/" + str(i)) as Label).text = str(d)
		
		# if this day has occurred yet
		if d <= GameManager.day:
			
			# generate position based on origin + offset
			var y_pos = -1 * y_height * ((all_rates[i] - _min) / (_max - _min))
			var pos = origin + Vector2(x_width * (i / 9.0), y_pos)
			
			var point = get_node("Graph/Points/" + str(i)) as Sprite2D
			point.visible = true
			point.position = pos
			point_positions.append(pos)
			
			# dont generate a line for the starting point bc theres no point behind
			if d > max(1, GameManager.day - 9):
				var line = get_node("Graph/Lines/" + str(i - 1)) as Line2D
				line.visible = true
				line.clear_points()
				line.add_point(point_positions[i-1])
				line.add_point(point_positions[i])
				var increasing = point_positions[i-1].y < point_positions[i].y
				line.default_color = RED if increasing else GREEN

func on_hover(node: String) -> void:
	match node:
		"increase": $TransferInfo/Increase.material.set_shader_parameter("width", 1)
		"decrease": $TransferInfo/Decrease.material.set_shader_parameter("width", 1)
		"exchange": $Exchange/ExchangeButtonOutline.visible = true

func off_hover(node: String) -> void:
	match node:
		"increase": $TransferInfo/Increase.material.set_shader_parameter("width", 0)
		"decrease": $TransferInfo/Decrease.material.set_shader_parameter("width", 0)
		"exchange": $Exchange/ExchangeButtonOutline.visible = false

func change_transfer(direction: int = 0) -> void:
	transfer_amount = TRANSFER_AMOUNTS[
		clamp(TRANSFER_AMOUNTS.find(transfer_amount) + direction, 0, TRANSFER_AMOUNTS.size() - 1)
	]
	$TransferInfo/ExchangeMineral/Amount.text = Math.format_number_short(transfer_amount)
	$Exchange/ExchangeDisabled.visible = GameManager.player.minerals[selected_mineral] < transfer_amount
	$Exchange/ExchangeButton.visible = !$Exchange/ExchangeDisabled.visible
	if GameManager.day > 1: generate_points()

func change_mineral(direction: int = 0) -> void:
	selected_mineral = unlocked_minerals[
		(unlocked_minerals.find(selected_mineral) + direction) % unlocked_minerals.size()
	]
	var new_colours = [
		GameManager.mineral_data[selected_mineral].light_colour,
		GameManager.mineral_data[selected_mineral].mid_colour
	]
	GameManager.clear_inventory.emit()
	GameManager.show_mineral.emit(Enums.Mineral.GOLD)
	GameManager.show_mineral.emit(selected_mineral)
	$TransferInfo/ExchangeMineral/Mineral.texture = GameManager.mineral_data[selected_mineral].texture
	$Exchange/ExchangeButton/Mineral.texture = GameManager.mineral_data[selected_mineral].texture
	$TransferInfo/ExchangeMineral.material.set_shader_parameter("replacement_colors", new_colours)
	$Stats/Average.material.set_shader_parameter("replacement_colors", new_colours)
	$Stats/MaxMin.material.set_shader_parameter("replacement_colors", new_colours)
	
	var next_mineral = unlocked_minerals[
		(unlocked_minerals.find(selected_mineral) + 1) % unlocked_minerals.size()
	]
	var next_colours = [
		GameManager.mineral_data[next_mineral].light_colour,
		GameManager.mineral_data[next_mineral].mid_colour
	]
	$Exchange/NextMineral.material.set_shader_parameter("replacement_colors", next_colours)
	
	var prev_mineral = unlocked_minerals[
		(unlocked_minerals.find(selected_mineral) - 1) % unlocked_minerals.size()
	]
	var prev_colours = [
		GameManager.mineral_data[prev_mineral].light_colour,
		GameManager.mineral_data[prev_mineral].mid_colour
	]
	$Exchange/PrevMineral.material.set_shader_parameter("replacement_colors", prev_colours)

	$Exchange/ExchangeDisabled/Label.text = "not enough\n" + Enums.Mineral.find_key(selected_mineral).to_lower()
	
	# this also generates points
	change_transfer()
	
func exchange_mineral() -> void:
	if !GameManager.can_afford(transfer_amount, selected_mineral): return
	GameManager.add_mineral.emit(Enums.Mineral.GOLD, rates[selected_mineral].target.current)
	GameManager.add_mineral.emit(selected_mineral, -transfer_amount)

func _on_exchange_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		exchange_mineral()
