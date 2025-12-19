extends TextureButton

const PRICE_VIS := -35
const PRICE_HIDE := -5
const PRICES: Array[int] = [25, 100, 250]

const AFFORD := preload("res://scientist/assets/price_hover.png")
const BROKE := preload("res://scientist/assets/price_hover_disabled.png")

var hover_tween: Tween

signal new_bar_unlocked(colour: String)

func show_price() -> void:
	mouse_entered.connect(func (): material.set_shader_parameter("width", 1))
	
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property($PriceHover, "position:y", PRICE_VIS, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	_set_price()

func hide_price() -> void:
	mouse_exited.connect(func (): material.set_shader_parameter("width", 0))
	
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property($PriceHover, "position:y", PRICE_HIDE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	_set_price()

func _get_level() -> Dictionary:
	var colours = ["orange", "green", "blue"]
	var level = 0
	for i in colours.size():
		if GameManager.get_stat(colours[i] + "_portion").level == 1: level = i; break
	
	return {"level": level, "colour": colours[level]}

func _set_price() -> void:
	var level = _get_level()
	$PriceHover/Label.text = str(PRICES[level.level])
	$PriceHover.texture = AFFORD if GameManager.player.get_mineral(Enums.Mineral.OLIVINE) >= PRICES[level.level] else BROKE

func _on_pressed() -> void:
	var level = _get_level()
	if GameManager.player.get_mineral(Enums.Mineral.OLIVINE) < PRICES[level.level]:
		return
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_UP)
	
	GameManager.add_mineral.emit(Enums.Mineral.OLIVINE, -PRICES[level.level])
	GameManager.get_stat(level.colour + "_portion").level = 2
	visible = level.level != 2
	GameManager.player.portions_changed = true
	_set_price()
	new_bar_unlocked.emit(level.colour)
	
