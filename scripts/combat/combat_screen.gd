extends Control
## Combat screen: the run's hero vs this room's monsters (1-4), turn by turn, then EXP and gold, then the path screen.

const ENEMY_TURN_DELAY: float = 0.6
const CREATION_SCENE: String = "res://scenes/character/character_creation.tscn"
const PATH_SCENE: String = "res://scenes/path/path.tscn"
const CARD_STYLE: StyleBoxFlat = preload("res://scenes/ui/box_style.tres")
const SPRITE_FPS: int = 6
const SPRITE_SIZE: int = 96  # 32x32 art shown 3x
const FLEE_DC_BASE: int = 10  # flee: d20 + Speed vs 10 + fastest monster's Speed
## Battle log colors (BBCode: the log understands tags like [b]bold[/b] and [color=#hex]text[/color]).
const HERO_COLOR: String = "#7fd17f"
const ENEMY_COLOR: String = "#ff7a7a"
const GOLD: String = "#ffd34d"
const GRAY: String = "#8a8a8a"
const PASSIVE_COLOR: String = "#6fd3ff"
const EXP_COLOR: String = "#8fb4ff"

var hero: Combatant
var enemies: Array[Combatant] = []
var target: Combatant  # the monster the hero attacks; click a card to change it
var fight_over: bool = false  # true after a win or a flee, so Continue only works once
var animations: Array[AtlasTexture] = []


func _ready() -> void:
	%AttackButton.pressed.connect(_on_attack)
	%DefendButton.pressed.connect(_on_defend)
	%FleeButton.pressed.connect(_on_flee)
	%ItemButton.pressed.connect(_open_items)
	%Log.get_v_scroll_bar().modulate.a = 0  # floating log: no visible scrollbar, the mouse wheel still scrolls
	%InfoButton.pressed.connect(func() -> void: _show_info(not %InfoText.visible))
	for button in %Buttons.get_children():
		_add_cursor(button)
	if Run.hero == null:
		Run.start_test()  # this scene was started on its own, not from character creation
	_start_fight()


func _start_fight() -> void:
	hero = Run.hero
	enemies = Run.enemies()
	target = enemies[0]
	hero.start_fight()
	%FleeButton.visible = not Run.is_boss()
	for foe in enemies:
		%EnemyList.add_child(_make_card(foe))
		var row: Button = _command_button("", _set_target.bind(foe))
		%TargetList.add_child(row)
	var where: String = "Boss fight" if Run.is_boss() else "Room %d of %d" % [Run.room, Run.ROOMS]
	var names: String = ", ".join(enemies.map(func(foe: Combatant) -> String: return foe.display_name))
	%Title.text = "%s:  %s" % [where, names]
	_log("[color=%s][b]--- %s: %s ---[/b][/color]" % [GOLD, where, names])
	if Run.room_note != "":
		_log(Run.room_note)
		Run.room_note = ""
	_update_labels()

	# Initiative: your d20 + Speed vs one d20 for the group + its fastest Speed. Ties go to the monsters (Elf wins ties).
	var hero_rolls: Array[int] = Dice.roll_d20s(hero.roll_mode())
	var hero_init: int = Dice.keep(hero_rolls, hero.roll_mode()) + hero.speed
	var enemy_roll: int = Dice.roll_d20()
	var fastest: int = _fastest_speed()
	var enemy_init: int = enemy_roll + fastest
	var order: String = "Who goes first: %s rolled %s %+d Speed = %d, monsters rolled %d %+d Speed = %d." % [
		hero.display_name, hero.rolled_text(hero_rolls), hero.speed, hero_init, enemy_roll, fastest, enemy_init]
	if hero_init == enemy_init:
		order += " Tie! %s first." % (
			"%s (%s wins ties) goes" % [hero.display_name, hero.passive("wins_ties")] if hero.wins_ties else "The monsters go")
	_log(order)
	if hero_init > enemy_init or (hero_init == enemy_init and hero.wins_ties):
		_hero_turn()
	else:
		_enemy_turn()


## Play every sprite strip: show frame N of the strip, moving on SPRITE_FPS times a second.
func _process(_delta: float) -> void:
	var tick: int = Time.get_ticks_msec() * SPRITE_FPS / 1000
	for frames in animations:
		var size: int = frames.atlas.get_height()
		frames.region = Rect2(tick % (frames.atlas.get_width() / size) * size, 0, size, size)


