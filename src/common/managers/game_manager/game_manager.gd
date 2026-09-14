extends Node2D

const KRUOS_CLICK_TIMER := 9999.
const INITIAL_STATE := Enums.State.OPENING
const BASE_SPAWN := {
	"interval": 2.5,
	"mean": 1,
	"sd": 0.3
}

const FEEDBACK_LINK := "https://forms.gle/YEPHf47NBtVLg9Mj7"

var player: Player
var location: Vector2
var state: Enums.State

@export var blizzard_chance: float = 0.16

@export_group("Mission")
@export var asteroid_spawns: Array[AsteroidData]
@export var level_data: Array[LevelData]
@export var mineral_data: Dictionary[Enums.Mineral, MineralData]
@export var powerup_data: Dictionary[Powerup.PowerupType, PowerupData]

var powerup_modifiers: Dictionary[Powerup.PowerupType, float] = {
	Powerup.PowerupType.DOUBLE_MINERALS: 0., # next n minerals drop double
	Powerup.PowerupType.SNOW_TRAIL: 0., # next n clicks are double clicks
	Powerup.PowerupType.LASER: 0., # next n rocks are instantly broken
	Powerup.PowerupType.MORE_ROCKS: 0., # next rock broken spawns n additional new rocks
	Powerup.PowerupType.PAUSE: 0., # all rocks are frozen for n seconds
	Powerup.PowerupType.SIZE_UP: 0., # target size up
	Powerup.PowerupType.AUTOCLICK: 0.
}

@export_group("Preload")
@export var particles: Dictionary[String, PackedScene]

const SCREEN_HEIGHT := 180

## the total distance the player must fly to reach the next planet
const DISTANCES: Dictionary[Enums.Planet, int] = {
	Enums.Planet.DYRT: 3200 - SCREEN_HEIGHT,
	Enums.Planet.KRUOS: 3200,
	Enums.Planet.VULCAN: 1000
}

# how long the player took to reach each planet (used for alfheim)
var days_taken: Array[int] = [
	0, # DYRT
	0, # KRUOS
	0  # VULCAN
]

## tutorial phase
var tutorial_progress: Array[Enums.Tutorial] = []

## the current day. the first day is 1
var day: int = 1

## if we stop at kruos or not pre much
var demo_mode: bool = false

## the current planet
var planet: Enums.Planet = Enums.Planet.DYRT

## the target distance for the current planet
var planet_distance: int

var remove_preload_timer: Timer

var click_multiplier: float = 1.

var weights: Dictionary[Enums.Asteroid, float]

var endless := false

var using_hitbar := false

## used for lightening asteroid rings
var lighten_hits := false

# inventory
@warning_ignore("unused_signal")
signal show_mineral(mineral: Enums.Mineral)
@warning_ignore("unused_signal")
signal set_inventory(state: Enums.InventoryState, faded: bool, position: Vector2)
@warning_ignore("unused_signal")
signal clear_inventory()
@warning_ignore("unused_signal")
signal show_inventory()
@warning_ignore("unused_signal")
signal hide_inventory()

# mission
@warning_ignore("unused_signal")
signal boost(amount: float)
@warning_ignore("unused_signal")
signal asteroid_broke()
@warning_ignore("unused_signal")
signal time_added()
signal click_boosted()

#mouse
@warning_ignore("unused_signal")
signal set_mouse_state(state: Enums.MouseState)
@warning_ignore("unused_signal")
signal asteroid_hit(asteroid: Asteroid, hit_data: HitData)
@warning_ignore("unused_signal")
signal powerup_hit(powerup: Powerup)
signal finished_holding()
@warning_ignore("unused_signal")
signal hide_discovery()
@warning_ignore("unused_signal")
signal out_of_clicks()
@warning_ignore("unused_signal")
signal multi_hit()

