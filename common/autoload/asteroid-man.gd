extends Node
class_name AsteroidManager

var player := GameManager.player
var scenes: Dictionary[String, PackedScene] = {
	"asteroid": preload("res://mission/asteroid/asteroid.tscn"),
	"mineral": preload("res://mission/mineral/mineral.tscn"),
	"lightning": preload("res://mission/effects/lightning/lightning.tscn")
}
@onready var parents: Dictionary[String, Node] = {
	"asteroid": $Asteroids,
	"mineral": $Minerals,
	"lightning": $Lightning
}
var timers: Dictionary[String, Timer] = {
	"spawn": Timer.new(),
	"duration": Timer.new()
}
@onready var boundary = $Boundary

# var weights: Dictionary[GameManager.Asteroid, float]
var asteroids: Array[AsteroidData]
# var minerals: Dictionary[GameManager.Mineral, AtlasTexture]
var distance: float = 0

var spawn = {
	"pool": [],
	"sum": 0,
	"progress": -1
}

const START_SPAWN := 1
const END_SPAWN := 0.7
const NEW_MINERAL_TIME := 0.5

func _ready() -> void:
	spawn_new_asteroid()
	
	timers.get("spawn").wait_time = START_SPAWN
	timers.get("spawn").timeout.connect(spawn_new_asteroid)
	
	timers.get("duration").wait_time = player.get_stat("fuel_capacity").value
	timers.get("duration").timeout.connect(mission_ended)
	
	GameManager.mouse_clicked.connect(_asteroid_hit)
	
	GameManager.set_mouse_state.emit(GameManager.MouseState.MISSION)
	GameManager.play.connect(func(): get_tree().paused = false)
	GameManager.pause.connect(func(): get_tree().paused = true)
	
	for _name in timers:
		add_child(timers.get(_name))
		timers.get(_name).start()

func _process(delta: float) -> void:
	distance += GameManager.player.get_stat("thruster_speed").value * delta

func _asteroid_hit(asteroid: Node) -> void:
	if !asteroid.has_meta("asteroid"): return
	
	var damage = GameManager.player.get_stat("hit_strength").value
	damage = calculate_olivine(asteroid, damage)
		
	asteroid.hit(damage)
	_chain_lightning(asteroid)

func _chain_lightning(asteroid: RigidBody2D, hit: Array[RigidBody2D] = []) -> void:
	if randf() < GameManager.player.get_stat("lightning_chance").value:
		var closest = asteroid.find_closest_asteroid(hit)
		
		if closest != null:
			closest.hit(GameManager.player.get_stat("lightning_damage").value)
			var lightning_chain = scenes.get("lightning").instantiate()
			lightning_chain.from = asteroid
			lightning_chain.to = closest
			lightning_chain.duration = 0.5
			add_child(lightning_chain)
			
			if len(hit) + 1 < GameManager.player.get_stat("lightning_length").value:
				hit.append(asteroid)
				_chain_lightning(closest, hit)

func calculate_olivine(asteroid: Node, damage: float) -> float:
	if !GameManager.player.discovered_locations.has(GameManager.State.SCIENTIST):
		return damage
	
	var colour = GameManager.player.hit_strength
	if colour == "blue":
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.CRITICAL_HIT)
	
	GameManager.player.olivine_fragments += GameManager.player.get_stat(colour + "_yield").value
	if GameManager.player.olivine_fragments >= 1:
		var olivine = floor(GameManager.player.olivine_fragments)
		var change = _calc_change(olivine * GameManager.player.get_stat("mineral_value").value)
		for value in change:
			var amount = change[value]
			for i in range(amount):
				spawn_mineral(asteroid.position, CustomMath.random_vector(500), GameManager.Mineral.OLIVINE, value)
		GameManager.player.olivine_fragments -= olivine
	
	return damage * GameManager.player.get_stat(colour + "_damage").value

func mission_ended() -> void:
	GameManager.state_changed.emit(GameManager.State.HOME)
	GameManager.set_mouse_state.emit(GameManager.MouseState.DEFAULT)
	queue_free()

func random_edge(indent: int = 50) -> Dictionary:
	var edge = randi_range(1, 4)
	var result = {
		"position": Vector2(0, 0),
		"velocity": Vector2(0, 0)
	}
	# extents is w/2, h/2
	var size = boundary.get_node("CollisionShape2D").shape.extents
	var pos = boundary.collision_shape.global_position
	
	match edge: 
		1: # North
			result.position = pos + Vector2(randf_range(-size.x + indent, size.x - indent), - size.y)
			result.velocity = Vector2(randf() - 0.5, 1)
		2: # East
			result.position = pos + Vector2(size.x, randf_range(-size.y + indent, size.y - indent))
			result.velocity = Vector2(-1, randf() - 0.5)
		3: # South
			result.position = pos + Vector2(randf_range(-size.x + indent, size.x - indent), size.y)
			result.velocity = Vector2(randf() - 0.5, -1)
		_: # West
			result.position = pos + Vector2(- size.x, randf_range(-size.y + indent, size.y - indent))
			result.velocity = Vector2(1, randf() - 0.5)
	
	return result

