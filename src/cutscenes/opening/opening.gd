extends Node2D

const ASTEROIDS := [
	preload("res://mission/asteroid/assets/amethyst.png"),
	preload("res://mission/asteroid/assets/kyanite.png"),
	preload("res://mission/asteroid/assets/larimar.png"),
	preload("res://mission/asteroid/assets/tugtupite.png"),
	preload("res://mission/asteroid/assets/quartz.png")
	
]

const ASTEROID_SPEED := 500

@export var skip: bool = false
@export var starting_bg_pos: int
@export var end_bg_pos: int
@onready var still_ship: Sprite2D = $StillShip

@onready var bg: Sprite2D = $BG
@onready var bg_2: Sprite2D = $BG2

@onready var asteroids: Node2D = $Asteroids
@onready var asteroid: Area2D = $Asteroid
@onready var asteroid_sprite: Sprite2D = $Asteroid/Asteroid
@onready var ship: Area2D = $Ship
@onready var ship_collision: CollisionPolygon2D = $Ship/CollisionPolygon2D
@onready var play: TextureButton = $Play

@onready var dialogue: MarginContainer = $Dialogue
@onready var dialogue_text: Label = $Dialogue/MarginContainer/DialogueText
@onready var next: TextureButton = $Next

@onready var normal_mode: TextureButton = $NormalMode
@onready var chill_mode: TextureButton = $ChillMode
@onready var zen_mode: TextureButton = $ZenMode

var bg_speed := 160
var first_hit := false
var alt: int = -1
var falling: bool = false

var m: float
var a: float

func _ready() -> void:
	StatManager.upgrade_stat("autocollect")
	
	play.mouse_entered.connect(func (): hover_texture_button(play))
	play.mouse_exited.connect(func (): off_hover_texture_button(play))
	
	next.mouse_entered.connect(func (): hover_texture_button(next))
	next.mouse_exited.connect(func (): off_hover_texture_button(next))
	
	normal_mode.mouse_entered.connect(func (): hover_texture_button(normal_mode))
	normal_mode.mouse_exited.connect(func (): off_hover_texture_button(normal_mode))
	normal_mode.pressed.connect(func (): 
		close_mode_selection(normal_mode, chill_mode, zen_mode)
		play_cutscene()
	)
	
	chill_mode.mouse_entered.connect(func (): hover_texture_button(chill_mode))
	chill_mode.mouse_exited.connect(func (): off_hover_texture_button(chill_mode))
	chill_mode.pressed.connect(func (): 
		close_mode_selection(chill_mode, normal_mode, zen_mode)
		GameManager.trackpad_mode = true
		play_cutscene()
	)
	
	zen_mode.mouse_entered.connect(func (): hover_texture_button(zen_mode))
	zen_mode.mouse_exited.connect(func (): off_hover_texture_button(zen_mode))
	zen_mode.pressed.connect(func (): 
		close_mode_selection(zen_mode, chill_mode, normal_mode)
		play_cutscene()
		StatManager.upgrade_stat("autocollect")
		GameManager.zen_mode = true
		pre_upgrade_stat("hit_strength", 3)
		pre_upgrade_stat("click_speed", 15)
		pre_upgrade_stat("red_yield", 2)
		pre_upgrade_stat("orange_yield", 1)
		pre_upgrade_stat("green_yield", 2)
	)
	
	play.pressed.connect(open_mode_selection)
	
	GameManager.pause_locked = true
	
	if skip:
		GameManager.pause_locked = false
		GameManager.state_changed.emit(Enums.State.HOME)
		GameManager.planet_changed.emit(Enums.Planet.DYRT)
		visible = false
		chill_mode.pressed.emit()
		after(2, queue_free)
		return
	else:
		GameManager.state_changed.emit(Enums.State.OPENING)
		
	m = Settings.get_setting(Settings.SettingType.MUSIC_VOLUME)
	a = Settings.get_setting(Settings.SettingType.AMBIENCE_VOLUME)
	
	Settings.set_setting(Settings.SettingType.MUSIC_VOLUME, 0)
	Settings.set_setting(Settings.SettingType.AMBIENCE_VOLUME, 0)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ENGINE)
	after(0.86, func (): if !falling: AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ENGINE), false)

func pre_upgrade_stat(n: String, amt: int) -> void:
	var cost = StatManager.get_stat(n).cost
	for i in range(amt): StatManager.upgrade_stat(n)
	StatManager.get_stat(n).cost = cost
	StatManager.get_stat(n).upgraded.emit()

func hover_texture_button(b: TextureButton) -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	b.material.set_shader_parameter("width", 1)

func off_hover_texture_button(b: TextureButton) -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	b.material.set_shader_parameter("width", 0)

func open_mode_selection() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(normal_mode, "position:x", 7, 0.5)
	
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t2.tween_property(chill_mode, "position:x", 7, 0.6)
	
	var t3 = create_tween()
	t3.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t3.tween_property(zen_mode, "position:x", 7, 0.7)
	
	var t4 = create_tween()
	t4.tween_property(play, "position:x", 330, 0.2)

func close_mode_selection(f: TextureButton, s: TextureButton, th: TextureButton) -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(f, "position:x", -120, 0.5)
	
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t2.tween_property(s, "position:x", -120, 0.6)
	
	var t3 = create_tween()
	t3.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t3.tween_property(th, "position:x", -120, 0.7)

