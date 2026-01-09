extends Node
class_name MineralSpawner

var player := GameManager.player
var MINERAL_SCENE := preload("res://mission/mineral/mineral.tscn")
var level_data: Array[LevelData]

## minerals
var minerals: Dictionary[Enums.Mineral, AtlasTexture]

func _ready() -> void:
	for mineral in Enums.Mineral.keys():
		var tex = AtlasTexture.new()
		tex.atlas = load("res://mission/mineral/assets/" + mineral.to_lower() + ".png")
		minerals.set(Enums.Mineral[mineral], tex)

## calculate the olivine that should be spawned from this click
func calculate_olivine(asteroid: Node) -> void:
	var colour = GameManager.player.hit_strength
	GameManager.player.olivine_fragments += StatManager.get_stat(colour + "_yield").value * \
		GameManager.get_item_stat("stopwatch", "mineral_multiplier")
	
	if GameManager.player.olivine_fragments >= 1:
		var olivine = floor(GameManager.player.olivine_fragments)
		var change = _calc_change(olivine * StatManager.get_stat("mineral_value").value)
		
		for value in change:
			var amount = change[value]
			for i in range(amount):
				_spawn_mineral(asteroid.position, CustomMath.random_vector(500), Enums.Mineral.OLIVINE, value)
		
		GameManager.player.olivine_fragments -= olivine

func spawn_minerals(asteroid: Asteroid) -> void:
	var data: LevelData = asteroid.data.custom_level_data
	if data == null:
		data = level_data[asteroid.level]
	
	for mineral in asteroid.data.drops:
		var change = _calc_change(randi_range(data.minerals_min, data.minerals_max) * \
			StatManager.get_stat("mineral_value").value * \
			GameManager.get_item_stat("stopwatch", "mineral_multiplier"))
		for value in change:
			var amount = change[value]
			for i in range(amount):
				_spawn_mineral(asteroid.position, CustomMath.random_vector(500), mineral, value)
	
	if GameManager.player.equipped_items.has("pickaxe"):
		var pickaxe = GameManager.player.equipped_items["pickaxe"]
		if randf() <= pickaxe.get_value("gold_chance"):
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PICKAXE)
			var change = _calc_change(pickaxe.get_value("gold_amount"))
			for value in change:
				var amount = change[value]
				for i in range(amount):
					_spawn_mineral(asteroid.position, CustomMath.random_vector(500), Enums.Mineral.GOLD, value)
		

func _spawn_mineral(position: Vector2, velocity: Vector2, mineral: Enums.Mineral, value: int) -> void:
	var new_mineral = MINERAL_SCENE.instantiate()
	new_mineral.position = position
	new_mineral.linear_velocity = velocity
	new_mineral.angular_velocity = randf_range(-30, 30)
	new_mineral.mineral = mineral
	new_mineral.value = value
	new_mineral.mineral_tex = minerals.get(mineral)
	add_child(new_mineral)

func collect_all() -> void:
	for child in get_children():
		var mineral = child as Mineral
		mineral.value *= GameManager.get_item_stat("harvesting", "mineral_multiplier")
		GameManager.collect_mineral.emit(mineral)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MINERAL_PICKUP)
		mineral.queue_free()

func _calc_change(amount: int) -> Dictionary[int, int]:
	var values: Array[int] = [1, 10, 100, 1000, 10000]
	var change: Dictionary[int, int] = {1: 0, 10: 0, 100: 0, 1000: 0, 10000: 0}
	
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
