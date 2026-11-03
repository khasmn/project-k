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
	return keep(roll_d20s(mode), mode)


## The raw d20s for a roll: one, or two with advantage/disadvantage (to show both in the log).
static func roll_d20s(mode: Mode = Mode.NORMAL) -> Array[int]:
	var rolls: Array[int] = [roll(20)]
	if mode != Mode.NORMAL:
		rolls.append(roll(20))
	return rolls


## The d20 that counts from roll_d20s().
static func keep(rolls: Array[int], mode: Mode) -> int:
	return rolls.max() if mode == Mode.ADVANTAGE else rolls.min()


## d20 + modifier vs DC. Meet or beat the DC to succeed.
## Natural 20 always succeeds (crit), natural 1 always fails (fumble).
## crit_min lowers the crit range (Keen Eye: 19), and a crit always succeeds.
static func check(modifier: int, dc: int, mode: Mode = Mode.NORMAL, crit_min: int = 20) -> Dictionary:
	var rolls: Array[int] = roll_d20s(mode)
	var natural: int = keep(rolls, mode)
	var total: int = natural + modifier
	var success: bool = natural >= crit_min or (natural != 1 and total >= dc)
	return {
		"natural": natural,
		"rolls": rolls,
		"modifier": modifier,
		"total": total,
		"dc": dc,
		"success": success,
		"crit": natural >= crit_min,
		"fumble": natural == 1,
	}
