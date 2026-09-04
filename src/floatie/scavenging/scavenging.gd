extends Control

const PRICE_OFF_HOVER := 105
const PRICE_ON_HOVER := 170

const BASE_PERCENT_POS := 162
const PERCENT_WIDTH := BASE_PERCENT_POS - 46 

@onready var daily_scavenges: UpgradeButton = $Buttons/DailyScavenges
@onready var rarity: UpgradeButton = $Buttons/Rarity
@onready var duration: UpgradeButton = $Buttons/Duration
@onready var price: TextureRect = $Buttons/Price
@onready var price_text: Label = $Buttons/Price/Price
@onready var reward: OpenReward = $Reward

@onready var scavenge: TextureButton = $Scavenge
@onready var progress: Panel = $Progress
@onready var progress_bar: Panel = $Progress/Progress
@onready var percent: Label = $Progress/Percent

var scavenges_left := 1
var scavenge_timer := -1.
var scavenging := false

func _ready() -> void:
	daily_scavenges.mouse_entered.connect(func (): show_price(daily_scavenges))
	daily_scavenges.mouse_exited.connect(func (): hide_price())
	rarity.mouse_entered.connect(func (): show_price(rarity))
	rarity.mouse_exited.connect(func (): hide_price())
	duration.mouse_entered.connect(func (): show_price(duration))
	duration.mouse_exited.connect(func (): hide_price())
	
	scavenge.mouse_entered.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		scavenge.material.set_shader_parameter("width", 1))
	
	scavenge.mouse_exited.connect(
		func ():
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
			scavenge.material.set_shader_parameter("width", 0)
	)
	
	scavenge.pressed.connect(start_scavenge)
	
	GameManager.day_changed.connect(
		func (_d):
			scavenge.disabled = false
			scavenges_left = int(ceil(StatManager.get_stat("daily_scavenges").value))
	)

func start_scavenge() -> void:
	if scavenges_left <= 0: return
	
	scavenge.hide()
	progress.show()
	scavenge_timer = StatManager.get_stat("scavenge_duration").value
	scavenging = true
	scavenges_left -= 1
	
	if scavenges_left <= 0: scavenge.disabled = true

func end_scavenge() -> void:
	scavenge.show()
	progress.hide()
	
	var rng = RandomNumberGenerator.new()
	
	reward.load_reward(
		rng.rand_weighted(DroneManager.reward_chances.values())
	)
	scavenging = false

func _process(delta: float) -> void:
	if scavenge_timer <= 0 && scavenging:
		end_scavenge()
	elif scavenge_timer > 0 && scavenging:
		scavenge_timer -= delta
		var p = (1 - (scavenge_timer / StatManager.get_stat("scavenge_duration").value))
		progress_bar.material.set_shader_parameter("progress", p * 1.2 - 0.1)
		percent.text = str(round(1000 * p) / 10.) + "%"
		percent.position.y = BASE_PERCENT_POS - p * PERCENT_WIDTH

func show_price(button: UpgradeButton) -> void:
	price_text.text = StatManager.get_stat(button.stat_name).display_cost
	
	price.position.y = button.position.y + 1
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(price, "position:x", PRICE_ON_HOVER, 0.3)

func hide_price() -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(price, "position:x", PRICE_OFF_HOVER, 0.3)
