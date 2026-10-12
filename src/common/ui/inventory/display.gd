extends Control

@onready var row: NinePatchRect = $VBoxContainer/Row
@onready var v_box_container: VBoxContainer = $VBoxContainer

var row_labels: Dictionary[Enums.Mineral, RichTextLabel]
var rows: Array[NinePatchRect]
var regex: RegEx

func _ready() -> void:
	GameManager.clear_inventory.connect(clear_inventory)
	GameManager.show_mineral.connect(create_row)
	GameManager.add_mineral.connect(update_amount)
	GameManager.state_changed.connect(check_fade)
	
	regex = RegEx.new()
	regex.compile(".*[^[]")

func check_fade(s: Enums.State) -> void:
	if s == Enums.State.SCIENTIST:
		modulate = Color(1, 1, 1, 0.5)
	elif s == Enums.State.LAUNCH && !GameManager.player.has_discovered_state(Enums.State.BLEEG):
		modulate = Color.TRANSPARENT
	else:
		modulate = Color.WHITE

func clear_inventory() -> void:
	rows.map(func (x): x.queue_free())
	rows.clear()
	row_labels.clear()

func create_row(m: Enums.Mineral) -> void:
	if row_labels.has(m):
		return
	
	var new_row = row.duplicate()
	new_row.material = new_row.material.duplicate()
	new_row.material.set_shader_parameter("replacement_colors", [
		GameManager.mineral_data[m].dark_colour,
		GameManager.mineral_data[m].mid_colour,
		GameManager.mineral_data[m].light_colour
	])
	new_row.visible = true
	
	row_labels.set(m, new_row.get_child(0))
	rows.append(new_row)
	v_box_container.add_child(new_row)
	
	new_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	update_amount(m)

func update_amount(m: Enums.Mineral, _a=0) -> void:
	if !row_labels.has(m):
		return
	
	row_labels[m].text = Math.format_number_short(GameManager.player.minerals[m]) + \
		" [img]res://common/minerals/" + Enums.Mineral.find_key(m).to_lower() + ".png[/img]"
