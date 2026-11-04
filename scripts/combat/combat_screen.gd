extends Control
## Combat screen: the run's hero vs this room's monsters (1-4), turn by turn, then EXP and gold, then the path screen.

const ENEMY_TURN_DELAY: float = 0.6
const CREATION_SCENE: String = "res://scenes/character/character_creation.tscn"
const PATH_SCENE: String = "res://scenes/path/path.tscn"
const TOWN_SCENE: String = "res://scenes/city/town.tscn"
const CARD_STYLE: StyleBoxFlat = preload("res://scenes/ui/box_style.tres")
const SPRITE_FPS: int = 6
const START_DELAY: float = 1.0  # seconds before the initiative roll
const SPRITE_SIZE: int = 96  # 32x32 art shown 3x
const BACKGROUND_FRAME: int = 384  # backgrounds are strips of 384x128 frames
const ARROW_FPS: int = 2  # the target arrow bobs slowly
const BACKGROUND_FPS: int = 2  # slow on purpose: a fast-moving background can cause motion sickness
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
var dice: DiceTray = DiceTray.new()
var fx: FightFx = FightFx.new()
var hero_sprite: HeroSprite
var pictures: Dictionary = {}  # Combatant -> its TextureRect on the battlefield
var landing: int = 0  # hits still flying or flashing; the log waits for them
var animations: Dictionary = {}  # AtlasTexture -> frames per second


func _ready() -> void:
	%AttackButton.pressed.connect(_on_attack)
	%SkillButton.pressed.connect(_open_skills)
	%DefendButton.pressed.connect(_on_defend)
	%ItemButton.pressed.connect(_open_items)
	var back: StyleBoxTexture = StyleBoxTexture.new()
	back.texture = _strip("res://assets/backgrounds/%s.png" % Run.BACKGROUND, BACKGROUND_FRAME,
		BACKGROUND_FPS if Settings.animate_background else 0)  # 0 FPS = stays on frame 1
	back.set_content_margin_all(12)
	%Arena.add_theme_stylebox_override("panel", back)
	dice.alignment = BoxContainer.ALIGNMENT_CENTER
	dice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Arena.add_child(dice)  # a PanelContainer stacks its children: the dice float over the fight
	Dice.recording = Settings.animate_dice
	if Run.hero_look:  # a created hero has a sprite; the test hero keeps its name label
		var sprite: HeroSprite = HeroSprite.new()
		sprite.custom_minimum_size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
		sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sprite.show_look(Run.hero_look)
		%HeroToken.add_child(sprite)
		%HeroToken.move_child(sprite, 0)
		%HeroTokenName.hide()
		hero_sprite = sprite
	add_child(fx)  # last child: effects draw above everything
	%Log.get_v_scroll_bar().modulate.a = 0  # floating log: no visible scrollbar, the mouse wheel still scrolls
	%MeditateButton.pressed.connect(_on_meditate)
	for button in %Buttons.get_children():
		UI.add_cursor(button)
	if Run.hero == null:
		Run.start_test()  # this scene was started on its own, not from character creation
	_set_buttons_enabled(false)  # nothing to click until the first turn is decided
	_start_fight()


