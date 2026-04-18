extends HBoxContainer

@export var drop_height := 150.
@export var drop_dur := 1.
@export var hold_dur := 5.

@onready var new_mineral_popup: NewMineralPopup = $NewMineralPopup

var drop_tween: Tween
@onready var base_pos: Vector2 = position

func _ready() -> void:
	position.y = base_pos.y - drop_height
	GameManager.player.mineral_discovered.connect(spawn_popup)

func spawn_popup(m: Enums.Mineral) -> void:
	if SaveManager.loading_save: return
	z_index = 2 if GameManager.state == Enums.State.EXCHANGE else 0
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.NEW_MINERAL)
	
	if drop_tween: drop_tween.kill()
	
	drop_tween = create_tween()
	drop_tween.tween_property(self, "position:y", base_pos.y, drop_dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	drop_tween.tween_property(self, "position:y", base_pos.y, hold_dur)
	drop_tween.tween_property(self, "position:y", base_pos.y-drop_height, drop_dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
	new_mineral_popup.set_mineral(m)
