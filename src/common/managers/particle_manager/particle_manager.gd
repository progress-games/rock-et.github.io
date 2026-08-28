extends Node2D

@export var particles: Dictionary[ParticleType, PackedScene]

var remove_preload_timer: Timer

enum ParticleType {
	CORUNDUM_HIT,
	SPEED_BOOST,
	ROCK_HIT,
	POWERUP,
	MULTI_HIT,
	SNOW_TRAIL,
	BAR_HIT,
	BOXING_GLOVES,
	SPENT_COINS,
	REWARD,
	OPEN_CHEST
}

# Dictionary[ParticleType, Array] -> Array[GPUParticles2D]
var capacity: Dictionary[ParticleType, Array] = {}

func _ready() -> void:
	_preload_particles()


func _preload_particles() -> void:
	for n in particles.values():
		var p = n.instantiate()
		add_child(p)
		p.global_position = Vector2(-100, 0)
		p.emitting = true
		p.set_meta("preloaded", true)
	
	remove_preload_timer = Timer.new()
	remove_preload_timer.wait_time = 0.2
	remove_preload_timer.one_shot = true
	remove_preload_timer.timeout.connect(_remove_preloaded)
	add_child(remove_preload_timer)
	remove_preload_timer.start()

func _remove_preloaded() -> void:
	for n in get_children():
		if n.has_meta("preloaded"):
			n.queue_free()

## adds queue free to all returned particles
func get_particles(type: ParticleType) -> GPUParticles2D:
	var new = particles[type].instantiate() as GPUParticles2D
	new.finished.connect(
		func (): 
			#print_debug(capacity)
			#capacity.get(type).erase(new)
			new.queue_free()
	)
	
	#capacity.set(type, capacity.get(type, []))
	#var cap = capacity.get(type)
	#cap.append(new)
	#if cap.size() > 15: cap.front().finished.emit()
	
	return new
