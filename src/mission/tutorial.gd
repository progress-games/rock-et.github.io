extends Node2D

const MULTIHIT_RANGE = 27
const GREEN := Color("239063")
const RED := Color(0.682, 0.137, 0.204, 1.0)
const FULL := Vector2(13, 6) # size.y, position.y
const EMPTY := Vector2(4, 15)

@onready var asteroids: Node2D = $"../AsteroidSpawner/Asteroids"
@onready var mineral_spawner: MineralSpawner = $"../MineralSpawner"
@onready var asteroid_spawner: Node2D = $"../AsteroidSpawner"

@onready var hit_asteroid: Label = $Labels/HitAsteroid
@onready var automatic_collection: Label = $Labels/AutomaticCollection
@onready var multi_hit: Label = $Labels/MultiHit
@onready var asteroid_ring: Label = $Labels/AsteroidRing

@onready var big_asteroid: Label = $Labels/BigAsteroid
@onready var orange_hitbar: Label = $Labels/OrangeHitbar

@onready var kruos_labels: Array[Label] = [
	$Labels/Welcome, 
	$Labels/Limited, 
	$Labels/Hitbar, 
	$Labels/Hitbar2,
	$Labels/Mouse,
	$Labels/Red
]
@onready var next: Button = $Labels/Next
@onready var clicks_left: HBoxContainer = $"../UI/ClicksLeft"
@onready var mouse_pointer: ColorRect = $Labels/MousePointer
@onready var progress: ColorRect = $Labels/MousePointer/ColorRect/Progress

var kruos_progress := -1

var looking_for_multi := false
var update_hitbar_text := false
var triggered_big_rock := false

func _ready() -> void:
	hide()
	var waiting_for_love = false
	
	if on_planet(Enums.Planet.DYRT):
		if !has_done(Enums.Tutorial.FIRST_MISSION):
			after(1.15, first)
			waiting_for_love = true
		if !has_done(Enums.Tutorial.BIG_ROCK):
			wait_for_orange()
			waiting_for_love = true
	
	if on_planet(Enums.Planet.KRUOS):
		if !has_done(Enums.Tutorial.KRUOS_CLICKS):
			after(1.15, kruos)
			waiting_for_love = true
	
	if !waiting_for_love:
		queue_free()

func on_planet(p: Enums.Planet) -> bool:
	return GameManager.planet == p

func has_done(t: Enums.Tutorial) -> bool:
	return GameManager.tutorial_progress.has(t)

func kruos() -> void:
	pause()
	advance_kruos()
	next.pressed.connect(advance_kruos)

func advance_kruos() -> void:
	next.hide()
	kruos_progress += 1
	kruos_labels[max(0, kruos_progress - 1)].visible = false
	
	if kruos_progress == 2:
		clicks_left.z_index = 7
	else:
		clicks_left.z_index = 0
	
	if kruos_progress == 4:
		mouse_pointer.visible = true
		progress.color = GREEN
		progress.size.y = FULL.x
		progress.position.y = FULL.y
	elif kruos_progress > 4:
		progress.color = RED
		progress.size.y = EMPTY.x
		progress.position.y = EMPTY.y
	
	
	if kruos_progress == kruos_labels.size():
		play()
		GameManager.tutorial_progress.append(Enums.Tutorial.KRUOS_CLICKS)
		queue_free()
		return
	
	var label = kruos_labels[kruos_progress]
	label.visible = true
	var text = label.text
	label.text = ""
	var t = create_tween()
	t.tween_property(label, "text", text, 0.03 * text.length())
	t.finished.connect(func (): after(0.3, next.show))

func wait_for_orange() -> void:
	if StatManager.get_stat("orange_portion").level == 1:
		return
	
	wait_for_big_rock()

func wait_for_big_rock() -> void:
	asteroid_spawner.asteroid_spawned.connect(
		func (a: Asteroid):
			if a.level == 1 && !triggered_big_rock:
				triggered_big_rock = true
				after(1.15, func (): fourth(a)))

func _process(_delta: float) -> void:
	if looking_for_multi: 
		look_for_multi()

func look_for_multi() -> void:
	for a in asteroids.get_children():
		for a2 in asteroids.get_children().filter(func (x): return x != a):
			for a3 in asteroids.get_children().filter(func (x): return x != a && x != a2):
				if in_multihit_range(a, a2, a3):
					third(a, a2, a3)
					looking_for_multi = false
					return

func in_multihit_range(a: Asteroid, a2: Asteroid, a3: Asteroid) -> bool:
	return a.position.distance_to(a2.position) < MULTIHIT_RANGE && \
		a2.position.distance_to(a3.position) < MULTIHIT_RANGE && \
		a3.position.distance_to(a.position) < MULTIHIT_RANGE

func after(secs: float, f: Callable) -> void:
	var t = Timer.new()
	t.wait_time = secs
	t.one_shot = true
	t.timeout.connect(func (): f.call(); t.queue_free())
	add_child(t)
	t.start()

func pause() -> void:
	asteroids.get_children().map(func (x: Node2D): x.remove_meta("asteroid"))
	GameManager.pause_locked = true
	get_tree().paused = true
	PhysicsServer2D.set_active(true)
	show()

func play() -> void:
	asteroids.get_children().map(func (x: Node2D): x.set_meta("asteroid", true))
	GameManager.pause_locked = false
	get_tree().paused = false
	hide()

func first() -> void:
	pause()
	hit_asteroid.show()
	
	@warning_ignore("integer_division")
	var focused: Asteroid = asteroids.get_child(0)
	focused.set_meta("asteroid", true)
	focused.speed_mult = 0
	focused.material.set_shader_parameter("width", 1)
	focused.z_index = 6
	
	GameManager.asteroid_broke.connect(second, CONNECT_ONE_SHOT)
	GameManager.asteroid_hit.connect(func (_a, _h): asteroid_ring.show(), CONNECT_ONE_SHOT)

func second() -> void:
	asteroid_ring.hide()
	hit_asteroid.hide()
	automatic_collection.show()
	after(2, func(): play(); looking_for_multi = true; automatic_collection.hide())

func third(a: Asteroid, a2: Asteroid, a3: Asteroid) -> void:
	pause()
	multi_hit.show()
	
	a.set_meta("asteroid", true)
	a.speed_mult = 0
	a.material.set_shader_parameter("width", 1)
	a.z_index = 6
	
	a2.set_meta("asteroid", true)
	a2.speed_mult = 0
	a2.material.set_shader_parameter("width", 1)
	a2.z_index = 6
	
	a3.set_meta("asteroid", true)
	a3.speed_mult = 0
	a3.material.set_shader_parameter("width", 1)
	a3.z_index = 6
	
	GameManager.asteroid_broke.connect(func (): play(); multi_hit.hide(), CONNECT_ONE_SHOT)
	
	GameManager.tutorial_progress.append(Enums.Tutorial.FIRST_MISSION)

func fourth(a: Asteroid) -> void:
	if a == null: return
	pause()
	
	big_asteroid.show()
	
	a.set_meta("asteroid", true)
	a.speed_mult = 0
	a.material.set_shader_parameter("width", 1)
	a.z_index = 6
	
	after(1, func (): orange_hitbar.show())
	
	GameManager.asteroid_broke.connect(func (): 
		play()
		update_hitbar_text = false
		big_asteroid.hide()
		orange_hitbar.hide()
		GameManager.tutorial_progress.append(Enums.Tutorial.BIG_ROCK),
		CONNECT_ONE_SHOT)
