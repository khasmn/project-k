extends Control
## Path screen between fights: pick 1 of 3 doors (every door ends in a battle), or spend stat points.

const COMBAT_SCENE: String = "res://scenes/combat/combat.tscn"
const TOWN_SCENE: String = "res://scenes/city/town.tscn"
const PATH_SCENE: String = "res://scenes/path/path.tscn"
const CARD_STYLE: StyleBoxFlat = preload("res://scenes/ui/box_style.tres")
const REST_CLICK_DELAY: float = 0.5  # Rest/Train appear where the door was: block a double click picking one
## Left stripe color and subtitle per door type.
const TYPE_COLORS: Dictionary = {
	"elite": Color(0.9, 0.3, 0.3), "rest": Color(0.4, 0.8, 0.45), "shop": Color(0.95, 0.75, 0.25),
	"event": Color(0.45, 0.65, 1.0), "boss": Color(0.75, 0.3, 0.9),
	"heal": Color(0.4, 0.8, 0.45), "train": Color(0.4, 0.6, 1.0),
}
const SUBTITLES: Dictionary = {
	"elite": "ELITE  -  HARDER BATTLE", "rest": "REST  -  THEN A BATTLE", "shop": "SHOP  -  THEN A BATTLE",
	"event": "EVENT  -  THEN A BATTLE", "boss": "BOSS  -  FINAL BATTLE",
	"heal": "HEAL  -  THEN A BATTLE", "train": "TRAIN  -  THEN A BATTLE",
}

var hero: Combatant
var gear_window: GearWindow = GearWindow.new()
var dice: DiceTray = DiceTray.new()


func _ready() -> void:
	if Run.hero == null:
		Run.start_test()  # this scene was started on its own
	hero = Run.hero
	%CharacterButton.pressed.connect(_open_character)
	%CharacterPanel.closed.connect(_close_character)
	var gear_button: Button = %CharacterButton.duplicate()  # same gold look as CHARACTER
	gear_button.text = "GEAR"
	gear_button.pressed.connect(gear_window.open.bind(GearWindow.Mode.GEAR))
	%CharacterButton.add_sibling(gear_button)
	var town_button: Button = %CharacterButton.duplicate()
	town_button.text = "BACK TO TOWN"
	town_button.tooltip_text = "Go back to town. The chapter starts again from room 1;\nyou keep your level, gear, gold and materials."
	town_button.pressed.connect(_back_to_town)
	gear_button.add_sibling(town_button)
	add_child(gear_window)
	dice.alignment = BoxContainer.ALIGNMENT_CENTER
	Dice.recording = Settings.animate_dice
	gear_window.closed.connect(_on_window_closed)
	_update_sidebar()
	_show_doors()


func _show_doors() -> void:
	_clear_doors()
	%HeadingTitle.text = "CHOOSE YOUR PATH"
	if Run.is_boss():
		%HeadingText.text = "The road ends here."
		_add_card("Bandit Camp", "boss", "The Bandit Chief waits by the fire, axe in hand.", _enter.bind("boss"))
		return
	%HeadingText.text = "Pick a path to continue"
	for door in Run.door_choices():
		_add_card(door.name, door.type, door.description, _enter.bind(door.type, door.get("event", "")))


## Clicked a door. Rest asks Rest or Train first, Shop opens the Peddler's Cart, Event shows its scene. All end in a battle.
func _enter(type: String, event: String = "") -> void:
	Run.room_type = type
	match type:
		"rest":
			_show_rest()
			return
		"shop":
			Run.room_note = "You leave the peddler's cart behind. Down the road, an enemy jumps out!"
			Peddler.open_cart()
			gear_window.open(GearWindow.Mode.PEDDLER)  # closing it ("Leave the cart") starts the battle
			return
		"event":
			_show_event(event)
			return
		"elite":
			Run.room_note = "A tough foe and its pack block the way!"
	_to_battle()


## The event's story and one card per choice, each saying its check. Choices you can't pay for are greyed out.
func _show_event(id: String) -> void:
	var event: Dictionary = Run.data("events")[id]
	Run.events_seen.append(id)
	_clear_doors()
	%HeadingTitle.text = event.name.to_upper()
	%HeadingText.text = event.text
	for choice: Dictionary in event.choices:
		_add_card(choice.label, "event", "", _choose.bind(choice), RoomEvent.check_text(choice))
		if not RoomEvent.can_choose(choice):
			%Doors.get_child(-1).set_meta("locked", true)  # not enough gold: stays greyed out
	await _block_double_click()


## Roll (the dice tumble where the cards were), then show what happened and one card to go on.
func _choose(choice: Dictionary) -> void:
	_clear_doors()
	Dice.history.clear()  # only this check's dice
	var result: Dictionary = RoomEvent.choose(choice)
	%Doors.add_child(dice)
	await dice.show_rolls(true)
	%Doors.remove_child(dice)
	%HeadingTitle.text = choice.label.to_upper() + ("" if not choice.has("stat") else (": SUCCESS!" if result.success else ": FAILURE"))
	%HeadingText.text = result.text
	_update_sidebar()
	if result.skip:
		_add_card("Walk on", "event", "You get past without a fight.", _skip_fight, "NO BATTLE")
	else:
		Run.room_note = "After the %s, the road goes on. An enemy jumps out!" % Run.data("events")[Run.events_seen.back()].name
		_add_card("On to the battle", "elite" if Run.room_type == "elite" else "event", "", _to_battle,
			"ELITE BATTLE" if Run.room_type == "elite" else "BATTLE")
	await _block_double_click()


