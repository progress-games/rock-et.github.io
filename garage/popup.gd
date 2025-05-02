extends Area2D

@export var level_sprites: Array[Texture2D]
@export var stat_name: String

func _ready() -> void:
	GameManager.player.stat_upgraded.connect(_update_sprite)

func _on_mouse_entered() -> void:
	$Popup.visible = true

func _on_mouse_exited() -> void:
	$Popup.visible = false

func _update_sprite(stat: Stat) -> void:
	if stat.name == stat_name and len(level_sprites) > stat.level - 1:
		$Sprite.texture = level_sprites[stat.level - 1]
