class_name Combatant
extends RefCounted
## One fighter (hero or enemy): stats, HP, passives, and how it attacks.

const DEFEND_BONUS: int = 4
const MAX_ENERGY: int = 7
const COOLDOWN_EXTRA: int = 2  # a used skill waits its cost + 2 turns (monster skills cost 0: 2 turns)
const SKILL_CHANCE: int = 5  # a monster uses its skill on a d6 roll of 5 or 6

var display_name: String
var max_hp: int
var hp: int
var attack: int
var attack_name: String = "Attack"  # "Magic" for a Mage
var energy_name: String = "Energy"  # "Mana" for a Mage: same rules, another name
var defense: int
var speed: int
var damage_die: int
var weapon: String = "weapon"  # for the log: "sword (d8)"
var sprite: String = ""  # file in assets/sprites/enemies/, a strip of square frames
var exp_reward: int = 0
var gold_reward: int = 0
var luck: int = 0  # forging grade (Gear.forge)
var charisma: int = 0  # haggling (Peddler.haggle)
var charmed: bool = false  # Luck Charm: the next attack rolls with advantage
var power: int = 0  # a companion's skill strength (Howl bonus, Warm Egg heal)
var loot: Dictionary = {}  # what a monster drops when beaten (Gear.loot)
var defending: bool = false
var skills: Array[Dictionary] = []  # from data/skills.json: heroes list "skills", monsters have one "skill"
var start_energy: int = 1  # Energy at your first turn of a fight (Mage: 3 Mana)
var turn: int = 0  # this fighter's turns so far in this fight
var ready_on: Dictionary = {}  # skill name -> the turn it can be used again
var energy: int = 0  # heroes pay a skill's "cost" in Energy; monsters use theirs by chance
var shield: int = 0  # absorbs this much damage, then breaks
var statuses: Dictionary = {}  # "poison"/"burn" -> {"power", "turns"}, "stun" -> true

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
	energy_name = data.get("energy_name", "Energy")
	start_energy = int(data.get("start_energy", 1))
	defense = int(data.defense)
	speed = int(data.speed)
	damage_die = int(data.damage_die)
	weapon = data.get("weapon", "weapon")
	var looks: Variant = data.get("sprite", "")
	sprite = looks[Dice.roll(looks.size()) - 1] if looks is Array else looks  # a list of looks: pick one
	for id: String in data.get("skills", [data.skill] if data.has("skill") else []):
		skills.append(Run.data("skills")[id])
	exp_reward = int(data.get("exp", 0))
	luck = int(data.get("luck", 0))
	charisma = int(data.get("charisma", 0))
	power = int(data.get("power", 0))
	loot = data.get("loot", {})
	gold_reward = int(data.get("gold", 0))
	passive_names = data.get("passive_names", {})
	var effects: Dictionary = data.get("effects", {})
	for effect in effects:
		# JSON numbers come in as floats; the passive variables are ints or bools.
		set(effect, int(effects[effect]) if effects[effect] is float else effects[effect])


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
func attack_mode(target: Combatant, with_advantage: bool = advantage) -> Dice.Mode:
	if not target.defending:
		return Dice.Mode.ADVANTAGE if with_advantage else Dice.Mode.NORMAL
	return Dice.Mode.NORMAL if with_advantage else Dice.Mode.DISADVANTAGE


## Damage bonus from Attack: +1 per 2 points (Attack 5 = +2).
func damage_from_attack() -> int:
	return attack / 2


func passive(effect: String) -> String:
	return passive_names.get(effect, effect.capitalize())


func start_fight() -> void:
	defending = false
	lucky_used = false
	charmed = false
	energy = start_energy - 1  # your first turn adds the 1 back
	turn = 0
	ready_on.clear()
	shield = 0
	statuses.clear()


## Start of this fighter's turn: Defend wears off, +1 Energy, regen heals, poison and burn hurt. Returns log lines or "".
func start_turn() -> String:
	defending = false
	energy = mini(energy + 1, MAX_ENERGY)
	turn += 1
	var lines: PackedStringArray = []
	if regen > 0 and hp < max_hp:
		var healed: int = mini(regen, max_hp - hp)
		hp += healed
		lines.append("%s: %s regenerates %d HP." % [passive("regen"), display_name, healed])
	for status in ["poison", "burn"]:
		if statuses.has(status):
			var hurt: Dictionary = statuses[status]
			hurt.turns -= 1
			if hurt.turns == 0:
				statuses.erase(status)
			lines.append("%s takes %d %s damage." % [display_name, hurt.power, status] + take_damage(hurt.power, false))
	return "\n".join(lines)


