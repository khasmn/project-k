class_name GearWindow
extends Control
## One window for the Shop (buy and sell), the GEAR screen (wear and take off) and the Blacksmith (forge and
## upgrade, with Torvik the dwarf talking above the lists and a ForgeScene cutscene after each try),
## with the hero in the middle so you see the gear on them. Built in code; the town and path screens add one.
## It covers the whole screen with a dark backdrop, so nothing behind it can be clicked while it's open.

signal closed

enum Mode { SHOP, GEAR, FORGE }

const BOX: StyleBox = preload("res://scenes/ui/gold_box.tres")
const TAB: StyleBox = preload("res://scenes/ui/gold_tab.tres")
const TAB_TEXT: Color = Color(0.12, 0.09, 0.04)  # dark text on the gold tab, like the battle screen
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
const TITLES: Array[String] = ["SHOP", "GEAR", "BLACKSMITH"]
const FORGE_SECTIONS: Dictionary = {"basic": "BASIC RECIPES", "blueprint": "BLUEPRINTS (dropped by monsters)",
	"starmetal": "STARMETAL (1 Shard each, the boss drops them)"}

var mode: Mode = Mode.SHOP
var forge_text: String = ""  # the last forge or upgrade result, shown until the window closes
var upgrading: bool = false  # Blacksmith tab: false = forge new gear, true = upgrade gear you have
var npc: Dictionary = {}
var npc_row: HBoxContainer = HBoxContainer.new()
var talk: Label = Label.new()
var scene: ForgeScene = ForgeScene.new()
var title: Label = Label.new()
var sprite: HeroSprite = HeroSprite.new()
var stats: Label = Label.new()
var scroll: ScrollContainer = ScrollContainer.new()
var left: VBoxContainer = VBoxContainer.new()
var right: VBoxContainer = VBoxContainer.new()
var slots_left: VBoxContainer = VBoxContainer.new()
var slots_right: VBoxContainer = VBoxContainer.new()
## Blacksmith only: each area sits in its own framed box with a gold name tab (other modes hide the frames).
var sections: Array = []  # [tab, panel] pairs
var no_box: StyleBoxEmpty = StyleBoxEmpty.new()
var npc_box: VBoxContainer
var list_box: VBoxContainer
var list_tab: Label


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
	npc = Run.data("npcs").blacksmith
	var portrait: TextureRect = TextureRect.new()
	portrait.texture = load("res://assets/sprites/npc/blacksmith.png")
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	npc_row.add_child(portrait)
	talk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk.custom_minimum_size.x = 700
	talk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	talk.add_theme_font_size_override("font_size", 17)
	npc_row.add_child(talk)
	npc_box = _section(npc_row, npc.name.to_upper())
	rows.add_child(npc_box)
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
	scroll.custom_minimum_size = Vector2(420, 380)  # the Blacksmith list is longer than the window
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(left)
	list_box = _section(scroll, "FORGE")
	list_tab = list_box.get_child(0).get_child(0)
	for column in [list_box, slots_left, _section(middle, "HERO"), slots_right, _section(right, "MATERIALS")]:
		columns.add_child(column)
	right.custom_minimum_size.x = 280
	middle.custom_minimum_size.x = 220
	rows.add_child(UI.menu_button("Close", _close))
	add_child(scene)
	hide()


func open(as_mode: Mode) -> void:
	mode = as_mode
	forge_text = ""
	upgrading = false
	_say("greet")
	refresh()
	show()


func refresh() -> void:
	for column in [left, right, slots_left, slots_right]:
		for old in column.get_children():
			old.queue_free()
	list_box.visible = mode != Mode.GEAR
	npc_box.visible = mode == Mode.FORGE
	for section: Array in sections:
		section[0].visible = mode == Mode.FORGE
		section[1].add_theme_stylebox_override("panel", BOX if mode == Mode.FORGE else no_box)
	slots_left.visible = mode == Mode.GEAR
	slots_right.visible = mode == Mode.GEAR
	title.text = "%s      Gold %d" % [TITLES[mode], Run.gold]
	sprite.show_look(Run.hero_look)
	var hero: Combatant = Run.hero
	stats.text = "HP %d / %d\n%s %d   Defense %d   Speed %d" % [hero.hp, hero.max_hp, hero.attack_name, hero.attack, hero.defense, hero.speed]
	match mode:
		Mode.SHOP: _show_shop()
		Mode.GEAR: _show_gear()
		Mode.FORGE: _show_forge()


