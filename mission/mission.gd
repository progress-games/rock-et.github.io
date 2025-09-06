extends Node2D

## Each determines the spawn pool to draw from
@export var increment: float = 0.01

## An constant array of pieces data and mineral drops for each level
var level_data: Array[LevelData] = GameManager.level_data

## A dictionary with any weight multipliers 
var weights: Dictionary[Enums.Asteroid, float]

var duration_timer: Timer = Timer.new()
var distance: float = 0
var progress: float = 0

const CORUNDUM_EFFECT := 2.5

func _enter_tree() -> void:
	$AsteroidSpawner.increment = increment
	$AsteroidSpawner.level_data = level_data
	$MineralSpawner.level_data = level_data

func _ready() -> void:
	$AsteroidSpawner.asteroid_spawned.connect(asteroid_spawned)
	GameManager.mouse_clicked.connect(asteroid_hit)
	
	GameManager.set_mouse_state.emit(Enums.MouseState.MISSION)
	GameManager.play.connect(func(): get_tree().paused = false)
	GameManager.pause.connect(func(): get_tree().paused = true)
	
	GameManager.boost.connect(func (progress: float):
		distance += progress * GameManager.DISTANCE
		progress = distance / GameManager.DISTANCE
		$AsteroidSpawner.progress = progress
	)
	
	duration_timer.wait_time = GameManager.get_stat("fuel_capacity").value
	duration_timer.timeout.connect(mission_ended)
	add_child(duration_timer)
	duration_timer.start()

func mission_ended() -> void:
	GameManager.state_changed.emit(Enums.State.HOME)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	queue_free()

func _process(delta: float) -> void:
	distance += GameManager.player.get_stat("thruster_speed").value * delta
	if (distance / GameManager.DISTANCE) - progress >= increment:
		progress = distance / GameManager.DISTANCE
		$AsteroidSpawner.progress = progress
	
	$FuelBar.material.set_shader_parameter("progress", duration_timer.time_left 
		/ GameManager.get_stat("fuel_capacity").value)

func asteroid_spawned(asteroid: Asteroid) -> void:
	asteroid.asteroid_broken.connect($AsteroidSpawner.break_asteroid)
	asteroid.asteroid_broken.connect($MineralSpawner.spawn_minerals)

func asteroid_hit(asteroid: Node) -> void:
	if !asteroid.has_meta("asteroid"): return
	
	var damage = GameManager.player.get_stat("hit_strength").value
	
	if GameManager.player.has_discovered_state(Enums.State.SCIENTIST):
		$MineralSpawner.calculate_olivine(asteroid)
		
		var colour = GameManager.player.hit_strength
		if colour == "blue":
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.CRITICAL_HIT)
	
		damage = damage * GameManager.player.get_stat(colour + "_damage").value
	
	if asteroid.asteroid_type == Enums.Asteroid.CORUNDUM:
		var new_time: float = duration_timer.time_left - GameManager.get_stat("armour").value
		if new_time > 0: duration_timer.start(new_time)
		else: duration_timer.timeout.emit()
	
	asteroid.hit(damage)
