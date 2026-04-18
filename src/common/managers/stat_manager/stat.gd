extends Resource
class_name Stat

enum StatType {
	FUEL_CAPACITY,
	THRUSTER_SPEED,
	MINERAL_VALUE,
	HIT_SIZE,
	HIT_STRENGTH,
	CLICK_SPEED,
	LIGHTNING_LENGTH,
	LIGHTNING_DAMAGE,
	LIGHTNING_CHANCE,
	RED_DAMAGE,
	RED_PORTION,
	RED_YIELD,
	ORANGE_DAMAGE,
	ORANGE_PORTION,
	ORANGE_YIELD,
	GREEN_DAMAGE,
	GREEN_PORTION,
	GREEN_YIELD,
	BLUE_DAMAGE,
	BLUE_PORTION,
	BLUE_YIELD,
	BAR_REPLENISH,
	ROCK_BOOST,
	BOOST_DISTANCE,
	ARMOUR,
	BOOST_DISCOUNT,
	POWERUP_DURATION,
	POWERUP_SPAWN_RATE,
	POWERUP_ULTRA_CHANCE,
	UNLOCKED_POWERUPS,
	SPEED_BOOST_POWERUP,
	MORE_MINERALS_POWERUP
}

enum DisplayType {
	SPEED,
	MULT,
	TIME,
	CHANCE,
	BASIC,
	PER_CLICK,
	PERCENT_SPEED,
	BIG_NUMBER,
	CLICKS_PER_SECOND
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
	
	if display_format == DisplayType.PERCENT_SPEED or display_format == DisplayType.CHANCE:
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
	
	if next_level: next_level.upgrade()
	
	cost = round(cost)
	display_cost = Math.format_number_short(round(cost))
	upgraded.emit()

func update_display() -> String:
	var v: float = round(value * pow(10.0, decimal_places)) / pow(10.0, decimal_places)
	match display_format:
		DisplayType.SPEED:
			return str(v) + "px/s"
		DisplayType.MULT:
			return str(v) + "x"
		DisplayType.TIME:
			return str(round(v / 60))  + "m " + str(round(int(v) % 60)) + "s" \
				if v > 60 else str(v) + "s"
		DisplayType.CHANCE:
			return str(round(v * 1000) / 10) + "%"
		DisplayType.BASIC:
			return str(v)
		DisplayType.BIG_NUMBER:
			return Math.format_number_short(int(value))
		DisplayType.PER_CLICK:
			return str(v) + "/pc"
		DisplayType.PERCENT_SPEED:
			return str(round(v * 60000) / 10) + "% px/s"
		DisplayType.CLICKS_PER_SECOND:
			return str(v) + "c/s"
	return ""

func bank_level(_s) -> void:
	banked_levels += 1

func is_max() -> bool:
	return level >= max_level
