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
	DIAMONDS,
	COIN
}

const DIAMOND = " [img]res://common/minerals/diamond.png[/img]"
const SPIN = " [img]res://alfheim/wheel/spin_ticket.png[/img]"
const COIN = " [img]res://common/minerals/coin.png[/img]"

const DIAMOND_S = "[img]res://alfheim/wheel/little diamond.png[/img]"
const SPIN_S = " [img]res://alfheim/wheel/little spin.png[/img]"
const COIN_S = " [img]res://alfheim/wheel/little coin.png[/img]"


@export var outcome: Outcome
@export var rarity: Rarity
@export var reward: Reward
@export var amount: int
var portion_size: float:
	get():
		return 1 + StatManager.get_stat("win_width").value if outcome == Outcome.WIN \
		else 1. 

var reward_text: String:
	get():
		return (" +" if outcome == Outcome.WIN else " -") + str(max(get_amount(), 0)) + get_sprite()

var small_reward_text: String:
	get():
		return (" +" if outcome == Outcome.WIN else " -") + str(get_amount()) + get_little()

func get_amount() -> int:
	return amount - (int(ceil(StatManager.get_stat("loss_subtraction").value)) if outcome == Outcome.LOSS else 0)

func get_sprite() -> String:
	match reward:
		Reward.SPINS: return SPIN
		Reward.DIAMONDS: return DIAMOND
		_: return COIN

func get_little() -> String:
	match reward:
		Reward.SPINS: return SPIN_S
		Reward.DIAMONDS: return DIAMOND_S
		_: return COIN_S
