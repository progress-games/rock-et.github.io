extends Node2D
class_name BoostDisplay

enum DisplayMode {
	LAUNCH,
	VIEW
}

const MINERAL_TEX: Dictionary[Enums.Asteroid, CompressedTexture2D] = {
	Enums.Asteroid.AMETHYST: preload("uid://b4xqv7kb5mxeh"),
	Enums.Asteroid.TOPAZ: preload("uid://de6ecytkdg64d"),
	Enums.Asteroid.KYANITE: preload("uid://bwtrkfiu4oln"),
	Enums.Asteroid.CORUNDUM: preload("uid://dt6u16hckwu52")
}

## minimum height of progress bars
const MIN_HEIGHT := 4

## locked mineral colour (lighter brown)
const LOCKED_MINERAL_COLOUR := Color("cd683d")

## unlocked mineral colour (darker brown)
const UNLOCKED_MINERAL_COLOUR := Color('9e4539')

## unlocking mineral colour (yellowish orange)
const UNLOCKING_MINERAL_COLOUR := Color("fbb954")

## height of boost bar
const BOOST_HEIGHT := 84

## to account for the size of the ship sprite on the slider, we need to add some leeway
const SHIP_BUFFER := 20

## because we're increasing the height of the slider, we need to adjust the position
const SHIP_OFFSET := -10

## maximum boost distance. maxed out boost will go 0.5
const MAX_BOOST_DIS := 0.6

## determines if the slider is visible or not
@export var mode: DisplayMode

signal progress_changed(progress: float)

var boost: float
var order: Array[Array] = []
var page: int = 0

## the furthest we can upgrade/launch (0 - 1)
var max_progress: float

## current amount launching/upgrade level (0 - 1)
var progress: float

@onready var ship_sprite: Sprite2D = $ShipSprite
@onready var ship_slider: VSlider = $ShipSlider

@onready var boost_progress: NinePatchRect = $BoostProgress
@onready var unlocking_progress: NinePatchRect = $UnlockingProgress
@onready var total_progress: NinePatchRect = $TotalProgress

@onready var minerals: ReferenceRect = $Minerals

func _ready() -> void:
	# get order minerals appear in
	for asteroid in GameManager.asteroid_spawns:
		if asteroid.start > MAX_BOOST_DIS or not Enums.Planet.DYRT in asteroid.planets: break
		order.append([asteroid.asteroid_type, asteroid.start])
	
	StatManager.stat_upgraded.connect(func (s): if s.stat_name == "boost_distance": set_max())
	
	ship_slider.visible = mode == DisplayMode.LAUNCH
	ship_sprite.visible = mode == DisplayMode.VIEW
	
	set_max()
	set_progress()
	set_minerals()
	set_mineral_colours()

func set_max_launch_mode() -> void:
	max_progress = min(1, StatManager.get_stat("boost_distance").value / MAX_BOOST_DIS)
	
	# Set height of ship slider
	ship_slider.min_value = 0
	ship_slider.max_value = max_progress
	ship_slider.value = progress
	ship_slider.size.y = max_progress * BOOST_HEIGHT + SHIP_BUFFER
	ship_slider.position.y = (1 - max_progress) * BOOST_HEIGHT + SHIP_OFFSET

func set_max_view_mode() -> void:
	max_progress = 1
	progress = StatManager.get_stat("boost_distance").value / MAX_BOOST_DIS
	
	boost_progress.size.y = progress * BOOST_HEIGHT
	boost_progress.position.y = (1 - progress) * BOOST_HEIGHT
	
	var next_level_value = StatManager.get_stat("boost_distance").next_level.value / MAX_BOOST_DIS
	unlocking_progress.size.y = next_level_value * BOOST_HEIGHT
	unlocking_progress.position.y = (1 - next_level_value) * BOOST_HEIGHT
	
	ship_sprite.position.y = (1 - progress) * BOOST_HEIGHT

func set_max() -> void:
	if mode == DisplayMode.LAUNCH:
		set_max_launch_mode()
	else:
		set_max_view_mode()
	
	# Set height of total progress (the furthest we can boost with this upgrade)
	total_progress.size.y = max_progress * BOOST_HEIGHT
	total_progress.position.y = (1 - max_progress) * BOOST_HEIGHT

func set_progress() -> void:
	progress = ship_slider.value
	
	var height = min(total_progress.size.y, 
		floor(MIN_HEIGHT + (progress / max_progress) * total_progress.size.y))
	
	boost_progress.size.y = height
	boost_progress.position.y = BOOST_HEIGHT - height

func set_minerals() -> void:
	for node in minerals.get_children():
		node.queue_free()
	
	for i in order.size():
		var val = order[i]
		var asteroid_type = val[0]
		var spawn_progress = val[1]
		
		var new_rect = TextureRect.new()
		new_rect.texture = MINERAL_TEX[asteroid_type]
		
		minerals.add_child(new_rect)
		new_rect.position.y += (1 - spawn_progress / MAX_BOOST_DIS) * minerals.size.y
		new_rect.position.x = (minerals.size.x - new_rect.texture.get_size().x) / 2
		new_rect.set_meta("mineral", i)

func _on_ship_value_changed(value: float) -> void:
	if value != 0.0: 
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SLIDER)
	set_progress()
	set_minerals()
	set_mineral_colours()
	progress_changed.emit(value)

func set_mineral_colours(show_upgrade: bool = false) -> void:
	var next_level_value = StatManager.get_stat("boost_distance").next_level.value / MAX_BOOST_DIS
	unlocking_progress.visible = show_upgrade
	
	for node in minerals.get_children():
		if !node.has_meta("mineral"): continue
		
		# progress val this mineral unlocks at
		var val = order[node.get_meta("mineral")][1] / MAX_BOOST_DIS
		
		# consider progress to be ship position
		if val <= progress:
			node.self_modulate = UNLOCKED_MINERAL_COLOUR
		elif val <= next_level_value and show_upgrade:
			node.self_modulate = UNLOCKING_MINERAL_COLOUR
		else:
			node.self_modulate = LOCKED_MINERAL_COLOUR
