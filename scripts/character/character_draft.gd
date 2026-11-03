class_name CharacterDraft
extends RefCounted
## A hero being created: rolled race and talent, picked class, and the shared rerolls.

const RARITY_CHANCES: Dictionary = {"common": 50, "uncommon": 25, "rare": 15, "epic": 8, "legendary": 2}
const REROLLS: int = 5

var races: Dictionary = _load("res://data/races.json")
var talents: Dictionary = _load("res://data/talents.json")
var classes: Dictionary = _load("res://data/classes.json")

var race_id: String = roll_by_rarity(races)
var talent_id: String = roll_by_rarity(talents)
var class_id: String = ""
var rerolls_left: int = REROLLS


## Spend one shared reroll on the race. Returns false if none are left.
func reroll_race() -> bool:
	if rerolls_left == 0:
		return false
	rerolls_left -= 1
	race_id = roll_by_rarity(races)
	return true


## Spend one shared reroll on the talent. Returns false if none are left.
func reroll_talent() -> bool:
	if rerolls_left == 0:
		return false
	rerolls_left -= 1
	talent_id = roll_by_rarity(talents)
	return true


## Final stats: the class's base stats plus the race's changes. Needs a class picked.
func stats() -> Dictionary:
	var result: Dictionary = {}
	for stat in classes[class_id].stats:
		result[stat] = int(classes[class_id].stats[stat]) + int(races[race_id].stats.get(stat, 0))
	return result


## Roll a rarity (Common 50%, Uncommon 25%, Rare 15%, Epic 8%, Legendary 2%), then a random
## entry of that rarity. Rarities with no entries are skipped and the others scale up.
static func roll_by_rarity(entries: Dictionary) -> String:
	var ids_by_rarity: Dictionary = {}
	for id in entries:
		ids_by_rarity.get_or_add(entries[id].rarity, []).append(id)
	var total: int = 0
	for rarity in RARITY_CHANCES:
		if ids_by_rarity.has(rarity):
			total += RARITY_CHANCES[rarity]
	var pick: int = Dice.roll(total)
	for rarity in RARITY_CHANCES:
		if not ids_by_rarity.has(rarity):
			continue
		pick -= RARITY_CHANCES[rarity]
		if pick <= 0:
			var ids: Array = ids_by_rarity[rarity]
			return ids[Dice.roll(ids.size()) - 1]
	return ""


static func _load(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))
