extends Resource
class_name LaunchPanel

enum PanelRequirement {
	STATE,
	BOUGHT_POTION
}

@export var planets: Array[Enums.Planet]
@export var required_state: Enums.State
@export var requirement: PanelRequirement
