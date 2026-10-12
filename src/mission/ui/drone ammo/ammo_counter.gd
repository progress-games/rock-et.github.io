extends HBoxContainer
class_name AmmoCounter

var drone: DroneStats

@onready var ammo_row: AmmoRow = $AmmoRow
@onready var quantity: Label = $Quantity
@onready var drone_tex: TextureRect = $Drone

var max_bullets: int
var current_bullets: int

func _ready() -> void:
	max_bullets = int(ceil(drone.get_stat(DroneEnums.StatType.AMMO)))
	current_bullets = max_bullets
	
	ammo_row.set_drone_type(drone.drone_type)
	ammo_row.set_bullets(current_bullets)
	drone_tex.texture = DroneManager.get_drone_sprite(drone.drone_type)
	quantity.text = "x" + str(current_bullets)

func add_bullets() -> void:
	var amt = max_bullets - current_bullets
	current_bullets += amt
	quantity.text = "x" + str(current_bullets)
	ammo_row.add_bullets(amt)

func deduct_bullet() -> void:
	if current_bullets == 0: return
	current_bullets -= 1
	ammo_row.deduct_bullet()
	quantity.text = "x" + str(current_bullets)