func _start_fight() -> void:
	hero = Run.hero
	enemies = Run.enemies()
	target = enemies[0]
	hero.start_fight()
	%SkillButton.visible = not hero.skills.is_empty()
	%MeditateButton.text = "   " + ("Meditate" if hero.energy_name == "Mana" else "Concentrate")
	%MeditateButton.tooltip_text = "Skip your attack to gain 1 extra %s." % hero.energy_name
	for i in Combatant.MAX_ENERGY:  # one box per point of Energy
		var box: ColorRect = ColorRect.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		%HeroEnergyBar.add_child(box)
	for foe in enemies:
		%EnemyList.add_child(_make_card(foe))
		var row: Button = UI.menu_button("", _set_target.bind(foe))
		row.clip_text = true  # status text like "(Poison 2)" is cut instead of widening the box
		%TargetList.add_child(row)
	var where: String = "Boss fight" if Run.is_boss() else "Room %d of %d" % [Run.room, Run.ROOMS]
	var names: String = ", ".join(enemies.map(func(foe: Combatant) -> String: return foe.display_name))
	%Title.text = "%s:  %s" % [where, names]
	_log("[color=%s][b]--- %s: %s ---[/b][/color]" % [GOLD, where, names])
	if Run.room_note != "":
		_log(Run.room_note)
		Run.room_note = ""
	_update_labels()
	if Settings.animate_dice:  # a moment to see the fight before the first dice (the play tool skips it)
		await get_tree().create_timer(START_DELAY).timeout

	Dice.history.clear()  # building the monster group rolled dice too; only show the fight's rolls
	# Initiative: your d20 + Speed vs one d20 for the group + its fastest Speed. Ties go to the monsters (Elf wins ties).
	var hero_rolls: Array[int] = Dice.roll_d20s(hero.roll_mode())
	var hero_init: int = Dice.keep(hero_rolls, hero.roll_mode()) + hero.speed
	await dice.show_rolls(true)
	var enemy_roll: int = Dice.roll_d20()
	await dice.show_rolls(false)
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


## Play every strip: show frame N of the strip, moving on its own frames per second.
func _process(_delta: float) -> void:
	for frames: AtlasTexture in animations:
		UI.animate(frames, animations[frames])
	%Arena.queue_redraw()  # a box style doesn't repaint by itself when its texture changes; the sprites do


## A strip from UI.strip that this screen keeps animating.
func _strip(path: String, frame_width: int = 0, fps: int = SPRITE_FPS) -> AtlasTexture:
	var frames: AtlasTexture = UI.strip(path, frame_width)
	animations[frames] = fps
	return frames


func _info(foe: Combatant) -> String:
	var text: String = "%s\nHP %d / %d\nAttack %d, %s (d%d)\nArmor %d   Speed %d" % [
		foe.display_name, foe.hp, foe.max_hp, foe.attack, foe.weapon, foe.damage_die, foe.armor(), foe.speed]
	if not foe.skills.is_empty():
		text += "\nSkill: %s" % foe.skills[0].name
	if foe.status_text():
		text += "\n" + foe.status_text()
	return text


func _hero_turn() -> void:
	var turn_text: String = hero.start_turn()
	if turn_text != "":
		_log(turn_text)
	_update_labels()
	if not hero.is_alive():
		_defeat()
		return
	if hero.shake_off_stun():
		_log("%s is stunned and loses this turn!" % hero.display_name)
		_enemy_turn()
		return
	_set_buttons_enabled(true)
	%TurnLabel.text = "Your turn: pick a target, then an action"


func _on_attack() -> void:
	_set_buttons_enabled(false)
	var before: Dictionary = _snapshot()
	var line: String = hero.strike(target)
	await dice.show_rolls(true)  # the strike is already decided; show its dice, then the result
	await _animate(hero, Run.data("classes").get(Run.hero_look.get("class", ""), {}), [target], before)
	_log(line)
	_after_action()


## The skill list: name and Energy cost; a skill you can't pay for is greyed out.
func _open_skills() -> void:
	var buttons: Array[Button] = []
	for skill in hero.skills:
		var wait: int = hero.skill_wait(skill)
		var cost: String = "wait %d" % wait if wait else "%d %s" % [skill.cost, hero.energy_name]
		var button: Button = UI.menu_button("%s (%s)" % [skill.name, cost], _on_skill.bind(skill))
		button.tooltip_text = "%s You get 1 %s back each turn. After use, wait %d turns." % [
			skill.description, hero.energy_name, Combatant.cooldown(skill)]
		button.disabled = wait > 0 or hero.energy < int(skill.cost)
		buttons.append(button)
	if not Run.is_boss():
		var flee: Button = UI.menu_button("Flee", _on_flee)
		flee.tooltip_text = "d20 + Speed vs 10 + the fastest monster's Speed. Escape = no gold or EXP; fail = you lose your turn."
		buttons.append(flee)
	_open_menu(buttons)


