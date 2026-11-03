extends Control
## Combat screen: the run's hero vs this room's enemy, turn by turn, then EXP and gold, then the path screen.

const ENEMY_TURN_DELAY: float = 0.6
const CREATION_SCENE: String = "res://scenes/character/character_creation.tscn"
const PATH_SCENE: String = "res://scenes/path/path.tscn"
## Battle log colors (BBCode: the log understands tags like [b]bold[/b] and [color=#hex]text[/color]).
const HERO_COLOR: String = "#7fd17f"
const ENEMY_COLOR: String = "#ff7a7a"
const GOLD: String = "#ffd34d"
const GRAY: String = "#8a8a8a"
const PASSIVE_COLOR: String = "#6fd3ff"
const EXP_COLOR: String = "#8fb4ff"

var hero: Combatant
var enemy: Combatant
var fight_won: bool = false  # true after a win, so Continue only works once


func _ready() -> void:
	%AttackButton.pressed.connect(_on_attack)
	%DefendButton.pressed.connect(_on_defend)
	if Run.hero == null:
		Run.start_test()  # this scene was started on its own, not from character creation
	_start_fight()


func _start_fight() -> void:
	hero = Run.hero
	enemy = Run.enemy()
	hero.start_fight()
	var where: String = "Boss fight" if Run.is_boss() else "Room %d of %d" % [Run.room, Run.ROOMS]
	%Title.text = "%s:  %s" % [where, enemy.display_name]
	_log("[color=%s][b]--- %s: %s ---[/b][/color]" % [GOLD, where, enemy.display_name])
	if Run.room_note != "":
		_log(Run.room_note)
		Run.room_note = ""
	_update_labels()

	# Initiative: d20 + Speed, highest goes first. Ties go to the enemy, unless the hero wins ties (Elf).
	var hero_rolls: Array[int] = Dice.roll_d20s(hero.roll_mode())
	var hero_roll: int = Dice.keep(hero_rolls, hero.roll_mode())
	var enemy_roll: int = Dice.roll_d20()
	var hero_init: int = hero_roll + hero.speed
	var enemy_init: int = enemy_roll + enemy.speed
	var order: String = "Who goes first: %s rolled %s %+d Speed = %d, %s rolled %d %+d Speed = %d." % [
		hero.display_name, hero.rolled_text(hero_rolls), hero.speed, hero_init,
		enemy.display_name, enemy_roll, enemy.speed, enemy_init]
	if hero_init == enemy_init:
		order += " Tie! %s goes first." % (
			"%s (%s wins ties)" % [hero.display_name, hero.passive("wins_ties")] if hero.wins_ties else enemy.display_name)
	_log(order)
	if hero_init > enemy_init or (hero_init == enemy_init and hero.wins_ties):
		_hero_turn()
	else:
		_enemy_turn()


func _hero_turn() -> void:
	var regen_text: String = hero.start_turn()
	if regen_text != "":
		_log(regen_text)
	_update_labels()
	_set_buttons_enabled(true)
	%TurnLabel.text = "Your turn: choose an action"


func _on_attack() -> void:
	_set_buttons_enabled(false)
	_log(hero.strike(enemy))
	_after_action()


func _on_defend() -> void:
	_set_buttons_enabled(false)
	hero.defending = true
	_log("%s defends (+%d Armor until next turn)." % [hero.display_name, Combatant.DEFEND_BONUS])
	_after_action()


func _after_action() -> void:
	_update_labels()
	if not enemy.is_alive():
		_win()
	else:
		_enemy_turn()


func _enemy_turn() -> void:
	_set_buttons_enabled(false)
	%TurnLabel.text = "%s's turn..." % enemy.display_name
	# await pauses this function until the timer runs out, so the turn doesn't happen instantly.
	await get_tree().create_timer(ENEMY_TURN_DELAY).timeout
	_log(enemy.strike(hero))
	_update_labels()
	if not hero.is_alive():
		_log("[color=" + ENEMY_COLOR + "][b]Defeated![/b][/color] Run over %s." % ("at the boss fight" if Run.is_boss() else "in room %d of %d" % [Run.room, Run.ROOMS]))
		%TurnLabel.text = "Defeated! Your run is over."
		_add_choice("New hero", _new_hero)
	else:
		_hero_turn()


