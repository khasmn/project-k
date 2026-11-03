extends Control
## Combat screen: the run's hero vs the current enemy, turn by turn, then EXP, level-up or run end.

const ENEMY_TURN_DELAY: float = 0.6
const CREATION_SCENE: String = "res://scenes/character/character_creation.tscn"

var hero: Combatant
var enemy: Combatant
var fight_won: bool = false  # true between a win and starting the next fight


func _ready() -> void:
	%AttackButton.pressed.connect(_on_attack)
	%DefendButton.pressed.connect(_on_defend)
	%LevelUpPanel.confirmed.connect(_next_fight)
	if Run.hero == null:
		Run.start_test()  # this scene was started on its own, not from character creation
	_start_fight()


func _start_fight() -> void:
	hero = Run.hero
	enemy = Run.enemy()
	hero.start_fight()
	fight_won = false
	_clear_choices()
	%Buttons.show()
	%Title.text = "Fight %d of %d:  %s" % [Run.fight_number, Run.FIGHTS.size(), enemy.display_name]
	_log("[b]--- Fight %d of %d: %s ---[/b]" % [Run.fight_number, Run.FIGHTS.size(), enemy.display_name])
	_update_labels()

	# Initiative: d20 + Speed, highest goes first. Ties go to the enemy, unless the hero wins ties (Elf).
	var hero_rolls: Array[int] = Dice.roll_d20s(hero.roll_mode())
	var hero_roll: int = Dice.keep(hero_rolls, hero.roll_mode())
	var enemy_roll: int = Dice.roll_d20()
	var hero_init: int = hero_roll + hero.speed
	var enemy_init: int = enemy_roll + enemy.speed
	_log("Initiative: %s %s = %d%s, %s %s = %d" % [
		hero.display_name, Dice.sum_text(hero_roll, hero.speed), hero_init, hero.advantage_note(hero_rolls),
		enemy.display_name, Dice.sum_text(enemy_roll, enemy.speed), enemy_init])
	if hero_init == enemy_init:
		_log("Tie! %s goes first." % (
			"%s (%s)" % [hero.display_name, hero.passive("wins_ties")] if hero.wins_ties else enemy.display_name))
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
		_log("[b]Defeated![/b] Run over at fight %d of %d." % [Run.fight_number, Run.FIGHTS.size()])
		%TurnLabel.text = "Defeated! Your run is over."
		_add_choice("New hero", _new_hero)
	else:
		_hero_turn()


func _win() -> void:
	_log("[b]Victory![/b]")
	var heal_text: String = hero.win_fight()
	if heal_text != "":
		_log(heal_text)
	fight_won = true
	if Run.is_last_fight():
		_log("[b]Run complete![/b] You beat all %d fights." % Run.FIGHTS.size())
		%TurnLabel.text = "Run complete! You beat all %d fights." % Run.FIGHTS.size()
		_add_choice("New hero", _new_hero)
		_update_labels()
		return
	var levels: int = Run.gain_exp(enemy.exp_reward)
	_log("+%d EXP." % enemy.exp_reward)
	_update_labels()
	if levels > 0:
		_log("[b]Level up![/b] Now level %d: spend %d stat points." % [Run.level, levels * Run.POINTS_PER_LEVEL])
		%ActionPanel.hide()
		%LevelUpPanel.open(hero, levels * Run.POINTS_PER_LEVEL)
	else:
		%TurnLabel.text = "Victory!"
		_add_choice("Next fight", _next_fight)


func _next_fight() -> void:
	if not fight_won:
		return  # a second click on a button that was already used
	%ActionPanel.show()
	Run.fight_number += 1
	_start_fight()


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


func _clear_choices() -> void:
	for button in %Choices.get_children():
		%Choices.remove_child(button)
		button.queue_free()


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
	%Level.text = "Level %d   EXP %d / %d" % [Run.level, Run.experience, Run.exp_needed()]
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
	%Log.append_text(text + "\n")
