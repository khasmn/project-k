extends PanelContainer
## Level-up panel: spend stat points with + / - buttons, then Confirm.

signal confirmed

## [stat, label, amount per point, hint]. "{attack}" becomes Attack or Magic.
const STATS: Array = [
	["max_hp", "Max HP", 3, "also heals"],
	["attack", "{attack}", 1, "hit and damage"],
	["defense", "Defense", 1, "+1 Armor"],
	["speed", "Speed", 1, "initiative"],
]

var hero: Combatant
var points_left: int = 0
var added: Dictionary = {}  # stat -> points put in (not applied until Confirm)


func _ready() -> void:
	%ConfirmButton.pressed.connect(_on_confirm)
	hide()


func open(for_hero: Combatant, points: int) -> void:
	hero = for_hero
	points_left = points
	added = {}
	for row in %StatRows.get_children():
		%StatRows.remove_child(row)
		row.queue_free()
	for entry in STATS:
		%StatRows.add_child(_make_row(entry))
	_refresh()
	show()


## One line: "Attack   3 -> 4   [-] [+]   hit and damage". Named Row_<stat> so tests can find it.
func _make_row(entry: Array) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row_" + entry[0]
	row.add_theme_constant_override("separation", 12)
	for part in ["Name", "Value"]:
		var label: Label = Label.new()
		label.name = part
		label.custom_minimum_size = Vector2(110, 0)
		row.add_child(label)
	row.get_node("Name").text = entry[1].replace("{attack}", hero.attack_name)
	for part in [["Minus", "-", -1], ["Plus", "+", 1]]:
		var button: Button = Button.new()
		button.name = part[0]
		button.text = part[1]
		button.custom_minimum_size = Vector2(36, 32)
		button.pressed.connect(_change.bind(entry[0], part[2]))
		row.add_child(button)
	var hint: Label = Label.new()
	hint.text = "+%d per point, %s" % [entry[2], entry[3]] if entry[2] > 1 else entry[3]
	hint.modulate = Color(1, 1, 1, 0.6)
	row.add_child(hint)
	return row


func _change(stat: String, delta: int) -> void:
	if (delta > 0 and points_left == 0) or (delta < 0 and added.get(stat, 0) == 0):
		return
	added[stat] = added.get(stat, 0) + delta
	points_left -= delta
	_refresh()


func _refresh() -> void:
	%PointsLabel.text = "LEVEL UP!   Level %d   Points left: %d" % [Run.level, points_left]
	for entry in STATS:
		var row: Node = %StatRows.get_node("Row_" + entry[0])
		var now: int = int(hero.get(entry[0]))
		var pending: int = added.get(entry[0], 0) * entry[2]
		row.get_node("Value").text = str(now) if pending == 0 else "%d -> %d" % [now, now + pending]
		row.get_node("Minus").disabled = added.get(entry[0], 0) == 0
		row.get_node("Plus").disabled = points_left == 0
	%ConfirmButton.disabled = points_left > 0
	%ConfirmButton.text = "Confirm" if points_left == 0 else "Spend all points first"


func _on_confirm() -> void:
	if points_left > 0 or not visible:
		return
	for entry in STATS:
		if added.get(entry[0], 0) > 0:
			hero.raise_stat(entry[0], added[entry[0]] * entry[2])
	hide()
	confirmed.emit()
