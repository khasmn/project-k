class_name CharacterDraft
extends RefCounted
## A hero being created: rolled race and talent, picked class, and 5 rerolls each for race and talent.

const RARITY_CHANCES: Dictionary = {"common": 50, "uncommon": 25, "rare": 15, "epic": 8, "legendary": 2}
const REROLLS: int = 5

var races: Dictionary = Run.data("races")
var talents: Dictionary = Run.data("talents")
var classes: Dictionary = Run.data("classes")
var looks: Dictionary = Run.data("looks")

var race_id: String = roll_by_rarity(races)
var talent_id: String = roll_by_rarity(talents)
var class_id: String = ""
var race_rerolls_left: int = REROLLS
var talent_rerolls_left: int = REROLLS
## Name and appearance: skin is an index into the race's "skins", the others are ids from looks.json.
var look: Dictionary = {"name": "", "skin": 0, "hair_style": "short", "hair_color": "brown", "outfit": "adventurer"}


## Spend one "race" or "talent" reroll. Returns false if none are left.
func reroll(kind: String) -> bool:
	var left: String = kind + "_rerolls_left"
	if get(left) == 0:
		return false
	set(left, get(left) - 1)
	set(kind + "_id", roll_by_rarity(get(kind + "s")))
	return true


## Final stats: the class's base stats plus race and talent changes. Needs a class picked.
func stats() -> Dictionary:
	var result: Dictionary = {}
	for stat in classes[class_id].stats:
		result[stat] = (int(classes[class_id].stats[stat]) + int(races[race_id].stats.get(stat, 0))
			+ int(talents[talent_id].get("stats", {}).get(stat, 0)))
	return result


## Everything Combatant.new() needs to build this hero. A Mage attacks with Magic.
func hero_data() -> Dictionary:
	var hero_class: Dictionary = classes[class_id]
	var s: Dictionary = stats()
	return {
		"name": look.name if look.name != "" else hero_class.name,
		"hp": s.hp,
		"attack": s[hero_class.attack_stat],
		"attack_name": hero_class.attack_stat.capitalize(),
		"defense": s.defense,
		"speed": s.speed,
		"damage_die": hero_class.damage_die,
		"weapon": hero_class.weapon.to_lower(),
		"skills": hero_class.skills,
		"energy_name": hero_class.get("energy_name", "Energy"),
		"start_energy": hero_class.get("start_energy", 1),
		"effects": races[race_id].get("effects", {}).merged(talents[talent_id].get("effects", {})),
		"passive_names": _passive_names(),
	}


## What HeroSprite needs to draw this hero (no class yet = no weapon).
func sprite_look() -> Dictionary:
	return {
		"race": race_id, "class": class_id, "outfit": look.outfit, "hair_style": look.hair_style,
		"skin": Color(races[race_id].skins[look.skin]), "hair_color": Color(looks.hair_colors[look.hair_color]),
	}


## Which race or talent each effect comes from, for the log: {"advantage": "Chosen One"}.
func _passive_names() -> Dictionary:
	var names: Dictionary = {}
	for entry in [races[race_id], talents[talent_id]]:
		for effect in entry.get("effects", {}):
			names[effect] = entry.name
	return names


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