## Info: the HERO box shows the target's info instead, and its tab shows the target's name. Free action.
func _show_info(on: bool) -> void:
	%InfoText.visible = on
	%HeroInfo.visible = not on
	%HeroTab.text = target.display_name.to_upper() if on else "HERO"
	%InfoText.text = _info(target)


func _info(foe: Combatant) -> String:
	return "%s\nHP %d / %d\nAttack %d, %s (d%d)\nArmor %d   Speed %d" % [
		foe.display_name, foe.hp, foe.max_hp, foe.attack, foe.weapon, foe.damage_die, foe.armor(), foe.speed]


func _hero_turn() -> void:
	var regen_text: String = hero.start_turn()
	if regen_text != "":
		_log(regen_text)
	_update_labels()
	_set_buttons_enabled(true)
	%TurnLabel.text = "Your turn: pick a target, then an action"


func _on_attack() -> void:
	_set_buttons_enabled(false)
	_log(hero.strike(target))
	_after_action()


func _on_defend() -> void:
	_set_buttons_enabled(false)
	hero.defending = true
	_log("%s defends: +%d Armor, and monsters attack with disadvantage until your next turn." % [
		hero.display_name, Combatant.DEFEND_BONUS])
	_after_action()


## Item: swap the action buttons for a list of your items (and Back).
func _open_items() -> void:
	var all: Dictionary = Run.data("items")
	for button in %ItemMenu.get_children():
		button.queue_free()
	for id in Run.items:
		var item: Dictionary = all[id]
		var button: Button = _command_button("%s x%d" % [item.name, Run.items[id]], _use_item.bind(id, item))
		button.tooltip_text = "Heal %d%% of your Max HP" % item.heal_percent
		button.disabled = Run.items[id] == 0 or hero.hp == hero.max_hp
		%ItemMenu.add_child(button)
	%ItemMenu.add_child(_command_button("Back", _close_items))
	%Buttons.hide()
	%ItemMenu.show()


func _close_items() -> void:
	%ItemMenu.hide()
	%Buttons.show()


## Using an item takes your turn.
func _use_item(id: String, item: Dictionary) -> void:
	if Run.items[id] == 0:
		return
	_close_items()
	_set_buttons_enabled(false)
	Run.items[id] -= 1
	var healed: int = mini(ceili(hero.max_hp * item.heal_percent / 100.0), hero.max_hp - hero.hp)
	hero.hp += healed
	_log("%s drinks a %s: +%d HP (%d left)." % [hero.display_name, item.name, healed, Run.items[id]])
	_after_action()


## Flee: d20 + Speed vs 10 + the fastest monster's Speed. Escape = no gold or EXP. Fail = you lose your turn.
func _on_flee() -> void:
	_set_buttons_enabled(false)
	var dc: int = FLEE_DC_BASE + _fastest_speed()
	var result: Dictionary = Dice.check(hero.speed, dc, hero.roll_mode())
	var line: String = "%s tries to flee: rolled %s, %+d Speed = %d vs %d (10 + fastest monster's Speed)" % [
		hero.display_name, hero.rolled_text(result.rolls), hero.speed, result.total, dc]
	if not result.success:
		_log(line + ": failed!")
		_enemy_turn()
		return
	_log(line + ": [b]escaped![/b] No gold or EXP from this fight.")
	fight_over = true
	%TurnLabel.text = "You got away."
	_add_choice("Continue", _continue)


func _after_action() -> void:
	_update_labels()
	if _alive().is_empty():
		_win()
		return
	if not target.is_alive():
		target = _alive()[0]
		_update_labels()
	_enemy_turn()


func _enemy_turn() -> void:
	_set_buttons_enabled(false)
	for foe in _alive():
		%TurnLabel.text = "%s's turn..." % foe.display_name
		# await pauses this function until the timer runs out, so the turns don't happen instantly.
		await get_tree().create_timer(ENEMY_TURN_DELAY).timeout
		_log(foe.strike(hero))
		_update_labels()
		if not hero.is_alive():
			_log("[color=%s][b]Defeated![/b][/color] Run over %s." % [ENEMY_COLOR,
				"at the boss fight" if Run.is_boss() else "in room %d of %d" % [Run.room, Run.ROOMS]])
			%TurnLabel.text = "Defeated! Your run is over."
			_add_choice("New hero", _new_hero)
			return
	_hero_turn()


