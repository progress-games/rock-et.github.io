extends Node
class_name CustomMath

static func from_dist(percent: float, mean: float, std_dev: float) -> int:
	# Clamp percent to avoid edge cases
	percent = clamp(percent, 0.00001, 0.99999)

	# Approximate inverse CDF using the inverse error function
	# Reference: https://stackoverflow.com/a/23292986
	var a = 0.147  # Constant in approximation
	var ln = log(1.0 - percent * percent)
	var term1 = 2.0 / (PI * a) + ln / 2.0
	var sqrt_term = sqrt(term1 * term1 - ln / a)
	var erfinv = sign(percent - 0.5) * sqrt(sqrt_term - term1)

	# Convert to normal distribution value
	var z = sqrt(2) * erfinv
	var value = mean + std_dev * z

	return round(value)

static func random_vector(n: float = 1000) -> Vector2:
	return Vector2(randf_range(-n, n), randf_range(-n, n))
