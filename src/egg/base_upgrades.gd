extends Control

enum Tab {
	FREEZE,
	SHARD
}

const ON_HOVER_POS := 14
const OFF_HOVER_POS := 86
const PRICE_TWEEN_DUR := 0.3

@onready var price: NinePatchRect = $Price
@onready var price_text: Label = $Price/Price

@onready var freeze_chance: UpgradeButton = $Wall/Freeze/FreezeChance
@onready var hit_size: UpgradeButton = $Wall/Freeze/HitSize
@onready var freeze_dur: UpgradeButton = $Wall/Freeze/FreezeDur

@onready var shard_amount: UpgradeButton = $Wall/Shard/ShardAmount
@onready var shard_chance: UpgradeButton = $Wall/Shard/ShardChance
@onready var shard_damage: UpgradeButton = $Wall/Shard/ShardDamage

@onready var freeze_buttons: Control = $Wall/Freeze
@onready var shard_buttons: Control = $Wall/Shard

@onready var freeze_stats: Control = $Stats/Freeze
@onready var shard_stats: Control = $Stats/Shard

@onready var freeze_tab: TextureButton = $Tabs/FreezeTab
@onready var locked_tab: TextureButton = $Tabs/LockedTab
@onready var shard_tab: TextureButton = $Tabs/ShardTabs

var current_tab: Tab = Tab.FREEZE

func _ready() -> void:
	freeze_chance.mouse_entered.connect(func (): show_price(freeze_chance))
	freeze_chance.mouse_exited.connect(hide_price)
	
	hit_size.mouse_entered.connect(func (): show_price(hit_size))
	hit_size.mouse_exited.connect(hide_price)
	
	freeze_dur.mouse_entered.connect(func (): show_price(freeze_dur))
	freeze_dur.mouse_exited.connect(hide_price)
	
	shard_amount.mouse_entered.connect(func (): show_price(shard_amount))
	shard_amount.mouse_exited.connect(hide_price)
	
	shard_chance.mouse_entered.connect(func (): show_price(shard_chance))
	shard_chance.mouse_exited.connect(hide_price)
	
	shard_damage.mouse_entered.connect(func (): show_price(shard_damage))
	shard_damage.mouse_exited.connect(hide_price)

func set_tab(tab: Tab) -> void:
	current_tab = tab
	freeze_buttons.visible = tab == Tab.FREEZE
	shard_buttons.visible = tab == Tab.SHARD
	freeze_stats.visible = tab == Tab.FREEZE
	shard_stats.visible = tab == Tab.SHARD


func show_price(u: UpgradeButton) -> void:
	price_text.text = StatManager.get_stat(u.stat_name).display_cost
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	
	var t = create_tween()
	t.tween_property(price, "position:x", ON_HOVER_POS, PRICE_TWEEN_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_price() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	
	var t = create_tween()
	t.tween_property(price, "position:x", OFF_HOVER_POS, PRICE_TWEEN_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
