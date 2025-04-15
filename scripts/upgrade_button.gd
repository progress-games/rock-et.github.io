extends Button
class_name UpgradeButton

var stat: Stat

func set_stat(_stat: Stat) -> void:
	stat = _stat
	update_text()
	pressed.connect(stat.upgrade)

func update_text() -> void:
	text = "Upgrade " + stat.name + "\n$" + str(stat.cost)
