extends Node2D

const BASE_PROGRESS := 138
const MIN_HEIGHT := 4

const LOCKED_MINERAL_COLOUR := Color("cd683d")
const UNLOCKED_MINERAL_COLOUR := Color('9e4539')
const UNLOCKING_MINERAL_COLOUR := Color("fbb954")

var progress: float
var order: Array[Enums.Mineral] = []

func _ready() -> void:
	# get order minerals appear in
	for asteroid in GameManager.asteroid_spawns:
		for drop in asteroid.drops:
			if !order.has(drop):
				order.append(drop)
	
	_set_progress()
	_set_minerals()
	$UnlockingProgress.visible = false
	$Buttons/Distance.pressed.connect(_set_progress)

func _set_progress() -> void:
	progress = float(GameManager.get_stat("boost_distance").value) / float(Enums.Mineral.size())
	
	var height = floor(MIN_HEIGHT + progress * $TotalProgress.size.y)
	$LockedProgress.size.y = height
	$LockedProgress.position.y = BASE_PROGRESS - height + MIN_HEIGHT + 1
	$Ship.position.y = $LockedProgress.position.y
	
	var next_mineral = float(GameManager.get_stat("boost_distance").value + 1) / float(Enums.Mineral.size())
	next_mineral = min(1, next_mineral)
	var next_height = floor(MIN_HEIGHT + next_mineral * $TotalProgress.size.y)
	$UnlockingProgress.size.y = next_height
	$UnlockingProgress.position.y = BASE_PROGRESS - next_height + MIN_HEIGHT

func _set_minerals() -> void:
	for node in $TotalProgress/Minerals.get_children():
		node.queue_free()
	
	for i in range(order.size()):
		var new_rect = TextureRect.new()
		new_rect.texture = load("res://bleeg/assets/minerals/" + 
			Enums.Mineral.find_key(order[order.size() - 1 - i]).to_lower() + ".png")
		new_rect.set_stretch_mode(TextureRect.StretchMode.STRETCH_KEEP_CENTERED)
		new_rect.set_v_size_flags(TextureRect.SizeFlags.SIZE_EXPAND)
		new_rect.set_meta("mineral", order.size() - 1 - i)
		
		if order.size() - 1 - i < GameManager.get_stat("boost_distance").value:
			new_rect.self_modulate = UNLOCKED_MINERAL_COLOUR
		else:
			new_rect.self_modulate = LOCKED_MINERAL_COLOUR
		
		$TotalProgress/Minerals.add_child(new_rect)

func _on_distance_mouse_entered() -> void:
	$UnlockingProgress.visible = true
	
	for node in $TotalProgress/Minerals.get_children():
		if node.has_meta("mineral"):
			if node.get_meta("mineral") == GameManager.get_stat("boost_distance").value:
				node.self_modulate = UNLOCKING_MINERAL_COLOUR
			elif node.get_meta("mineral") < GameManager.get_stat("boost_distance").value:
				node.self_modulate = UNLOCKED_MINERAL_COLOUR
			else:
				node.self_modulate = LOCKED_MINERAL_COLOUR

func _on_distance_mouse_exited() -> void:
	$UnlockingProgress.visible = false
	
	for node in $TotalProgress/Minerals.get_children():
		if node.has_meta("mineral"):
			if node.get_meta("mineral") < GameManager.get_stat("boost_distance").value:
				node.self_modulate = UNLOCKED_MINERAL_COLOUR
			else:
				node.self_modulate = LOCKED_MINERAL_COLOUR
