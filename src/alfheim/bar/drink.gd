extends Resource
class_name Drink

@export var modifiers: Array[DrinkModifier]
#@export var drunk: int
@export var texture: CompressedTexture2D
@export var name: String
@export var price: int

func get_modifiers(m: DrinkModifier.ModifierType) -> Array[DrinkModifier]:
	return modifiers.filter(func (dm: DrinkModifier): return dm.modifier_type == m)

func get_positives_str() -> String:
	return "\n".join(get_modifiers(DrinkModifier.ModifierType.POSITIVE).map(
		func (m: DrinkModifier):
			return m.get_text()
	))

func get_negatives_str() -> String:
	return "\n".join(get_modifiers(DrinkModifier.ModifierType.NEGATIVE).map(
		func (m: DrinkModifier):
			return m.get_text()
	))
