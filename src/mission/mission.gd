extends Node2D

## Each determines the spawn pool to draw from
@export var increment: float = 0.01

## An constant array of pieces data and mineral drops for each level
var level_data: Array[LevelData] = GameManager.level_data

## A dictionary with any weight multipliers 
var weights: Dictionary[Enums.Asteroid, float]

var duration_timer: Timer = Timer.new()
var using_timer := false
var clicks_left: int = ClickEffectManager.clicks
var boxing_hits: int

var distance: float = 0
var progress: float = 0
var fuel_amount: float = 0

const TIME_AFTER_CLICKS := 2
const CORUNDUM_EFFECT := 2
const LIGHTNING_SCENE = preload("res://mission/effects/lightning/lightning.tscn")
const DAY_RECAP := preload("res://common/ui/day_recap/day_recap.tscn")

@onready var clicks_left_ui: HBoxContainer = $UI/ClicksLeft
@onready var clicks_left_label: Label = $UI/ClicksLeft/Label
@onready var fuel_bar: ColorRect = $UI/FuelBar
@onready var countdown: Label = $Countdown
@onready var boxing_gloves: TextureRect = $UI/BoxingGloves
@onready var spawners: Dictionary[String, Node2D] = {
	"asteroid": $AsteroidSpawner,
	"mineral": $MineralSpawner,
	"powerup": $PowerupSpawner,
	"click_effect": $ClickEffectSpawner
}

func _enter_tree() -> void:
	$AsteroidSpawner.increment = increment
	$AsteroidSpawner.level_data = level_data
	$MineralSpawner.level_data = level_data
	$Countdown.visible = false

func _ready() -> void:
	spawners.asteroid.asteroid_spawned.connect(asteroid_spawned)
	GameManager.asteroid_hit.connect(asteroid_hit)
	
	GameManager.set_mouse_state.emit(Enums.MouseState.MISSION)
	GameManager.play.connect(func(): get_tree().paused = false)
	GameManager.pause.connect(func(): get_tree().paused = true)
	
	GameManager.boost.connect(func (p: float):
		distance += p * GameManager.planet_distance
	)
	
	GameManager.time_added.connect(add_time)
	GameManager.music_changed.connect(func (_s): new_planet())
	setup_duration()
	
	boxing_gloves.visible = GameManager.player.has_equipped("boxing_gloves")
	if GameManager.player.has_equipped("boxing_gloves"):
		boxing_hits = GameManager.get_item_stat("boxing_gloves", "hits")
		boxing_gloves.material.set_shader_parameter("progress", 1)
	
	GameManager.player.scientist_disabled = GameManager.planet != Enums.Planet.DYRT

## determines whether we're using clicks or timer
func setup_duration() -> void:
	clicks_left_ui.visible = false
	fuel_bar.visible = false
	
	if GameManager.planet == Enums.Planet.DYRT:
		duration_timer.wait_time = StatManager.get_stat("fuel_capacity").value
		duration_timer.timeout.connect(mission_ended)
		add_child(duration_timer)
		duration_timer.start()
		
		fuel_amount = duration_timer.time_left
		
		fuel_bar.visible = true
		using_timer = true
		return
	
	if GameManager.planet == Enums.Planet.KRUOS:
		clicks_left_label.text = str(clicks_left)
		clicks_left_ui.visible = true

func new_planet() -> void:
	spawners.mineral.collect_all()
	spawners.asteroid.clean_up()
	GameManager.hide_inventory.emit()
	
	spawners.asteroid.cleaned_up.connect(queue_free)

func mission_ended() -> void:
	if GameManager.player.equipped_items.has("harvesting"):
		spawners.mineral.collect_all()
	
	GameManager.pause.emit()
	countdown.visible = false
	$DayRecap.play()
	$DayRecap.visible = true
	GameManager.state_changed.emit(Enums.State.HOME)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	$UI.visible = false
	
	if GameManager.planet == Enums.Planet.KRUOS:
		spawners.powerup.clean_up()
	
	GameManager.play.connect(func ():
		GameManager.state_changed.emit(Enums.State.HOME)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.LAND)
		GameManager.show_inventory.emit()
		queue_free()
	)

func _process(delta: float) -> void:
	distance += StatManager.get_stat("thruster_speed").value * delta + \
		(GameManager.powerup_modifiers[Powerup.PowerupType.SPEED_BOOST]) * delta
	
	if (distance / GameManager.planet_distance) - progress >= increment:
		progress = distance / GameManager.planet_distance
		spawners.asteroid.progress = progress if progress < 1 else 0.89
	
	if using_timer:
		update_fuel()

