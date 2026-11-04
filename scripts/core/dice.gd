class_name Dice
## The one place all game dice are rolled. Never call randi() for game rolls elsewhere.

enum Mode { NORMAL, ADVANTAGE, DISADVANTAGE }

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Testing only: the next dice return these numbers in order, whatever the die.
static var forced_rolls: Array[int] = []
## When on, every roll is noted as [sides, result] so the battle screen can show it (DiceTray).
static var recording: bool = false
static var history: Array = []


static func roll(sides: int, shown: bool = true) -> int:
	var result: int
	if forced_rolls.is_empty():
		result = rng.randi_range(1, sides)
	else:
		var forced: int = forced_rolls.pop_front()
		if forced < 1 or forced > sides:
			push_error("Forced roll %d doesn't fit a d%d, using %d" % [forced, sides, clampi(forced, 1, sides)])
		result = clampi(forced, 1, sides)
	if recording and shown:
		history.append([sides, result])
	return result


## Roll a d20. Advantage keeps the higher of two rolls, disadvantage the lower.
static func roll_d20(mode: Mode = Mode.NORMAL) -> int:
	return keep(roll_d20s(mode), mode)


## The raw d20s for a roll: one, or two with advantage/disadvantage (to show both in the log).
static func roll_d20s(mode: Mode = Mode.NORMAL) -> Array[int]:
	var rolls: Array[int] = [roll(20)]
	if mode != Mode.NORMAL:
		rolls.append(roll(20))
	return rolls


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
		"total": total,
		"success": success,
		"crit": natural >= crit_min,
		"fumble": natural == 1,
	}
