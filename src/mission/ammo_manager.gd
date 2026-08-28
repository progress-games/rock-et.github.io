extends VBoxContainer

const AMMO_COUNTER = preload("uid://bvwhl3smygc1r")

var counters: Array[AmmoCounter]

func load_drones(drones: Array[Drone]) -> void:
	for drone in drones:
		var new_counter = AMMO_COUNTER.instantiate()
		new_counter.drone = drone.drone_stats
		new_counter.set_meta("drone", drone)
		counters.append(new_counter)
		add_child(new_counter)

func shot(drone: Drone) -> void:
	var counter = counters[counters.find_custom(func (x): return x.get_meta("drone") == drone)]
	counter.deduct_bullet()

func add_ammo() -> void:
	for counter in counters:
		counter.add_bullets()
