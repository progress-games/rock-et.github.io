extends Resource
class_name WheelPortion

enum Outcome {
	INSANELY_GOOD,
	REALLY_GOOD,
	GOOD,
	DECENT,
	NEUTRAL,
	BAD,
	REALLY_BAD,
	DEVASTATING,
	SUICIDAL
}

@export var rewards: Array[WheelReward]
@export var colour: Color
@export var outcome: Outcome
var portion_size: int


func generate_rewards() -> void:
	for i in range(randi_range(2, 3)):
		var new_reward = generate_reward()
		var idx = rewards.find_custom(func (x): 
			return x.effect == new_reward.effect && x.operation == new_reward.operation
		)
		if idx > -1 && new_reward:
			var r = rewards[idx]
			r.amount += new_reward.amount
		else:
			rewards.append(new_reward)

func generate_reward() -> WheelReward:
	var reward = WheelReward.new()
	match outcome:
		WheelPortion.Outcome.INSANELY_GOOD:
			reward = insanely_good_reward(reward)
		WheelPortion.Outcome.REALLY_GOOD:
			reward = really_good_reward(reward)
		WheelPortion.Outcome.GOOD:
			reward = good_reward(reward)
		WheelPortion.Outcome.DECENT:
			reward = decent_reward(reward)
		WheelPortion.Outcome.NEUTRAL:
			reward = neutral_reward(reward)
		WheelPortion.Outcome.BAD:
			reward = bad_reward(reward)
		WheelPortion.Outcome.REALLY_BAD:
			reward = really_bad_reward(reward)
		WheelPortion.Outcome.DEVASTATING:
			reward = devastating_reward(reward)
		WheelPortion.Outcome.SUICIDAL:
			reward = suicidal_reward(reward)
	
	return reward

func insanely_good_reward(reward: WheelReward) -> WheelReward:
	reward.operation = reward.random_good_operation()
	if reward.operation == WheelReward.Operation.MULT:
		reward.effect = reward.random_mineral()
		reward.amount = snappedf(randf_range(1.25, 1.75), 0.05)
	else:
		reward.effect = reward.random_effect()
		if reward.effect == WheelReward.Effect.SPINS:
			reward.amount = randi_range(2, 5)
		else:
			reward.amount = randi_range(150, 200)
	
	return reward

func really_good_reward(reward: WheelReward) -> WheelReward:
	reward.operation = reward.random_good_operation()
	if reward.operation == WheelReward.Operation.MULT:
		reward.effect = reward.random_mineral()
		reward.amount = snappedf(randf_range(1.1, 1.3), 0.05)
	else:
		reward.effect = reward.random_effect()
		if reward.effect == WheelReward.Effect.SPINS:
			reward.amount = randi_range(1, 2)
		else:
			reward.amount = randi_range(50, 100)
	
	return reward

func good_reward(reward: WheelReward) -> WheelReward:
	reward.operation = WheelReward.Operation.ADD
	reward.effect = reward.random_effect()
	if reward.effect == WheelReward.Effect.SPINS:
		reward.amount = 1
	else:
		reward.amount = randi_range(20, 50)
	
	return reward

func decent_reward(reward: WheelReward) -> WheelReward:
	reward.operation = WheelReward.Operation.ADD
	reward.effect = reward.random_effect()
	if reward.effect == WheelReward.Effect.SPINS:
		reward.amount = 1
	else:
		reward.amount = randi_range(5, 20)
	
	return reward

func neutral_reward(reward: WheelReward) -> WheelReward:
	if rewards.size() > 0: 
		reward.amount = 0
	
	reward.operation = WheelReward.Operation.ADD
	reward.effect = WheelReward.Effect.SPINS
	reward.amount = 1
	
	return reward

func bad_reward(reward: WheelReward) -> WheelReward:
	if rewards.size() > 0: 
		reward.amount = 0
	
	reward.effect = WheelReward.Effect.NOTHING
	
	return reward

func really_bad_reward(reward: WheelReward) -> WheelReward:
	reward.operation = reward.random_bad_operation()
	if reward.operation == WheelReward.Operation.MULT:
		reward.effect = reward.random_mineral()
		reward.amount = snappedf(randf_range(0.8, 0.95), 0.05)
	else:
		reward.effect = reward.random_effect()
		if reward.effect == WheelReward.Effect.SPINS:
			reward.amount = randi_range(1, 2)
		else:
			reward.amount = randi_range(20, 50)
	
	return reward

func devastating_reward(reward: WheelReward) -> WheelReward:
	reward.operation = reward.random_bad_operation()
	if reward.operation == WheelReward.Operation.MULT:
		reward.effect = reward.random_mineral()
		reward.amount = snappedf(randf_range(0.8, 0.95), 0.05)
	else:
		reward.effect = reward.random_effect()
		if reward.effect == WheelReward.Effect.SPINS:
			reward.amount = randi_range(2, 5)
		else:
			reward.amount = randi_range(50, 100)
	
	return reward

func suicidal_reward(reward: WheelReward) -> WheelReward:
	reward.operation = WheelReward.Operation.SUBTRACT
	reward.effect = reward.random_effect()
	if reward.effect == WheelReward.Effect.SPINS:
		reward.amount = 999
	else:
		reward.amount = 999999
	
	return reward
