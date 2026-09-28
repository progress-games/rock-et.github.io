extends Control

const ROCK = preload("uid://do3btcu6i43f7")
const DURABILITY_WIDTH = 80.
const WHITE_OUTLINE = preload("uid://dstl4edni51y1")

@onready var rock_grid: GridContainer = $FlipGame/Board/MarginContainer2/GridContainer
@onready var remaining_durability: ColorRect = $FlipGame/Title/MarginContainer2/VBoxContainer/ColorRect/RemainingDurability
@onready var durability_rect: ColorRect = $FlipGame/Title/MarginContainer2/VBoxContainer/ColorRect
@onready var collect: Button = $FlipGame/Collect

@onready var rewards_panel: VBoxContainer = $VBoxContainer
@onready var rewards_hbox: HBoxContainer = $VBoxContainer/Rewards/MarginContainer2/VBoxContainer/Drones
@onready var nothing_reward: Label = $VBoxContainer/Rewards/MarginContainer2/VBoxContainer/Nothing

var grid_size = Vector2(2, 2)
var rocks: Array[FlipRock]

var drones: Array[TextureRect]

var pickaxe_durability: float
var current_durability: float

var durability_tween: Tween

## -1 = nothing, else drone type enum
var rewards: Array[int]

signal collected

func _ready() -> void:
	modulate = Color.TRANSPARENT
	collect.pressed.connect(collect_rewards)

func reset() -> void:
	show()
	var t = create_tween()
	t.tween_property(self, "modulate", Color.WHITE, .3)
	
	collect.disabled = true
	nothing_reward.show()
	
	drones.map(func (x): x.queue_free())
	drones.clear()
	
	pickaxe_durability = StatManager.get_stat("pickaxe_durability").value
	current_durability = pickaxe_durability
	remaining_durability.size.x = durability_rect.size.x
	
	grid_size = Vector2(
		int(ceil(StatManager.get_stat("scavenge_grid").value)),
		int(ceil(StatManager.get_stat("scavenge_grid").value))
	)
	
	generate_rewards()
	setup_rocks()

func choose_reward() -> DroneManager.Reward:
	# https://www.desmos.com/calculator/yvw6oxqgty
	var vals = [
		[.4, .3],
		[.7, .2],
		[1.1, .2],
		[1.4, .2]
	]
	
	var x = (StatManager.get_stat("scavenge_rarity").level - 1.) / \
		(StatManager.get_stat("scavenge_rarity").max_level - 1.)
	
	var chances = [
		-0.3 * x + 0.3 # nothing chance
	]
	for v in vals:
		chances.append(Math.normal_value(x, v[0], v[1]))
	#print(chances)
	var rng = RandomNumberGenerator.new()
	
	return rng.rand_weighted(chances) as DroneManager.Reward

func generate_rewards() -> void:
	rewards = []
	
	for i in range(grid_size.x * grid_size.y):
		var reward = choose_reward()
		
		if i == grid_size.x * grid_size.y - 1:
			reward = DroneManager.Reward.COMMON
		
		if reward == DroneManager.Reward.NOTHING:
			rewards.append(-1)
		else:
			var drone = DroneManager.get_reward(reward)
			rewards.append(drone)
	
	rewards.shuffle()

func setup_rocks() -> void:
	rock_grid.get_children().map(func (x): x.queue_free())
	
	rock_grid.columns = grid_size.x
	
	for i in range(grid_size.x):
		for j in range(grid_size.y):
			var new_rock = ROCK.instantiate() as FlipRock
			
			var idx = ceil((i * grid_size.x) + j)
			if rewards[idx] == -1: new_rock.has_nothing = true
			else: new_rock.drone_type = rewards[idx]
			
			var adjacent = []
			if i > 0: adjacent.append(idx - grid_size.x)
			if i < grid_size.x - 1: adjacent.append(idx + grid_size.x)
			if j > 0: adjacent.append(idx - 1)
			if j < grid_size.y - 1: adjacent.append(idx + 1)
			
			new_rock.set_meta("adjacent", adjacent)
			
			rock_grid.add_child(new_rock)
			new_rock.pressed.connect(func (): hit_rock(new_rock))

func add_drone_reward(drone_type: DroneEnums.DroneType) -> void:
	nothing_reward.hide()
	
	var shader = ShaderMaterial.new()
	shader.shader = WHITE_OUTLINE
	
	var tex = TextureRect.new()
	tex.texture = DroneManager.get_drone_sprite(drone_type)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tex.tooltip_text = DroneEnums.DroneType.find_key(drone_type).to_lower()
	
	tex.material = shader
	tex.material.set_shader_parameter("pattern", 1)
	tex.material.set_shader_parameter("color", DroneManager.get_rarity_colour(drone_type))
	drones.append(tex)
	
	rewards_hbox.add_child(tex)

func collect_rewards() -> void:
	rock_grid.get_children().map(
		func (x: FlipRock):
			if x.hits <= 0 && !x.has_nothing:
				DroneManager.add_new_drone(x.drone_type)
	)
	collected.emit()
	hide()
	modulate = Color.TRANSPARENT

func hit_rock(rock: FlipRock, damage: float = StatManager.get_stat("pickaxe_damage").value) -> void:
	if current_durability <= 0:
		var t = create_tween()
		durability_rect.color = Color.RED
		t.tween_property(durability_rect, "color", Color.WHITE, 0.3)
		return
	
	if rock.hits <= 0:
		return
	
	rock.hit(damage)
	current_durability -= 1
	
	if durability_tween: 
		durability_tween.kill()
	
	durability_tween = create_tween()
	durability_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	durability_tween.tween_property(
		remaining_durability, 
		"size:x", 
		(current_durability / pickaxe_durability) * DURABILITY_WIDTH, 
		0.5
	)
	
	if rock.hits <= 0 && !rock.has_nothing:
		add_drone_reward(rock.drone_type)
	
	if rock.hits < 0:
		hit_rock(
			rock_grid.get_child(rock.get_meta("adjacent").pick_random()),
			abs(rock.hits)
		)
	
	if current_durability <= 0:
		collect.disabled = false
