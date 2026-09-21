extends Control

@onready var positives: RichTextLabel = $ActiveDrinks/HBoxContainer/MarginContainer/MarginContainer/RichTextLabel
@onready var negatives: RichTextLabel = $ActiveDrinks/HBoxContainer/MarginContainer2/MarginContainer/RichTextLabel
@onready var active_drinks: VBoxContainer = $ActiveDrinks
@onready var close_tab: TextureButton = $"../../CloseTab"
@onready var launch: TextureButton = $"../Launch"

func _ready() -> void:
	GameManager.state_changed.connect(func (s): 
		if s == Enums.State.LAUNCH && visible: 
			GameManager.hide_inventory.emit()
			refresh_tab())
	GameManager.day_changed.connect(func (_d): refresh_tab())

func refresh_tab() -> void:
	var positive_effects = DrinksManager.get_effects(DrinkModifier.ModifierType.POSITIVE)
	if positive_effects == "": positive_effects = "no active positive effects"
	
	var negative_effects = DrinksManager.get_effects(DrinkModifier.ModifierType.NEGATIVE)
	if negative_effects == "": negative_effects = "no active negative effects"
	
	active_drinks.visible = positive_effects != "no active positive effects" || \
		negative_effects != "no active negative effects"
	
	positives.text = positive_effects
	negatives.text = negative_effects