func _win() -> void:
	_log("[color=%s][b]Victory![/b][/color]" % HERO_COLOR)
	var heal_text: String = hero.win_fight()
	if heal_text != "":
		_log(heal_text)
	fight_over = true
	if Run.is_boss():
		_log("[color=" + GOLD + "][b]Run complete![/b][/color] You beat the %s!" % enemies[0].display_name)
		%TurnLabel.text = "Run complete! You beat the %s!" % enemies[0].display_name
		_add_choice("New hero", _new_hero)
		_update_labels()
		return
	var exp_total: int = 0
	var gold_total: int = 0
	for foe in enemies:
		exp_total += foe.exp_reward
		gold_total += foe.gold_reward
	var levels: int = Run.gain_exp(exp_total)
	Run.gold += gold_total
	_log("[color=%s]+%d EXP.[/color]  [color=%s]+%d gold.[/color]" % [EXP_COLOR, exp_total, GOLD, gold_total])
	if levels > 0:
		_log("[color=" + GOLD + "][b]Level up![/b][/color] Now level %d: +%d stat points. Spend them with CHARACTER on the path screen." % [
			Run.level, levels * Run.POINTS_PER_LEVEL])
	_update_labels()
	%TurnLabel.text = "Victory!"
	_add_choice("Continue", _continue)


func _continue() -> void:
	if not fight_over:
		return  # a second click on a button that was already used
	fight_over = false
	Run.room += 1
	Run.room_type = ""
	get_tree().change_scene_to_file(PATH_SCENE)


func _new_hero() -> void:
	Run.hero = null
	get_tree().change_scene_to_file(CREATION_SCENE)


func _add_choice(text: String, on_pressed: Callable) -> void:
	%Choices.add_child(_command_button(text, on_pressed))
	%Buttons.hide()  # the fight is over: only the choice buttons make sense now


## A menu line in the COMMAND style (same look as Attack/Defend), with the hover cursor.
func _command_button(text: String, on_pressed: Callable) -> Button:
	var button: Button = %AttackButton.duplicate(0)  # copy the look only, not the Attack signal
	button.unique_name_in_owner = false
	button.disabled = false  # Attack is disabled when the fight ends; the copy must not be
	button.text = "   " + text
	button.pressed.connect(on_pressed)
	_add_cursor(button)
	return button


## Show a ▶ in front of a command while the mouse is over it.
func _add_cursor(button: Button) -> void:
	button.mouse_entered.connect(func() -> void: button.text = "▶" + button.text.substr(1))
	button.mouse_exited.connect(func() -> void: button.text = " " + button.text.substr(1))


func _alive() -> Array[Combatant]:
	var alive: Array[Combatant] = []
	alive.assign(enemies.filter(func(foe: Combatant) -> bool: return foe.is_alive()))
	return alive


func _fastest_speed() -> int:
	return _alive().map(func(foe: Combatant) -> int: return foe.speed).max()


## A clickable monster card: name, HP bar, HP and stats. Clicking it makes that monster the target.
func _make_card(foe: Combatant) -> Button:
	var card: Button = Button.new()
	card.custom_minimum_size = Vector2(0, 116)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.pressed.connect(_set_target.bind(foe))
	var lines: VBoxContainer = VBoxContainer.new()
	lines.name = "Lines"
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.offset_left = 10
	lines.offset_top = 6
	lines.offset_right = -10
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE  # clicks go through to the card
	for part in ["Name", "HPBar", "HP", "Stats"]:
		var node: Control = ProgressBar.new() if part == "HPBar" else Label.new()
		if node is Label:
			node.clip_text = true  # long text is cut instead of stretching the card
		node.name = part
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.add_child(node)
	var bar: ProgressBar = lines.get_node("HPBar")
	bar.custom_minimum_size = Vector2(0, 12)
	bar.show_percentage = false
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.3, 0.3)
	bar.add_theme_stylebox_override("fill", fill)
	lines.get_node("Name").add_theme_font_size_override("font_size", 18)
	lines.get_node("Stats").add_theme_font_size_override("font_size", 13)
	card.add_child(lines)
	if foe.sprite != "":
		var frames: AtlasTexture = AtlasTexture.new()
		frames.atlas = load("res://assets/sprites/enemies/%s.png" % foe.sprite)
		frames.region = Rect2(0, 0, frames.atlas.get_height(), frames.atlas.get_height())
		animations.append(frames)
		var picture: TextureRect = TextureRect.new()
		picture.texture = frames
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
		picture.custom_minimum_size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
		picture.grow_horizontal = Control.GROW_DIRECTION_BOTH
		picture.grow_vertical = Control.GROW_DIRECTION_BOTH
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(picture)
		lines.hide()  # art only: the info shows on hover or with the Info command
	return card


