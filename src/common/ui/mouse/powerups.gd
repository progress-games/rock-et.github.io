extends HBoxContainer

const POWERUP_DURATION := 3.

const BASE := Color("2e222f")
const SUPER := Color("f9c22b")

const IGNORE: Array[Powerup.PowerupType] = [
	Powerup.PowerupType.EXPLOSION,
	Powerup.PowerupType.LASER,
	Powerup.PowerupType.MORE_ROCKS,
	Powerup.PowerupType.LOCK_ON,
	Powerup.PowerupType.GOLDEN_ASTEROID
]

# includes super powerups too
# eg. "falseSPEED_BOOST" is not super, speed boost
var powerups: Dictionary[Powerup.PowerupType, TextureRect]

var powerup_listening: Dictionary[Powerup.PowerupType, bool]
var powerup_timers: Dictionary[Powerup.PowerupType, float]

func _ready() -> void:
	reset_dicts()
	setup_powerups()
	GameManager.powerup_hit.connect(increment_count)
	GameManager.state_changed.connect(func (s): 
		if s == Enums.State.MISSION: reset_dicts())

func reset_dicts() -> void:
	for p in Powerup.PowerupType.values():
		powerup_listening[p] = false
		powerup_timers[p] = 0.

func setup_powerups() -> void:
	for powerup in GameManager.powerup_data.keys():
		# not super
		if powerup in IGNORE: continue
		
		var rect = $SpeedBoost.duplicate() as TextureRect
		rect.texture = GameManager.powerup_data[powerup].texture
		rect.material = rect.material.duplicate()
		rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		rect.get_child(0).text = "x0"
		rect.visible = false
		add_child(rect)
		powerups[powerup] = rect
	
	$SpeedBoost.queue_free()

func _process(delta: float) -> void:
	for p in powerups.keys():
		if !powerup_listening[p] and powerup_timers[p] <= 0. and powerups[p].visible:
			powerups[p].material.set_shader_parameter("color", BASE)
			powerups[p].visible = false
		
		if powerup_listening[p]:
			var v = round(GameManager.powerup_modifiers[p] * 10.) / 10.
			powerup_listening[p] = v > 0
			var label = powerups[p].get_child(0) as Label
			if str(v).ends_with(".0"): v = int(v)
			label.text = "x" + str(v)
			#if p == Powerup.PowerupType.SNOW_TRAIL: label.text = str(v) + "px"
		
		if powerup_timers[p] > 0.:
			var label = powerups[p].get_child(0) as Label
			label.text = str(round(powerup_timers[p] * 10.) / 10.) + "s"
			powerup_timers[p] -= delta

func increment_count(powerup: Powerup) -> void:
	var powerup_type = powerup.powerup_type
	
	if powerup_type in IGNORE: return
	
	powerups[powerup_type].visible = true
	var super_mult = 1.
	
	if powerup.super_powerup: 
		super_mult = 3.
		powerups[powerup_type].material.set_shader_parameter("color", SUPER)
	
	match powerup_type:
		Powerup.PowerupType.TIPSY, Powerup.PowerupType.SNOW_TRAIL:
			powerup_timers[powerup_type] = StatManager.get_stat("tipsy_powerup").value * super_mult \
				if powerup_type == Powerup.PowerupType.TIPSY else POWERUP_DURATION
		_:
			powerup_listening[powerup_type] = true
