extends NinePatchRect

const POWERUP_SLOT_PANEL = preload("uid://dlcyduoodbuth")
const POWERUP_SLOT_PANEL_HOVER = preload("uid://b6a614jsixqkq")

const UNLOCKED_SLOT = preload("uid://c02g6pqubgqhu")
const LOCKED_SLOT = preload("uid://bf8qy05oso2ky")

const UNLOCKED_COLOUR := Color(0.216, 0.306, 0.29, 1.0)
const HOVER_COLOUR := Color(0.573, 0.663, 0.518, 1.0)

@export var slots: Array[TextureRect]
@onready var price: Label = $Label

func _ready() -> void:
	mouse_entered.connect(on_hover)
	mouse_exited.connect(off_hover)
	gui_input.connect(func (e):
		if e is InputEventMouseButton and e.is_pressed() and e.button_index == MOUSE_BUTTON_LEFT:
			if StatManager.can_upgrade_stat("powerup_capacity"):
				StatManager.upgrade_stat("powerup_capacity")
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
				update_slots(true))
	
	update_slots()

func update_price() -> void:
	price.text = str(StatManager.get_stat("powerup_capacity").display_cost)

func on_hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	texture = POWERUP_SLOT_PANEL_HOVER
	update_slots(true)

func off_hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	texture = POWERUP_SLOT_PANEL
	update_slots()

func update_slots(hovering: bool = false) -> void:
	var available = int(ceil(StatManager.get_stat("powerup_capacity").value))
	
	for i in range(slots.size()):
		var slot = slots[i]
		if i < available:
			slot.texture = UNLOCKED_SLOT
			slot.modulate = UNLOCKED_COLOUR
		elif hovering && i == available:
			slot.texture = UNLOCKED_SLOT
			slot.modulate = HOVER_COLOUR
		else:
			slot.texture = LOCKED_SLOT
			slot.modulate = Color.WHITE
	
	update_price()
	
