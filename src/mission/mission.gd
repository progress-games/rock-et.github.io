extends Node2D

## Each determines the spawn pool to draw from
@export var increment: float = 0.01

## An constant array of pieces data and mineral drops for each level
var level_data: Array[LevelData] = GameManager.level_data

## A dictionary with any weight multipliers 
var weights: Dictionary[Enums.Asteroid, float]

var duration_timer: Timer = Timer.new()
var using_timer := false
var clicks_left: int = ClickEffectManager.clicks + DrinksManager.get_stat(DrinkModifier.ModifyingStat.CLICKS)
var boxing_hits: int

var distance: float = 0
var progress: float = 0
var fuel_amount: float = 0

const CLICK_BOOST := 5 # px moved in 1s after click
const TIME_AFTER_CLICKS := 2
const CORUNDUM_EFFECT := 2
const LIGHTNING_SCENE = preload("res://mission/effects/lightning/lightning.tscn")
const DAY_RECAP := preload("res://common/ui/day_recap/day_recap.tscn")
const MULTI_HIT = preload("uid://bylmv31upyu40")
const CORUNDUM_GAIN = preload("uid://cikl7i827i533")
const CORUNDUM_LOSS = preload("uid://btke86pdvdmjf")
const MULTIHIT_REFINED = preload("uid://ci7cdc5j3dopv")

@onready var clicks_left_ui: HBoxContainer = $UI/ClicksLeft
@onready var clicks_left_label: Label = $UI/ClicksLeft/Label
@onready var fuel_bar: ColorRect = $UI/FuelBar
@onready var countdown: Label = $Countdown
@onready var boxing_gloves: TextureRect = $UI/BoxingGloves
@onready var stopwatch: TextureRect = $UI/Stopwatch
@onready var spawners: Dictionary[String, Node2D] = {
	"asteroid": $AsteroidSpawner,
	"mineral": $MineralSpawner,
	"powerup": $PowerupSpawner,
	"click_effect": $ClickEffectSpawner,
	"bullets": $BulletSpawner
}
@onready var potions: HBoxContainer = $Potions

## timeout all timers when they leave the scene
var timers: Array[Timer]

## flips to true when there's a multihit, then the next asteroid hit will spawn a multi hit, then it will flip to false
var spawn_multi_hit: bool = false

var spawn_hit_bar: bool = false

## current px/s recieved from clicking
var current_click_boost: float = 0

func _enter_tree() -> void:
	$AsteroidSpawner.increment = increment
	$AsteroidSpawner.level_data = level_data
	$MineralSpawner.level_data = level_data
	$Countdown.visible = false
	
	if GameManager.day > 1:
		$Label.visible = false

func _ready() -> void:
	spawners.asteroid.asteroid_spawned.connect(asteroid_spawned)
	GameManager.asteroid_hit.connect(asteroid_hit)
	
	GameManager.set_mouse_state.emit(Enums.MouseState.MISSION)
	GameManager.play.connect(func(): get_tree().paused = false)
	GameManager.pause.connect(func(): get_tree().paused = true)
	GameManager.multi_hit.connect(func (): spawn_multi_hit = true)
	
	GameManager.boost.connect(func (p: float):
		distance += p * GameManager.planet_distance
	)
	
	GameManager.time_added.connect(add_time)
	GameManager.music_changed.connect(func (_s): new_planet())
	setup_duration()
	
	stopwatch.visible = false
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
		
		if GameManager.player.has_equipped("stopwatch"):
			var t = Timer.new()
			t.wait_time = duration_timer.wait_time - 5
			t.timeout.connect(
				func ():
					stopwatch.visible = true
					AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.STOPWATCH)
					StatManager.get_stat("mineral_value").value *= \
						GameManager.get_item_stat("stopwatch", "mineral_multiplier")
					var t2 = Timer.new()
					t2.wait_time = 4.9
					t2.timeout.connect(
						func (): 
							StatManager.get_stat("mineral_value").value /= \
						GameManager.get_item_stat("stopwatch", "mineral_multiplier")
					)
					add_child(t2)
					t2.start()
			)
			add_child(t)
			t.start()
	
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
	
	countdown.visible = false
	potions.clean_up()
	$DayRecap.visible = true
	$UI.visible = false
	$Label.visible = false
	
	if GameManager.planet == Enums.Planet.KRUOS:
		spawners.powerup.clean_up()
	
	GameManager.pause.emit()
	GameManager.pause_locked = true
	$DayRecap.play()

