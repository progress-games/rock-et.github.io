extends Control

func _ready() -> void:
	refresh()
	GameManager.add_mineral.connect(func (m, a): refresh())

func refresh() -> void:
	$Header.text = "day " + str(GameManager.day) + " recap"
	
	for node in $Stats/Minerals/Minerals/Minerals.get_children(): node.queue_free()
	for node in $Stats/Upgrades/Upgrades/Upgrades.get_children(): node.queue_free()
	
	$Stats/Minerals.visible = GameManager.day_stats.minerals.size() != 0
	$Stats/Upgrades.visible = GameManager.day_stats.upgrades.size() != 0
	
	for mineral in GameManager.day_stats.minerals.keys():
		var amount = GameManager.day_stats.minerals[mineral]
		var texture = GameManager.MINERAL_TEXTURES[mineral]
		
		var texture_rect = TextureRect.new()
		texture_rect.texture = texture
		
		var amount_label = Label.new()
		amount_label.text = str(amount)
		amount_label.add_theme_font_override("font", load("res://common/fonts/BitPap.ttf"))
		
		var hbox = HBoxContainer.new()
		$Stats/Minerals/Minerals/Minerals.add_child(hbox)
		hbox.add_child(texture_rect)
		hbox.add_child(amount_label)
	
	for upgrade in GameManager.day_stats.upgrades:
		var label = Label.new()
		label.text = upgrade
		label.add_theme_font_override("font", load("res://common/fonts/BitPap.ttf"))
		$Stats/Upgrades/Upgrades/Upgrades.add_child(label)
