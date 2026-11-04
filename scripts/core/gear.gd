class_name Gear
## Gear rules: buying, selling, wearing, taking off and forging (data/gear.json, data/recipes.json).
## A piece is {"id": gear id, "grade": index in GRADES, "plus": upgrade level 0-3}. Shop gear is Common;
## forged gear rolls its grade. Upgrades add to the main stat too.
## The state lives in Run: Run.bag (pieces you carry) and Run.gear (slot -> piece you wear). Worn gear adds
## its stats to the hero and shows on the hero sprite (helmet, armor, shield; a weapon gets a "tint").

const SELL_RATE: float = 0.5  # gear sells back for half its price
const STAT_NAMES: Dictionary = {"defense": "Defense", "max_hp": "Max HP", "speed": "Speed"}
## Forging: d20 + Luck. [name, lowest total, bonus to the main (first) stat, color]. A natural 20 is at least Epic.
const GRADES: Array = [
	["Crude", 0, -1, Color(0.6, 0.6, 0.6)], ["Common", 6, 0, Color.WHITE], ["Uncommon", 12, 1, Color(0.4, 0.85, 0.4)],
	["Rare", 16, 2, Color(0.4, 0.6, 1.0)], ["Epic", 19, 3, Color(0.75, 0.4, 0.95)], ["Legendary", 22, 4, Color(1.0, 0.6, 0.15)],
]
const COMMON: int = 1
const EPIC: int = 4
## Upgrading +0 -> +1 -> +2 -> +3: d20 + Luck vs these DCs. Costs 2/3/4 of the piece's "upgrade" material
## and 10/20/30 gold. Fail: the cost is gone. Natural 1: also -1 level. Beat the DC by 10+: +2 levels.
const UPGRADE_DCS: Array[int] = [6, 10, 14]
const MAX_PLUS: int = 3
const BIG_SUCCESS: int = 10


static func entry(id: String) -> Dictionary:
	return Run.data("gear")[id]


## The 16x16 picture of a gear piece, an item or a material (assets/sprites/items/<id>.png).
static func icon(id: String) -> Texture2D:
	return load("res://assets/sprites/items/%s.png" % id)


static func piece(id: String, grade: int = COMMON) -> Dictionary:
	return {"id": id, "grade": grade, "plus": 0}


## "Rare Steel Helm +2"; Common pieces just use the name.
static func title(item: Dictionary) -> String:
	var name: String = entry(item.id).name if item.grade == COMMON else "%s %s" % [GRADES[item.grade][0], entry(item.id).name]
	return name + (" +%d" % item.plus if item.plus else "")


static func color(item: Dictionary) -> Color:
	return GRADES[item.grade][3]


## The piece's stats with its grade bonus and upgrade level added to the main (first) stat.
static func stats(item: Dictionary) -> Dictionary:
	var result: Dictionary = entry(item.id).stats.duplicate()
	result[result.keys()[0]] += GRADES[item.grade][2] + item.plus
	return result


## Some gear is for certain classes only ("classes"); everything else fits anyone.
static func fits(id: String) -> bool:
	var classes: Array = entry(id).get("classes", [])
	return classes.is_empty() or Run.hero_look.get("class", "") in classes


static func buy(id: String) -> void:
	Run.gold -= int(entry(id).price)
	Run.bag.append(piece(id))


static func sell_price(item: Dictionary) -> int:
	return maxi(1, int(entry(item.id).price * SELL_RATE) + 5 * GRADES[item.grade][2])


static func sell(item: Dictionary) -> void:
	Run.bag.erase(item)
	Run.gold += sell_price(item)


## Wear a piece from the bag; whatever was in its slot goes back to the bag.
static func wear(item: Dictionary) -> void:
	var slot: String = entry(item.id).slot
	if slot == "jewelry":  # two jewelry slots: the first free one, or swap the first
		slot = "jewelry2" if Run.gear.has("jewelry1") and not Run.gear.has("jewelry2") else "jewelry1"
	if Run.gear.has(slot):
		take_off(slot)
	Run.bag.erase(item)
	Run.gear[slot] = item
	_apply(item, 1)


static func take_off(slot: String) -> void:
	var item: Dictionary = Run.gear[slot]
	Run.gear.erase(slot)
	Run.bag.append(item)
	_apply(item, -1)


## "+1 Defense, -1 Speed". Attack says Magic for a Mage.
static func bonus_text(item: Dictionary) -> String:
	var parts: PackedStringArray = []
	var all: Dictionary = stats(item)
	for stat in all:
		parts.append("%+d %s" % [all[stat], Run.hero.attack_name if stat == "attack" else STAT_NAMES[stat]])
	return ", ".join(parts)


## A recipe can be forged when it's known (basic and Starmetal always, blueprints once found) and fits the class.
static func known(id: String) -> bool:
	var recipe: Dictionary = Run.data("recipes")[id]
	return fits(id) and (recipe.section != "blueprint" or id in Run.blueprints)


