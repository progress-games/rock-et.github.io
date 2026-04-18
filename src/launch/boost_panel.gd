extends Node2D

const MINERAL_COLOUR := Color("cd683d")
const NO_DISCOUNT_POS := Vector2(-10, -7)
const DISCOUNT_POS := Vector2(-11, -14)

@onready var price_before_discount: Label = $PriceBeforeDiscount
@onready var discount_cross: ColorRect = $DiscountCross
@onready var boost_display: Node2D = $BoostDisplay
@onready var price_after_discount: Label = $PriceAfterDiscount

func _ready() -> void:
	StatManager.stat_upgraded.connect(func (s): if s.stat_name == "boost_discount": _enable_discount())
	
	price_after_discount.visible = false
	discount_cross.visible = false
	boost_display.progress_changed.connect(_set_progress)
	
	_enable_discount()
	_set_progress(0)

func _enable_discount() -> void:
	if StatManager.get_stat("boost_discount").level == 1:
		price_before_discount.position = NO_DISCOUNT_POS
	else:
		price_before_discount.position = DISCOUNT_POS
		price_before_discount.add_theme_color_override("font_color", MINERAL_COLOUR)
		discount_cross.visible = true
		price_after_discount.visible = true

func _set_progress(progress: float) -> void:
	var price = pow(progress * 100, 1.4)
	price_before_discount.text = Math.format_number_short(price)
	# 1000 -> 10.00%, 100 -> 1%, 10 -> 0.1%
	price_after_discount.text = Math.format_number_short(price * 
		(1 - (StatManager.get_stat("boost_discount").value)))
	boost_display.progress = progress
	boost_display.set_max()
