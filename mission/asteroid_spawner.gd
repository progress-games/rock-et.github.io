extends Node

## An array of which asteroids can spawn when and their associated data
var asteroids: Array[AsteroidData] = GameManager.asteroid_spawns

const ASTEROID_SCENE := preload("res://mission/asteroid/asteroid.tscn")
const START_SPAWN := 1
const END_SPAWN := 0.7

var spawn_timer: Timer = Timer.new()
var asteroid_spawns: Array
var progress: float = 0.
var increment: float
var level_data: Array[LevelData]

# should probably replace this but whatever its being fucking annoying
@onready var boundary := $"../Boundary"

signal asteroid_spawned(asteroid: Asteroid)

func _ready() -> void:
	spawn_timer.wait_time = START_SPAWN
	spawn_timer.timeout.connect(spawn_new_asteroid)
	add_child(spawn_timer)
	spawn_timer.start()
	
	asteroid_spawns = get_asteroids_spawns(asteroids, increment)
	
	spawn_new_asteroid(true)

func random_edge(first: bool = false, indent: int = 50) -> Dictionary:
	var edge = randi_range(1, 4) if !first else 3
	var result = {
		"position": Vector2(0, 0),
		"velocity": Vector2(0, 0)
	}
	# extents is w/2, h/2
	var size = boundary.get_node("CollisionShape2D").shape.extents
	var pos = boundary.global_position
	
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

# spawn logic is at line 104
func spawn_new_asteroid(first: bool = false) -> void:
	var edge = random_edge(first, 50)
	
	spawn_timer.wait_time = (START_SPAWN - (START_SPAWN - END_SPAWN) * progress) * \
		(1 / GameManager.get_item_stat("binoculars", "asteroid_spawn"))
	
	var weight = randf()
	var level = randf()
	var pool = asteroid_spawns[floor(progress / increment)]
	
	# finds the index of the smallest weight that it still larger than ours
	var idx: int = Math.get_weighted_value(pool.weights, weight)
	var lvl: int = Math.get_weighted_value(pool.spawns[idx], level)
	var asteroid: AsteroidData = pool.order[idx]
	var lvl_data = level_data[idx]
	
	if asteroid.custom_level_data != null:
		lvl_data = asteroid.custom_level_data
	
	spawn_asteroid(edge.position, edge.velocity * 250, lvl, asteroid)

func spawn_asteroid(position: Vector2, velocity: Vector2, level: int, asteroid_data: AsteroidData) -> Asteroid:
	var new_asteroid = ASTEROID_SCENE.instantiate()
	
	new_asteroid.data = asteroid_data
	new_asteroid.level = level
	new_asteroid.position = position
	new_asteroid.velocity = velocity
	
	asteroid_spawned.emit(new_asteroid)
	add_child(new_asteroid)
	
	return new_asteroid

func break_asteroid(asteroid: Asteroid) -> void:
	var data: LevelData = asteroid.data.custom_level_data
	if data == null:
		data = level_data[asteroid.level]
	
	for i in range(randi_range(data.pieces_min, data.pieces_max)):
		var new_asteroid = spawn_asteroid(asteroid.position, CustomMath.random_vector(500), 
			asteroid.level - 1, asteroid.data)
		# boundary.lock_in(new_asteroid)
	
	GameManager.asteroid_broke.emit()

"""
How spawning works: 
	[{order: [amethyst, topaz, ...], weights: [1, 0.5], spawns [[0.8, 0.2, 0, 0, 0], [], ...]}, ...]

generate a random number between 0 and 1 (weight)
generate a random number between 0 and 1 (level)

first get the progress (p) and increment (inc)
get spawn pool at position floor(p / inc) (spawn)
use weights to determine the idx of the spawning asteroid (i)
get the asteroid type at spawn.order[i] and use level to get level in spawn.spawns
"""

## get the spawn rates for this progress
func get_asteroid_spawns_progress(start: float, end: float, progress: float) -> Array: # Array[float]
	# deviation params for each level of asteroid (1-5)
	const params := [
		[0., 0.12, 0.], # mean, sd, cutoff
		[0.3, 0.11, 0.],
		[0.5, 0.1, 0.1],
		[0.6, 0.1, 0.4],
		[1.05, 0.01, 0.]
	]
	var width := end - start
	var x = (progress - start) / width
	var sum = 0.
	
	var spawns: Array = []
	
	for param in params:
		if progress < param[2] * width + start:
			spawns.append(sum)
		else:
			var v = Math.normal_value(x, param[0], param[1])
			spawns.append(v + sum)
			sum += v
	
	spawns = spawns.map(func (x): return x / sum)
	return spawns

## gets asteroid spawn rates for every progress incremented by 0.01 for 1 asteroid type
func get_asteroid_spawns(start: float, end: float, increment: float = 0.01) -> Array: # Array[Array]
	var progress := start
	var spawns = []
	var width := end - start
	
	for i in range(width / increment):
		spawns.append(get_asteroid_spawns_progress(start, end, progress))
		progress += increment
	
	return spawns

## gets asteroid spawn rates for every progress incremented by 0.01 for all asteroid types
## input: [{mineral: amethyst, weight: weight, start: start, end: end}, ...]
## output: [{order: [amethyst, topaz, ...], weights: [1, 0.5], spawns [[0.8, 0.2, 0, 0, 0], [], ...]}, ...]
func get_asteroids_spawns(asteroids: Array[AsteroidData], increment: float = 0.01) -> Array: # Array[Dictionary]
	var asteroid_spawns := []
	
	# for each asteroid, create:
	# [{data: AsteroidData, levels: [[0.8, 0.2, 0, 0, 0], [0.7, 0.2, ...], ...]}, ...]
	for asteroid in asteroids:
		asteroid_spawns.append({
			"data": asteroid,
			"levels": get_asteroid_spawns(snapped(asteroid.start, 0.001), snapped(asteroid.end, 0.001), increment)
		})
	
	var spawns := []
	
	# loop for every increment we're going by (0.01 -> 100 loops)
	for i in range(1 / increment):
		# at this progress, these are the things that can spawn
		spawns.append({
			"order": [],
			"weights": [],
			"spawns": []
		})
		
		var weight_sum := 0
		
		for asteroid in asteroid_spawns:
			if i < asteroid.data.start / increment or i >= floor(asteroid.data.end / increment):
				continue

			spawns[i].order.append(asteroid.data)
			spawns[i].weights.append(asteroid.data.weight + weight_sum)
			spawns[i].spawns.append(asteroid.levels[int(i - asteroid.data.start / increment)])
			weight_sum += asteroid.data.weight
		
		#if spawns[i].order.size() == 0:
			#push_error("Asteroid spawns is invalid at position: " + str(i * increment))
		
		spawns[i].weights = spawns[i].weights.map(func (x): return x / weight_sum)
	
	return spawns