func _show_shop() -> void:
	_header(left, "BUY")
	var potion: Button = _button(left, "Healing Potion  %dg  (have %d)" % [POTION_PRICE, Run.items.get(POTION, 0)], _buy_potion, POTION)
	potion.disabled = Run.gold < POTION_PRICE
	var recipes: Dictionary = Run.data("recipes")
	for id: String in Run.data("gear"):
		if Gear.fits(id) and not recipes.has(id):  # forged gear isn't sold
			var item: Dictionary = Gear.piece(id)
			var buy: Button = _button(left, "%s  %dg  (%s)" % [Gear.title(item), Gear.entry(id).price, Gear.bonus_text(item)],
				_act.bind(Gear.buy, id), id)
			buy.disabled = Run.gold < int(Gear.entry(id).price)
	_header(right, "SELL (your bag)")
	for item in Run.bag:
		_piece_button(right, "%s  +%dg" % [Gear.title(item), Gear.sell_price(item)], _act.bind(Gear.sell, item), item)
	if Run.bag.is_empty():
		_header(right, "Nothing to sell. Take gear off in GEAR first.")


func _show_gear() -> void:
	for slot in SLOT_SIDES[0]:
		_slot_box(slots_left, slot)
	for slot in SLOT_SIDES[1]:
		_slot_box(slots_right, slot)
	_header(right, "BAG (click to wear)")
	for item in Run.bag:
		var wear: Button = _piece_button(right, "%s  (%s)" % [Gear.title(item), Gear.bonus_text(item)], _act.bind(Gear.wear, item), item)
		wear.disabled = not Gear.fits(item.id)
	if Run.bag.is_empty():
		_header(right, "Empty. Buy gear at the Shop.")


## Two tabs: Forge (recipes) and Upgrade (gear you have). Materials and the last result on the right.
func _show_forge() -> void:
	var tabs: HBoxContainer = HBoxContainer.new()
	for tab: String in ["Forge new", "Upgrade"]:
		var button: Button = UI.menu_button(tab, _set_tab.bind(tab == "Upgrade"), 20)
		if upgrading == (tab == "Upgrade"):
			button.add_theme_color_override("font_color", UI.GOLD)
		tabs.add_child(button)
	left.add_child(tabs)
	list_tab.text = "UPGRADE" if upgrading else "FORGE"
	if upgrading:
		_show_upgrades()
	else:
		_show_recipes()
	var materials: Dictionary = Run.data("materials")
	if forge_text:
		_header(right, forge_text)
	for material: String in materials:
		_line(right, "%s  x%d" % [materials[material].name, Run.materials.get(material, 0)], material)
	if upgrading:
		_header(right, "Upgrades roll d20 + Luck (%d) vs the DC. Fail: the cost is gone. Natural 1: -1 level. Beat the DC by 10: +2 levels." % Run.hero.luck)
	else:
		_header(right, "Forging rolls d20 + Luck (%d) for the grade:\nCrude, Common, Uncommon, Rare, Epic, Legendary." % Run.hero.luck)


## Recipes by section; each line says what it needs and how many you have. Unfound blueprints say who drops them.
func _show_recipes() -> void:
	var recipes: Dictionary = Run.data("recipes")
	var materials: Dictionary = Run.data("materials")
	for section in FORGE_SECTIONS:
		_header(left, FORGE_SECTIONS[section])
		for id: String in recipes:
			var recipe: Dictionary = recipes[id]
			if recipe.section != section or not Gear.fits(id):
				continue
			var item: Dictionary = Gear.piece(id)
			if not Gear.known(id):
				_line(left, "%s  (find its blueprint: %s)" % [Gear.entry(id).name, _dropped_by(id)], id).modulate.a = 0.4
				continue
			var needs: PackedStringArray = []
			for material in recipe.materials:
				needs.append("%d %s (have %d)" % [recipe.materials[material], materials[material].name, Run.materials.get(material, 0)])
			var forge: Button = _button(left, "%s  (%s)\n%s, %dg" % [Gear.entry(id).name, Gear.bonus_text(item), ", ".join(needs), recipe.gold],
				_try.bind(Gear.forge, id), id)
			forge.disabled = not Gear.can_forge(id)