## Meditate (Concentrate without Mana): the whole turn goes into 1 more Energy.
func _on_meditate() -> void:
	_set_buttons_enabled(false)
	hero.energy = mini(hero.energy + 1, Combatant.MAX_ENERGY)
	_log("%s focuses: +1 %s." % [hero.display_name, hero.energy_name])
	_after_action()


func _on_skill(skill: Dictionary) -> void:
	_close_menu()
	_set_buttons_enabled(false)
	var foes: Array[Combatant] = [target]
	foes.append_array(_alive().filter(func(foe: Combatant) -> bool: return foe != target))
	var before: Dictionary = _snapshot()
	var line: String = hero.use_skill(skill, foes, [hero])
	await dice.show_rolls(true)
	await _animate(hero, skill, foes if skill.get("area", "") == "all" else [target], before)
	_log(line)
	_after_action()


## Everyone's HP, shield and statuses before an action, so the animation can show what changed.
func _snapshot() -> Dictionary:
	var state: Dictionary = {}
	for fighter: Combatant in _everyone():
		state[fighter] = [fighter.hp, fighter.shield, fighter.statuses.keys()]
	return state


## Show an action that already happened: user's attack (or skill) pose, then for each target its projectile,
## impact, damage number and new status effects. move: a class or skill entry with "pose", "aura",
## "projectile", "impact", "shield_fx" (all optional). The rules are done before this; it only shows them.
func _animate(user: Combatant, move: Dictionary, targets: Array, before: Dictionary) -> void:
	if not Settings.animate_attacks:
		return
	var node: Control = _node_of(user)
	if move.has("aura"):
		await fx.play(move.aura, node)
	if move.has("shield"):  # a shield skill: no attack, the shields light up
		if user != hero:
			await fx.monster_cast(node)
		elif hero_sprite:
			await hero_sprite.play_attack(move.get("pose", ""), func(_blow: int) -> void: pass)
		for ally: Combatant in _everyone():
			if ally.shield > before[ally][1]:
				fx.play(move.get("shield_fx", "shield"), _node_of(ally))
		await get_tree().create_timer(0.35).timeout
		return
	var blows: int = int(move.get("attacks", 1))
	var land: Callable = func(blow: int) -> void:
		for target_hit: Combatant in targets:
			_land(target_hit, node, move, before, blow == blows - 1)
	if user == hero and hero_sprite:
		await hero_sprite.play_attack(move.get("pose", Run.hero_look.get("class", "") + "_attack"), land)
	else:
		if move.is_empty():
			move = {"impact": "bite" if user.weapon == "bite" else "slash"}
		for blow in blows:
			await fx.monster_attack(pictures.get(user), user.sprite, 1.0, land.bind(blow))
	while landing > 0:
		await get_tree().process_frame


## One blow reaching a target: projectile, impact effect, then a number, "Blocked" or "Miss" (only after the last blow).
func _land(target_hit: Combatant, from: Control, move: Dictionary, before: Dictionary, last: bool) -> void:
	landing += 1
	var node: Control = _node_of(target_hit)
	await fx.fly(move.get("projectile", ""), from, node)
	var damage: int = before[target_hit][0] - target_hit.hp
	var blocked: int = before[target_hit][1] - target_hit.shield
	if damage > 0 or not last:
		fx.play(move.get("impact", ""), node)
	if last:
		var color: Color = Color(1, 0.45, 0.4) if target_hit == hero else Color(1, 1, 1)
		await fx.hurt(node, str(damage) if damage > 0 else ("Blocked" if blocked > 0 else "Miss"), color)
		for status in target_hit.statuses:
			if not status in before[target_hit][2]:
				fx.play(status, node)
	landing -= 1


func _everyone() -> Array[Combatant]:
	var everyone: Array[Combatant] = [hero]
	everyone.append_array(enemies)
	return everyone


func _node_of(fighter: Combatant) -> Control:
	if fighter == hero:
		return hero_sprite if hero_sprite else %HeroToken
	return pictures.get(fighter)


