extends ColorRect
class_name OpenReward

const VIS_COLOUR := Color(0.0, 0.0, 0.0, 0.675)
const CHEST_POS := Vector2(256, 20)
const OPENING_CHEST_POS := Vector2(150, 79)
const REWARD_PARTICLE_POS := Vector2(160, 90)

@export var rarity_colours: Dictionary[DroneManager.Rarity, Color]
@export var nothing_responses: Array[String]

var rewards: Array[DroneManager.Reward] = []
var opening: bool = false
var opening_particles: GPUParticles2D

@onready var reward_chest: TextureButton = $RewardChest
@onready var empty: Label = $Empty
@onready var drones: HBoxContainer = $Drones
@onready var close: Button = $Close

func _ready() -> void:
	show()
	reward_chest.mouse_entered.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		reward_chest.material.set_shader_parameter("width", 1))
	
	reward_chest.mouse_exited.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		reward_chest.material.set_shader_parameter("width", 0))
	
	reward_chest.pressed.connect(start_reward)
	reward_chest.position = CHEST_POS
	reward_chest.hide()
	drones.hide()
	
	opening_particles = ParticleManager.get_particles(ParticleManager.ParticleType.REWARD)
	add_child(opening_particles)
	opening_particles.emitting = true
	opening_particles.position = REWARD_PARTICLE_POS
	opening_particles.scale *= 3
	
	close.pressed.connect(reset)
	reset()

func reset() -> void:
	rewards.clear()
	reward_chest.hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	self_modulate = Color.TRANSPARENT
	drones.hide()
	empty.hide()
	close.hide()
	opening_particles.hide()
	reward_chest.position = CHEST_POS
	reward_chest.disabled = false

func load_reward(reward: DroneManager.Reward) -> void:
	rewards.append(reward)
	
	rock_chest()
	var t = Timer.new()
	t.timeout.connect(func ():
		if opening: t.queue_free()
		else: rock_chest())
	add_child(t)
	t.start(2)
	
	reward_chest.show()

func start_reward() -> void:
	opening = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	reward_chest.disabled = true
	
	var t = create_tween()
	t.tween_property(self, "self_modulate", VIS_COLOUR, 0.3)
	
	var t2 = create_tween()
	t2.tween_property(reward_chest, "position", OPENING_CHEST_POS, 0.3)
	t2.tween_property(reward_chest, "scale", Vector2.ONE * 2, 2)
	t2.finished.connect(open_reward)
	
	var tim = Timer.new()
	tim.timeout.connect(
		func ():
			if !opening: 
				tim.queue_free()
			else: 
				tim.wait_time = max(tim.wait_time - 0.1, 0.05)
				shake_chest(tim.wait_time)
	)
	add_child(tim)
	tim.start(0.5)

func rock_chest() -> void:
	var t = create_tween()
	t.tween_property(reward_chest, "rotation_degrees", 30, 0.3)
	t.tween_property(reward_chest, "rotation_degrees", -20, 0.2)
	t.tween_property(reward_chest, "rotation_degrees", 10, 0.1)
	t.tween_property(reward_chest, "rotation_degrees", -5, 0.05)
	t.tween_property(reward_chest, "rotation_degrees", 0, 0.01)

func shake_chest(dur: int) -> void:
	var dir = clamp(reward_chest.rotation_degrees, -1, 1)
	
	var t = create_tween()
	t.tween_property(reward_chest, "rotation_degrees", -1 * dir * 30, dur)

func open_reward() -> void:
	reward_chest.hide()
	reward_chest.scale = Vector2.ONE
	opening = false
	
	opening_particles.show()
	
	var next = Timer.new()
	next.one_shot = true
	next.timeout.connect(
		func ():
			next.queue_free()
			close.show()
	)
	add_child(next)
	
	if rewards.all(func (x): return x == DroneManager.Reward.NOTHING):
		empty.show()
		next.start(1)
		close.text = nothing_responses.pick_random()
	else:
		drones.get_children().map(func (x): x.queue_free())
		var r = 0
		for reward in rewards:
			if reward == DroneManager.Reward.NOTHING:
				continue
			
			var drone_type = DroneManager.get_reward(reward)
			DroneManager.add_new_drone(drone_type)
			
			var tex = TextureRect.new()
			tex.texture = DroneManager.get_drone_sprite(drone_type)
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.custom_minimum_size = tex.texture.get_size() * 2.
			tex.use_parent_material = true
			tex.tooltip_text = DroneEnums.DroneType.find_key(drone_type).to_lower()
			
			if r > 0:
				var t = Timer.new()
				t.wait_time = r
				t.timeout.connect(func():
					t.queue_free()
					drones.add_child(tex)
					var p = ParticleManager.get_particles(ParticleManager.ParticleType.OPEN_CHEST)
					p.emitting = true
					tex.add_child(p)
					p.position += tex.size / 2
					p.show_behind_parent = true
				)
				add_child(t)
				t.start()
			else:
				drones.add_child(tex)
				var p = ParticleManager.get_particles(ParticleManager.ParticleType.OPEN_CHEST)
				p.emitting = true
				tex.add_child(p)
				p.position += tex.size / 2
				p.show_behind_parent = true
			r += 1
		
		drones.show()
		close.text = "cool"
		next.start(r)
	
