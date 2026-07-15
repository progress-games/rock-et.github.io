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
	Effect.QUARTZ: 2.,
	Effect.DIAMOND: 1.,
	Effect.TUGTUPITE: 0.9,
	Effect.LARIMAR: 0.4
}

@export var amount: float
@export var operation: Operation
@export var effect: Effect
var description: String:
	get():
		return format_desc()

var normalised: bool = false

func normalise_amount() -> void:
	if normalised: print_debug("reward already normalised!"); return
	normalised = true
	match operation:
		Operation.MULT:
			amount = snappedf(amount, 0.05)
		_:
			amount = min(amount * effect_multipliers[effect], 99999)

func format_desc() -> String:
	if effect == Effect.NOTHING: return 'NOTHING'
	if amount == 0: return ""
	
	var t = ""
	match operation:
		Operation.ADD:
			t += "+" + str(int(ceil(min(amount * effect_multipliers[effect], 99999))))
		Operation.MULT:
			t += "x" + str(snappedf(amount, 0.05))
		Operation.SUBTRACT:
			t += "-" + str(int(ceil(min(amount * effect_multipliers[effect], 99999))))
	
	t = t.rstrip("$.0") + " "
	
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
	if GameManager.player.has_discovered_mineral(Enums.Mineral.LARIMAR):
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
