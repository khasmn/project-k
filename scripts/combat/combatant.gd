class_name Combatant
extends RefCounted
## One fighter (hero or enemy): stats, HP, passives, and how it attacks.

const DEFEND_BONUS: int = 4

var display_name: String
var max_hp: int
var hp: int
var attack: int
var attack_name: String = "Attack"  # "Magic" for a Mage
var defense: int
var speed: int
var damage_die: int
var weapon: String = "weapon"  # for the log: "sword (d8)"
var exp_reward: int = 0  # EXP the hero gets for beating this enemy
var gold_reward: int = 0
var defending: bool = false

# Passives, set from the "effects" of a race or talent in data/. Enemies have none.
var damage_bonus: int = 0  # Glass Cannon
var crit_min: int = 20  # Keen Eye: 19
var advantage: bool = false  # Chosen One
var lucky: bool = false  # Lucky: first nat 1 each fight is rerolled
var regen: int = 0  # Mossfolk: HP at the start of each turn
var wins_ties: bool = false  # Elf
var heal_on_win: int = 0  # Bloodlust
var second_wind: bool = false  # Second Wind: once per run, survive a lethal hit at 1 HP
var lucky_used: bool = false
var passive_names: Dictionary = {}  # effect -> race/talent name, e.g. {"advantage": "Chosen One"}


func _init(data: Dictionary) -> void:
	display_name = data.name
	max_hp = int(data.hp)
	hp = max_hp
	attack = int(data.attack)
	attack_name = data.get("attack_name", "Attack")
	defense = int(data.defense)
	speed = int(data.speed)
	damage_die = int(data.damage_die)
	weapon = data.get("weapon", "weapon")
	exp_reward = int(data.get("exp", 0))
	gold_reward = int(data.get("gold", 0))
	passive_names = data.get("passive_names", {})
	var effects: Dictionary = data.get("effects", {})
	for effect in effects:
		# JSON numbers come in as floats; the passive variables are ints or bools.
		set(effect, int(effects[effect]) if effects[effect] is float else effects[effect])


## Load one entry (e.g. "bandit") from a JSON file in data/.
static func load_from(path: String, id: String) -> Combatant:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Combatant.new(all[id])


## The number an attacker's roll must meet or beat to hit this fighter.
func armor() -> int:
	return 10 + defense + (DEFEND_BONUS if defending else 0)


func is_alive() -> bool:
	return hp > 0


func roll_mode() -> Dice.Mode:
	return Dice.Mode.ADVANTAGE if advantage else Dice.Mode.NORMAL


## How a d20 roll reads in the log: "14", "9 and 15 (Chosen One keeps 15)" or "9 and 15 (Hero defends, keeps 9)".
func rolled_text(rolls: Array[int], mode: Dice.Mode = roll_mode(), defender: String = "") -> String:
	if rolls.size() < 2:
		return str(rolls[0])
	var reason: String = passive("advantage") if mode == Dice.Mode.ADVANTAGE else defender + " defends,"
	return "%d and %d (%s keeps %d)" % [rolls[0], rolls[1], reason, Dice.keep(rolls, mode)]


## Attacking a defending target rolls with disadvantage (it cancels out advantage, like in D&D).
func attack_mode(target: Combatant) -> Dice.Mode:
	if not target.defending:
		return roll_mode()
	return Dice.Mode.NORMAL if advantage else Dice.Mode.DISADVANTAGE


## Damage bonus from Attack: +1 per 2 points (Attack 5 = +2).
func damage_from_attack() -> int:
	return attack / 2


## The race or talent name behind an effect, for the log.
func passive(effect: String) -> String:
	return passive_names.get(effect, effect.capitalize())


func start_fight() -> void:
	defending = false
	lucky_used = false


## Start of this fighter's turn: Defend wears off, regen heals. Returns a log line or "".
func start_turn() -> String:
	defending = false
	if regen == 0 or hp == max_hp:
		return ""
	var healed: int = mini(regen, max_hp - hp)
	hp += healed
	return "%s: %s regenerates %d HP." % [passive("regen"), display_name, healed]


## Called after winning a fight. Returns a log line or "".
func win_fight() -> String:
	if heal_on_win == 0 or hp == max_hp:
		return ""
	var healed: int = mini(heal_on_win, max_hp - hp)
	hp += healed
	return "%s: %s heals %d HP." % [passive("heal_on_win"), display_name, healed]


## Lose HP. Second Wind turns the first lethal hit of the run into 1 HP. Returns a log note or "".
func take_damage(amount: int) -> String:
	hp = maxi(hp - amount, 0)
	if hp == 0 and second_wind:
		second_wind = false
		hp = 1
		return " %s! %s survives with 1 HP." % [passive("second_wind"), display_name]
	return ""


## Attack roll (d20 + Attack) vs target's Armor; on a hit, roll damage (always at least 1).
## Damage = weapon die + half Attack. A crit rolls the damage die twice. Returns two log lines, e.g.
## "Warrior attacks Bandit: rolled 14, +5 Attack = 19 vs Armor 10: hit!"
## "    Damage: sword (d8) rolled 7, +2 (half Attack) = 9 damage."
func strike(target: Combatant) -> String:
	var line: String = "%s attacks %s: " % [display_name, target.display_name]
	var mode: Dice.Mode = attack_mode(target)
	var result: Dictionary = Dice.check(attack, target.armor(), mode, crit_min)
	if result.fumble and lucky and not lucky_used:
		lucky_used = true
		line += "rolled %s, a natural 1! %s rerolls: " % [rolled_text(result.rolls, mode, target.display_name), passive("lucky")]
		result = Dice.check(attack, target.armor(), mode, crit_min)
	var rolled: String = rolled_text(result.rolls, mode, target.display_name)
	if result.fumble:
		return line + "rolled %s, a natural 1: automatic miss!" % rolled
	if result.crit:
		line += "rolled %s, a natural %d: CRITICAL HIT!" % [rolled, result.natural]
		if result.natural < 20:
			line += " (%s: crits on %d or more)" % [passive("crit_min"), crit_min]
	else:
		line += "rolled %s, %+d %s = %d vs Armor %d: %s" % [rolled, attack, attack_name,
			result.total, target.armor(), "hit!" if result.success else "miss."]
		if not result.success:
			return line

	var rolls: Array[int] = [Dice.roll(damage_die)]
	if result.crit:
		rolls.append(Dice.roll(damage_die))
	var dice_total: int = rolls[0] + (rolls[1] if rolls.size() > 1 else 0)
	var damage_text: String = "%s (d%d) rolled %s" % [weapon, damage_die,
		"twice: %d + %d" % [rolls[0], rolls[1]] if result.crit else str(rolls[0])]
	var bonus: int = damage_from_attack() + damage_bonus
	damage_text += ", %+d (half %s)" % [damage_from_attack(), attack_name]
	if damage_bonus != 0:
		damage_text += ", %+d %s" % [damage_bonus, passive("damage_bonus")]
	var damage: int = maxi(dice_total + bonus, 1)
	damage_text += " = %d damage" % damage
	if dice_total + bonus < 1:
		damage_text += " (minimum 1)"
	return line + "\n    Damage: " + damage_text + "." + target.take_damage(damage)


## Raise a stat (stat points at level-up). More Max HP also heals the same amount.
func raise_stat(stat: String, amount: int) -> void:
	if stat == "max_hp":
		max_hp += amount
		hp += amount
	else:
		set(stat, int(get(stat)) + amount)
