extends Node2D

## Each determines the spawn pool to draw from
@export var increment: float = 0.01

## An constant array of pieces data and mineral drops for each level
var level_data: Array[LevelData] = GameManager.level_data

## A dictionary with any weight multipliers 
var weights: Dictionary[Enums.Asteroid, float]

var duration_timer: Timer = Timer.new()
var boxing_hits: int

var distance: float = 0
var progress: float = 0

const CORUNDUM_EFFECT := 2
const LIGHTNING_SCENE = preload("res://mission/effects/lightning/lightning.tscn")
const DAY_RECAP := preload("res://common/ui/day_recap/day_recap.tscn")
const CORUNDUM_HIT := preload("res://mission/effects/corundum_hit.tscn")

func _enter_tree() -> void:
	$AsteroidSpawner.increment = increment
	$AsteroidSpawner.level_data = level_data
	$MineralSpawner.level_data = level_data
	$Countdown.visible = false

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
	
	$FuelBar.visible = true
	
	$BoxingGlove.visible = GameManager.player.has_equipped("boxing_gloves")
	if GameManager.player.has_equipped("boxing_gloves"):
		boxing_hits = GameManager.get_item_stat("boxing_gloves", "hits")
		$BoxingGlove.material.set_shader_parameter("progress", 1)

func mission_ended() -> void:
	if GameManager.player.equipped_items.has("harvesting"):
		$MineralSpawner.collect_all()
	
	GameManager.pause.emit()
	$DayRecap.play()
	$DayRecap.visible = true
	GameManager.state_changed.emit(Enums.State.HOME)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	$FuelBar.visible = false
	
	GameManager.play.connect(func ():
		GameManager.state_changed.emit(Enums.State.HOME)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.LAND)
		queue_free()
	)

func _process(delta: float) -> void:
	distance += GameManager.player.get_stat("thruster_speed").value * delta
	if (distance / GameManager.DISTANCE) - progress >= increment:
		progress = distance / GameManager.DISTANCE
		$AsteroidSpawner.progress = progress
	
	$FuelBar.material.set_shader_parameter("progress", duration_timer.time_left 
		/ GameManager.get_stat("fuel_capacity").value)
	
	if duration_timer.time_left <= 5:
		$Countdown.visible = true
		if $Countdown.text != str(int(ceil(duration_timer.time_left))):
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.COUNTDOWN)
		$Countdown.text = str(int(ceil(duration_timer.time_left)))
		$Countdown.add_theme_color_override(
			"font_color", 
			Color.TRANSPARENT.lerp(Color.WHITE, lerp(1, 0, duration_timer.time_left/5)))


func asteroid_spawned(asteroid: Asteroid) -> void:
	asteroid.asteroid_broken.connect($AsteroidSpawner.break_asteroid)
	asteroid.asteroid_broken.connect($MineralSpawner.spawn_minerals)

func asteroid_hit(asteroid: Node) -> void:
	if !asteroid.has_meta("asteroid"): return
	
	var damage = GameManager.player.get_stat("hit_strength").value * GameManager.click_multiplier
	
	if GameManager.player.has_discovered_state(Enums.State.SCIENTIST) and !GameManager.player.scientist_disabled:
		$MineralSpawner.calculate_olivine(asteroid)
		
		var colour = GameManager.player.hit_strength
		if colour == "blue":
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.CRITICAL_HIT)
	
		damage = damage * GameManager.player.get_stat(colour + "_damage").value
	
	if GameManager.player.combo_amount != 0:
		damage = damage * GameManager.player.combo_amount * GameManager.get_item_stat("combo", "damage_multiplier")
	
	if $BoxingGlove.visible:
		damage *= GameManager.get_item_stat("boxing_gloves", "damage_multiplier")
		boxing_hits -= 1
		$BoxingGlove.material.set_shader_parameter("progress", float(boxing_hits)
			/ float(GameManager.get_item_stat("boxing_gloves", "hits")))
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PUNCH)
	
	$BoxingGlove.visible = boxing_hits > 0
	
	if asteroid.asteroid_type == Enums.Asteroid.CORUNDUM:
		var new_time: float = duration_timer.time_left - GameManager.get_stat("armour").value
		if new_time > 0: duration_timer.start(new_time)
		else: duration_timer.timeout.emit()
		
		var new_particles = CORUNDUM_HIT.instantiate()
		$Effects.add_child(new_particles)
		new_particles.global_position = asteroid.global_position
		new_particles.emitting = true
		new_particles.finished.connect(new_particles.queue_free)
	
	asteroid.hit(damage)
	_chain_lightning(asteroid)

func _chain_lightning(asteroid: RigidBody2D, hit: Array[RigidBody2D] = []) -> void:
	if randf() < GameManager.player.get_stat("lightning_chance").value:
		var idx = randi_range(0, $AsteroidSpawner/Asteroids.get_child_count() - 1)
		var closest = $AsteroidSpawner/Asteroids.get_child(idx) as Asteroid
		
		if closest != null:
			closest.hit(GameManager.get_stat("lightning_damage").value)
			var lightning_chain = LIGHTNING_SCENE.instantiate()
			lightning_chain.from = asteroid.position
			lightning_chain.to = closest.position
			lightning_chain.duration = 1.5
			$Effects/Lightning.add_child(lightning_chain)
			
			if len(hit) + 1 < GameManager.player.get_stat("lightning_length").value:
				hit.append(asteroid)
				_chain_lightning(closest, hit)
