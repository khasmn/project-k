class_name Combatant
extends RefCounted
## One fighter (hero or enemy): stats, HP, and how it attacks.

const DEFEND_BONUS: int = 2

var display_name: String
var max_hp: int
var hp: int
var attack: int
var defense: int
var speed: int
var damage_die: int
var defending: bool = false


func _init(data: Dictionary) -> void:
	display_name = data.name
	max_hp = int(data.hp)
	hp = max_hp
	attack = int(data.attack)
	defense = int(data.defense)
	speed = int(data.speed)
	damage_die = int(data.damage_die)


## Load one entry (e.g. "bandit") from a JSON file in data/.
static func load_from(path: String, id: String) -> Combatant:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Combatant.new(all[id])


## The number an attacker's roll must meet or beat to hit this fighter.
func armor() -> int:
	return 10 + defense + (DEFEND_BONUS if defending else 0)


func is_alive() -> bool:
	return hp > 0


## Attack roll vs target's Armor; on a hit, roll damage (always at least 1). Nat 20 doubles damage.
## Returns a log line like "Hero: 14 + 3 = 17 vs Armor 11, hit! d8: 4 + 3 = 7 damage."
func strike(target: Combatant) -> String:
	var result: Dictionary = Dice.check(attack, target.armor())
	var line: String = "%s: %s = %d vs Armor %d" % [
		display_name, Dice.sum_text(result.natural, attack), result.total, target.armor()]
	if not result.success:
		return line + (", nat 1, automatic miss!" if result.fumble else ", miss.")
	var damage_roll: int = Dice.roll(damage_die)
	var damage: int = maxi(damage_roll + attack, 1)
	var damage_text: String = "d%d: %s" % [damage_die, Dice.sum_text(damage_roll, attack)]
	if result.crit:
		damage *= 2
		line += ", CRITICAL HIT! (%s) x 2" % damage_text
	else:
		line += ", hit! " + damage_text
	target.hp = maxi(target.hp - damage, 0)
	line += " = %d damage" % damage
	return line + (" (minimum)." if damage_roll + attack < 1 else ".")
