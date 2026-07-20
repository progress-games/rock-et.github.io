extends Control

const HOVER_LOCATION = 2
const OFF_HOVER_LOCATION = -100
@export var drinks: Dictionary[String, Drink]

@onready var drink_buttons: Array[TextureButton] = [
	$Drinks/TextureButton, 
	$Drinks/TextureButton2, 
	$Drinks/TextureButton3, 
	$Drinks/TextureButton4, 
	$Drinks/TextureButton5
]

@onready var price: Label = $Price
@onready var drink_name: Label = $Details/DrinkName/MarginContainer/Label
@onready var positives: Label = $Details/Desc/Positives/MarginContainer/Label
@onready var negatives: Label = $Details/Desc/Negatives/MarginContainer/Label
@onready var details: VBoxContainer = $Details

@onready var positives_panel: MarginContainer = $Details/Desc/Positives
@onready var negatives_panel: MarginContainer = $Details/Desc/Negatives

func _ready() -> void:
	for n in drinks.keys():
		drinks[n].name = n
	
	drink_buttons.map(
		func (d: TextureButton):
			d.mouse_entered.connect(func (): hover_drink(d))
			d.mouse_exited.connect(func (): off_hover_drink(d))
			d.pressed.connect(func (): buy_drink(d))
	)
	
	price.pivot_offset_ratio = Vector2.ONE * 0.5
	
	GameManager.day_changed.connect(refresh_bar)
	refresh_bar()
	off_hover_drink(drink_buttons[0])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("potion slot 1"):
		refresh_bar()

func refresh_bar(_d = 0) -> void:
	for drink in drink_buttons:
		var drink_type = drinks.values().pick_random()
		drink.disabled = false
		drink.modulate = Color(1, 1, 1)
		drink.texture_normal = drink_type.texture
		drink.set_meta("drink_type", drink_type)

func buy_drink(drink: TextureButton) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
	
	var drink_type: Drink = drink.get_meta("drink_type")
	
	for m in drink_type.modifiers:
		DrinksManager.add_modifer(m)
	
	off_hover_drink(drink)
	drink.disabled = true
	drink.modulate = Color(0.0, 0.0, 0.0, 0.412)

func hover_drink(drink: TextureButton) -> void:
	if drink.disabled: return
	drink.material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	
	var drink_type: Drink = drink.get_meta("drink_type")
	drink_name.text = drink_type.name
	price.text = str(drink_type.price)
	positives.text = drink_type.get_positives_str()
	negatives.text = drink_type.get_negatives_str()
	
	positives_panel.visible = positives.text != ""
	negatives_panel.visible = negatives.text != ""
	price.visible = true
	
	details.visible = true
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(details, "position:y", HOVER_LOCATION, 0.25)

func off_hover_drink(drink: TextureButton) -> void:
	if drink.disabled: return
	drink.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(details, "position:y", OFF_HOVER_LOCATION, 0.25)
	
	price.visible = false
	#t.finished.connect(func (): details.visible = false)
