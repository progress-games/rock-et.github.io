extends Node2D

const MINERAL_COLOUR := Color("cd683d")
const NO_DISCOUNT_POS := Vector2(-10, -7)
const DISCOUNT_POS := Vector2(-11, -14)

func _ready() -> void:
	StatManager.stat_upgraded.connect(func (s): if s.stat_name == "boost_discount": _enable_discount())
	
	$PriceAfterDiscount.visible = false
	$DiscountCross.visible = false
	$BoostDisplay.progress_changed.connect(_set_progress)
	
	_enable_discount()
	_set_progress(0)

func _enable_discount() -> void:
	if StatManager.get_stat("boost_discount").level == 1:
		$PriceBeforeDiscount.position = NO_DISCOUNT_POS
	else:
		$PriceBeforeDiscount.position = DISCOUNT_POS
		$PriceBeforeDiscount.add_theme_color_override("font_color", MINERAL_COLOUR)
		$DiscountCross.visible = true
		$PriceAfterDiscount.visible = true

func _set_progress(progress: float) -> void:
	var price = pow(progress * 100, 1.4)
	$PriceBeforeDiscount.text = CustomMath.format_number_short(price)
	# 1000 -> 10.00%, 100 -> 1%, 10 -> 0.1%
	$PriceAfterDiscount.text = CustomMath.format_number_short(price * 
		(1 - (StatManager.get_stat("boost_discount").value / 10000)))
	$BoostDisplay.progress = progress
	$BoostDisplay._set_max()
