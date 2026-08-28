extends VBoxContainer
class_name AmmoRow

const MAX_WIDTH = 100
const MAX_PER_ROW = 20
const ROW_AMOUNT = 5

var drone_type: DroneEnums.DroneType

var active_row: int = ROW_AMOUNT - 1
var sprite_w: int
var bullets_per_row: int

@onready var rows: Array[TextureRect] = [
	$Row1, $Row2, $Row3, $Row4, $Row5
]

func _ready() -> void:
	set_drone_type(drone_type)

func set_drone_type(d: DroneEnums.DroneType) -> void:
	drone_type = d
	
	var img = DroneManager.get_bullet_sprite(drone_type).get_image()
	img.rotate_90(COUNTERCLOCKWISE)
	sprite_w = img.get_width()
	
	@warning_ignore("integer_division")
	bullets_per_row = min(MAX_PER_ROW, MAX_WIDTH / sprite_w)
	custom_minimum_size.x = bullets_per_row * sprite_w
	
	for row in rows:
		row.custom_minimum_size.x = custom_minimum_size.x
		row.texture = ImageTexture.create_from_image(img)

func set_bullets(amt: int) -> void:
	for i in range(ROW_AMOUNT * bullets_per_row): deduct_bullet()
	add_bullets(amt)

func deduct_bullet() -> void:
	if rows[active_row].custom_minimum_size.x <= 0:
		return
	
	rows[active_row].custom_minimum_size.x -= sprite_w
	
	if active_row == 0:
		custom_minimum_size.x = min(custom_minimum_size.x, rows[active_row].custom_minimum_size.x)
	
	if rows[active_row].custom_minimum_size.x == 0:
		rows[active_row].hide()
		active_row = max(0, active_row - 1)

func add_bullets(bullets: int) -> void:
	var row = 0
	while bullets > 0 and row <= ROW_AMOUNT - 1:
		rows[row].show()
		
		var current_bullets = rows[row].custom_minimum_size.x / sprite_w
		var to_add = min(MAX_PER_ROW - current_bullets, bullets)
		rows[row].custom_minimum_size.x += to_add * sprite_w
		
		bullets -= to_add
		if bullets > 0: row += 1
	
	active_row = min(ROW_AMOUNT - 1, row)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("potion slot 1"):
		deduct_bullet()
	elif Input.is_action_just_pressed("potion slot 2"):
		add_bullets(5)
	