func _set_target(foe: Combatant) -> void:
	if foe.is_alive():
		target = foe
		_update_labels()
		if %InfoText.visible:
			_show_info(true)


func _update_labels() -> void:
	%HeroName.text = Run.hero_title
	%HeroHPBar.max_value = hero.max_hp
	%HeroHPBar.value = hero.hp
	%HeroHP.text = "HP %d / %d" % [hero.hp, hero.max_hp]
	var passives: Array = []
	for name in hero.passive_names.values():
		if not name in passives:
			passives.append(name)
	%HeroTokenName.text = hero.display_name
	%HeroTokenBar.max_value = hero.max_hp
	%HeroTokenBar.value = hero.hp
	%HeroStats.text = "%s %d (d%d)   Armor %d%s   Speed %d\nPassives: %s" % [
		hero.attack_name, hero.attack, hero.damage_die, hero.armor(), " (defending)" if hero.defending else "",
		hero.speed, ", ".join(passives) if passives else "none in combat"]
	%Level.text = "Level %d   EXP %d / %d   Gold %d" % [Run.level, Run.experience, Run.exp_needed(), Run.gold]
	%ExpBar.max_value = Run.exp_needed()
	%ExpBar.value = Run.experience

	for i in enemies.size():
		var foe: Combatant = enemies[i]
		var card: Button = %EnemyList.get_child(i)
		var lines: Node = card.get_node("Lines")
		lines.get_node("Name").text = foe.display_name
		lines.get_node("HPBar").max_value = foe.max_hp
		lines.get_node("HPBar").value = foe.hp
		lines.get_node("HP").text = "HP %d / %d" % [foe.hp, foe.max_hp] if foe.is_alive() else "Defeated"
		lines.get_node("Stats").text = "Atk %d d%d Arm %d Spd %d" % [foe.attack, foe.damage_die, foe.armor(), foe.speed]
		card.tooltip_text = _info(foe) if foe.is_alive() else ""
		card.disabled = not foe.is_alive()
		card.modulate = Color(1, 1, 1, 1 if foe.is_alive() else 0.4)
		var style: StyleBoxFlat = CARD_STYLE.duplicate()
		if foe == target and foe.is_alive():
			style.border_color = Color(1, 0.83, 0.3)
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			card.add_theme_stylebox_override(state, style)
		var row: Button = %TargetList.get_child(i)
		var is_target: bool = foe == target and foe.is_alive()
		row.text = "%s %s  %s" % ["▶" if is_target else " ", foe.display_name, "%d/%d" % [foe.hp, foe.max_hp] if foe.is_alive() else "down"]
		row.disabled = not foe.is_alive()
		row.add_theme_color_override("font_color", Color(1, 0.83, 0.3) if is_target else Color(1, 1, 1))


func _set_buttons_enabled(enabled: bool) -> void:
	%InfoButton.disabled = not enabled
	if not enabled:
		_show_info(false)
	%AttackButton.disabled = not enabled
	%DefendButton.disabled = not enabled
	%FleeButton.disabled = not enabled
	%ItemButton.disabled = not enabled or Run.items.values().all(func(count: int) -> bool: return count == 0)


func _log(text: String) -> void:
	%Log.append_text(_highlight(text) + "\n")


## Color names, passives, hits, misses and damage so a log line is easy to scan.
func _highlight(text: String) -> String:
	for passive in hero.passive_names.values():
		text = text.replace(passive, "[color=%s]%s[/color]" % [PASSIVE_COLOR, passive])
	var attackers: Array = [[hero, HERO_COLOR]]
	for foe in enemies:
		attackers.append([foe, ENEMY_COLOR])
	for fighter in attackers:
		var name_text: String = fighter[0].display_name + " attacks"
		if text.begins_with(name_text):
			text = "[color=%s][b]%s[/b][/color]%s" % [fighter[1], name_text, text.substr(name_text.length())]
	text = text.replace("CRITICAL HIT!", "[color=%s][b]CRITICAL HIT![/b][/color]" % GOLD)
	text = text.replace(": hit!", ": [b]hit![/b]")
	text = text.replace("automatic miss!", "[color=%s]automatic miss![/color]" % GRAY)
	text = text.replace(": miss.", ": [color=%s]miss.[/color]" % GRAY)
	text = text.replace("Damage:", "[color=%s]Damage:[/color]" % GRAY)
	var damage: RegEx = RegEx.create_from_string("= (\\d+) damage")
	return damage.sub(text, "= [b]$1 damage[/b]", true)