func _process(delta: float) -> void:
	distance += StatManager.get_stat("thruster_speed").value * delta + \
		(GameManager.current_click_boost) * delta
	
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
	if asteroid.broken: return
	
	var damage = StatManager.get_stat("hit_strength").value * GameManager.click_multiplier * hit_data.damage_mult
	
	if GameManager.player.has_discovered_state(Enums.State.SCIENTIST) and !GameManager.player.scientist_disabled and\
	(!GameManager.zen_mode || Input.is_action_pressed("hitbar")):
		spawners.mineral.calculate_olivine(asteroid)
		
		var colour = GameManager.player.hit_strength
		if colour == "blue":
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.CRITICAL_HIT)
	
		damage *= StatManager.get_portion_power(colour, "damage")
		
		if spawn_hit_bar:
			spawn_hit_bar = false
			
			var new_particles = ParticleManager.get_particles(ParticleManager.ParticleType.BAR_HIT)
			new_particles.colour = colour
			$Effects.add_child(new_particles)
			new_particles.global_position = asteroid.global_position
			new_particles.emitting = true
	
	if GameManager.player.combo_amount != 0:
		damage = damage * GameManager.player.combo_amount * GameManager.get_item_stat("combo", "damage_multiplier")
	
	if boxing_gloves.visible:
		damage *= GameManager.get_item_stat("boxing_gloves", "damage_multiplier")
		boxing_hits -= 1
		boxing_gloves.material.set_shader_parameter("progress", float(boxing_hits)
			/ float(GameManager.get_item_stat("boxing_gloves", "hits")))
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PUNCH)
	
		boxing_gloves.visible = boxing_hits > 0
		spawn_particles(ParticleManager.ParticleType.BOXING_GLOVES, asteroid.global_position)
	
	var armour = -StatManager.get_stat("armour").value
	if asteroid.asteroid_type == Enums.Asteroid.CORUNDUM && armour != 0:
		add_time(armour)
		var new_particles = spawn_particles(ParticleManager.ParticleType.CORUNDUM_HIT, asteroid.global_position)
		new_particles.texture = CORUNDUM_GAIN if -StatManager.get_stat("armour").value > 0 else CORUNDUM_LOSS
	
	if spawn_multi_hit:
		var p = spawn_particles(ParticleManager.ParticleType.MULTI_HIT, asteroid.global_position)
		spawn_multi_hit = false
		if GameManager.player.has_equipped("refined_tech"):
			p.texture = MULTIHIT_REFINED
	
	if GameManager.powerup_modifiers[Powerup.PowerupType.INSTA_BREAK] > 0:
		damage = INF
		GameManager.powerup_modifiers[Powerup.PowerupType.INSTA_BREAK] -= 1
	
	if randf() <= StatManager.get_stat("freeze_chance").value:
		asteroid.set_frozen()
	
	if hit_data.freeze_dur > 0:
		asteroid.set_frozen(hit_data.freeze_dur)
	
	damage *= DrinksManager.get_stat(DrinkModifier.ModifyingStat.HIT_STRENGTH)
	
	asteroid.hit(damage)
	
	if asteroid.hits <= 0 and randf() <= StatManager.get_stat("shard_chance").value:
		spawners.bullets.spawn_shards(asteroid)
	
	_chain_lightning(asteroid, hit_data.lightning_chance_multiplier)

func spawn_particles(particle_type: ParticleManager.ParticleType, pos: Vector2) -> GPUParticles2D:
	var new_particles = ParticleManager.get_particles(particle_type)
	$Effects.add_child(new_particles)
	new_particles.global_position = pos
	new_particles.emitting = true
	return new_particles

func add_time(x: float) -> void:
	if !fuel_bar.visible: return
	var new_time = min(StatManager.get_stat("fuel_capacity").value, duration_timer.time_left + x)
	if new_time > 0: 
		duration_timer.start(new_time)
	else: 
		duration_timer.timeout.emit()

func _chain_lightning(asteroid: Asteroid, chance: float, hit: Array[Area2D] = []) -> void:
	if randf() > StatManager.get_stat("lightning_chance").value * chance + DrinksManager.get_stat(DrinkModifier.ModifyingStat.LIGHTNING_CHANCE):
		return
		
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
	spawn_hit_bar = true
	if !using_timer and clicks_left > 0 and event is InputEventMouseButton\
	and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		clicks_left -= 1
		clicks_left_label.text = str(clicks_left)
		spawners.click_effect.clicked()
		
		var particles = ParticleManager.get_particles(ParticleManager.ParticleType.SPEED_BOOST)
		particles.emitting = true
		particles.one_shot = true
		particles.position = Vector2(0, -100)
		particles.lifetime = 1
		particles.finished.connect(func (): particles.queue_free())
		$Effects.add_child(particles)
		
		GameManager.click_boosted.emit()
		
		if clicks_left == 0:
			call_deferred("_out_of_clicks")
			duration_timer.wait_time = TIME_AFTER_CLICKS
			duration_timer.timeout.connect(mission_ended)
			add_child(duration_timer)
			duration_timer.start()
			using_timer = true
