extends HBoxContainer

const MEGA_ROCK = preload("uid://82ymh3grsnry")

const ASTEROID_STORM_INTERVAL := 0.05
const ASTEROID_STORM_AMOUNT := 100
const COLLECT_ALL_MULT := 10
const GATLING_CLICK = 50
const GATLING_CLICK_DUR = 10
const GOLD_RUSH_DUR = 15
const SUPERSIZE_TIMER = 8
const SUPERNOVA_SIZE = 6
const SUPERNOVA_PULL = 3

@onready var potions: Array[TextureRect] = [
	$TextureRect, 
	$TextureRect2, 
	$TextureRect3
]

@onready var asteroid_spawner: Node2D = $"../AsteroidSpawner"
@onready var mineral_spawner: MineralSpawner = $"../MineralSpawner"
@onready var click_effect_spawner: Node2D = $"../ClickEffectSpawner"

var timers: Array[Timer]

func _ready() -> void:
	visible = GameManager.player.equipped_potions.size() > 0
	
	setup_potions()

func setup_potions() -> void:
	for i in range(GameManager.player.equipped_potions.size()):
		var potion_name = GameManager.player.equipped_potions[i]
		var potion_type = GameManager.player.all_potions[potion_name]
		potions[i].texture = potion_type.texture
		potions[i].set_meta("potion", potion_name)
	
	potions.map(func (x): if !x.has_meta("potion"): x.set_meta("used", true); x.visible = false)

func _input(event: InputEvent) -> void:
	for i in range(potions.size()):
		if !potions[i]: continue
		var p = potions[i]
		if event.is_action_pressed("potion slot " + str(i+1)) and !p.get_meta("used", false):
			trigger_potion(p.get_meta("potion"))
			p.modulate = Color(1, 1, 1, 0.2)
			p.set_meta("used", true)
			GameManager.player.equipped_potions.erase(p.get_meta("potion"))
			GameManager.player.owned_potions.erase(p.get_meta("potion"))

func after(dur: float, f: Callable, one_shot: bool = true) -> Timer:
	var t = Timer.new()
	t.wait_time = dur
	t.one_shot = one_shot
	t.timeout.connect(f)
	add_child(t)
	timers.append(t)
	t.start()
	
	return t

func clean_up() -> void:
	for timer in timers:
		timer.timeout.emit()
		timer.queue_free()

func trigger_potion(potion_name: String) -> void:
	match potion_name:
		"asteroid_storm":
			var t = after(ASTEROID_STORM_INTERVAL, asteroid_spawner.spawn_new_asteroid, false)
			after(ASTEROID_STORM_AMOUNT * ASTEROID_STORM_INTERVAL, t.queue_free)
		"vacuum":
			mineral_spawner.collect_all(COLLECT_ALL_MULT)
		"gatling_click":
			var v = StatManager.get_stat("click_speed").value
			StatManager.get_stat("click_speed").value = 50
			
			after(GATLING_CLICK_DUR, func (): StatManager.get_stat("click_speed").value = v)
		"gold_rush":
			mineral_spawner.gold_rush = true
			
			after(GOLD_RUSH_DUR, func (): mineral_spawner.gold_rush = false)
		"supernova":
			var s = ClickEffectManager.stats[ClickEffectManager.ClickType.BLACKHOLE]
			s[ClickEffectManager.StatType.PULL] += SUPERNOVA_PULL
			var diff = SUPERSIZE_TIMER - s[ClickEffectManager.StatType.DURATION]
			s[ClickEffectManager.StatType.DURATION] += diff
			
			var b: Node2D = click_effect_spawner.spawn_click_effect(ClickEffectManager.ClickType.BLACKHOLE)
			b.mission_scale = Vector2.ONE * SUPERNOVA_SIZE
			b.global_position = Vector2(320, 180) / 2
			b._update_size(SUPERNOVA_SIZE)
			b.update_blackhole_scale(SUPERNOVA_SIZE)
			
			after(SUPERSIZE_TIMER, 
			func(): 
				s[ClickEffectManager.StatType.PULL] -= SUPERNOVA_PULL
				s[ClickEffectManager.StatType.DURATION] -= diff)
		"supersize":
			GameManager.powerup_modifiers[Powerup.PowerupType.SIZE_UP] += 3
			after(SUPERSIZE_TIMER, func (): GameManager.powerup_modifiers[Powerup.PowerupType.SIZE_UP] -= 3)
		"mega_rock":
			var rock: Asteroid = asteroid_spawner.spawn_new_asteroid()
			rock.sprite.texture = MEGA_ROCK
			rock.linear_velocity *= 0.4
			
			rock.hits = 100
			rock.collision_layer = 0
			
			var i = MEGA_ROCK.get_image().get_used_rect()
			var h = rock.hit_bar
			var x = Vector2(40, 40)
			
			rock.sprite.modulate = Color.WHITE
			rock.flash_sprite.texture = MEGA_ROCK
			rock.flash_sprite.material = rock.flash_sprite.material.duplicate()
			rock.collision_shape.shape.size = MEGA_ROCK.get_size()
			
			h.material = h.material.duplicate()
			
			h.position -= (Vector2(i.size) + x) / 2
			h.size = Vector2(i.size) + x
			h.material.set_shader_parameter("inner", 0.47)
