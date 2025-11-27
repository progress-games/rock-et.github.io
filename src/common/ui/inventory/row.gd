extends TextureRect

@export var top: bool
@export var mineral: Enums.Mineral

const RED := Color('b33831')
const GREEN := Color('91db69')
const COLOUR_DUR := 3
const TOP_SPRITE = preload("res://common/ui/inventory/assets/base.png")

var add_minerals: Dictionary[String, Variant] = {
	"amount": 0,
	"time": 0
}
var mode: Mode
var inventory: Enums.InventoryState
var sum: int = 0

enum Mode {
	TOTAL,
	SUM
}

func _ready() -> void:
	if top:
		texture = TOP_SPRITE
		$HBoxContainer.position.y += 1
	
	material = material.duplicate()
	material.set_shader_parameter("replacement_colors", [
		GameManager.mineral_data[mineral].light_colour,
		GameManager.mineral_data[mineral].mid_colour,
		GameManager.mineral_data[mineral].dark_colour
	])
	
	set_meta("row", true)
	set_meta("mineral", mineral)

	$HBoxContainer/Mineral.texture = GameManager.mineral_data[mineral].texture
	mode = Mode.SUM if inventory == Enums.InventoryState.MISSION else Mode.TOTAL
	
	GameManager.add_mineral.connect(add_mineral)
	GameManager.show_mineral.connect(func (m): add_mineral(m, 0))
	
	GameManager.hide_inventory.connect(func (): visible = false)
	GameManager.show_inventory.connect(func (): visible = true)
	
	if mode == Mode.SUM:
		$HBoxContainer/Amount.text = "+" + CustomMath.format_number_short(sum)
	else:
		$HBoxContainer/Amount.text = CustomMath.format_number_short(GameManager.player.minerals[mineral])

func add_mineral(_mineral: Enums.Mineral, _amt: int) -> void:
	if _mineral != mineral or _amt == 0: return
	add_minerals.amount = _amt
	add_minerals.time = COLOUR_DUR
	sum += _amt
	
	if mode == Mode.SUM:
		$HBoxContainer/Amount.text = "+" + CustomMath.format_number_short(sum)
	else:
		$HBoxContainer/Amount.text = CustomMath.format_number_short(GameManager.player.minerals[mineral])

func _process(delta: float) -> void:
	if add_minerals.time > 0:
		add_minerals.time = max(0, add_minerals.time - delta)
		var c = Color.WHITE
		c = c.lerp(GREEN if add_minerals.amount > 0 else RED, add_minerals.time / 3)
		$HBoxContainer/Amount.set("theme_override_colors/font_color", c)

func fade(fade: bool = false) -> void:
	var colours = [
		GameManager.mineral_data[mineral].light_colour,
		GameManager.mineral_data[mineral].mid_colour,
		GameManager.mineral_data[mineral].dark_colour
	]
	colours = colours.map(func (x): return x + Color(0, 0, 0, -0.4) if fade else x)
	material.set_shader_parameter("replacement_colors", colours)
