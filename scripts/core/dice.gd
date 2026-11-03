class_name Dice
## The one place all game dice are rolled. Never call randi() for game rolls elsewhere.

enum Mode { NORMAL, ADVANTAGE, DISADVANTAGE }

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Roll one die with the given number of sides (d6 = roll(6)).
static func roll(sides: int) -> int:
	return rng.randi_range(1, sides)


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