func update_fuel() -> void:
	countdown.visible = duration_timer.time_left <= 5
	if duration_timer.time_left <= 5:
		if countdown.text != str(int(ceil(duration_timer.time_left))):
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.COUNTDOWN)
		countdown.text = str(int(ceil(duration_timer.time_left)))
		countdown.add_theme_color_override(
			"font_color", 
			Color.TRANSPARENT.lerp(Color.WHITE, lerp(1, 0, duration_timer.time_left/5)))
	
	if !fuel_bar.visible: return
	
	var fuel_left: float = (duration_timer.time_left / StatManager.get_stat("fuel_capacity").value)
	fuel_amount = fuel_amount * .95 + fuel_left * .05
	
	if fuel_left > fuel_amount:
		fuel_bar.material.set_shader_parameter("waveColour", Color(0.118, 0.737, 0.451, 1.0))
		fuel_bar.material.set_shader_parameter("lineColour", Color(0.137, 0.565, 0.388, 1.0))
	else:
		fuel_bar.material.set_shader_parameter("waveColour", Color(0.918, 0.31, 0.212, 1.0))
		fuel_bar.material.set_shader_parameter("lineColour", Color(0.702, 0.22, 0.192, 1.0))
	
	fuel_bar.material.set_shader_parameter("progress", fuel_amount)

func asteroid_spawned(asteroid: Asteroid) -> void:
	asteroid.asteroid_broken.connect(spawners.asteroid.break_asteroid)
	asteroid.asteroid_broken.connect(spawners.mineral.spawn_minerals)

func asteroid_hit(asteroid: Asteroid, hit_data: HitData) -> void:
	var damage = StatManager.get_stat("hit_strength").value * GameManager.click_multiplier * hit_data.damage_mult
	
	if GameManager.player.has_discovered_state(Enums.State.SCIENTIST) and !GameManager.player.scientist_disabled:
		spawners.mineral.calculate_olivine(asteroid)
		
		var colour = GameManager.player.hit_strength
		if colour == "blue":
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.CRITICAL_HIT)
	
		damage = damage * StatManager.get_stat(colour + "_damage").value
	
	if GameManager.player.combo_amount != 0:
		damage = damage * GameManager.player.combo_amount * GameManager.get_item_stat("combo", "damage_multiplier")
	
	if boxing_gloves.visible:
		damage *= GameManager.get_item_stat("boxing_gloves", "damage_multiplier")
		boxing_hits -= 1
		boxing_gloves.material.set_shader_parameter("progress", float(boxing_hits)
			/ float(GameManager.get_item_stat("boxing_gloves", "hits")))
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PUNCH)
	
		boxing_gloves.visible = boxing_hits > 0
	
	if asteroid.asteroid_type == Enums.Asteroid.CORUNDUM:
		add_time(-StatManager.get_stat("armour").value)
		var new_particles = ParticleManager.get_particles(ParticleManager.ParticleType.CORUNDUM_HIT)
		$Effects.add_child(new_particles)
		new_particles.global_position = asteroid.global_position
		new_particles.emitting = true
	
	if GameManager.powerup_modifiers[Powerup.PowerupType.INSTA_BREAK] > 0:
		damage = INF
		GameManager.powerup_modifiers[Powerup.PowerupType.INSTA_BREAK] -= 1
	
	if randf() <= StatManager.get_stat("freeze_chance").value:
		asteroid.set_frozen()
	
	asteroid.hit(damage)
	_chain_lightning(asteroid, hit_data.lightning_chance_multiplier)

func add_time(x: float) -> void:
	if !fuel_bar.visible: return
	var new_time = min(StatManager.get_stat("fuel_capacity").value, duration_timer.time_left + x)
	if new_time > 0: 
		duration_timer.start(new_time)
	else: 
		duration_timer.timeout.emit()

func _chain_lightning(asteroid: RigidBody2D, chance: float, hit: Array[RigidBody2D] = []) -> void:
	if randf() < StatManager.get_stat("lightning_chance").value * chance:
		var idx = randi_range(0, spawners.asteroid.active_asteroids.get_child_count() - 1)
		var closest = spawners.asteroid.active_asteroids.get_child(idx) as Asteroid
		
		if closest != null:
			closest.hit(StatManager.get_stat("lightning_damage").value * StatManager.get_stat("hit_strength").value)
			var lightning_chain = LIGHTNING_SCENE.instantiate()
			lightning_chain.from = asteroid.position
			lightning_chain.to = closest.position
			lightning_chain.duration = 1.5
			$Effects/Lightning.add_child(lightning_chain)
			
			if len(hit) + 1 < StatManager.get_stat("lightning_length").value:
				hit.append(asteroid)
				_chain_lightning(closest, chance, hit)

func _out_of_clicks() -> void: GameManager.out_of_clicks.emit()

func _input(event: InputEvent) -> void:
	if !using_timer and clicks_left > 0 and event is InputEventMouseButton and event.pressed:
		clicks_left -= 1
		clicks_left_label.text = str(clicks_left)
		spawners.click_effect.clicked()
		if clicks_left == 0:
			call_deferred("_out_of_clicks")
			duration_timer.wait_time = TIME_AFTER_CLICKS
			duration_timer.timeout.connect(mission_ended)
			add_child(duration_timer)
			duration_timer.start()
			using_timer = true
