extends Control
## Combat prototype screen: one hero vs one enemy, turn by turn.

const ENEMY_TURN_DELAY: float = 0.6

var hero: Combatant
var enemy: Combatant


func _ready() -> void:
	%AttackButton.pressed.connect(_on_attack)
	%DefendButton.pressed.connect(_on_defend)
	%RestartButton.pressed.connect(_start_fight)
	_start_fight()


func _start_fight() -> void:
	hero = Combatant.load_from("res://data/heroes.json", "test_hero")
	enemy = Combatant.load_from("res://data/enemies.json", "bandit")
	%Log.clear()
	%RestartButton.hide()
	_update_labels()

	# Initiative: d20 + Speed, highest goes first (hero wins ties).
	var hero_init: int = Dice.roll_d20() + hero.speed
	var enemy_init: int = Dice.roll_d20() + enemy.speed
	_log("Initiative: %s %d, %s %d" % [hero.display_name, hero_init, enemy.display_name, enemy_init])
	if enemy_init > hero_init:
		_enemy_turn()
	else:
		_hero_turn()


func _hero_turn() -> void:
	hero.defending = false
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
		_end_fight("Victory!")
	else:
		_enemy_turn()


func _enemy_turn() -> void:
	_set_buttons_enabled(false)
	# await pauses this function until the timer runs out, so the turn doesn't happen instantly.
	await get_tree().create_timer(ENEMY_TURN_DELAY).timeout
	_log(enemy.strike(hero))
	_update_labels()
	if not hero.is_alive():
		_end_fight("Defeated!")
	else:
		_hero_turn()


func _end_fight(text: String) -> void:
	_log("[b]%s[/b]" % text)
	_set_buttons_enabled(false)
	%RestartButton.show()


func _update_labels() -> void:
	%HeroLabel.text = "%s  HP %d/%d" % [hero.display_name, hero.hp, hero.max_hp]
	%EnemyLabel.text = "%s  HP %d/%d" % [enemy.display_name, enemy.hp, enemy.max_hp]


func _set_buttons_enabled(enabled: bool) -> void:
	%AttackButton.disabled = not enabled
	%DefendButton.disabled = not enabled


func _log(text: String) -> void:
	%Log.append_text(text + "\n")
