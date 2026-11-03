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


func _init(data: Dictionary) -> void:
	display_name = data.name
	max_hp = int(data.hp)
	hp = max_hp
	attack = int(data.attack)
	attack_name = data.get("attack_name", "Attack")
	defense = int(data.defense)
	speed = int(data.speed)
	damage_die = int(data.damage_die)
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
	return "%s regenerates %d HP." % [display_name, healed]


## Called after winning a fight. Returns a log line or "".
func win_fight() -> String:
	if heal_on_win == 0 or hp == max_hp:
		return ""
	var healed: int = mini(heal_on_win, max_hp - hp)
	hp += healed
	return "Bloodlust: %s heals %d HP." % [display_name, healed]


## Lose HP. Second Wind turns the first lethal hit of the run into 1 HP. Returns a log note or "".
func take_damage(amount: int) -> String:
	hp = maxi(hp - amount, 0)
	if hp == 0 and second_wind:
		second_wind = false
		hp = 1
		return " Second Wind! %s survives with 1 HP." % display_name
	return ""


## Attack roll vs target's Armor; on a hit, roll damage (always at least 1).
## A crit rolls the damage die twice.
## Returns a log line like "Hero: 14 + 3 = 17 vs Armor 11, hit! d8: 4 + 3 = 7 damage."
func strike(target: Combatant) -> String:
	var line: String = ""
	var result: Dictionary = Dice.check(attack, target.armor(), roll_mode(), crit_min)
	if result.fumble and lucky and not lucky_used:
		lucky_used = true
		line = "%s rolls a nat 1, Lucky rerolls! " % display_name
		result = Dice.check(attack, target.armor(), roll_mode(), crit_min)
	line += "%s: %s = %d vs Armor %d" % [
		display_name, Dice.sum_text(result.natural, attack), result.total, target.armor()]
	if not result.success:
		return line + (", nat 1, automatic miss!" if result.fumble else ", miss.")
	var bonus: int = attack + damage_bonus
	var damage_roll: int = Dice.roll(damage_die)
	var damage_text: String = "d%d: %s" % [damage_die, Dice.sum_text(damage_roll, bonus)]
	if result.crit:
		var extra_roll: int = Dice.roll(damage_die)
		damage_text = "2d%d: %d + %s" % [damage_die, damage_roll, Dice.sum_text(extra_roll, bonus)]
		damage_roll += extra_roll
	var damage: int = maxi(damage_roll + bonus, 1)
	line += (", CRITICAL HIT! " if result.crit else ", hit! ") + damage_text
	line += " = %d damage" % damage + (" (minimum)." if damage_roll + bonus < 1 else ".")
	return line + target.take_damage(damage)


## Level-up upgrade from data/upgrades.json, e.g. {"stat": "defense", "amount": 1}.
func apply_upgrade(upgrade: Dictionary) -> void:
	var amount: int = int(upgrade.amount)
	if upgrade.stat == "max_hp":
		max_hp += amount
		hp += amount
	else:
		set(upgrade.stat, int(get(upgrade.stat)) + amount)


func upgrade_text(upgrade: Dictionary) -> String:
	return upgrade.text.replace("{attack}", attack_name)
