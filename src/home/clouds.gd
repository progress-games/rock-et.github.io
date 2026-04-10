extends Node2D

var clouds := [
	preload("uid://d4hs0rtr5p3eo"),
	preload("uid://bn30fm23gu06g"),
	preload("uid://dnjj6u8sqd6jv"),
	preload("uid://bmpfsixamtgqh"),
	preload("uid://dufmshetld6fp")
]

@export_group("clouds")
@export var cloud_min_speed := 50
@export var cloud_max_speed := 100
@export var cloud_min_offset := -260
@export var cloud_max_offset := -240
@export var cloud_spawn_frequency := 1

@export_group("birds")
@export var bird_min_speed := 1
@export var bird_max_speed := 10
@export var bird_min_offset := -250
@export var bird_max_offset := -200
@export var bird_spawn_frequency := 5
@export var bird_colours: Array[ColorPair]

@onready var active_clouds: Array[Dictionary] = []
@onready var active_birds: Array[Dictionary] = []
@onready var bird: AnimatedSprite2D = $Bird

var cloud_spawn_timer: Timer
var bird_spawn_timer: Timer

func _ready() -> void:
	cloud_spawn_timer = Timer.new()
	cloud_spawn_timer.wait_time = cloud_spawn_frequency
	cloud_spawn_timer.one_shot = false
	cloud_spawn_timer.timeout.connect(spawn_cloud)
	add_child(cloud_spawn_timer)
	cloud_spawn_timer.start()
	
	for i in range(5): spawn_cloud(true)
	
	bird_spawn_timer = Timer.new()
	bird_spawn_timer.wait_time = bird_spawn_frequency
	bird_spawn_timer.one_shot = false
	bird_spawn_timer.timeout.connect(spawn_bird)
	add_child(bird_spawn_timer)
	bird_spawn_timer.start()
	
	for i in range(2): spawn_bird(true)

func _process(delta: float) -> void:
	for cloud in active_clouds:
		if cloud.sprite.rotation_degrees > 50 or cloud.sprite.rotation_degrees < -50:
			cloud.sprite.queue_free()
			active_clouds.erase(cloud)
		else:
			cloud.sprite.rotation_degrees += cloud.direction * cloud.speed * delta
	
	for b in active_birds:
		if b.sprite.offset.x > 170 or b.sprite.offset.x < -170:
			b.sprite.queue_free()
			active_birds.erase(b)
		else:
			b.sprite.offset.x += b.direction * b.speed * delta
	
func spawn_cloud(first: bool = false) -> void:
	var sprite = Sprite2D.new()
	var tex = clouds.pick_random()
	var direction = ([-1, 1]).pick_random()
	sprite.texture = tex
	sprite.offset.y = randi_range(cloud_min_offset, cloud_max_offset)
	sprite.rotation_degrees = 50 * direction
	if first: sprite.rotation_degrees += 100 * randf()
	active_clouds.append({
		"sprite": sprite,
		"direction": -direction,
		"speed": randi_range(cloud_min_speed, cloud_max_speed)
	})
	add_child(sprite)

func spawn_bird(first: bool = false) -> void:
	var new_bird = bird.duplicate()
	var speed = randf_range(0.2, 1)
	var direction = ([-1, 1]).pick_random()
	var colours = bird_colours.pick_random()
	new_bird.speed_scale = speed
	new_bird.flip_h = direction == 1
	new_bird.offset = Vector2(170 * -direction, randi_range(bird_min_offset, bird_max_offset))
	new_bird.material = new_bird.material.duplicate()
	new_bird.material.set_shader_parameter("replacement_colors", [colours.colour_1, colours.colour_2])
	if first: new_bird.offset.x += 340 * randf_range(0.2, 0.7)
	active_birds.append({
		"sprite": new_bird,
		"direction": direction,
		"speed": speed * (bird_max_speed - bird_min_speed) + bird_min_speed
	})
	add_child(new_bird)
	new_bird.play()
	
