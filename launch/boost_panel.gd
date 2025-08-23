extends Node2D

const MIN_HEIGHT := 4
const BASE_POS := -53
const MINERAL_COLOUR := Color("cd683d")
const SELECTED_MINERAL_COLOUR := Color('9e4539')
const MINERALS_PER_PAGE := 4
const MAX_PROGRESS := 0.6

var boost: float
var order: Array[Enums.Mineral] = []
var page: int = 0
var progress: float

func _ready() -> void:
	# get order minerals appear in
	for asteroid in GameManager.asteroid_spawns:
		for drop in asteroid.drops:
			if !order.has(drop):
				order.append(drop)
	
	$Ship.max_value = MAX_PROGRESS
	
	_set_progress()
	_set_minerals()

func _set_progress() -> void:
	progress = $Ship.value / MAX_PROGRESS
	
	$Price.text = Math.format_number_short(pow(progress * 100, 1.4))
	
	var height = min($TotalProgress.size.y, floor(MIN_HEIGHT + progress * $TotalProgress.size.y))
	$BoostProgress.size.y = height
	$BoostProgress.position.y = BASE_POS - height + MIN_HEIGHT

func _set_minerals() -> void:
	for node in $TotalProgress/Minerals.get_children():
		node.queue_free()
	
	for i in range(MINERALS_PER_PAGE):
		var new_rect = TextureRect.new()
		new_rect.texture = load("res://bleeg/assets/minerals/" + 
			Enums.Mineral.find_key(
				order[order.size() - 1 - i + MINERALS_PER_PAGE * page]
			).to_lower() + ".png")
		new_rect.set_stretch_mode(TextureRect.StretchMode.STRETCH_KEEP_CENTERED)
		new_rect.set_v_size_flags(TextureRect.SizeFlags.SIZE_EXPAND)
		new_rect.set_meta("mineral", order.size() - 1 - i)
		
		if order.size() - 1 - i <= floor(progress * MINERALS_PER_PAGE):
			new_rect.self_modulate = SELECTED_MINERAL_COLOUR
		else:
			new_rect.self_modulate = MINERAL_COLOUR
		
		$TotalProgress/Minerals.add_child(new_rect)

func _on_ship_value_changed(value: float) -> void:
	$Ship.value = min($Ship.value, GameManager.get_stat("boost_distance").value / 4 * $Ship.max_value)
	_set_progress()
	_set_minerals()
