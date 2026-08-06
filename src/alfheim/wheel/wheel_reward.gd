extends Resource
class_name WheelReward

enum Operation {
	ADD,
	SUBTRACT,
	MULT
}

enum Effect {
	SPINS,
	QUARTZ,
	DIAMOND,
	TUGTUPITE,
	LARIMAR,
	NOTHING
}

var effect_multipliers: Dictionary[Effect, float] = {
	Effect.SPINS: 1.,
	Effect.QUARTZ: 1.,
	Effect.DIAMOND: 0.8,
	Effect.TUGTUPITE: 0.6,
	Effect.LARIMAR: 0.2,
	Effect.NOTHING: 1.
}

@export var amount: float
@export var operation: Operation
@export var effect: Effect
var description: String:
	get():
		return format_desc()

var normalised: bool = false

func normalise_amount(a: float) -> float:
	if operation == Operation.MULT:
		return snappedf(a, 0.05)
	
	return int(ceil(min(a * effect_multipliers[effect] * \
		(1 + StatManager.get_stat("wheel_level").level / 10.), 99999)))

func format_desc() -> String:
	if effect == Effect.NOTHING: return 'NOTHING'
	if amount == 0: return ""
	
	var t = ""
	match operation:
		Operation.ADD:
			t += "+" + str(normalise_amount(amount))
		Operation.MULT:
			t += "x" + str(normalise_amount(amount))
		Operation.SUBTRACT:
			t += "-" + str(normalise_amount(amount))
	
	t = t.trim_suffix(".0") + " "
	
	match effect:
		Effect.SPINS:
			t += "[img]res://alfheim/wheel/spin_ticket.png[/img]"
		_:
			t += "[img]res://common/minerals/" + Effect.find_key(effect).to_lower() + ".png[/img]"
	
	return t

func get_minerals() -> Array[Effect]:
	var options: Array[Effect] = [Effect.QUARTZ, Effect.DIAMOND, Effect.TUGTUPITE, Effect.LARIMAR]
	if !GameManager.player.has_discovered_mineral(Enums.Mineral.TUGTUPITE):
		options.erase(Effect.TUGTUPITE)
	if !GameManager.player.has_discovered_mineral(Enums.Mineral.LARIMAR):
		options.erase(Effect.LARIMAR)
	
	return options

func random_effect() -> Effect:
	var options = get_minerals()
	options.append(Effect.SPINS)
	return options.pick_random()

func random_mineral() -> Effect:
	return get_minerals().pick_random()

func random_bad_operation() -> Operation:
	return [Operation.SUBTRACT, Operation.MULT].pick_random()

func random_good_operation() -> Operation:
	return [Operation.ADD, Operation.MULT].pick_random()
