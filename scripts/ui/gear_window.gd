class_name GearWindow
extends Control
## One window for the Shop (buy and sell) and the GEAR screen (wear and take off), with the hero in the
## middle so you see the gear on them. Built in code; the town and path screens each add one.
## It covers the whole screen with a dark backdrop, so nothing behind it can be clicked while it's open.

signal closed

const BOX: StyleBox = preload("res://scenes/ui/gold_box.tres")
const POTION: String = "healing_potion"
const POTION_PRICE: int = 10
const PREVIEW_SIZE: int = 160
const FONT_SIZE: int = 16
const ICON_SIZE: int = 32  # item pictures in the lists (16x16 art shown 2x)
const SLOT_SIZE: int = 72  # the boxes around the hero on the GEAR page
const SLOT_NAMES: Dictionary = {"helmet": "Helmet", "armor": "Armor", "weapon": "Weapon", "offhand": "Shield",
	"jewelry1": "Jewelry", "jewelry2": "Jewelry"}
## GEAR page: which slot boxes stand left and right of the hero.
const SLOT_SIDES: Array = [["helmet", "armor", "weapon"], ["offhand", "jewelry1", "jewelry2"]]

var shop: bool = false
var title: Label = Label.new()
var sprite: HeroSprite = HeroSprite.new()
var stats: Label = Label.new()
var left: VBoxContainer = VBoxContainer.new()
var right: VBoxContainer = VBoxContainer.new()
var slots_left: VBoxContainer = VBoxContainer.new()
var slots_right: VBoxContainer = VBoxContainer.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.5)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)  # a ColorRect stops mouse clicks by default
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", BOX)
	panel.custom_minimum_size = Vector2(920, 440)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var rows: VBoxContainer = VBoxContainer.new()
	panel.add_child(rows)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UI.GOLD)
	rows.add_child(title)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	rows.add_child(columns)
	var middle: VBoxContainer = VBoxContainer.new()
	sprite.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	middle.add_child(sprite)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	middle.add_child(stats)
	for column in [left, slots_left, middle, slots_right, right]:
		columns.add_child(column)
	left.custom_minimum_size.x = 400
	right.custom_minimum_size.x = 280
	middle.custom_minimum_size.x = 220
	rows.add_child(UI.menu_button("Close", _close))
	hide()


## shop = true: Buy and Sell lists. false: what you wear and what's in your bag.
func open(as_shop: bool) -> void:
	shop = as_shop
	refresh()
	show()


func refresh() -> void:
	for column in [left, right, slots_left, slots_right]:
		for old in column.get_children():
			old.queue_free()
	left.visible = shop
	slots_left.visible = not shop
	slots_right.visible = not shop
	title.text = "%s      Gold %d" % ["SHOP" if shop else "GEAR", Run.gold]
	sprite.show_look(Run.hero_look)
	var hero: Combatant = Run.hero
	stats.text = "HP %d / %d\n%s %d   Defense %d   Speed %d" % [hero.hp, hero.max_hp, hero.attack_name, hero.attack, hero.defense, hero.speed]
	if shop:
		_header(left, "BUY")
		var potion: Button = _button(left, "Healing Potion  %dg  (have %d)" % [POTION_PRICE, Run.items.get(POTION, 0)], _buy_potion, POTION)
		potion.disabled = Run.gold < POTION_PRICE
		for id: String in Run.data("gear"):
			if Gear.fits(id):
				var buy: Button = _button(left, "%s  %dg  (%s)" % [Gear.entry(id).name, Gear.entry(id).price, Gear.bonus_text(id)],
					_act.bind(Gear.buy, id), id)
				buy.tooltip_text = Gear.bonus_text(id)
				buy.disabled = Run.gold < int(Gear.entry(id).price)
		_header(right, "SELL (your bag)")
		for id in Run.bag:
			_button(right, "%s  +%dg" % [Gear.entry(id).name, Gear.sell_price(id)], _act.bind(Gear.sell, id), id)
		if Run.bag.is_empty():
			_header(right, "Nothing to sell. Take gear off in GEAR first.")
	else:
		for slot in SLOT_SIDES[0]:
			_slot_box(slots_left, slot)
		for slot in SLOT_SIDES[1]:
			_slot_box(slots_right, slot)
		_header(right, "BAG (click to wear)")
		for id in Run.bag:
			var wear: Button = _button(right, "%s  (%s)" % [Gear.entry(id).name, Gear.bonus_text(id)], _act.bind(Gear.wear, id), id)
			wear.disabled = not Gear.fits(id)
		if Run.bag.is_empty():
			_header(right, "Empty. Buy gear at the Shop.")


## Run a Gear action (buy, sell, wear, take_off) on one id or slot, then redraw.
func _act(action: Callable, what: String) -> void:
	action.call(what)
	refresh()


func _buy_potion() -> void:
	Run.gold -= POTION_PRICE
	Run.items[POTION] = Run.items.get(POTION, 0) + 1
	refresh()


func _header(column: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UI.GOLD)
	column.add_child(label)


func _button(column: VBoxContainer, text: String, on_pressed: Callable, icon_id: String) -> Button:
	var button: Button = UI.menu_button(text, on_pressed, FONT_SIZE)
	button.icon = Gear.icon(icon_id)
	button.expand_icon = true  # scale the 16x16 picture up to the line height
	button.add_theme_constant_override("icon_max_width", ICON_SIZE)
	column.add_child(button)
	return button


## A framed box with the picture of what's worn in this slot (empty if nothing). Click it to take that off.
func _slot_box(column: VBoxContainer, slot: String) -> void:
	var id: String = Run.gear.get(slot, "")
	var box: Button = Button.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		box.add_theme_stylebox_override(state, BOX)
	box.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.expand_icon = true
	box.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.disabled = id == ""
	if id:
		box.icon = Gear.icon(id)
		box.tooltip_text = "%s: %s\nClick to take off" % [Gear.entry(id).name, Gear.bonus_text(id)]
		box.pressed.connect(_act.bind(Gear.take_off, slot))
		UI.add_cursor(box)
	column.add_child(box)
	var label: Label = Label.new()
	label.text = SLOT_NAMES[slot]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	column.add_child(label)


func _close() -> void:
	hide()
	closed.emit()
