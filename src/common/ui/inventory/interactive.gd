extends Control

const WHITE_OUTLINE = preload("uid://dstl4edni51y1")
const PLANET_MINERALS := {
	Enums.Planet.DYRT: [
		Enums.Mineral.AMETHYST, 
		Enums.Mineral.OLIVINE, 
		Enums.Mineral.GOLD, 
		Enums.Mineral.TOPAZ, 
		Enums.Mineral.KYANITE,
		Enums.Mineral.CORUNDUM]
}

@onready var amount: Label = $Interactive/Amount
@onready var mineral_grid: GridContainer = $Interactive/Minerals
@onready var panel: Control = $Panel

var mineral_buttons: Dictionary[Enums.Mineral, TextureButton]

var listening_mineral: Enums.Mineral

func _ready() -> void:
	GameManager.player.mineral_discovered.connect(unlock_mineral)
	GameManager.add_mineral.connect(func (m, _a): show_mineral(m))
	setup_minerals()
	SaveManager.loaded_save.connect(
		func ():
			for m in SaveManager.save.discovered_minerals:
				unlock_mineral(m)
			show_mineral(PLANET_MINERALS[GameManager.planet][0])
	)

func unlock_mineral(m: Enums.Mineral) -> void:
	if !mineral_buttons.has(m):
		return
	 
	mineral_buttons[m].disabled = false
	mineral_buttons[m].modulate = Color.WHITE

func setup_minerals() -> void:
	mineral_grid.get_children().map(func (x): x.queue_free())
	mineral_buttons.clear()
	
	var white_outline = ShaderMaterial.new()
	white_outline.shader = WHITE_OUTLINE
	
	for mineral in PLANET_MINERALS[GameManager.planet]:
		var new_button = TextureButton.new()
		
		new_button.texture_normal = load("res://common/ui/inventory/assets/minerals/" + \
		 Enums.Mineral.find_key(mineral).to_lower() + ".png")
		new_button.modulate = Color(0, 0, 0, 0.3)
		new_button.disabled = true
		
		new_button.material = white_outline.duplicate()
		new_button.material.set_shader_parameter("width", 0)
		
		new_button.mouse_entered.connect(
			func ():
				new_button.material.set_shader_parameter("width", 1)
				GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		)
		
		new_button.mouse_exited.connect(
			func ():
				new_button.material.set_shader_parameter("width", 0)
				GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		)
		
		new_button.pressed.connect(show_mineral.bind(mineral))
		
		mineral_buttons.set(mineral, new_button)
		
		mineral_grid.add_child(new_button)

func show_mineral(mineral: Enums.Mineral) -> void:
	listening_mineral = mineral
	amount.text = Math.format_number_short(GameManager.player.minerals[mineral])
	
	var colours = [
		GameManager.mineral_data[mineral].dark_colour,
		GameManager.mineral_data[mineral].mid_colour,
		GameManager.mineral_data[mineral].light_colour,
	]
	panel.material.set_shader_parameter("replacement_colors", colours)
