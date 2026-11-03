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


## Attack roll vs target's Armor; on a hit, roll damage. Nat 20 doubles damage.
## Returns a log line like "Hero: 14 + 3 = 17 vs Armor 11, hit! 7 damage."
func strike(target: Combatant) -> String:
	var result: Dictionary = Dice.check(attack, target.armor())
	var line: String = "%s: %d + %d = %d vs Armor %d" % [
		display_name, result.natural, attack, result.total, target.armor()]
	if not result.success:
		return line + (", nat 1, stumbles!" if result.fumble else ", miss.")
	var damage: int = Dice.roll(damage_die) + attack
	if result.crit:
		damage *= 2
	target.hp = maxi(target.hp - damage, 0)
	return line + (", CRITICAL HIT! %d damage." if result.crit else ", hit! %d damage.") % damage
