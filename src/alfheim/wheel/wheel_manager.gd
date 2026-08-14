extends Control

@export var rarity_chances: Dictionary[WheelPortion.Rarity, float]
@export var outcome_chances: Dictionary[WheelPortion.Outcome, float]
@export var default_portions: Array[WheelPortion]

@onready var wheel: Wheel = $Wheel
@onready var choosing_upgrade: WheelUpgradeChoice = $ChoosingUpgrade
@onready var spin_arrow: TextureButton = $SpinArrow
@onready var reroll: TextureButton = $Wheel/Reroll

var current_rarities: Dictionary[WheelPortion.Rarity, float]
var current_outcomes: Dictionary[WheelPortion.Outcome, float]

# Outcome -> Rarity -> Array[WheelPortion]
var all_portions: Dictionary[WheelPortion.Outcome, Dictionary]

var daily_rerolls := 0

func _ready() -> void:
	#GameManager.add_mineral.emit(Enums.Mineral.DIAMOND, 10000)
	
	wheel.finished_spinning.connect(generate_new_wheel)
	
	choosing_upgrade.upgrade_chosen.connect(upgrade_chosen)
	
	current_outcomes = outcome_chances.duplicate_deep()
	current_rarities = rarity_chances.duplicate_deep()
	
	setup_all_portions()
	setup_spin_arrow()
	generate_new_wheel()
	setup_roll()
	update_wheel()

func setup_roll() -> void:
	GameManager.day_changed.connect(
		func (_d):
			daily_rerolls = int(ceil(StatManager.get_stat("wheel_reroll").value))
			reroll.visible = daily_rerolls > 0
			reroll.modulate = Color.WHITE
	)
	
	reroll.mouse_entered.connect(
		func ():
			reroll.material.set_shader_parameter("width", 1)
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ROLL)
	)
	
	reroll.mouse_exited.connect(
		func ():
			reroll.material.set_shader_parameter("width", 0)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	)
	
	reroll.pressed.connect(
		func ():
			if daily_rerolls <= 0: return
			daily_rerolls -= 1
			generate_new_wheel()
			if daily_rerolls <= 0:
				reroll.modulate = Color(0, 0, 0, 0.3)
	)

func setup_all_portions() -> void:
	for outcome in WheelPortion.Outcome.values():
		all_portions.set(outcome, {})
		for rarity in WheelPortion.Rarity.values():
			all_portions[outcome].set(rarity, [])
	
	for portion in default_portions:
		all_portions[portion.outcome][portion.rarity].append(portion)

func setup_spin_arrow() -> void:
	spin_arrow.mouse_entered.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		spin_arrow.material.set_shader_parameter("width", 1))
	
	spin_arrow.mouse_exited.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		spin_arrow.material.set_shader_parameter("width", 0))
	
	spin_arrow.pressed.connect(spin_wheel)

func update_wheel() -> void:
	var s = StatManager.get_stat("loss_chance").value
	current_outcomes[WheelPortion.Outcome.LOSS] = outcome_chances[WheelPortion.Outcome.LOSS] - s
	current_outcomes[WheelPortion.Outcome.WIN] = outcome_chances[WheelPortion.Outcome.WIN] + s 
	
	s = StatManager.get_stat("ultra_rare_chance").value
	var default_chance = rarity_chances[WheelPortion.Rarity.ULTRA_RARE]
	var chance = s * default_chance
	var diff = (default_chance - chance) / 3
	current_rarities[WheelPortion.Rarity.ULTRA_RARE] = chance
	current_rarities[WheelPortion.Rarity.RARE] = rarity_chances[WheelPortion.Rarity.RARE] - diff
	current_rarities[WheelPortion.Rarity.UNCOMMON] = rarity_chances[WheelPortion.Rarity.UNCOMMON] - diff
	current_rarities[WheelPortion.Rarity.COMMON] = rarity_chances[WheelPortion.Rarity.COMMON] - diff
	
	all_portions.values().map(
			func (d):
				d.get(WheelPortion.Rarity.COMMON).map(
					func (p: WheelPortion):
					p.amount = int(ceil(p.amount * StatManager.get_stat("common_multiplier").value))
				)
	)
	
	choosing_upgrade.update_bars(current_outcomes, current_rarities)

func upgrade_chosen(upgrade: WheelUpgrade) -> void:
	upgrade.upgrade_func.call()
	
	if upgrade.short_desc.find("refined") > -1:
		all_portions[WheelPortion.Outcome.LOSS][WheelPortion.Rarity.COMMON].pop_back()
	
	if upgrade.new_portion_1 != null:
		all_portions[upgrade.new_portion_1.outcome][upgrade.new_portion_1.rarity].append(upgrade.new_portion_1)
	
	if upgrade.new_portion_2 != null:
		all_portions[upgrade.new_portion_2.outcome][upgrade.new_portion_2.rarity].append(upgrade.new_portion_2)
	
	update_wheel()
	generate_new_wheel()
	StatManager.upgrade_stat("wheel_level_chosen")

func spin_wheel() -> void:
	if !wheel.pay_for_spin():
		return
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(spin_arrow, "rotation", spin_arrow.rotation + 2 * PI, 0.75)

func generate_new_wheel() -> void:
	wheel.generate_new_wheel(all_portions, current_rarities, current_outcomes)