## Worn gear first, then the bag. Each line: the next level, its DC and cost.
func _show_upgrades() -> void:
	_header(left, "WEARING")
	for slot: String in Run.gear:
		_upgrade_line(Run.gear[slot])
	_header(left, "BAG")
	for item in Run.bag:
		_upgrade_line(item)
	if Run.gear.is_empty() and Run.bag.is_empty():
		_header(left, "No gear yet. Buy or forge some first.")


func _upgrade_line(item: Dictionary) -> void:
	if item.plus == Gear.MAX_PLUS:
		_line(left, "%s  (%s)  MAX" % [Gear.title(item), Gear.bonus_text(item)], item.id)
		return
	var cost: Dictionary = Gear.upgrade_cost(item)
	var button: Button = _piece_button(left, "%s  (%s)\n+%d -> +%d: DC %d, %d %s (have %d), %dg" % [Gear.title(item), Gear.bonus_text(item),
		item.plus, item.plus + 1, Gear.UPGRADE_DCS[item.plus], cost.count, Run.data("materials")[cost.material].name,
		Run.materials.get(cost.material, 0), cost.gold], _try.bind(Gear.upgrade, item), item)
	button.disabled = not Gear.can_upgrade(item)


## The name of the monster whose loot has this blueprint, e.g. "Wolf".
func _dropped_by(id: String) -> String:
	var enemies: Dictionary = Run.data("enemies")
	for enemy: String in enemies:
		if enemies[enemy].has("rooms") and enemies[enemy].get("loot", {}).get("blueprint", "") == id:
			return enemies[enemy].name
	return "?"


func _set_tab(upgrade_tab: bool) -> void:
	upgrading = upgrade_tab
	refresh()


## Forge or upgrade (Gear.forge / Gear.upgrade), then Torvik comments and the cutscene plays.
func _try(action: Callable, what: Variant) -> void:
	var result: Dictionary = action.call(what)
	forge_text = result.text
	_say(result.outcome)
	refresh()
	if Settings.animate_forge:
		scene.play(result)


## Torvik says a random line of this kind (data/npcs.json).
func _say(kind: String) -> void:
	var lines: Array = npc[kind]
	talk.text = "\"%s\"" % lines[Dice.roll(lines.size(), false) - 1]  # his name is on the box tab


## Run a Gear action (buy, sell, wear, take_off) on one id, piece or slot, then redraw.
func _act(action: Callable, what: Variant) -> void:
	action.call(what)
	refresh()


func _buy_potion() -> void:
	Run.gold -= POTION_PRICE
	Run.items[POTION] = Run.items.get(POTION, 0) + 1
	refresh()


## A gold name tab over a framed box holding content (the battle screen's ENEMIES / COMMAND / HERO look).
func _section(content: Control, tab_text: String) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var tab: PanelContainer = PanelContainer.new()
	tab.add_theme_stylebox_override("panel", TAB)
	tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var label: Label = Label.new()
	label.text = tab_text
	label.add_theme_color_override("font_color", TAB_TEXT)
	label.add_theme_font_size_override("font_size", 13)
	tab.add_child(label)
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(content)
	box.add_child(tab)
	box.add_child(panel)
	sections.append([tab, panel])
	return box


func _header(column: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


## A picture and text that can't be clicked (materials, blueprints not found yet).
func _line(column: VBoxContainer, text: String, icon_id: String) -> HBoxContainer:
	var line: HBoxContainer = HBoxContainer.new()
	var picture: TextureRect = TextureRect.new()
	picture.texture = Gear.icon(icon_id)
	picture.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line.add_child(picture)
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	line.add_child(label)
	column.add_child(line)
	return line


## A list line for a piece you own, in its grade's color.
func _piece_button(column: VBoxContainer, text: String, on_pressed: Callable, item: Dictionary) -> Button:
	var button: Button = _button(column, text, on_pressed, item.id)
	button.add_theme_color_override("font_color", Gear.color(item))
	return button


## A framed box with the picture of what's worn in this slot (empty if nothing). Click it to take that off.
func _slot_box(column: VBoxContainer, slot: String) -> void:
	var box: Button = Button.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		box.add_theme_stylebox_override(state, BOX)
	box.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.expand_icon = true
	box.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.disabled = not Run.gear.has(slot)
	if Run.gear.has(slot):
		var item: Dictionary = Run.gear[slot]
		box.icon = Gear.icon(item.id)
		box.tooltip_text = "%s: %s\nClick to take off" % [Gear.title(item), Gear.bonus_text(item)]
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
