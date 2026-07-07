extends Control

const ON_HOVER_POS := 14
const OFF_HOVER_POS := 86
const PRICE_TWEEN_DUR := 0.3

@onready var price: NinePatchRect = $Price
@onready var price_text: Label = $Price/Price

@onready var freeze_chance: UpgradeButton = $Wall/FreezeChance
@onready var hit_size: UpgradeButton = $Wall/HitSize
@onready var freeze_dur: UpgradeButton = $Wall/FreezeDur

var price_tween: Tween

func _ready() -> void:
	freeze_chance.mouse_entered.connect(func (): show_price(freeze_chance))
	freeze_chance.mouse_exited.connect(hide_price)
	
	hit_size.mouse_entered.connect(func (): show_price(hit_size))
	hit_size.mouse_exited.connect(hide_price)
	
	freeze_dur.mouse_entered.connect(func (): show_price(freeze_dur))
	freeze_dur.mouse_exited.connect(hide_price)

func show_price(u: UpgradeButton) -> void:
	price_text.text = StatManager.get_stat(u.stat_name).display_cost
	
	if price_tween:
		price_tween.kill()
	price_tween = create_tween()
	price_tween.tween_property(price, "position:x", ON_HOVER_POS, PRICE_TWEEN_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_price() -> void:
	price_tween.kill()
	price_tween = create_tween()
	price_tween.tween_property(price, "position:x", OFF_HOVER_POS, PRICE_TWEEN_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
