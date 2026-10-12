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
	BIG_NUMBER,
	CLICKS_PER_SECOND,
	DISTANCE,
	ADD_TIME,
	PLUS_PERCENT_FULL_NUMBER,
	GRID
}

@export var cost: float
@export var mineral: Enums.Mineral
@export var display_format: DisplayType
@export var decimal_places: int = 1
@export var value: float
@export var tooltip: String
@export var max_level: int = 9999
@export var display_name: String
@export var level: int = 1

var base_cost: float
var base_value: float
var base_level: int

var stat_name: String
var upgrade_method: Callable = bank_level
var display_value: String:
	get():
		return update_display()
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
signal resetted

func reset() -> void:
	if base_cost:
		next_level = null
		cost = base_cost
		value = base_value
		level = base_level
	else:
		base_cost = cost
		base_value = value
		base_level = level
	resetted.emit()

func add_upgrade_method(method: Callable) -> void:
	upgrade_method = method
	
	if display_format == DisplayType.PERCENT_SPEED:
		decimal_places += 2
	
	if next_level: next_level.add_upgrade_method(method)
	
	for i in range(banked_levels):
		upgrade_method.call(self)
		if next_level: next_level.upgrade()
	
	banked_levels = 0
	
	cost = round(cost)
	display_cost = Math.format_number_short(round(cost))

func upgrade() -> void:
	if level >= max_level:
		display_cost = "MAX"
		return
	
	level += 1
	upgrade_method.call(self)
	
	if decimal_places == 0: value = int(ceil(value))
	
	if next_level: next_level.upgrade()
	
	cost = round(cost)
	display_cost = Math.format_number_short(round(cost))
	upgraded.emit()

func update_display(suffix: bool = true) -> String:
	if !suffix:
		print_stack()
	
	var v: String
	match display_format:
		DisplayType.CHANCE:
			v = str(
				snappedf(
					value * pow(10, decimal_places + 2) / pow(10, decimal_places), 
				0.01)
			)
			return v.rstrip("0").rstrip(".") + "%"
		DisplayType.TIME:
			if value > 60:
				return str(floor(value / 60)).rstrip("0").rstrip(".")  + "m " + \
					str(snappedf(fmod(value, 60), 1)) + "s" 
			else:
				return str(snappedf(value, .1)).trim_suffix(".0") + "s"
	
	v = str(snappedf(value, 1 / pow(10, decimal_places + 1))).rstrip("0").rstrip(".")
	
	match display_format:
		DisplayType.SPEED:
			return v + "px/s"
		DisplayType.DISTANCE:
			return v + "px"
		DisplayType.MULT:
			return v + "x"
		DisplayType.BASIC:
			return v
		DisplayType.BIG_NUMBER:
			return Math.format_number_short(int(value))
		DisplayType.PER_CLICK:
			return v + "/pc"
		DisplayType.PERCENT_SPEED:
			return str(round(value * 60000) / 10) + "% px/s"
		DisplayType.CLICKS_PER_SECOND:
			return v + "c/s"
		DisplayType.ADD_TIME:
			return "+" + str(-value) + "s"
		DisplayType.PLUS_PERCENT_FULL_NUMBER:
			return "+" + v + "%"
		DisplayType.GRID:
			return v + "x" + v
	return ""

func bank_level(_s) -> void:
	banked_levels += 1

func is_max() -> bool:
	return level >= max_level
