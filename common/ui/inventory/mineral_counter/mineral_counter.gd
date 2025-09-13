extends Node2D

const GAP := 2
const TEXT_COLOUR := Color("00e100")
const BUFFER := 20

@export var mineral: Enums.Mineral

var add_minerals: Dictionary[String, Variant] = {
	"amount": 0,
	"time": 0
}

func _ready() -> void:
	$Mineral.texture = GameManager.MINERAL_TEXTURES.get(mineral)
	$AddMineral.set("theme_override_colors/font_color", Color(0., 0., 0., 0.))
	GameManager.add_mineral.connect(update_width)
	GameManager.show_mineral.connect(func (m): update_width(m, 0))
	
	GameManager.hide_inventory.connect(func (): visible = false)
	GameManager.show_inventory.connect(func (): visible = true)

func update_width(_mineral: Enums.Mineral, _amt: int) -> void:
	mineral = _mineral
	$Mineral.texture = GameManager.MINERAL_TEXTURES.get(mineral)
	$Score.text = CustomMath.format_number_short(GameManager.player.get_mineral(mineral))
	
	if _amt > 0:
		add_minerals.amount += _amt
		add_minerals.time = 1
		$AddMineral.text = "+" + CustomMath.format_number_short(add_minerals.amount)
		$AddMineral.position.x = $Score.position.x + $Score.get_minimum_size().x + GAP
	
	$BG.size.x = get_width()

func _process(delta: float) -> void:
	if add_minerals.time > 0:
		add_minerals.time = max(0, add_minerals.time - delta)
		var c = TEXT_COLOUR
		c.a = add_minerals.time
		$AddMineral.set("theme_override_colors/font_color", c)
	elif add_minerals.amount != 0:
		add_minerals.amount = 0
		$BG.size.x = get_width()
		

func get_width() -> float:
	if add_minerals.time > 0.2:
		return $Mineral.texture.get_size().x + 2*GAP + $Score.get_minimum_size().x + $AddMineral.get_minimum_size().x + BUFFER
	
	return $Mineral.texture.get_size().x + 2*GAP + $Score.get_minimum_size().x + BUFFER
