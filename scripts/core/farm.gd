class_name Farm
## The Farm in town: buy baby animals (data/animals.json), name them, pick one to come along.
## Some monsters drop eggs (loot "egg"); an egg hatches the next time you open the Farm.
## The companion fights on its own after the hero and grows with every won fight: Baby -> Young -> Adult.
## An animal is {"kind", "name", "exp"}; it lives in Run.animals.

const MAX_ANIMALS: int = 4
const GROW_EXP: Array[int] = [20, 60]  # EXP to become Young, then Adult


## A beaten monster may drop its egg: loot d20 >= "egg_roll". Eggs need a free barn place. Returns a log line or "".
static func egg_drop(foe: Combatant) -> String:
	var kind: String = foe.loot.get("egg", "")
	if not kind:
		return ""
	var rolled: int = Dice.roll(20)
	if rolled < int(foe.loot.egg_roll):
		return ""
	var egg: String = Run.data("animals")[kind].egg
	if Run.animals.size() + Run.eggs.size() >= MAX_ANIMALS:
		return "Egg roll %d: %s dropped a %s, but your barn is full. It rolls away." % [rolled, foe.display_name, egg]
	Run.eggs.append(kind)
	return "Egg roll %d: %s dropped a %s! It will hatch at the Farm." % [rolled, foe.display_name, egg]


## Every egg you carry hatches into a baby (opening the Farm). Returns the new animals.
static func hatch() -> Array[Dictionary]:
	var born: Array[Dictionary] = []
	for kind in Run.eggs:
		born.append(_add(kind))
	Run.eggs.clear()
	return born


## Let an animal go to make room; the one coming along stays the same animal.
static func release(index: int) -> void:
	Run.animals.remove_at(index)
	if Run.companion == index:
		Run.companion = -1
	elif Run.companion > index:
		Run.companion -= 1


static func can_buy(kind: String) -> bool:
	return Run.gold >= int(Run.data("animals")[kind].price) and Run.animals.size() + Run.eggs.size() < MAX_ANIMALS


static func buy(kind: String) -> Dictionary:
	Run.gold -= int(Run.data("animals")[kind].price)
	return _add(kind)


## A new baby with a random name; the first animal comes along by itself.
static func _add(kind: String) -> Dictionary:
	var data: Dictionary = Run.data("animals")[kind]
	var animal: Dictionary = {"kind": kind, "name": data.names[Dice.roll(data.names.size(), false) - 1], "exp": 0}
	Run.animals.append(animal)
	if Run.companion == -1:
		Run.companion = Run.animals.size() - 1
	return animal


## 0 baby, 1 young, 2 adult.
static func stage(animal: Dictionary) -> int:
	return GROW_EXP.filter(func(needed: int) -> bool: return animal.exp >= needed).size()


## This animal's stats now: its stage's entry with its name, weapon and skill.
static func stats(animal: Dictionary) -> Dictionary:
	var data: Dictionary = Run.data("animals")[animal.kind]
	var stats: Dictionary = data.stages[stage(animal)].duplicate()
	stats.merge({"stage_name": stats.name, "name": animal.name, "weapon": data.weapon, "skill": data.skill}, true)
	return stats


static func picture(animal: Dictionary) -> String:
	return "res://assets/sprites/animals/%s_%d.png" % [animal.kind, stage(animal)]


## The animal coming along this fight (null if none), always at full HP.
static func companion() -> Combatant:
	return Combatant.new(stats(Run.animals[Run.companion])) if Run.companion >= 0 else null


## "Fang: Howl, +1 to hit and damage on the next 2 attacks." for the Farm list and tooltips.
static func skill_text(animal: Dictionary) -> String:
	var skill: Dictionary = Run.data("skills")[stats(animal).skill]
	return "%s: %s" % [skill.name, skill.description.format({"power": int(stats(animal).power)})]


## A won fight: the companion gets the monsters' EXP. Returns the log line (with growing up, if it does).
static func gain_exp(amount: int) -> String:
	var animal: Dictionary = Run.animals[Run.companion]
	var before: int = stage(animal)
	animal.exp += amount
	var line: String = "%s +%d EXP." % [animal.name, amount]
	if stage(animal) > before:
		line += " %s grew into a %s!" % [animal.name, stats(animal).stage_name]
	return line


## "Fang the Puppy, EXP 5 / 20" (adults: "EXP 63").
static func title(animal: Dictionary) -> String:
	var growing: String = " / %d" % GROW_EXP[stage(animal)] if stage(animal) < GROW_EXP.size() else ""
	return "%s the %s, EXP %d%s" % [animal.name, stats(animal).stage_name, animal.exp, growing]
