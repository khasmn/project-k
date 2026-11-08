class_name RoomEvent
## The event door: a short scene from data/events.json with choices. A choice may cost gold ("gold_cost")
## and may be a check (d20 + "stat" vs "dc"). Its "success" or "fail" outcome can give or take gold, HP,
## EXP, items, materials, or change the next fight: "first", "stun_foes", "poison", "ally", "elite", "skip".

const POISON: Dictionary = {"power": 1, "turns": 3}


## A random event of this chapter not seen this run (all seen: any of them). Events without "chapters" go anywhere.
static func pick() -> String:
	var all: Dictionary = Run.data("events")
	var ids: Array = all.keys().filter(func(id: String) -> bool: return Run.chapter in all[id].get("chapters", [Run.chapter]))
	var fresh: Array = ids.filter(func(id: String) -> bool: return not id in Run.events_seen)
	var pool: Array = fresh if fresh else ids
	return pool[0] if pool.size() == 1 else pool[Dice.roll(pool.size(), false) - 1]


static func can_choose(choice: Dictionary) -> bool:
	return Run.gold >= int(choice.get("gold_cost", 0))


## "Charisma +1 vs DC 14", "20 gold" or "No check".
static func check_text(choice: Dictionary) -> String:
	if choice.has("stat"):
		return "%s %+d vs DC %d" % [stat_name(choice.stat), Run.hero.get(choice.stat), choice.dc]
	return "%d gold" % choice.gold_cost if choice.has("gold_cost") else "No check"


## The stat as the hero calls it ("Magic" for a Mage's attack).
static func stat_name(stat: String) -> String:
	return Run.hero.attack_name if stat == "attack" else stat.capitalize()


## Make the choice: pay, roll, apply the outcome. Returns {"success", "skip", "text"}.
static func choose(choice: Dictionary) -> Dictionary:
	Run.gold -= int(choice.get("gold_cost", 0))
	var success: bool = true
	var lines: PackedStringArray = []
	if choice.has("stat"):
		var bonus: int = Run.hero.get(choice.stat)
		var result: Dictionary = Dice.check(bonus, int(choice.dc), Run.hero.roll_mode())
		success = result.success
		lines.append("Rolled %s %+d %s = %d vs DC %d: %s" % [Run.hero.rolled_text(result.rolls), bonus, stat_name(choice.stat), result.total,
			choice.dc, "success!" if success else "failure."])
	var outcome: Dictionary = choice.success if success else choice.get("fail", {})
	lines.append(outcome.get("text", ""))
	lines.append_array(_apply(outcome))
	return {"success": success, "skip": outcome.get("skip", false), "text": "\n".join(lines).strip_edges()}


## Rewards and costs now; next-fight effects wait in Run.next_fight. Returns short lines like "+15 gold".
static func _apply(outcome: Dictionary) -> PackedStringArray:
	var hero: Combatant = Run.hero
	var lines: PackedStringArray = []
	if outcome.has("gold"):
		var gold: int = maxi(int(outcome.gold), -Run.gold)  # never below 0 gold
		Run.gold += gold
		lines.append("%+d gold" % gold)
	if outcome.has("heal_percent"):
		var healed: int = mini(ceili(hero.max_hp * outcome.heal_percent / 100.0), hero.max_hp - hero.hp)
		hero.hp += healed
		lines.append("+%d HP" % healed)
	if outcome.has("damage"):
		var hurt: int = mini(int(outcome.damage), hero.hp - 1)  # an event never kills
		hero.hp -= hurt
		lines.append("-%d HP" % hurt)
	if outcome.has("exp"):
		var levels: int = Run.gain_exp(int(outcome.exp))
		lines.append("+%d EXP" % outcome.exp + (" - Level up! +%d stat points" % (levels * Run.POINTS_PER_LEVEL) if levels else ""))
	for id: String in outcome.get("items", {}):
		Run.items[id] = Run.items.get(id, 0) + int(outcome.items[id])
		lines.append("+%d %s" % [outcome.items[id], Run.data("items")[id].name])
	for id: String in outcome.get("materials", {}):
		Run.materials[id] = Run.materials.get(id, 0) + int(outcome.materials[id])
		lines.append("+%d %s" % [outcome.materials[id], Run.data("materials")[id].name])
	if outcome.get("elite", false):
		Run.room_type = "elite"
		lines.append("The next fight is an ELITE fight!")
	for effect: String in ["first", "stun_foes", "poison", "ally"]:
		if outcome.has(effect):
			Run.next_fight[effect] = outcome[effect]
	return lines
