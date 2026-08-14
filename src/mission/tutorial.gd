extends Node2D

const MULTIHIT_RANGE = 27

@onready var asteroids: Node2D = $"../AsteroidSpawner/Asteroids"
@onready var mineral_spawner: MineralSpawner = $"../MineralSpawner"
@onready var asteroid_spawner: Node2D = $"../AsteroidSpawner"

@onready var hit_asteroid: Label = $Labels/HitAsteroid
@onready var automatic_collection: Label = $Labels/AutomaticCollection
@onready var multi_hit: Label = $Labels/MultiHit
@onready var asteroid_ring: Label = $Labels/AsteroidRing

@onready var big_asteroid: Label = $Labels/BigAsteroid
@onready var orange_hitbar: Label = $Labels/OrangeHitbar

var looking_for_multi := false
var update_hitbar_text := false
var triggered_big_rock := false

func _ready() -> void:
	if GameManager.tutorial_progress == Enums.Tutorial.FINISHED:
		queue_free()
	
	hide()
	
	if GameManager.tutorial_progress == Enums.Tutorial.FIRST_MISSION:
		after(1.15, first)
	elif GameManager.tutorial_progress == Enums.Tutorial.BIG_ROCK:
		wait_for_orange()

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
	
	GameManager.tutorial_progress = Enums.Tutorial.BIG_ROCK

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
		GameManager.tutorial_progress = Enums.Tutorial.FINISHED,
		CONNECT_ONE_SHOT)
