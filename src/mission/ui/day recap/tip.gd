extends Resource
class_name Tip

enum TipType {
	SERIOUS,
	JOKE
}

enum RequirementType {
	STATE,
	MINERAL
}

const SHOULD_BE_SHOWN: int = 1

@export var text: String
@export var requirement: RequirementType = RequirementType.STATE
@export var mineral_req: Enums.Mineral = Enums.Mineral.AMETHYST
@export var state_req: Enums.State = Enums.State.HOME
@export var tip_type: TipType = TipType.SERIOUS

var shown: int = 0 
