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

static func format_number_short(n: int) -> String:
	var suffixes = [
		{ "threshold": 1_000_000_000_000_000_000, "suffix": "s" }, # sextillion
		{ "threshold": 1_000_000_000_000_000,     "suffix": "Q" }, # quintillion
		{ "threshold": 1_000_000_000_000,         "suffix": "q" }, # quadrillion
		{ "threshold": 1_000_000_000,             "suffix": "b" }, # billion
		{ "threshold": 1_000_000,                 "suffix": "m" }, # million
		{ "threshold": 1_000,                     "suffix": "k" }, # thousand
	]

	for item in suffixes:
		if n >= item["threshold"]:
			var short_val = float(n) / item["threshold"]
			var str_val = str(short_val)
			
			# Strip trailing zeroes and decimals
			if "." in str_val:
				str_val = str_val.rstrip("0").rstrip(".")
			
			# Ensure max 3 non-dot characters
			var without_dot = str_val.replace(".", "")
			while without_dot.length() > 3:
				str_val = str_val.substr(0, str_val.length() - 1)
				without_dot = str_val.replace(".", "")
				if "." in str_val and str_val.ends_with("."):
					str_val = str_val.substr(0, str_val.length() - 1)
					break
			
			return str_val + item["suffix"]

	return str(n)

# this doesn't square sd but who gives a fuck
static func normal_value(x: float, m: float, s: float) -> float:
	var raised = (-1 / (2 * s)) * pow(x - m, 2.)
	return (1 / sqrt(2 * PI)) * exp(raised)

## given an array and n, returns the index it landed on
## e.g [0.2, 1] and 0.5 gives index 1
## [0.2, 0.4, 0.6, 1], 0.5 -> 2
static func get_weighted_value(arr: Array, n: float) -> int:
	for i in arr.size():
		if n <= arr[i]:
			return i
	return -1
