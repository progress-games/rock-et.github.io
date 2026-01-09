extends Node2D

enum DisplayMode {
	LAUNCH,
	VIEW
}

## minimum height of progress bars
const MIN_HEIGHT := 4

## locked mineral colour (lighter brown)
const LOCKED_MINERAL_COLOUR := Color("cd683d")

## unlocked mineral colour (darker brown)
const UNLOCKED_MINERAL_COLOUR := Color('9e4539')

## unlocking mineral colour (yellowish orange)
const UNLOCKING_MINERAL_COLOUR := Color("fbb954")

## number of minerals shown at once (not implemented yet)
const MINERALS_PER_PAGE := 4

## height of boost bar
const BOOST_HEIGHT := 84

## to account for the size of the ship sprite on the slider, we need to add some leeway
const SHIP_BUFFER := 20

## because we're increasing the height of the slider, we need to adjust the position
const SHIP_OFFSET := -10

## determines if the slider is visible or not
@export var mode: DisplayMode

signal progress_changed(progress: float)

var boost: float
var order: Array[Array] = []
var page: int = 0
var max_progress: float
var progress: float

func _ready() -> void:
	# get order minerals appear in
	for asteroid in GameManager.asteroid_spawns:
		for drop in asteroid.drops:
			if !order.any(func(p): return p[0] == drop):
				# eg [Kyanite, 0.6]
				order.append([drop, asteroid.start])
	
	StatManager.stat_upgraded.connect(func (s): if s.stat_name == "boost_distance": _set_max())
	
	$ShipSlider.visible = mode == DisplayMode.LAUNCH
	$ShipSprite.visible = !$ShipSlider.visible
	
	_set_max()
	_set_progress()
	_set_minerals()
	set_mineral_colours()

func _set_max() -> void:
	var start = order[MINERALS_PER_PAGE * page]
	var end = order[MINERALS_PER_PAGE * (page + 1) - 1]
	
	if mode == DisplayMode.LAUNCH:
		max_progress = min(1, StatManager.get_stat("boost_distance").value / end[1])
	else:
		max_progress = 1
		progress = min(1, StatManager.get_stat("boost_distance").value / end[1])
		
		$BoostProgress.size.y = progress * BOOST_HEIGHT
		$BoostProgress.position.y = (1 - progress) * BOOST_HEIGHT
		
		var next_level_value = min(1, StatManager.get_stat("boost_distance").next_level.value / end[1])
		$UnlockingProgress.size.y = next_level_value * BOOST_HEIGHT
		$UnlockingProgress.position.y = (1 - next_level_value) * BOOST_HEIGHT
		
		$ShipSprite.position.y = (1 - progress) * BOOST_HEIGHT
	
	# Set height of total progress (the furthest we can boost with this upgrade)
	$TotalProgress.size.y = max_progress * BOOST_HEIGHT
	$TotalProgress.position.y = (1 - max_progress) * BOOST_HEIGHT
	
	# Set height of ship slider
	$ShipSlider.min_value = start[1]
	$ShipSlider.max_value = min(StatManager.get_stat("boost_distance").value, end[1])
	$ShipSlider.value = progress
	$ShipSlider.size.y = max_progress * BOOST_HEIGHT + SHIP_BUFFER
	$ShipSlider.position.y = (1 - max_progress) * BOOST_HEIGHT + SHIP_OFFSET

func _set_progress() -> void:
	progress = $ShipSlider.value
	
	var height = min($TotalProgress.size.y, floor(MIN_HEIGHT + (progress / $ShipSlider.max_value) * $TotalProgress.size.y))
	$BoostProgress.size.y = height
	$BoostProgress.position.y = BOOST_HEIGHT - height

func _set_minerals() -> void:
	for node in $Minerals.get_children():
		node.queue_free()
	
	for i in range(MINERALS_PER_PAGE):
		var idx = i + MINERALS_PER_PAGE * page
		var mineral = Enums.Mineral.find_key(order[idx][0])
		# put this on a scale: [0.1, 0.2, 0.5] -> [0, 0.1, 0.4] -> [0, 0.25, 1]
		var point = (order[idx][1] - order[idx - i][1]) / order[idx + (MINERALS_PER_PAGE - i - 1)][1]
		
		var new_rect = TextureRect.new()
		new_rect.texture = load("res://bleeg/assets/minerals/" + mineral.to_lower() + ".png")
		
		$Minerals.add_child(new_rect)
		new_rect.position.y += (1 - point) * $Minerals.size.y
		new_rect.position.x = ($Minerals.size.x - new_rect.texture.get_size().x) / 2
		new_rect.set_meta("mineral", idx)

func _on_ship_value_changed(value: float) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SLIDER)
	_set_progress()
	_set_minerals()
	set_mineral_colours()
	progress_changed.emit(value)

func set_mineral_colours(show_upgrade: bool = false) -> void:
	var end = order[MINERALS_PER_PAGE * (page + 1) - 1]
	var next_level_value = StatManager.get_stat("boost_distance").next_level.value / end[1]
	$UnlockingProgress.visible = show_upgrade
	
	for node in $Minerals.get_children():
		if !node.has_meta("mineral"): continue
		
		# progress val this mineral unlocks at
		var val = order[node.get_meta("mineral")][1] / end[1]
		
		# ajhjjjjjgjpo[wjrgpow
		if mode == DisplayMode.LAUNCH: val *= end[1]
		
		# consider progress to be ship position
		if val <= progress:
			node.self_modulate = UNLOCKED_MINERAL_COLOUR
		elif val <= next_level_value and show_upgrade:
			node.self_modulate = UNLOCKING_MINERAL_COLOUR
		else:
			node.self_modulate = LOCKED_MINERAL_COLOUR
