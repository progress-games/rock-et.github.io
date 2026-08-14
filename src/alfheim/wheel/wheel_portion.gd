extends Resource
class_name WheelPortion

enum Outcome {
	WIN,
	LOSS
}

enum Rarity {
	ULTRA_RARE,
	RARE,
	UNCOMMON,
	COMMON
}

enum Reward {
	SPINS,
	DIAMONDS
}

const DIAMOND = " [img]res://common/minerals/diamond.png[/img]"
const SPIN = " [img]res://alfheim/wheel/spin_ticket.png[/img]"

const DIAMOND_S = "[img]res://alfheim/wheel/little diamond.png[/img]"
const SPIN_S = "[img]res://alfheim/wheel/little spin.png[/img]"


@export var outcome: Outcome
@export var rarity: Rarity
@export var reward: Reward
@export var amount: int:
	get():
		return int(ceil(
			amount - StatManager.get_stat("loss_subtraction").value if outcome == Outcome.LOSS
			else amount
			))
var portion_size: float:
	get():
		return 1 + StatManager.get_stat("win_width").value if outcome == Outcome.WIN \
		else 1. 

var reward_text: String:
	get():
		return (" +" if outcome == Outcome.WIN else " -") + str(amount) + \
		(DIAMOND if reward == Reward.DIAMONDS else SPIN)

var small_reward_text: String:
	get():
		return (" +" if outcome == Outcome.WIN else " -") + str(amount) + \
		(DIAMOND_S if reward == Reward.DIAMONDS else SPIN_S)