func _on_defend() -> void:
	_set_buttons_enabled(false)
	hero.defending = true
	_log("%s defends: +%d Armor, and monsters attack with disadvantage until your next turn." % [
		hero.display_name, Combatant.DEFEND_BONUS])
	_after_action()


## Item: swap the action buttons for a list of your items (and Back).
func _open_items() -> void:
	var all: Dictionary = Run.data("items")
	var buttons: Array[Button] = []
	for id in Run.items:
		var item: Dictionary = all[id]
		var button: Button = UI.menu_button("%s x%d" % [item.name, Run.items[id]], _use_item.bind(id, item))
		button.tooltip_text = item.description
		button.disabled = Run.items[id] == 0 or not _item_helps(item)
		buttons.append(button)
	_open_menu(buttons)


## Item and Skill lists share one box in place of the COMMAND buttons, with Back at the bottom.
func _open_menu(buttons: Array[Button]) -> void:
	for old in %ItemMenu.get_children():
		old.queue_free()
	for button in buttons:
		%ItemMenu.add_child(button)
	%ItemMenu.add_child(UI.menu_button("Back", _close_menu))
	%Buttons.hide()
	%ItemMenu.show()


func _close_menu() -> void:
	%ItemMenu.hide()
	%Buttons.show()


## Using an item takes your turn.
func _use_item(id: String, item: Dictionary) -> void:
	if Run.items[id] == 0:
		return
	_close_menu()
	_set_buttons_enabled(false)
	Run.items[id] -= 1
	var effect: String = ""
	if item.has("heal_percent"):
		var healed: int = mini(ceili(hero.max_hp * item.heal_percent / 100.0), hero.max_hp - hero.hp)
		hero.hp += healed
		effect = "+%d HP" % healed
	if item.has("energy"):
		var gained: int = mini(int(item.energy), Combatant.MAX_ENERGY - hero.energy)
		hero.energy += gained
		effect = "+%d %s" % [gained, hero.energy_name]
	if item.has("advantage"):
		hero.charmed = true
		effect = "the next attack rolls with advantage"
	_log("%s uses a %s: %s (%d left)." % [hero.display_name, item.name, effect, Run.items[id]])
	_after_action()


## An item is greyed out when it would do nothing: full HP, full Energy, or a Luck Charm already glowing.
func _item_helps(item: Dictionary) -> bool:
	if item.has("heal_percent"):
		return hero.hp < hero.max_hp
	if item.has("energy"):
		return hero.energy < Combatant.MAX_ENERGY
	return not hero.charmed


## Flee: d20 + Speed vs 10 + the fastest monster's Speed. Escape = no gold or EXP. Fail = you lose your turn.
func _on_flee() -> void:
	_close_menu()
	_set_buttons_enabled(false)
	var dc: int = FLEE_DC_BASE + _fastest_speed()
	var result: Dictionary = Dice.check(hero.speed, dc, hero.roll_mode())
	var line: String = "%s tries to flee: rolled %s, %+d Speed = %d vs %d (10 + fastest monster's Speed)" % [
		hero.display_name, hero.rolled_text(result.rolls), hero.speed, result.total, dc]
	await dice.show_rolls(true)
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
		var turn_text: String = foe.start_turn()
		if turn_text != "":
			_log(turn_text)
			_update_labels()
		if not foe.is_alive():
			continue
		if foe.shake_off_stun():
			_log("%s is stunned and loses this turn!" % foe.display_name)
			continue
		# The skill-chance d6 isn't animated: it would add a throw to every monster turn.
		var uses_skill: bool = not foe.skills.is_empty() and foe.skill_wait(foe.skills[0]) == 0 and Dice.roll(6, false) >= Combatant.SKILL_CHANCE
		var before: Dictionary = _snapshot()
		var line: String = foe.use_skill(foe.skills[0], [hero], _alive()) if uses_skill else foe.strike(hero)
		await dice.show_rolls(false)
		await _animate(foe, foe.skills[0] if uses_skill else {}, [hero], before)
		_log(line)
		_update_labels()
		if not hero.is_alive():
			_defeat()
			return
	if _alive().is_empty():  # poison or burn finished the last monster
		_win()
		return
	if not target.is_alive():
		target = _alive()[0]
	_hero_turn()


