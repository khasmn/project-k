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