func _win() -> void:
	_log("[color=%s][b]Victory![/b][/color]" % HERO_COLOR)
	var heal_text: String = hero.win_fight()
	if heal_text != "":
		_log(heal_text)
	fight_won = true
	if Run.is_boss():
		_log("[color=" + GOLD + "][b]Run complete![/b][/color] You beat the %s!" % enemy.display_name)
		%TurnLabel.text = "Run complete! You beat the %s!" % enemy.display_name
		_add_choice("New hero", _new_hero)
		_update_labels()
		return
	var levels: int = Run.gain_exp(enemy.exp_reward)
	Run.gold += enemy.gold_reward
	_log("[color=%s]+%d EXP.[/color]  [color=%s]+%d gold.[/color]" % [EXP_COLOR, enemy.exp_reward, GOLD, enemy.gold_reward])
	if levels > 0:
		_log("[color=" + GOLD + "][b]Level up![/b][/color] Now level %d: +%d stat points. Spend them with CHARACTER on the path screen." % [
			Run.level, levels * Run.POINTS_PER_LEVEL])
	_update_labels()
	%TurnLabel.text = "Victory!"
	_add_choice("Continue", _continue)


func _continue() -> void:
	if not fight_won:
		return  # a second click on a button that was already used
	fight_won = false
	Run.room += 1
	Run.room_type = ""
	get_tree().change_scene_to_file(PATH_SCENE)


func _new_hero() -> void:
	Run.hero = null
	get_tree().change_scene_to_file(CREATION_SCENE)


func _add_choice(text: String, on_pressed: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(160, 40)
	button.pressed.connect(on_pressed)
	%Choices.add_child(button)
	%Buttons.hide()  # the fight is over: only the choice buttons make sense now


func _update_labels() -> void:
	%HeroName.text = Run.hero_title
	%HeroHPBar.max_value = hero.max_hp
	%HeroHPBar.value = hero.hp
	%HeroHP.text = "HP %d / %d" % [hero.hp, hero.max_hp]
	var passives: Array = []
	for name in hero.passive_names.values():
		if not name in passives:
			passives.append(name)
	%HeroStats.text = "%s %d (d%d)   Armor %d%s   Speed %d\nPassives: %s" % [
		hero.attack_name, hero.attack, hero.damage_die, hero.armor(), " (defending)" if hero.defending else "",
		hero.speed, ", ".join(passives) if passives else "none in combat"]
	%Level.text = "Level %d   EXP %d / %d   Gold %d" % [Run.level, Run.experience, Run.exp_needed(), Run.gold]
	%ExpBar.max_value = Run.exp_needed()
	%ExpBar.value = Run.experience

	%EnemyName.text = enemy.display_name
	%EnemyHPBar.max_value = enemy.max_hp
	%EnemyHPBar.value = enemy.hp
	%EnemyHP.text = "HP %d / %d" % [enemy.hp, enemy.max_hp]
	%EnemyStats.text = "Attack %d (d%d)   Armor %d   Speed %d" % [enemy.attack, enemy.damage_die, enemy.armor(), enemy.speed]


func _set_buttons_enabled(enabled: bool) -> void:
	%AttackButton.disabled = not enabled
	%DefendButton.disabled = not enabled


func _log(text: String) -> void:
	%Log.append_text(_highlight(text) + "\n")


## Color names, passives, hits, misses and damage so a log line is easy to scan.
func _highlight(text: String) -> String:
	for passive in hero.passive_names.values():
		text = text.replace(passive, "[color=%s]%s[/color]" % [PASSIVE_COLOR, passive])
	for fighter in [[hero, HERO_COLOR], [enemy, ENEMY_COLOR]]:
		var name_text: String = fighter[0].display_name + " attacks:"
		text = text.replace(name_text, "[color=%s][b]%s[/b][/color]" % [fighter[1], name_text])
	text = text.replace("CRITICAL HIT!", "[color=%s][b]CRITICAL HIT![/b][/color]" % GOLD)
	text = text.replace(": hit!", ": [b]hit![/b]")
	text = text.replace("automatic miss!", "[color=%s]automatic miss![/color]" % GRAY)
	text = text.replace(": miss.", ": [color=%s]miss.[/color]" % GRAY)
	text = text.replace("Damage:", "[color=%s]Damage:[/color]" % GRAY)
	var damage: RegEx = RegEx.create_from_string("= (\\d+) damage")
	return damage.sub(text, "= [b]$1 damage[/b]", true)