func spawn_new_asteroid() -> void:
	var edge = random_edge(50)
	
	if spawn.progress + 0.05 <= _calculate_progress():
		_recalculate_spawn()
	
	timers.get("spawn").wait_time = START_SPAWN - (START_SPAWN - END_SPAWN) * spawn.progress
	
	var n = randf_range(0, spawn.sum)
	var sum = 0
	
	for asteroid in spawn.pool:
		sum += asteroid.weight
		if n <= sum:
			spawn_asteroid(edge.position, edge.velocity * 500, asteroid.level, asteroid.level_data)
			break

func spawn_asteroid(position: Vector2, velocity: Vector2, level: int, level_data: Array[LevelData]) -> Rock:
	var new_asteroid = scenes.get("asteroid").instantiate()
	
	new_asteroid.set_level(level_data, level)
	new_asteroid.position = position
	new_asteroid.velocity = velocity
	new_asteroid.manager = self
	
	parents.get("asteroid").add_child(new_asteroid)
	
	return new_asteroid

func break_asteroid(asteroid: Rock) -> void:
	for mineral in asteroid.drops:
		var change = _calc_change(randi_range(mineral.min, mineral.max) * GameManager.player.get_stat("mineral_value").value)
		for value in change:
			var amount = change[value]
			for i in range(amount):
				spawn_mineral(asteroid.position, CustomMath.random_vector(500), mineral.mineral, value)
	
	for i in range(randi_range(asteroid.pieces.min, asteroid.pieces.max)):
		var new_asteroid = spawn_asteroid(asteroid.position, CustomMath.random_vector(500), 
			asteroid.level - 1, asteroid.level_data)
		boundary.lock_in(new_asteroid)
	
	GameManager.asteroid_broke.emit()

func spawn_mineral(position: Vector2, velocity: Vector2, mineral: GameManager.Mineral, value: int) -> void:
	var new_mineral = scenes.get('mineral').instantiate()
	new_mineral.position = position
	new_mineral.linear_velocity = velocity
	new_mineral.angular_velocity = randf_range(-30, 30)
	new_mineral.mineral = mineral
	new_mineral.value = value
	new_mineral.mineral_tex = minerals.get(mineral)
	parents.get("mineral").add_child(new_mineral)

func _calculate_progress() -> float:
	return distance / GameManager.D

func _recalculate_spawn() -> void:
	spawn = {
		"pool": [],
		"sum": 0,
		"progress": _calculate_progress()
	}
	
	
	for asteroid in asteroids:
		# The index we need to draw weights from
		var i = (spawn.progress - asteroid.spawn_rates[0].progress) / 0.05
		
		# If i is less than 0, we havent passed the first progress threshold yet
		if i >= 0:
			i = floor(i)
			
			# If i is greater than our list, we'll get the last item
			if i > asteroid.spawn_rates.size() - 1:
				_add_to_pool(asteroid.spawn_rates.back().weights, asteroid.level_data)
			else:
				# Get the weights for the current progress
				_add_to_pool(asteroid.spawn_rates[i].weights, asteroid.level_data)

func _add_to_pool(weights: Array[float], level_data: Array[LevelData]) -> void:
	for i in level_data.size():
		spawn.pool.append({
			"weight": weights[i], 
			"level_data": level_data,
			"level": i + 1
		})
		spawn.sum += weights[i]

func _calc_change(amount: int) -> Dictionary[int, int]:
	var values: Array[int] = [1, 25, 500, 2500, 10000]
	var change: Dictionary[int, int] = {1: 0, 25: 0, 500: 0, 2500: 0, 10000: 0}
	
	_calc_chance_aux(amount, values, change)
	return change

func _calc_chance_aux(n: int, values: Array[int], change: Dictionary[int, int]) -> Dictionary[int, int]:
	var back = values.back()
	
	if len(values) == 1:
		change[back] += n
		return change
	
	if n == back:
		change[back] += 1
		return change
	
	if n > back:
		change[back] += n / back
		n /= back
		values.pop_back()
		return _calc_chance_aux(n, values, change)
	
	if n < back:
		values.pop_back()
		return _calc_chance_aux(n, values, change)

	push_error("change not calculated correctly")
	return change