func set_hit_volume(amt: float, sfx_type = SoundEffect.SOUND_EFFECT_TYPE.HIT_SHIP) -> void:
	var sfx = AudioManager.sound_effects[AudioManager.sound_effects.find_custom(
		func (s):
			return s.type == sfx_type)]
	sfx.volume = amt

func decrement_hit_volume(amt: float, sfx_type = SoundEffect.SOUND_EFFECT_TYPE.HIT_SHIP) -> void:
	var sfx = AudioManager.sound_effects[AudioManager.sound_effects.find_custom(
		func (s):
			return s.type == sfx_type)]
	sfx.volume -= amt

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("potion slot 1"):
		spawn_asteroid()

func end() -> void:
	GameManager.pause_locked = false
	SaveManager.loading_save = true
	Settings.set_setting(Settings.SettingType.MUSIC_VOLUME, m)
	Settings.set_setting(Settings.SettingType.AMBIENCE_VOLUME, a)
	SaveManager.loading_save = false
	GameManager.state_changed.emit(Enums.State.HOME)
	GameManager.planet_changed.emit(Enums.Planet.DYRT)
	
	var t = Timer.new()
	t.wait_time = 0.05
	t.timeout.connect(func (): 
		decrement_hit_volume(0.75)
	)
	
	var t2 = Timer.new()
	t2.wait_time = 1.5
	t2.one_shot = true
	t2.timeout.connect(queue_free)
	
	add_child(t)
	add_child(t2)
	t.start()
	t2.start()

func play_cutscene() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	play.visible = false
	
	after(1, spawn_asteroid)

func after(secs: float, f: Callable, one_shot: bool = true) -> void:
	var t = Timer.new()
	t.wait_time = secs
	t.one_shot = one_shot
	t.timeout.connect(f)
	add_child(t)
	t.start()

func show_dialogue(text: String, f: Callable = func (): return) -> void:
	dialogue.visible = true
	dialogue_text.text = text
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	
	after(1, func ():
		next.show()
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	)
	
	next.pressed.connect(f, CONNECT_ONE_SHOT)

func _process(delta: float) -> void:
	bg.position.y += delta * bg_speed
	bg_2.position.y += delta * bg_speed
	
	for child in asteroids.get_children():
		if child.position.y > 180: 
			child.queue_free()
		if child.position.distance_to(ship.position) <= 28 && !child.get_meta("hit_ship", false):
			bounce_asteroid(child, clamp(child.position.x - ship.position.x, -1, 1))
			child.set_meta("hit_ship", true)
		elif !child.get_meta("hit_ship", false):
			child.position = child.position.move_toward(
				ship.position, 
				ASTEROID_SPEED * delta * (5/child.position.distance_to(ship.position) + 1)
			)

	if bg_speed > 0:
		move_bg_down(bg, bg_2)
		move_bg_down(bg_2, bg)
	else:
		move_bg_up(bg, bg_2)
		move_bg_up(bg_2, bg)

func bounce_asteroid(node: Node2D, dir: float) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIT_SHIP)
	
	var x = create_tween()
	x.tween_property(node, "position:x", node.position.x + randi_range(90, 100) * dir, 1)
	x.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var y = create_tween()
	y.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	y.tween_property(node, "position:y", node.position.y + 150, 0.5)
	
	if !first_hit:
		first_hit = true
		after(1.5, 
			func (): 
				show_dialogue(
					"hmm, I'm sure that was nothing", 
					func (): 
						dialogue.visible = false
						next.visible = false
						after(0.1, spawn_asteroid, false)
						after(3, func (): 
							set_hit_volume(-27)
							show_dialogue("uh oh", func (): 
										falling = true
										next.visible = false
										dialogue.visible = false
										after(2, func ():
											AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.FALLING)
											
											after(0.04, func (): 
												decrement_hit_volume(0.01, SoundEffect.SOUND_EFFECT_TYPE.FALLING), 
											false)
										)
										
										var t = create_tween()
										t.tween_property(self, "bg_speed", -1000, 4)
										t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
										ship.visible = false
										
										var t2 = create_tween()
										t2.tween_property(self, "rotation", rotation, 2)
										t2.tween_property(still_ship, "rotation", -PI, 1.5)
										t2.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
										after(6, end)))
						)
						)

func move_bg_down(b: Sprite2D, b2: Sprite2D) -> void:
	if b.position.y >= end_bg_pos + 30:
		b.position.y = b2.position.y - b2.texture.get_height()

func move_bg_up(b: Sprite2D, b2: Sprite2D) -> void:
	if b.position.y <= starting_bg_pos - 30:
		b.position.y = b2.position.y + b2.texture.get_height()

func random_edge() -> Vector2:
	alt = -alt
	return Vector2(320 * clamp(alt, 0, 1), randi_range(30, 150))

func spawn_asteroid() -> void:
	asteroid_sprite.texture = asteroid_sprite.texture.duplicate_deep()
	asteroid_sprite.texture.atlas = ASTEROIDS.pick_random()
	
	var new_asteroid = asteroid.duplicate()
	new_asteroid.position = random_edge()
	new_asteroid.visible = true
	new_asteroid.set_meta("hit_ship", false)
	
	asteroids.add_child(new_asteroid)
	
