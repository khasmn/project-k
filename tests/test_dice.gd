extends SceneTree
## Dice self-check. Run from the project folder:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_dice.gd

const ROLLS: int = 20000

var failed: bool = false


func _init() -> void:
	# Plain d20: only 1-20, every face shows up.
	var faces: Dictionary = {}
	for i in ROLLS:
		var r: int = Dice.roll(20)
		_check(r >= 1 and r <= 20, "d20 out of range: %d" % r)
		faces[r] = true
	_check(faces.size() == 20, "not every d20 face rolled")

	# Advantage averages higher than normal, disadvantage lower (~13.8 / 10.5 / 7.2).
	var avg_adv: float = _average(Dice.Mode.ADVANTAGE)
	var avg_norm: float = _average(Dice.Mode.NORMAL)
	var avg_dis: float = _average(Dice.Mode.DISADVANTAGE)
	_check(avg_adv > avg_norm + 2.0 and avg_dis < avg_norm - 2.0, "advantage/disadvantage wrong")

	# Nat 20 always succeeds, nat 1 always fails, otherwise total vs DC.
	var crits: int = 0
	for i in ROLLS:
		var hopeless: Dictionary = Dice.check(0, 99)
		_check(hopeless.success == (hopeless.natural == 20), "nat 20 rule broken")
		var easy: Dictionary = Dice.check(50, 2)
		_check(easy.success == (easy.natural != 1), "nat 1 rule broken")
		var normal: Dictionary = Dice.check(3, 12)
		if normal.natural != 1 and normal.natural != 20:
			_check(normal.success == (normal.total >= 12), "DC compare broken")
		if normal.crit:
			crits += 1
	_check(abs(float(crits) / ROLLS - 0.05) < 0.01, "nat 20 rate not ~5%")

	# Dev tools: forced rolls come out in order, same seed gives the same rolls.
	Dice.forced_rolls = [1, 20]
	_check(Dice.check(99, 2).fumble and Dice.check(-99, 50).crit, "forced rolls ignored")
	_check(Dice.forced_rolls.is_empty(), "forced rolls not used up")
	Dice.rng.seed = 42
	var first: int = Dice.roll(20)
	Dice.rng.seed = 42
	_check(Dice.roll(20) == first, "same seed gave different roll")

	if failed:
		quit(1)
		return
	print("Dice OK  (avg adv %.1f, normal %.1f, dis %.1f, crit rate %.1f%%)" % [avg_adv, avg_norm, avg_dis, 100.0 * crits / ROLLS])
	quit()


func _average(mode: Dice.Mode) -> float:
	var sum: int = 0
	for i in ROLLS:
		sum += Dice.roll_d20(mode)
	return float(sum) / ROLLS


# assert() doesn't stop a headless run, so record failures and exit with code 1.
func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failed = true
