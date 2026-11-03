extends Control
## Combat screen: the run's hero vs the current enemy, turn by turn, then level-up or run end.

const ENEMY_TURN_DELAY: float = 0.6
const CREATION_SCENE: String = "res://scenes/character/character_creation.tscn"

var hero: Combatant
var enemy: Combatant


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
	_clear_choices()
	%Title.text = "Fight %d/%d   |   Level %d %s" % [
		Run.fight_number, Run.FIGHTS.size(), Run.fight_number, Run.hero_title]
	_log("[b]--- Fight %d/%d: %s ---[/b]" % [Run.fight_number, Run.FIGHTS.size(), enemy.display_name])
	_update_labels()

	# Initiative: d20 + Speed, highest goes first. Ties go to the enemy, unless the hero wins ties (Elf).
	var hero_roll: int = Dice.roll_d20(hero.roll_mode())
	var enemy_roll: int = Dice.roll_d20()
	var hero_init: int = hero_roll + hero.speed
	var enemy_init: int = enemy_roll + enemy.speed
	_log("Initiative: %s %s = %d, %s %s = %d" % [
		hero.display_name, Dice.sum_text(hero_roll, hero.speed), hero_init,
		enemy.display_name, Dice.sum_text(enemy_roll, enemy.speed), enemy_init])
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
	_log("Your turn.")


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
	# await pauses this function until the timer runs out, so the turn doesn't happen instantly.
	await get_tree().create_timer(ENEMY_TURN_DELAY).timeout
	_log(enemy.strike(hero))
	_update_labels()
	if not hero.is_alive():
		_log("[b]Defeated![/b] Run over at fight %d of %d." % [Run.fight_number, Run.FIGHTS.size()])
		_add_choice("New hero", _new_hero)
	else:
		_hero_turn()


func _win() -> void:
	_log("[b]Victory![/b]")
	var heal_text: String = hero.win_fight()
	if heal_text != "":
		_log(heal_text)
	_update_labels()
	if Run.is_last_fight():
		_log("[b]Run complete![/b] You beat all %d fights." % Run.FIGHTS.size())
		_add_choice("New hero", _new_hero)
		return
	_log("Level up! Pick an upgrade.")
	for upgrade in Run.upgrade_choices():
		_add_choice(hero.upgrade_text(upgrade), func() -> void: _level_up(upgrade))


func _level_up(upgrade: Dictionary) -> void:
	hero.apply_upgrade(upgrade)
	Run.fight_number += 1
	_log("Level %d: %s." % [Run.fight_number, hero.upgrade_text(upgrade)])
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


func _clear_choices() -> void:
	for button in %Choices.get_children():
		%Choices.remove_child(button)
		button.queue_free()


func _update_labels() -> void:
	%HeroLabel.text = "%s  HP %d/%d  Armor %d" % [hero.display_name, hero.hp, hero.max_hp, hero.armor()]
	%EnemyLabel.text = "%s  HP %d/%d  Armor %d" % [enemy.display_name, enemy.hp, enemy.max_hp, enemy.armor()]


func _set_buttons_enabled(enabled: bool) -> void:
	%AttackButton.disabled = not enabled
	%DefendButton.disabled = not enabled


func _log(text: String) -> void:
	%Log.append_text(text + "\n")