func _defeat() -> void:
	_log("[color=%s][b]Defeated![/b][/color] Run over %s." % [ENEMY_COLOR,
		"at the boss fight" if Run.is_boss() else "in room %d of %d" % [Run.room, Run.ROOMS]])
	%TurnLabel.text = "Defeated! Your run is over."
	_add_choice("New hero", _new_hero)


func _win() -> void:
	_log("[color=%s][b]Victory![/b][/color]" % HERO_COLOR)
	var heal_text: String = hero.win_fight()
	if heal_text != "":
		_log(heal_text)
	fight_over = true
	for foe in enemies:
		var loot: String = Gear.loot(foe)
		if loot:
			_log("[color=%s]%s[/color]" % [GOLD, loot])
	if Run.is_boss():
		_log("[color=" + GOLD + "][b]Chapter complete![/b][/color] You beat the %s!" % enemies[0].display_name)
		%TurnLabel.text = "Chapter complete! You beat the %s!" % enemies[0].display_name
		_add_choice("Back to town", _back_to_town)
		var next: Button = UI.menu_button("Next chapter (coming soon)", _back_to_town)
		next.disabled = true
		%Choices.add_child(next)
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


func _back_to_town() -> void:
	Run.restart_chapter()
	get_tree().change_scene_to_file(TOWN_SCENE)


func _new_hero() -> void:
	Run.hero = null
	get_tree().change_scene_to_file(CREATION_SCENE)


func _add_choice(text: String, on_pressed: Callable) -> void:
	%Choices.add_child(UI.menu_button(text, on_pressed))
	%Buttons.hide()  # the fight is over: only the choice buttons make sense now


func _alive() -> Array[Combatant]:
	var alive: Array[Combatant] = []
	alive.assign(enemies.filter(func(foe: Combatant) -> bool: return foe.is_alive()))
	return alive


func _fastest_speed() -> int:
	return _alive().map(func(foe: Combatant) -> int: return foe.speed).max()


## A clickable monster card: name, HP bar, HP and stats. Clicking it makes that monster the target.
func _make_card(foe: Combatant) -> Button:
	var card: Button = Button.new()
	card.custom_minimum_size = Vector2(SPRITE_SIZE + 20, 116)  # fixed width keeps the group close together
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
	var arrow: TextureRect = TextureRect.new()  # marks the target, above its head
	arrow.name = "Arrow"
	arrow.texture = _strip("res://assets/sprites/ui/target_arrow.png", 9, ARROW_FPS)
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	arrow.offset_left = -13
	arrow.offset_right = 14
	arrow.offset_top = -12
	arrow.offset_bottom = 12
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(arrow)
	if foe.sprite != "":
		var picture: TextureRect = TextureRect.new()
		picture.texture = _strip("res://assets/sprites/enemies/%s.png" % foe.sprite)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Bosses are drawn on bigger canvases (48 or 64 px); all art keeps the same pixel scale and stands on the card's floor.
		var shown: float = picture.texture.region.size.y * SPRITE_SIZE / 32
		picture.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		picture.offset_left = -shown / 2
		picture.offset_right = shown / 2
		picture.offset_top = -10 - shown
		picture.offset_bottom = -10
		arrow.offset_top = card.custom_minimum_size.y - shown - 22
		arrow.offset_bottom = arrow.offset_top + 24
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(picture)
		bar.reparent(card)  # art only: the HP bar floats over the monster's head
		bar.custom_minimum_size.y = 8
		var half: float = minf(shown * 0.3, 40)
		bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		bar.offset_left = -half
		bar.offset_right = half
		bar.offset_top = -10 - shown - 10
		bar.offset_bottom = -10 - shown - 2
		arrow.offset_top -= 12
		arrow.offset_bottom -= 12
		card.custom_minimum_size.x = maxf(card.custom_minimum_size.x, shown)  # bosses are wider
		pictures[foe] = picture
		lines.hide()  # art only: the info shows when the mouse is over the monster
	return card


