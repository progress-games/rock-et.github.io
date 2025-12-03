extends Resource
class_name ExchangeRate

# for 100 mineral, we get this much gold

## the average target, sd (volatility), and current target
@export var target: Dictionary = {
	"mean": 100,
	"sd": 15
}

## how often the target is regenerated
@export var interval: int

## how much this exchange could fluctuate in one day
@export var volatility: int

## <0: this exchange points down; >0 this exchange points up
@export var volatility_bias: int

## the last 10 exchange rates
<<<<<<< Updated upstream
var past_rates: Array[float]
=======
var past_rates: Array = []
>>>>>>> Stashed changes

## the stats
var stats := {
	"max": -INF,
	"min": INF,
	"average": 0
}

func set_up() -> void:
	target.set("current", target.mean)
	target.set("target", target.mean)

func refresh() -> void:
	stats.max = max(target.current, stats.max)
	stats.min = min(target.current, stats.min)
	stats.average = past_rates.reduce(func (a, x): return a + x, 0) / past_rates.size()

func get_exchange(day: int) -> void:
	# if it's day 1, and we already have a rate here. for saving
	if past_rates.size() >= day:
		return
	if day % interval == 0:
		target.target = randfn(target.mean, target.sd)
	
	var direction = target.target - target.current
	
	if volatility_bias < 0:
		direction += randf_range(-volatility + volatility_bias, volatility)
	else:
		direction += randf_range(- volatility, volatility + volatility_bias)
	
	target.current += direction
	target.current = max(1, target.current)
	
	past_rates.append(target.current)
	if past_rates.size() > 10: past_rates.pop_front()
	
	refresh()