# state
signal state_changed(state: Enums.State)
signal day_changed(day: int)
@warning_ignore("unused_signal")
signal get_managed_state(state: Enums.State)
signal planet_changed(planet: Enums.Planet)
signal read_state_dialogue(state: Enums.State)
signal blizzard_started()
signal state_revealed(state: Enums.State)

signal endless_started()

# mineral
signal add_mineral(mineral: Enums.Mineral, amount: float)
signal collect_mineral(mineral: Mineral, position: Vector2)

# when needing to change music but not yet planet
signal music_changed(planet: Enums.Planet)

# pause/play
signal pause()
signal play()

signal tutorial_read(t: Enums.Tutorial)

var pause_locked: bool = false

# can't click in zen mode
var zen_mode: bool = false

var active_blizzard: bool = false

# use spacebar in trackpad mode
var trackpad_mode: bool = true

var current_click_boost: float = 0

var state_data: Dictionary[Enums.State, Dictionary]

func _ready() -> void:
	player = Player.new()
	
	pause.connect(func (): if !pause_locked: get_tree().paused = true)
	play.connect(func (): if !pause_locked: get_tree().paused = false)
	
	state_changed.connect(_state_changed)
	day_changed.connect(on_day_change)
	planet_changed.connect(on_planet_change)
	call_deferred("_emit_initial_state")
	
	finished_holding.connect(play.emit)
	
	click_boosted.connect(click_boost)

func read_tutorial(t: Enums.Tutorial) -> void:
	tutorial_progress.append(t)
	tutorial_read.emit(t)

func on_day_change(d: int) -> void:
	day = d
	if planet == Enums.Planet.KRUOS && \
	GameManager.player.has_discovered_mineral(Enums.Mineral.AMAZONITE) && \
	randf() <= blizzard_chance:
		active_blizzard = true
		blizzard_started.emit()
	else:
		active_blizzard = false

func on_planet_change(p: Enums.Planet) -> void:
	planet = p
	#days_taken[p] = day 
	clear_inventory.emit()
	planet_distance = DISTANCES[p]

func click_boost() -> void:
	var t = Timer.new()
	t.wait_time = .1
	t.one_shot = true
	current_click_boost += StatManager.get_stat("click_boost").value * 10
	t.timeout.connect(
		func ():
			current_click_boost -= StatManager.get_stat("click_boost").value * 10
			t.queue_free()
	)
	add_child(t)
	t.start()

func _emit_initial_state() -> void:
	day_changed.emit(day)

func _state_changed(new: Enums.State) -> void:
	if state == Enums.State.MISSION:
		reset_powerups()
		weights = {}
		day += 1
		day_changed.emit(day)
		lighten_hits = false
	
	if new == Enums.State.MISSION:
		reset_powerups()
		using_hitbar = player.has_discovered_state(Enums.State.SCIENTIST) &&\
			!player.scientist_disabled && planet != Enums.Planet.KRUOS
	
	state = new

func reset_powerups() -> void:
	powerup_modifiers = {
		Powerup.PowerupType.DOUBLE_MINERALS: 0., # next n minerals drop double
		Powerup.PowerupType.SNOW_TRAIL: 0., # next n clicks are double clicks
		Powerup.PowerupType.LASER: 0., # next n rocks are instantly broken
		Powerup.PowerupType.MORE_ROCKS: 0., # next rock broken spawns n additional new rocks
		Powerup.PowerupType.PAUSE: 0., # all rocks are frozen for n seconds
		Powerup.PowerupType.SIZE_UP: 0., # target size up
		Powerup.PowerupType.AUTOCLICK: 0.
	}

func start_endless() -> void:
	endless = true
	endless_started.emit()

func get_item_stat(item_name: String, stat_name: String, default = 1.) -> Variant:
	return default if !player.has_equipped(item_name) else player.equipped_items[item_name].get_value(stat_name)

func can_afford(amount: float, mineral: Enums.Mineral) -> bool:
	return player.can_afford(amount, mineral)
