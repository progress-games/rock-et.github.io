extends Node

var lightning: Line2D = null
var spark: Line2D = null
var frame := 0

@export var from: Vector2
@export var to: Vector2
@export var duration: float

func _ready() -> void:
	lightning = Line2D.new()
	add_child(lightning)
	spark = Line2D.new()
	add_child(spark)
	
	var timer = Timer.new()
	timer.wait_time = duration
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ELECTRIC_CRACK)
	
	draw_lightning(from, to)

func _process(_delta: float) -> void:
	frame += 1
	if frame % 3 == 0:
		frame = 0
		draw_lightning(from, to)

func draw_lightning(start: Vector2, end: Vector2) -> void:
	lightning.clear_points()
	spark.clear_points()
	
	var dir = start.angle_to_point(end)
	var dis = start.distance_to(end)
	var steps = floor(dis / 10.0)
	var current = start
	var step = (1 / steps) * dis
	var spark_point = randi_range(0, steps - 1)
	
	lightning.add_point(start)
	lightning.width = 2
	
	for i in range(steps):
		dir = current.angle_to_point(end) + randf_range(-0.5, 0.5)
		step = (1 / (steps - i)) * current.distance_to(end)
		
		current.x = current.x + step * cos(dir)
		current.y = current.y + step * sin(dir)
		
		lightning.add_point(current)
		
		if i == spark_point:
			draw_spark(current, current + Vector2(randf_range(-15, 15), randf_range(-15, 15)))
	
	lightning.add_point(end)
	
func draw_spark(start: Vector2, end: Vector2) -> void:
	var dir = start.angle_to_point(end)
	var dis = start.distance_to(end)
	var steps = 15.0
	var current = start
	var step = (1 / steps) * dis
	
	spark.add_point(start)
	spark.width = 1
	
	for i in range(steps):
		dir = current.angle_to_point(end) + randf_range(-2, 2)
		step = (1 / (steps - i)) * current.distance_to(end)
		
		current.x = current.x + step * cos(dir)
		current.y = current.y + step * sin(dir)
		
		spark.add_point(current)
	
