extends SceneTree
## Combat self-check: auto-plays many fights and checks they end correctly. Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_combat.gd

const FIGHTS: int = 1000
const MAX_ROUNDS: int = 100

var failed: bool = false


func _init() -> void:
	var hero_wins: int = 0
	var total_rounds: int = 0
	for i in FIGHTS:
		var hero: Combatant = Combatant.load_from("res://data/heroes.json", "test_hero")
		var enemy: Combatant = Combatant.load_from("res://data/enemies.json", "bandit")
		var rounds: int = 0
		while hero.is_alive() and enemy.is_alive() and rounds < MAX_ROUNDS:
			hero.strike(enemy)
			if enemy.is_alive():
				enemy.strike(hero)
			rounds += 1
		_check(rounds < MAX_ROUNDS, "fight never ended")
		_check(hero.is_alive() != enemy.is_alive(), "not exactly one winner")
		_check(hero.hp >= 0 and enemy.hp >= 0, "HP went below 0")
		total_rounds += rounds
		if hero.is_alive():
			hero_wins += 1

	# A weak attacker (negative Attack) still does at least 1 damage, never heals.
	var weak: Combatant = Combatant.new({"name": "Weak", "hp": 10, "attack": -5, "defense": 0, "speed": 0, "damage_die": 4})
	var dummy: Combatant = Combatant.new({"name": "Dummy", "hp": 1000, "attack": 0, "defense": -30, "speed": 0, "damage_die": 4})
	for i in FIGHTS:
		var hp_before: int = dummy.hp
		var line: String = weak.strike(dummy)
		_check(dummy.hp <= hp_before, "weak hit healed")
		if not "miss" in line:
			_check(dummy.hp < hp_before, "weak hit did 0 damage")
		if dummy.hp == 0:
			dummy.hp = 1000

	if failed:
		quit(1)
		return
	print("Combat OK  (hero wins %d%%, avg %.1f rounds)" % [100 * hero_wins / FIGHTS, float(total_rounds) / FIGHTS])
	quit()


# assert() doesn't stop a headless run, so record failures and exit with code 1.
func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failed = true
