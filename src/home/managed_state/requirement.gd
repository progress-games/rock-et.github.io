extends Resource
class_name Requirement

enum RequirementType {
	DAY,
	MINERAL,
	CUSTOM
}

@export var requirement_type: RequirementType
@export var mineral: Enums.Mineral
@export var day: int

@export var redirection: Enums.State