static func can_forge(id: String) -> bool:
	var recipe: Dictionary = Run.data("recipes")[id]
	for material in recipe.materials:
		if Run.materials.get(material, 0) < recipe.materials[material]:
			return false
	return known(id) and Run.gold >= recipe.gold


## Pay the materials and gold, roll d20 + Luck for the grade, put the piece in the bag.
## Returns {"item", "text", "outcome"} for the Blacksmith window ("forge", or "great" for Epic and better).
static func forge(id: String) -> Dictionary:
	var recipe: Dictionary = Run.data("recipes")[id]
	for material in recipe.materials:
		Run.materials[material] -= recipe.materials[material]
	Run.gold -= int(recipe.gold)
	var rolled: int = Dice.roll(20)
	var total: int = rolled + Run.hero.luck
	var grade: int = 0
	while grade + 1 < GRADES.size() and total >= GRADES[grade + 1][1]:
		grade += 1
	if rolled == 20:
		grade = maxi(grade, EPIC)
	var item: Dictionary = piece(id, grade)
	Run.bag.append(item)
	return {"item": item, "outcome": "great" if grade >= EPIC else "forge",
		"text": "Forged %s! Rolled %d %+d Luck = %d: %s." % [title(item), rolled, Run.hero.luck, total, GRADES[grade][0].to_upper()]}


## {"material", "count", "gold"} to take this piece one level up.
static func upgrade_cost(item: Dictionary) -> Dictionary:
	return {"material": entry(item.id).upgrade, "count": 2 + item.plus, "gold": 10 * (item.plus + 1)}


static func can_upgrade(item: Dictionary) -> bool:
	var cost: Dictionary = upgrade_cost(item)
	return item.plus < MAX_PLUS and Run.materials.get(cost.material, 0) >= cost.count and Run.gold >= cost.gold


## Pay, roll d20 + Luck vs the DC, change the level (also when worn). Returns like forge;
## outcome is "upgrade", "upgrade2" (beat the DC by 10+), "fail" or "down" (natural 1).
static func upgrade(item: Dictionary) -> Dictionary:
	var cost: Dictionary = upgrade_cost(item)
	Run.materials[cost.material] -= cost.count
	Run.gold -= cost.gold
	var dc: int = UPGRADE_DCS[item.plus]
	var rolled: int = Dice.roll(20)
	var total: int = rolled + Run.hero.luck
	var outcome: String = "fail"
	var change: int = 0
	if rolled == 1:
		outcome = "down" if item.plus > 0 else "fail"
		change = -1 if item.plus > 0 else 0
	elif rolled == 20 or total >= dc:
		change = 2 if total >= dc + BIG_SUCCESS and item.plus + 2 <= MAX_PLUS else 1
		outcome = "upgrade2" if change == 2 else "upgrade"
	var worn: String = ""
	for slot: String in Run.gear:
		if is_same(Run.gear[slot], item):  # the very piece you wear, not an equal copy in the bag
			worn = slot
	if worn:
		_apply(item, -1)
	item.plus += change
	if worn:
		_apply(item, 1)
	var line: String = "Rolled %d %+d Luck = %d vs DC %d: " % [rolled, Run.hero.luck, total, dc]
	line += {"upgrade": "success! Now %s.", "upgrade2": "great success, two levels! Now %s.", "fail": "failed. %s is unchanged.",
		"down": "natural 1! It cracked: now %s."}[outcome] % title(item)
	return {"item": item, "outcome": outcome, "text": line}


## After a won fight: the monster's material, and a d20 for its blueprint (data "loot"). Returns the log line.
static func loot(foe: Combatant) -> String:
	if foe.loot.is_empty():
		return ""
	var material: String = foe.loot.material
	Run.materials[material] = Run.materials.get(material, 0) + int(foe.loot.count)
	var text: String = "%s dropped %s x%d." % [foe.display_name, Run.data("materials")[material].name, foe.loot.count]
	var blueprint: String = foe.loot.get("blueprint", "")
	if blueprint and blueprint not in Run.blueprints:
		var rolled: int = Dice.roll(20)
		if rolled >= int(foe.loot.blueprint_roll):
			Run.blueprints.append(blueprint)
			text += " Loot roll %d: BLUEPRINT %s! (Blacksmith)" % [rolled, entry(blueprint).name]
	return text


## Add (direction 1) or remove (-1) a piece's stats, then update what the hero sprite shows.
static func _apply(item: Dictionary, direction: int) -> void:
	var all: Dictionary = stats(item)
	for stat in all:
		Run.hero.raise_stat(stat, direction * int(all[stat]))
	Run.hero.hp = clampi(Run.hero.hp, 1, Run.hero.max_hp)
	for slot in ["helmet", "armor", "offhand"]:
		Run.hero_look[slot] = Run.gear[slot].id if Run.gear.has(slot) else ""
	var tint: Array = entry(Run.gear.weapon.id).get("tint", [1, 1, 1]) if Run.gear.has("weapon") else [1, 1, 1]
	Run.hero_look.weapon_tint = Color(tint[0], tint[1], tint[2])
