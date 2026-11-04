extends Control
## The town between runs: click a building to open its window, or leave town to start the chapter.
## Shown after character creation (later also after the 1st and 2nd death).

const COMBAT_SCENE: String = "res://scenes/combat/combat.tscn"
const ART_SIZE: Vector2 = Vector2(384, 216)
## Each building: its clickable rectangle in art pixels (x, y, width, height) and what its window says.
const BUILDINGS: Array = [
	{"name": "Farm", "rect": [4, 92, 92, 74], "text": "Raise animals here. Some can follow you into battle as companions. (Coming soon)"},
	{"name": "Blacksmith", "rect": [100, 92, 70, 74]},
	{"name": "Inn", "rect": [178, 84, 94, 82], "text": "A warm bed and a hot meal."},
	{"name": "Shop", "rect": [282, 100, 92, 66]},
]
## Buildings that open the GearWindow instead of the plain window.
const GEAR_WINDOW_MODES: Dictionary = {"Blacksmith": GearWindow.Mode.FORGE, "Shop": GearWindow.Mode.SHOP}


var gear_window: GearWindow = GearWindow.new()
var gold: Label = Label.new()


func _ready() -> void:
	for building: Dictionary in BUILDINGS:
		%Picture.add_child(_building_button(building))
	gold.add_theme_font_size_override("font_size", 22)
	gold.add_theme_color_override("font_color", UI.GOLD)
	%Leave.add_child(gold)
	%Leave.add_child(UI.menu_button("Gear", _open_gear_window.bind(GearWindow.Mode.GEAR), 24))
	%Leave.add_child(UI.menu_button("Leave town", get_tree().change_scene_to_file.bind(COMBAT_SCENE), 24))
	add_child(gear_window)
	gear_window.closed.connect(_update_gold)
	_update_gold()
	for node: Control in %Leave.get_children():  # the gold label and the buttons, readable over the art
		node.add_theme_color_override("font_outline_color", Color.BLACK)
		node.add_theme_constant_override("outline_size", 6)


## An invisible button over the building's art with its name floating above the roof.
## Anchors are fractions of the picture, so the button stays on the building at any window size.
func _building_button(building: Dictionary) -> Button:
	var rect: Array = building.rect
	var button: Button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.anchor_left = rect[0] / ART_SIZE.x
	button.anchor_top = rect[1] / ART_SIZE.y
	button.anchor_right = (rect[0] + rect[2]) / ART_SIZE.x
	button.anchor_bottom = (rect[1] + rect[3]) / ART_SIZE.y
	button.tooltip_text = building.name
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_open.bind(building))
	var sign: Label = Label.new()
	sign.text = building.name
	sign.add_theme_font_size_override("font_size", 18)
	sign.add_theme_color_override("font_outline_color", Color.BLACK)
	sign.add_theme_constant_override("outline_size", 6)
	sign.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	sign.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sign.offset_top = -30
	button.add_child(sign)
	button.mouse_entered.connect(func() -> void: sign.add_theme_color_override("font_color", UI.GOLD))
	button.mouse_exited.connect(func() -> void: sign.remove_theme_color_override("font_color"))
	return button


func _update_gold() -> void:
	gold.text = "   Gold %d" % Run.gold


func _open_gear_window(mode: GearWindow.Mode) -> void:
	%Window.hide()
	gear_window.open(mode)


func _open(building: Dictionary) -> void:
	if building.name in GEAR_WINDOW_MODES:
		_open_gear_window(GEAR_WINDOW_MODES[building.name])
		return
	%WindowTitle.text = building.name.to_upper()
	%WindowText.text = building.text
	for old in %WindowButtons.get_children():
		old.queue_free()
	if building.name == "Inn":
		%WindowText.text += " Rest here to heal to full.\nHP %d / %d" % [Run.hero.hp, Run.hero.max_hp]
		var rest: Button = UI.menu_button("Rest (free)", _rest.bind(building))
		rest.disabled = Run.hero.hp == Run.hero.max_hp
		%WindowButtons.add_child(rest)
	%WindowButtons.add_child(UI.menu_button("Back", %Window.hide))
	%Window.show()


func _rest(inn: Dictionary) -> void:
	Run.hero.hp = Run.hero.max_hp
	_open(inn)
