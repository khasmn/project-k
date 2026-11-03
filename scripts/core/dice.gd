class_name Dice
## The one place all game dice are rolled. Never call randi() for game rolls elsewhere.

enum Mode { NORMAL, ADVANTAGE, DISADVANTAGE }

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Testing only: the next dice return these numbers in order, whatever the die.
static var forced_rolls: Array[int] = []


## Roll one die with the given number of sides (d6 = roll(6)).
static func roll(sides: int) -> int:
	if not forced_rolls.is_empty():
		var forced: int = forced_rolls.pop_front()
		if forced < 1 or forced > sides:
			push_error("Forced roll %d doesn't fit a d%d, using %d" % [forced, sides, clampi(forced, 1, sides)])
		return clampi(forced, 1, sides)
	return rng.randi_range(1, sides)


## Shows a roll with its modifier for the log: "14 + 3", "9 - 2".
static func sum_text(natural: int, modifier: int) -> String:
	return "%d %s %d" % [natural, "-" if modifier < 0 else "+", absi(modifier)]


## Roll a d20. Advantage keeps the higher of two rolls, disadvantage the lower.
static func roll_d20(mode: Mode = Mode.NORMAL) -> int:
	var first: int = roll(20)
	if mode == Mode.NORMAL:
		return first
	var second: int = roll(20)
	return maxi(first, second) if mode == Mode.ADVANTAGE else mini(first, second)


## d20 + modifier vs DC. Meet or beat the DC to succeed.
## Natural 20 always succeeds (crit), natural 1 always fails (fumble).
static func check(modifier: int, dc: int, mode: Mode = Mode.NORMAL) -> Dictionary:
	var natural: int = roll_d20(mode)
	var total: int = natural + modifier
	var success: bool = natural == 20 or (natural != 1 and total >= dc)
	return {
		"natural": natural,
		"modifier": modifier,
		"total": total,
		"dc": dc,
		"success": success,
		"crit": natural == 20,
		"fumble": natural == 1,
	}
