extends AnimatedSprite2D

var home: Vector2
var target: Vector2
const SPEED := 3
const endless_bg := preload("res://assets/store/itch bg.png")

func _ready() -> void:
	home = position
	GameManager.boost.connect(func (amount):
		target.y += GameManager.DISTANCE * amount
	)
	
	GameManager.state_changed.connect(
		func (s):
			if s == Enums.State.MISSION:
				stop()
			elif not is_playing():
				play("running_water")
				for n in get_children(): n.queue_free()
	)

func _process(delta: float) -> void:
	if GameManager.state == Enums.State.MISSION:
		target.y += delta * GameManager.player.get_stat("thruster_speed").value
	else:
		target = home
		
	position += (target - position) * delta * SPEED
	
	var total_pos = position + Vector2(0, get_child_count() * 300)
	if total_pos.y > -10:
		var new_bg = Sprite2D.new()
		new_bg.texture = endless_bg
		new_bg.position = Vector2(0, -300 * (get_child_count() + 1))
		new_bg.centered = false
		add_child(new_bg)