## A stunned fighter loses this turn (once).
func shake_off_stun() -> bool:
	return statuses.erase("stun")


## Short status text for the screen, e.g. "Poison 2, Shield 3".
func status_text() -> String:
	var parts: PackedStringArray = []
	for status in statuses:
		parts.append(status.capitalize() + ("" if status == "stun" else " %d" % statuses[status].turns))
	if shield > 0:
		parts.append("Shield %d" % shield)
	return ", ".join(parts)


func win_fight() -> String:
	if heal_on_win == 0 or hp == max_hp:
		return ""
	var healed: int = mini(heal_on_win, max_hp - hp)
	hp += healed
	return "%s: %s heals %d HP." % [passive("heal_on_win"), display_name, healed]


## Lose HP; a shield soaks blockable damage first (not poison or burn). Second Wind turns the first
## lethal hit of the run into 1 HP. Returns a log note or "".
func take_damage(amount: int, blockable: bool = true) -> String:
	var note: String = ""
	if blockable and shield > 0:
		var soaked: int = mini(shield, amount)
		shield -= soaked
		amount -= soaked
		note = " (shield blocks %d%s)" % [soaked, ", shield breaks" if shield == 0 else ""]
	hp = maxi(hp - amount, 0)
	if hp == 0 and second_wind:
		second_wind = false
		hp = 1
		return note + " %s! %s survives with 1 HP." % [passive("second_wind"), display_name]
	return note


## Attack roll (d20 + Attack) vs target's Armor; on a hit, roll damage (always at least 1).
## Damage = weapon die + half Attack. A crit rolls the damage die twice. Returns two log lines, e.g.
## "Warrior attacks Bandit: rolled 14, +5 Attack = 19 vs Armor 10: hit!"
## "    Damage: sword (d8) rolled 7, +2 (half Attack) = 9 damage."
## A skill can change the attack: "to_hit", "advantage", "extra_die" and an "effect" on a hit.
func strike(target: Combatant, move: Dictionary = {}) -> String:
	var line: String = "%s attacks %s: " % [display_name, target.display_name]
	var mode: Dice.Mode = attack_mode(target, advantage or charmed or move.get("advantage", false))
	charmed = false
	var inspired: int = 0  # a companion's Howl: +power to hit and damage for a few attacks
	if statuses.has("inspired"):
		inspired = statuses.inspired.power
		statuses.inspired.turns -= 1
		if statuses.inspired.turns == 0:
			statuses.erase("inspired")
	var to_hit: int = attack + int(move.get("to_hit", 0)) + inspired
	var result: Dictionary = Dice.check(to_hit, target.armor(), mode, crit_min)
	if result.fumble and lucky and not lucky_used:
		lucky_used = true
		line += "rolled %s, a natural 1! %s rerolls: " % [rolled_text(result.rolls, mode, target.display_name), passive("lucky")]
		result = Dice.check(to_hit, target.armor(), mode, crit_min)
	var rolled: String = rolled_text(result.rolls, mode, target.display_name)
	if result.fumble:
		return line + "rolled %s, a natural 1: automatic miss!" % rolled
	if result.crit:
		line += "rolled %s, a natural %d: CRITICAL HIT!" % [rolled, result.natural]
		if result.natural < 20:
			line += " (%s: crits on %d or more)" % [passive("crit_min"), crit_min]
	else:
		line += "rolled %s, %+d %s = %d vs Armor %d: %s" % [rolled, to_hit, attack_name + (" + Inspired" if inspired else ""),
			result.total, target.armor(), "hit!" if result.success else "miss."]
		if not result.success:
			return line

	var rolls: Array[int] = [Dice.roll(damage_die)]
	if result.crit:
		rolls.append(Dice.roll(damage_die))
	if move.has("extra_die"):
		rolls.append(Dice.roll(int(move.extra_die)))
	var dice_total: int = 0
	for roll in rolls:
		dice_total += roll
	var damage_text: String = "%s (d%d) rolled %s" % [weapon, damage_die,
		"twice: %d + %d" % [rolls[0], rolls[1]] if result.crit else str(rolls[0])]
	if move.has("extra_die"):
		damage_text += ", +d%d rolled %d" % [move.extra_die, rolls[-1]]
	var bonus: int = damage_from_attack() + damage_bonus + inspired
	damage_text += ", %+d (half %s)" % [damage_from_attack(), attack_name]
	if inspired:
		damage_text += ", %+d Inspired" % inspired
	if damage_bonus != 0:
		damage_text += ", %+d %s" % [damage_bonus, passive("damage_bonus")]
	var damage: int = maxi(dice_total + bonus, 1)
	damage_text += " = %d damage" % damage
	if dice_total + bonus < 1:
		damage_text += " (minimum 1)"
	line += "\n    Damage: " + damage_text + "." + target.take_damage(damage)
	if move.has("effect") and target.is_alive() and (result.crit or not move.effect.get("crit_only", false)):
		line += "\n    " + afflict(target, move.effect)
	return line


