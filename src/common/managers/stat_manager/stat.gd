extends Resource
class_name Stat

enum DisplayType {
	SPEED,
	MULT,
	TIME,
	CHANCE,
	BASIC,
	PER_CLICK,
	PERCENT_SPEED,
	INCREASE_MULT
}

@export var cost: float
@export var mineral: Enums.Mineral
@export var display_format: DisplayType
@export var value: float
@export var tooltip: String
@export var max_level: int = 9999
@export var display_name: String
@export var level: int = 1

var stat_name: String
var upgrade_method: Callable = bank_level
var display_value: String = "test"
var display_cost: String

var next_level_required: bool = true

# for displaying value of next level
var next_level: Stat = null:
	get:
		if !next_level and next_level_required:
			next_level = self.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
			next_level.next_level_required = false
			next_level.upgrade()
		return next_level
var banked_levels: int = 0

signal upgraded

func add_upgrade_method(method: Callable) -> void:
	upgrade_method = method
	
	for i in range(banked_levels):
		upgrade_method.call(self)
		next_level.upgrade()
	
	update_display()
	banked_levels = 0
	
	cost = round(cost)
	display_cost = CustomMath.format_number_short(round(cost))

func upgrade() -> void:
	if level >= max_level:
		display_cost = "MAX"
		return
	
	level += 1
	upgrade_method.call(self)
	
	if next_level: next_level.upgrade()
	update_display()
	
	cost = round(cost)
	display_cost = CustomMath.format_number_short(round(cost))
	upgraded.emit()

func update_display() -> String:
	match display_format:
		DisplayType.SPEED:
			return str(value) + "px/s"
	return ""

func bank_level(_s) -> void:
	banked_levels += 1

func is_max() -> bool:
	return level >= max_level
