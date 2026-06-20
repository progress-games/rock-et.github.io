extends Resource
class_name ExchangeRate

const STORE_AMOUNT = 100;


## the average target, sd (volatility), and current target
@export var mean: float = 1.0;
@export var sd: float = 0.3;

## how often the target is regenerated
@export var interval: int

@export var volatility: float = 0.1

## the last 100 exchange rates
var past_rates: Array = []

var past_rates_normalised: Array = []
var max_rate: float = -10.
var min_rate: float = 10.

var current: float = 0
var current_interval: int = 0;
var target: float = 0

func reset_rate() -> void:
	past_rates.clear()
	past_rates_normalised.clear()
	max_rate = -10
	min_rate = 10
	reset_target()

func reset_target() -> void:
	target = randfn(mean, sd)
	current_interval = 0;

func renormalise_rates() -> void:
	past_rates_normalised = past_rates.map(func (x): return (x - min_rate) / (max_rate - min_rate))

func recalculate_normalise_rates(front: float) -> void:
	if front > min_rate and front < max_rate:
		return
	
	if front == max_rate:
		max_rate = past_rates.max()
	elif front == min_rate:
		min_rate = past_rates.min()
	
	renormalise_rates()

func new_rate() -> void:
	var distance = target - current
	current += distance / (interval - current_interval)
	current += randf_range(-volatility, volatility)
	current = max(0., current)
	current_interval += 1
	
	past_rates.append(current)
	
	var renormalise = current > max_rate or current < min_rate
	
	max_rate = max(current, max_rate)
	min_rate = min(current, min_rate)
	
	if renormalise: renormalise_rates()
	
	if past_rates.size() > STORE_AMOUNT:
		past_rates_normalised.pop_front()
		recalculate_normalise_rates(past_rates.pop_front())
	
	past_rates_normalised.append((current - min_rate) / (max_rate - min_rate))
	
	if current_interval == interval:
		reset_target()