## The save target for this fighter's skills: 10 + its Attack (or Magic).
func save_dc() -> int:
	return 10 + attack


## The target saves (d20 + a stat vs this fighter's save DC) or gets the effect. No "save" = no way to resist.
func afflict(target: Combatant, effect: Dictionary) -> String:
	var name: String = effect.status.capitalize()
	if effect.has("save"):
		var stat: int = target.get(effect.save)
		var result: Dictionary = Dice.check(stat, save_dc())
		var line: String = "%s save: rolled %d, %+d %s = %d vs %d: " % [effect.save.capitalize(), result.natural, stat,
			effect.save.capitalize(), result.total, save_dc()]
		if result.success:
			return line + "resists!"
		return line + _set_status(target, effect, name)
	return _set_status(target, effect, name)


func _set_status(target: Combatant, effect: Dictionary, name: String) -> String:
	if effect.status == "stun":
		target.statuses.stun = true
		return "%s is stunned and loses its next turn!" % target.display_name
	target.statuses[effect.status] = {"power": int(effect.power), "turns": int(effect.turns)}
	return "%s: %d damage a turn for %d turns!" % [name, effect.power, effect.turns]


static func cooldown(skill: Dictionary) -> int:
	return int(skill.get("cost", 0)) + COOLDOWN_EXTRA


## How many more turns before this skill can be used again (0 = ready).
func skill_wait(skill: Dictionary) -> int:
	return maxi(int(ready_on.get(skill.name, 0)) - turn, 0)


## Use one of this fighter's skills. foes: who it can hit (the target first); allies: its own side (itself included).
func use_skill(skill: Dictionary, foes: Array[Combatant], allies: Array[Combatant]) -> String:
	energy -= int(skill.get("cost", 0))
	ready_on[skill.name] = turn + cooldown(skill) + 1
	var lines: PackedStringArray = ["%s uses %s!" % [display_name, skill.name]]
	if skill.has("shield"):
		var shielded: Array = allies if skill.get("shield_all", false) else [self]
		for ally: Combatant in shielded:
			ally.shield += int(skill.shield)
			lines.append("    %s gains Shield %d." % [ally.display_name, ally.shield])
	elif skill.has("heal"):
		var healed: int = mini(power, allies[0].max_hp - allies[0].hp)
		allies[0].hp += healed
		lines.append("    %s heals %d HP." % [allies[0].display_name, healed])
	elif skill.has("buff"):
		allies[0].statuses[skill.buff] = {"power": power, "turns": int(skill.turns)}
		lines.append("    %s is %s: %+d to hit and damage on the next %d attacks." % [allies[0].display_name, skill.buff, power, skill.turns])
	elif skill.has("save"):
		for foe in (foes if skill.get("area", "") == "all" else foes.slice(0, 1)):
			lines.append(_blast(foe, skill))
	else:
		for i in int(skill.get("attacks", 1)):
			if foes[0].is_alive():
				lines.append(strike(foes[0], skill))
	return "\n".join(lines)


## A save-based attack (no attack roll): fail = full damage and the effect, pass = half damage.
func _blast(foe: Combatant, skill: Dictionary) -> String:
	var stat: int = foe.get(skill.save)
	var result: Dictionary = Dice.check(stat, save_dc())
	var die: int = int(skill.get("damage_die", damage_die))
	var full: int = Dice.roll(die) + damage_from_attack()
	var damage: int = maxi(full / 2 if result.success else full, 1)
	var line: String = "%s: %s save rolled %d, %+d = %d vs %d: %s %d damage." % [foe.display_name,
		skill.save.capitalize(), result.natural, stat, result.total, save_dc(),
		"pass, half:" if result.success else "fail!", damage] + foe.take_damage(damage)
	if not result.success and foe.is_alive():
		line += " " + _set_status(foe, skill.effect, skill.effect.status.capitalize())
	return line


## More Max HP also heals the same amount.
func raise_stat(stat: String, amount: int) -> void:
	if stat == "max_hp":
		max_hp += amount
		hp += amount
	else:
		set(stat, int(get(stat)) + amount)
