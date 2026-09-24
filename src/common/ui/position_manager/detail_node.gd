extends Resource
class_name DetailNode

"""
on (day) show this speech bubble
once the player has visited (listening_state) (state_amount) times, show this speech bubble
"""

enum ShowRequirement {
	LISTENING_STATE,
	STAT_LEVEL,
	MINERAL_AMOUNT,
	CLICKY,
	SCAVENGE_CHEST
}

@export var speech_bubble: NodePath

@export var show_requirement: ShowRequirement

## each node is shown from this detail onwards
@export var show_nodes: Array[NodePath]

## each node is hidden from this detail onwards
@export var hide_nodes: Array[NodePath]

## each node is moved here when switching to this detail
@export var movements: Dictionary[NodePath, Vector2]

@export_group("state")
@export var listening_state: Enums.State
@export var state_amount: int
var total_state_amount: int

@export_group("mineral")
@export var mineral_type: Enums.Mineral
@export var mineral_amount: int

@export_group("stat")
@export var stat_name: String
@export var stat_level: int

var has_been_read: bool = false
var has_been_shown: bool = false
var entered_state_today: bool = false

var has_scavenged: bool = false

func _init() -> void:
	GameManager.day_changed.connect(func (_d):
		entered_state_today = false)
	GameManager.state_changed.connect(func (s): 
		if !entered_state_today && s == listening_state: 
			total_state_amount = max(total_state_amount, state_amount)
			state_amount -= 1
			entered_state_today = true)
	GameManager.scavenge_chest_closed.connect(func (): has_scavenged = true)

func force_read() -> void:
	has_been_read = true
	has_been_shown = true

func is_ready() -> bool:
	if has_been_read:
		return true
	
	match show_requirement:
		ShowRequirement.LISTENING_STATE:
			return state_amount == 0 || listening_state == Enums.State.HOME
		ShowRequirement.STAT_LEVEL:
			return StatManager.get_stat(stat_name).level >= stat_level
		ShowRequirement.MINERAL_AMOUNT:
			return GameManager.can_afford(mineral_amount, mineral_type)
		ShowRequirement.CLICKY:
			return ClickEffectManager.stats.values().any(func (x): 
				return x.get(ClickEffectManager.StatType.EVERY).size() > 0)
		ShowRequirement.SCAVENGE_CHEST:
			return has_scavenged
	
	assert(false, "something fishy is going on")
	return false