func _set_target(foe: Combatant) -> void:
	if foe.is_alive():
		target = foe
		_update_labels()


func _update_labels() -> void:
	%HeroName.text = Run.hero_title
	%HeroHPBar.max_value = hero.max_hp
	%HeroHPBar.value = hero.hp
	var full: Color = Color(0.3, 0.7, 1) if hero.energy_name == "Mana" else Color(1, 0.78, 0.3)
	for i in %HeroEnergyBar.get_child_count():
		%HeroEnergyBar.get_child(i).color = full if i < hero.energy else Color(0.22, 0.22, 0.27)
	%HeroHP.text = "HP %d / %d     %s %d / %d" % [hero.hp, hero.max_hp, hero.energy_name, hero.energy, Combatant.MAX_ENERGY]
	var passives: Array = []
	for name in hero.passive_names.values():
		if not name in passives:
			passives.append(name)
	%HeroTokenName.text = hero.display_name
	%HeroTokenBar.max_value = hero.max_hp
	%HeroTokenBar.value = hero.hp
	%HeroStats.text = "%s %d (d%d)   Armor %d%s   Speed %d%s\nPassives: %s" % [
		hero.attack_name, hero.attack, hero.damage_die, hero.armor(), " (defending)" if hero.defending else "",
		hero.speed, "   " + hero.status_text() if hero.status_text() else "",
		", ".join(passives) if passives else "none in combat"]
	%Level.text = "Level %d   EXP %d / %d   Gold %d" % [Run.level, Run.experience, Run.exp_needed(), Run.gold]
	%ExpBar.max_value = Run.exp_needed()
	%ExpBar.value = Run.experience

	for i in enemies.size():
		var foe: Combatant = enemies[i]
		var card: Button = %EnemyList.get_child(i)
		var lines: Node = card.get_node("Lines")
		lines.get_node("Name").text = foe.display_name
		var bar: ProgressBar = card.find_child("HPBar", true, false)
		bar.max_value = foe.max_hp
		bar.value = foe.hp
		lines.get_node("HP").text = "HP %d / %d" % [foe.hp, foe.max_hp] if foe.is_alive() else "Defeated"
		lines.get_node("Stats").text = "Atk %d d%d Arm %d Spd %d" % [foe.attack, foe.damage_die, foe.armor(), foe.speed]
		if foe.status_text():
			lines.get_node("Stats").text += "  " + foe.status_text()
		card.tooltip_text = _info(foe) if foe.is_alive() else ""
		card.disabled = not foe.is_alive()
		card.modulate = Color(1, 1, 1, 1 if foe.is_alive() else 0.4)
		var style: StyleBoxFlat = CARD_STYLE.duplicate()
		if foe.sprite != "":  # art stands on the background: no box
			style.draw_center = false
			style.border_color.a = 0
		card.get_node("Arrow").visible = foe == target and foe.is_alive()
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			card.add_theme_stylebox_override(state, style)
		var row: Button = %TargetList.get_child(i)
		var is_target: bool = foe == target and foe.is_alive()
		row.text = "%s %s  %s" % ["▶" if is_target else " ", foe.display_name, "%d/%d" % [foe.hp, foe.max_hp] if foe.is_alive() else "down"]
		if foe.is_alive() and foe.status_text():
			row.text += "  (%s)" % foe.status_text()
		row.disabled = not foe.is_alive()
		row.tooltip_text = _info(foe) if foe.is_alive() else ""
		row.add_theme_color_override("font_color", Color(1, 0.83, 0.3) if is_target else Color(1, 1, 1))


func _set_buttons_enabled(enabled: bool) -> void:
	%MeditateButton.disabled = not enabled or hero.energy >= Combatant.MAX_ENERGY
	%AttackButton.disabled = not enabled
	%SkillButton.disabled = not enabled
	%DefendButton.disabled = not enabled
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
