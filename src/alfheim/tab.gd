extends Control

@onready var positives: RichTextLabel = $HBoxContainer/MarginContainer/MarginContainer/RichTextLabel
@onready var negatives: RichTextLabel = $HBoxContainer/MarginContainer2/MarginContainer/RichTextLabel

func _ready() -> void:
	visibility_changed.connect(refresh_tab)
	GameManager.day_changed.connect(func (_d): refresh_tab())

func refresh_tab() -> void:
	var positive_effects = DrinksManager.get_effects(DrinkModifier.ModifierType.POSITIVE)
	if positive_effects == "": positive_effects = "no active positive effects"
	
	var negative_effects = DrinksManager.get_effects(DrinkModifier.ModifierType.NEGATIVE)
	if negative_effects == "": negative_effects = "no active negative effects"
	
	positives.text = positive_effects
	negatives.text = negative_effects
	
