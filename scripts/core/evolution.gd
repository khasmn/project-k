class_name Evolution
## The level 10 class change (data/evolutions.json): the hero picks 1 of 2 advanced classes for its base class,
## keeps its 2 skills, learns 2 new ones and gets a stat boost. One change per run (Run.evolution).

const LEVEL: int = 10


## True when the hero is level 10+ and hasn't picked yet.
static func ready() -> bool:
	return Run.level >= LEVEL and Run.evolution == "" and not choices().is_empty()


## The 2 advanced class ids for the hero's base class.
static func choices() -> Array:
	var all: Dictionary = Run.data("evolutions")
	return all.keys().filter(func(id: String) -> bool: return all[id].from == Run.hero_look.get("class", ""))


## "Defense +2, Max HP +6". Attack says Magic for a Mage.
static func boost_text(id: String) -> String:
	var parts: PackedStringArray = []
	var boost: Dictionary = Run.data("evolutions")[id].boost
	for stat: String in boost:
		parts.append("%s %+d" % [Run.hero.attack_name if stat == "attack" else Gear.STAT_NAMES[stat], boost[stat]])
	return ", ".join(parts)


static func evolve(id: String) -> void:
	var entry: Dictionary = Run.data("evolutions")[id]
	Run.evolution = id
	for stat: String in entry.boost:
		Run.hero.raise_stat(stat, int(entry.boost[stat]))
	for skill: String in entry.skills:
		Run.hero.skills.append(Run.data("skills")[skill])