## No fight this room: straight to the next room's doors.
func _skip_fight() -> void:
	Run.room += 1
	Run.room_type = ""
	get_tree().change_scene_to_file(PATH_SCENE)


## New cards appear where the last click was: block a double click picking one by accident.
func _block_double_click() -> void:
	for card in %Doors.get_children():
		card.disabled = true
	await get_tree().create_timer(REST_CLICK_DELAY).timeout
	for card in %Doors.get_children():
		card.disabled = card.has_meta("locked")


func _show_rest() -> void:
	_clear_doors()
	%HeadingTitle.text = "TAKE A BREAK"
	%HeadingText.text = "Pick one, then the battle starts"
	_add_card("Rest", "heal", "Heal %d%% of your Max HP (+%d HP)." % [Run.REST_HEAL_PERCENT, Run.rest_amount()], _rest)
	_add_card("Train", "train", "Gain %d stat point to spend with CHARACTER." % Run.TRAIN_POINTS, _train)
	await _block_double_click()


func _rest() -> void:
	var healed: int = Run.rest_amount()
	hero.hp += healed
	Run.room_note = "You rested: +%d HP." % healed
	_to_battle()


func _train() -> void:
	Run.points += Run.TRAIN_POINTS
	Run.room_note = "You trained hard: +%d stat point. Spend it with CHARACTER after this fight." % Run.TRAIN_POINTS
	_to_battle()


func _to_battle() -> void:
	get_tree().change_scene_to_file(COMBAT_SCENE)


## A clickable card: colored stripe on the left, name, type line (or `subtitle`) and a short story line.
func _add_card(title: String, type: String, text: String, on_pressed: Callable, subtitle: String = "") -> void:
	var card: Button = Button.new()
	card.name = "Card%d" % (%Doors.get_child_count() + 1)
	card.custom_minimum_size = Vector2(640, 96)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for state in ["normal", "hover", "pressed", "focus"]:
		var style: StyleBoxFlat = CARD_STYLE.duplicate()
		style.border_width_left = 8
		style.border_color = TYPE_COLORS[type]
		if state == "hover":
			style.bg_color = style.bg_color.lightened(0.08)
		card.add_theme_stylebox_override(state, style)
	card.pressed.connect(on_pressed)

	var lines: VBoxContainer = VBoxContainer.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.offset_left = 24
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE  # clicks go through to the card button
	for part in [[title.to_upper(), 20, TYPE_COLORS[type]], [subtitle if subtitle else SUBTITLES[type], 13, Color(1, 0.83, 0.3)], [text, 15, Color(1, 1, 1, 0.85)]]:
		var label: Label = Label.new()
		label.text = part[0]
		label.add_theme_font_size_override("font_size", part[1])
		label.add_theme_color_override("font_color", part[2])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.add_child(label)
	card.add_child(lines)
	%Doors.add_child(card)


func _clear_doors() -> void:
	for card in %Doors.get_children():
		%Doors.remove_child(card)
		card.queue_free()


func _on_window_closed() -> void:
	if gear_window.mode == GearWindow.Mode.PEDDLER:
		_to_battle()
	else:
		_update_sidebar()


func _back_to_town() -> void:
	Run.restart_chapter()
	get_tree().change_scene_to_file(TOWN_SCENE)


func _open_character() -> void:
	%Doors.hide()
	%CharacterButton.disabled = true
	%CharacterPanel.open(hero)


func _close_character() -> void:
	%Doors.show()
	%CharacterButton.disabled = false
	_update_sidebar()


func _update_sidebar() -> void:
	%Progress.text = "Boss fight" if Run.is_boss() else "Room %d of %d" % [Run.room, Run.ROOMS]
	%Gold.text = "Gold %d" % Run.gold
	%HeroName.text = Run.hero_title
	%HeroHPBar.max_value = hero.max_hp
	%HeroHPBar.value = hero.hp
	%HeroHP.text = "HP %d / %d" % [hero.hp, hero.max_hp]
	%Level.text = "Level %d   EXP %d / %d" % [Run.level, Run.experience, Run.exp_needed()]
	%ExpBar.max_value = Run.exp_needed()
	%ExpBar.value = Run.experience
	%HeroStats.text = "%s %d (d%d)\nArmor %d (10 + Defense %d)\nSpeed %d" % [
		hero.attack_name, hero.attack, hero.damage_die, hero.armor(), hero.defense, hero.speed]
	%CharacterButton.text = "CHARACTER" if Run.points == 0 else "CHARACTER  (%d points)" % Run.points
